extends SceneTree
## Check the reference-based opening layout, reachable repairs and terrace access.

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

func _run() -> void:
	var level = load("res://gameplay/levels/factory/factory_01_assembly.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	_check(level.level_number == 1, "Reference layout starts Factory progression")
	_check(level.get_meta("layout_reference") == "res://mapa.png", "Layout records its reference")
	_check(level.machines.size() == 6, "Six repair targets are registered")
	for index in level.machines.size():
		var puzzle := LogicPuzzle.create(level.level_number, index)
		_check(puzzle.headers.size() == 3, "Opening problems have one simple operator and no intermediate columns")
	_check(level.get_node("BackgroundMusic").playing, "Factory music starts")
	var player: CharacterBody3D = level.get_node("Player")
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.31
	shape.height = 1.5
	query.shape = shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	# Flood-fill actual clear ground cells from the spawn, accounting for the
	# player's volume rather than testing only unobstructed point rays.
	var clear: Dictionary[Vector2i, bool] = {}
	for x in range(-28, 29):
		for z in range(-24, 25):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x * 0.5, 0.83, z * 0.5))
			clear[Vector2i(x, z)] = space.intersect_shape(query, 1).is_empty()
	var queue: Array[Vector2i] = [Vector2i(0, 20)]
	var visited: Dictionary[Vector2i, bool] = {Vector2i(0, 20): true}
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if clear.get(next, false) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	for machine in level.machines:
		var reachable := false
		for cell in visited:
			var position := Vector2(cell.x * 0.5, cell.y * 0.5)
			if position.distance_to(Vector2(machine.position.x, machine.position.z)) < level.interaction_distance - 0.2:
				reachable = true
				break
		_check(reachable, "Reachable repair station: " + machine.name)
		player.position = machine.position + Vector3(0, 0.08, 1.65)
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		await _frames(4)
		_check(level.select_machine(machine), "Repair opens at station: " + machine.name)
		level._on_puzzle_closed()
	player.position = Vector3(-5, 0.08, 7.1)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	Input.action_press("move_up")
	Input.action_press("move_right")
	await _frames(120)
	Input.action_release("move_up")
	Input.action_release("move_right")
	_check(player.position.y > 1.7 and player.is_on_floor(), "Player can climb the terrace staircase")
	paused = false
	level.queue_free()
	await _frames(3)
	if failures.is_empty():
		print("PASS: Factory 01 reference layout, 6 reachable repair stations, music and walkable staircase")
	quit(0 if failures.is_empty() else 1)
