extends SceneTree
## Run: godot --headless --path . --script res://tests/player_running_test.gd

var player: CharacterBody3D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _key(code: Key, pressed: bool, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await _frames(1)

func _reset() -> void:
	for code in [KEY_SHIFT, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]:
		await _key(code, false)
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 1, 100)
	collision.shape = shape
	floor.position.y = -0.5
	floor.add_child(collision)
	world.add_child(floor)
	player = load("res://gameplay/player/player_humanoid.tscn").instantiate()
	world.add_child(player)
	await _frames(3)
	var animator := player.get_node("AnimationPlayer") as AnimationPlayer
	_check(animator.get_animation("Locomotion/run").loop_mode == Animation.LOOP_LINEAR, "Running animation loops")
	for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]:
		await _reset()
		await _key(KEY_SHIFT, true)
		await _key(code, true)
		await _frames(22)
		_check(Vector2(player.velocity.x, player.velocity.z).length() > player.speed + 1.0, "Shift increases speed: %s" % code)
		_check(animator.current_animation == "Locomotion/run", "Shift plays running: %s" % code)
		await _key(KEY_SHIFT, false)
		await _frames(22)
		_check(animator.current_animation == "Locomotion/walk", "Releasing Shift returns to walking: %s" % code)
		await _key(KEY_SHIFT, true)
		await _frames(22)
		_check(animator.current_animation == "Locomotion/run", "Shift pressed while walking starts running: %s" % code)
		await _key(code, false)
		await _frames(22)
		_check(animator.current_animation == "Locomotion/idle", "Shift alone does not move: %s" % code)
	await _reset()
	await _key(KEY_W, true)
	await _key(KEY_W, false)
	await _key(KEY_W, true)
	await _frames(22)
	_check(animator.current_animation == "Locomotion/walk", "Double tap remains walking")
	_check(Vector2(player.velocity.x, player.velocity.z).length() < player.speed + 0.1, "Double tap keeps walking speed")
	await _reset()
	world.queue_free()
	await _frames(2)
	if failures.is_empty():
		print("PASS: Shift running in 8 keys, speed/animation, release and no double-tap running")
	quit(0 if failures.is_empty() else 1)
