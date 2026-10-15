extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: ", description)

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await frames(30)
	var player = world.player
	check(player.is_on_floor(), "Player settles on factory floor")
	var start: Vector3 = player.position
	Input.action_press("forward")
	await frames(20)
	Input.action_release("forward")
	check(player.position.z < start.z - 0.5, "Forward input moves player through physics")
	Input.action_press("jump")
	await frames(8)
	check(player.position.y > 0.5, "Jump input lifts player")
	Input.action_release("jump")
	await frames(60)
	check(player.is_on_floor(), "Player lands after jump")
	player.energy = 20.0
	player.gems = 25.0
	check(player.spend_cryo() and player.energy == 0 and player.gems == 10, "Cryo uses regenerating reserve before gems")
	player.energy = 0
	player.gems = 0
	check(not player.spend_cryo(), "Insufficient energy refuses action")
	await frames(200)
	check(player.energy >= 35, "Energy regenerates without gems for puzzle retries")
	player.position = world.crate.position + Vector3(0, 0, 1.5)
	world.interact()
	check(player.carrying, "Nearby crate can be picked up")
	world.interact()
	check(not player.carrying, "Crate can be released")
	player.position = Vector3(-6, 3.05, -1.5)
	player.velocity = Vector3.ZERO
	player.facing = Vector3.FORWARD
	player.energy = 100
	world.freeze()
	check(world.freeze_time > 0, "Balcony provides clear cryo shot to rotor")
	await frames(2)
	check(world.gate.position.y == 6, "Frozen rotor opens gate")
	world.freeze_time = 0
	await frames(2)
	check(world.gate.position.y == 2, "Gate closes after thaw")
	player.position = world.enemy.position + Vector3(0, -0.85, 1.5)
	player.facing = Vector3.FORWARD
	player.energy = 0
	player.gems = 0
	for i in 3:
		world.attack()
	check(world.enemy_health == 0, "Three sword hits defeat miner with zero energy")
	player.position = Vector3(-4.5, 0.1, -13)
	await frames(2)
	check(world.shortcut, "Entering final area unlocks permanent shortcut")
	player.position = Vector3(6.5, 0.1, -7)
	await frames(2)
	check(world.complete, "Returning through shortcut completes loop")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
