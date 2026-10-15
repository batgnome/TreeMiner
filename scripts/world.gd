extends Node3D

const Player = preload("res://scripts/player.gd")
var player: CharacterBody3D
var crate: CharacterBody3D
var enemy: CharacterBody3D
var gate: StaticBody3D
var rotor: MeshInstance3D
var hud: Label
var enemy_health := 3
var enemy_state := "approach"
var enemy_timer := 0.0
var enemy_frozen := 0.0
var freeze_time := 0.0
var shortcut := false
var complete := false
var message := "Reach the orange balcony using the crate."
var spawn := Vector3(0, 0.1, 5)
var crate_spawn := Vector3(-3, 0.05, 0)

func _ready() -> void:
	configure_inputs()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.4
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a7bbce")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	box("Floor", Vector3(0, -0.5, -5), Vector3(24, 1, 30), Color("343e49"))
	box("Left wall", Vector3(-12, 3, -5), Vector3(0.5, 7, 30), Color("26313b"))
	box("Right wall", Vector3(12, 3, -5), Vector3(0.5, 7, 30), Color("26313b"))
	box("Back wall", Vector3(0, 3, 10), Vector3(24, 7, 0.5), Color("26313b"))
	box("End wall", Vector3(0, 3, -20), Vector3(24, 7, 0.5), Color("26313b"))
	# The full-width partition has one timed doorway and one permanent return door.
	box("Partition left", Vector3(-9, 2, -10), Vector3(6, 4, 0.5), Color("53616a"))
	box("Partition middle", Vector3(1, 2, -10), Vector3(8, 4, 0.5), Color("53616a"))
	box("Partition right", Vector3(10, 2, -10), Vector3(4, 4, 0.5), Color("53616a"))
	box("Header", Vector3(0, 5, -10), Vector3(24, 2, 0.5), Color("53616a"))
	gate = box("Cryo gate", Vector3(-4.5, 2, -10), Vector3(3, 4, 0.6), Color("498a9e"))
	box("Shortcut", Vector3(6.5, 2, -10), Vector3(3, 4, 0.6), Color("bd9348"))
	box("Balcony", Vector3(-6, 1.5, -3), Vector3(5, 3, 4), Color("b6793b"))
	rotor = visual(Vector3(-6, 4.3, -3), Vector3(0.2, 1.7, 1.7), Color("60d5e8"))
	box("Practice step", Vector3(5, 0.35, 4), Vector3(3, 0.7, 3), Color("627a70"))
	box("Practice platform", Vector3(8, 0.8, 0), Vector3(3, 1.6, 3), Color("627a70"))
	box("Root", Vector3(9, 3, -16), Vector3(2, 6, 2), Color("6e6345"))
	crate = CharacterBody3D.new()
	crate.name = "Crate"
	crate.collision_layer = 1
	crate.collision_mask = 1
	add_child(crate)
	attach_box(crate, Vector3.ONE * 1.3, Color("c59451"))
	crate.position = crate_spawn + Vector3.UP * 0.65
	enemy = CharacterBody3D.new()
	enemy.name = "InfectedMiner"
	enemy.collision_layer = 4
	enemy.collision_mask = 1
	add_child(enemy)
	attach_box(enemy, Vector3(0.9, 1.7, 0.9), Color("9f5141"))
	enemy.position = Vector3(0, 0.85, -5)
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = spawn
	player.slash.connect(attack)
	player.cryo.connect(freeze)
	player.interact.connect(interact)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(20, 20)
	hud.add_theme_font_size_override("font_size", 20)
	canvas.add_child(hud)

func configure_inputs() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "interact": KEY_E, "reset": KEY_R, "reset_crate": KEY_T, "release_mouse": KEY_ESCAPE}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for pair in [["attack", MOUSE_BUTTON_LEFT], ["cryo", MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var event := InputEventMouseButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0], event)

