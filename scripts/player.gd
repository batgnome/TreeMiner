extends CharacterBody3D

signal slash
signal cryo
signal interact

@export var speed := 8.0
@export var acceleration := 35.0
@export var jump_speed := 10.0
@export var gravity := 25.0
var health := 5
var energy := 100.0
var gems := 25.0
var facing := Vector3.FORWARD
var coyote := 0.0
var jump_buffer := 0.0
var attack_cooldown := 0.0
var cryo_cooldown := 0.0
var hurt_cooldown := 0.0
var energy_delay := 0.0
var yaw := 0.0
var pitch := -0.25
var pivot: Node3D
var boom: SpringArm3D
var body_visual: Node3D
var sword: MeshInstance3D
var carrying := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.6
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.8
	add_child(collider)
	body_visual = Node3D.new()
	add_child(body_visual)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.6
	mesh.mesh = capsule
	mesh.position.y = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c48143")
	mesh.material_override = material
	body_visual.add_child(mesh)
	sword = MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = Vector3(0.08, 0.08, 1.3)
	sword.mesh = blade
	sword.position = Vector3(0.55, 0.9, -0.4)
	body_visual.add_child(sword)
	pivot = Node3D.new()
	pivot.position.y = 1.5
	add_child(pivot)
	boom = SpringArm3D.new()
	boom.spring_length = 6.0
	boom.margin = 0.2
	boom.collision_mask = 1
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.2
	boom.shape = camera_shape
	pivot.add_child(boom)
	var camera := Camera3D.new()
	camera.current = true
	boom.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.003
		pitch = clampf(pitch - event.relative.y * 0.003, -1.0, 0.25)
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	pivot.rotation = Vector3(pitch, yaw, 0)
	coyote = 0.12 if is_on_floor() else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	cryo_cooldown = maxf(0.0, cryo_cooldown - delta)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	energy_delay = maxf(0.0, energy_delay - delta)
	if energy_delay == 0.0:
		energy = minf(100.0, energy + 22.0 * delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.15
	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = jump_speed
		jump_buffer = 0.0
		coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y > 4.0:
		velocity.y = 4.0
	velocity.y -= gravity * delta
	var axis := Input.get_vector("left", "right", "forward", "back")
	var direction := Vector3(axis.x, 0, axis.y).rotated(Vector3.UP, yaw)
	var target_speed := speed * (0.65 if carrying else 1.0)
	velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	if direction.length() > 0.1:
		facing = direction.normalized()
		body_visual.rotation.y = lerp_angle(body_visual.rotation.y, atan2(-facing.x, -facing.z), 18.0 * delta)
	move_and_slide()
	if Input.is_action_just_pressed("attack") and attack_cooldown == 0.0 and not carrying:
		attack_cooldown = 0.45
		slash.emit()
	if Input.is_action_just_pressed("cryo") and cryo_cooldown == 0.0 and not carrying:
		cryo.emit()
	if Input.is_action_just_pressed("interact"):
		interact.emit()
	sword.rotation.y = sin((0.45 - attack_cooldown) * 18.0) * 1.5 if attack_cooldown > 0.0 else 0.0
	body_visual.scale = Vector3.ONE * (0.9 if hurt_cooldown > 0.8 else 1.0)
	if position.y < -8.0:
		get_tree().reload_current_scene()

func spend_cryo() -> bool:
	if energy + gems < 35.0:
		return false
	var reserve_cost := maxf(0.0, 35.0 - energy)
	energy = maxf(0.0, energy - 35.0)
	gems -= reserve_cost
	energy_delay = 1.5
	cryo_cooldown = 0.6
	return true

func damage() -> void:
	if hurt_cooldown > 0.0:
		return
	health -= 1
	hurt_cooldown = 1.0
	if health <= 0:
		get_tree().reload_current_scene()