func attach_box(parent: Node3D, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	parent.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	parent.add_child(collision)

func box(title: String, location: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	add_child(body)
	body.position = location
	attach_box(body, size, color)
	return body

func visual(location: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	add_child(mesh)
	return mesh

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("reset_crate"):
		player.carrying = false
		crate.position = crate_spawn + Vector3.UP * 0.65
		crate.velocity = Vector3.ZERO
	update_crate(delta)
	update_enemy(delta)
	freeze_time = maxf(0, freeze_time - delta)
	# Do not close a solid gate through the player or the puzzle crate.
	if freeze_time == 0 and gate.position.y > 2.0:
		for occupant in [player, crate]:
			if absf(occupant.position.x + 4.5) < 2.2 and absf(occupant.position.z + 10) < 1.2:
				freeze_time = 0.2
	gate.position.y = 6.0 if freeze_time > 0 else 2.0
	if freeze_time == 0:
		rotor.rotation.x += delta * 3
	if player.position.z < -12 and not shortcut:
		shortcut = true
		var door := get_node("Shortcut") as StaticBody3D
		door.position.y = 7
		message = "Shortcut unlocked! Return through the gold doorway to finish."
	if shortcut and player.position.z > -8 and player.position.x > 4:
		complete = true
		message = "COOLING STATION COMPLETE — R to play again."
	var prompt := ""
	if player.global_position.distance_to(crate.global_position) < 2.6 or player.carrying:
		prompt = "E: place crate" if player.carrying else "E: carry crate | walk into it to push"
	hud.text = "COOLING STATION | Health %d/5 | Energy %d | Gems %d\nWASD move · Mouse camera · Space jump (hold for height)\nLMB katana · RMB cryo · E carry/place · T reset crate · R restart · Esc mouse\n%s\n%s\nCryo gate: %.1fs | Miner: %s" % [player.health, player.energy, player.gems, message, prompt, freeze_time, "defeated" if enemy_health <= 0 else enemy_state]

func update_crate(delta: float) -> void:
	if player.carrying:
		# Sweep toward the carry point; walls can never be crossed by teleporting.
		var target: Vector3 = player.position + player.facing * 1.3 + Vector3.UP * 1.0
		crate.velocity = (target - crate.position) * 12.0
		crate.move_and_slide()
	else:
		crate.velocity.y -= 25 * delta
		crate.velocity.x = 0
		crate.velocity.z = 0
		var offset := crate.position - player.position
		offset.y = 0
		if offset.length() < 1.3 and player.position.y < crate.position.y + 0.4:
			crate.velocity.x = player.velocity.x * 0.7
			crate.velocity.z = player.velocity.z * 0.7
		crate.move_and_slide()

func interact() -> void:
	if player.carrying:
		player.carrying = false
	elif player.position.distance_to(crate.position) < 2.6:
		player.carrying = true

func attack() -> void:
	if enemy_health <= 0:
		return
	var offset := enemy.position - (player.position + Vector3.UP * 0.8)
	if offset.length() < 2.4 and player.facing.dot(offset.normalized()) > 0.15:
		enemy_health -= 1
		enemy_state = "hurt"
		enemy_timer = 0.4
		if enemy_health <= 0:
			enemy.hide()
			enemy.collision_layer = 0
			message = "Miner defeated. Cryo the cyan rotor from the orange balcony."

func freeze() -> void:
	if not player.spend_cryo():
		message = "Insufficient energy — let the blue reserve recharge."
		return
	var origin: Vector3 = player.position + Vector3.UP
	var target := rotor.global_position
	var enemy_target := false
	if enemy_health > 0 and origin.distance_to(enemy.position) < origin.distance_to(target):
		target = enemy.position
		enemy_target = true
	var offset := target - origin
	if offset.length() > 5.0 or player.facing.dot(offset.normalized()) < 0.35:
		message = "Cryo missed. Face a nearby target (range 5m)."
		return
	var ray := PhysicsRayQueryParameters3D.create(origin, target, 1)
	ray.exclude = [player.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		message = "Cryo blocked — find a clear line of sight."
		return
	if enemy_target:
		enemy_frozen = 3.0
		message = "Miner frozen for three seconds."
	else:
		freeze_time = 10.0
		message = "Mechanism frozen! Hurry through the blue doorway."

func update_enemy(delta: float) -> void:
	if enemy_health <= 0:
		return
	enemy_frozen = maxf(0, enemy_frozen - delta)
	if enemy_frozen > 0:
		return
	enemy_timer = maxf(0, enemy_timer - delta)
	var offset := player.position - enemy.position
	offset.y = 0
	if enemy_state == "windup" and enemy_timer == 0:
		if offset.length() < 2.1 and absf(player.position.y - (enemy.position.y - 0.85)) < 1.5:
			player.damage()
		enemy_state = "recovery"
		enemy_timer = 1.1
	elif enemy_state in ["recovery", "hurt"] and enemy_timer == 0:
		enemy_state = "approach"
	elif enemy_state == "approach":
		if offset.length() < 1.8:
			enemy_state = "windup"
			enemy_timer = 0.8
		elif offset.length() < 9:
			var direction := offset.normalized()
			enemy.velocity.x = direction.x * 2.0
			enemy.velocity.z = direction.z * 2.0
	if enemy_state != "approach":
		enemy.velocity.x = 0
		enemy.velocity.z = 0
	enemy.velocity.y -= 25 * delta
	enemy.move_and_slide()
	var mesh := enemy.get_child(0) as MeshInstance3D
	mesh.scale = Vector3(1.2, 0.8, 1.2) if enemy_state == "windup" else Vector3.ONE
