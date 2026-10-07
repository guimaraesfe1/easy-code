extends SceneTree
## Standalone physics/camera regression checks. -- --capture saves rendered previews.

const LEVELS := [
	"res://gameplay/levels/factory/factory_06_final.tscn",
	"res://gameplay/levels/factory/factory_02_coolant.tscn",
	"res://gameplay/levels/factory/factory_03_dispatch.tscn",
]
var failures: Array[String] = []
var capture := false
var level: Node3D

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _capture(name: String) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/easy-code-" + name + ".png")

func _camera_inside() -> bool:
	var camera: Camera3D = level.get_node("CameraRig/Camera3D")
	var viewport_size := root.get_visible_rect().size
	var ground := Plane(Vector3.UP, 0.0)
	for corner in [Vector2.ZERO, Vector2(viewport_size.x, 0), viewport_size, Vector2(0, viewport_size.y)]:
		var point: Variant = ground.intersects_ray(camera.project_ray_origin(corner), camera.project_ray_normal(corner))
		if point == null or not level.floor_bounds.grow(0.02).has_point(Vector2(point.x, point.z)):
			return false
	return true

func _player_visible() -> bool:
	var camera: Camera3D = level.get_node("CameraRig/Camera3D")
	var player: CharacterBody3D = level.get_node("Player")
	for height in [0.1, 1.45]:
		var point := camera.unproject_position(player.global_position + Vector3.UP * height)
		if not root.get_visible_rect().has_point(point):
			return false
	return true

func _run() -> void:
	var files := DirAccess.get_files_at("res://gameplay/props/factory")
	var count := 0
	for file in files:
		if not file.ends_with(".tscn"):
			continue
		var prop: Node3D = load("res://gameplay/props/factory/" + file).instantiate()
		_check(prop.has_node("Visual"), "Prop retains a model reference: " + file)
		if prop is StaticBody3D:
			_check(prop.has_node("Collision") and prop.get_node("Collision").shape != null, "Solid prop has a shape: " + file)
			_check(prop.get_node("Collision").get_parent() == prop, "Collision is directly below its body: " + file)
		prop.free()
		count += 1
	_check(count == 143, "All 143 factory models have reusable props")
	for index in LEVELS.size():
		level = load(LEVELS[index]).instantiate()
		root.add_child(level)
		current_scene = level
		await _frames(40)
		var player: CharacterBody3D = level.get_node("Player")
		var camera: Camera3D = level.get_node("CameraRig/Camera3D")
		_check(player.is_on_floor(), "Player stands on floor in level %d" % (index + 1))
		_check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthographic projection")
		_check(level.get_node("CameraRig/PhantomCamera3D").is_active(), "Phantom Camera controls the camera")
		_check(_camera_inside(), "Initial viewport stays inside the map")
		_check(_player_visible(), "Player is visible at spawn")
		await _capture("factory-%d-spawn" % (index + 1))
		var start := player.global_position
		var camera_start := camera.global_position
		Input.action_press("move_up")
		await _frames(20)
		Input.action_release("move_up")
		_check(player.global_position.distance_to(start) > 0.35, "Player responds to movement")
		_check(camera.global_position.distance_to(camera_start) > 0.02, "Camera follows movement")
		var rig: Node3D = level.get_node("CameraRig")
		var follow_destination: Vector3 = rig.get_node("BoundedTarget").global_position + rig.get_node("PhantomCamera3D").follow_offset
		var follow_gap := camera.global_position.distance_to(follow_destination)
		_check(follow_gap > 0.02, "Following is damped rather than snapping to the player")
		_check(_camera_inside(), "Camera stays inside while moving")
		await _frames(30)
		follow_destination = rig.get_node("BoundedTarget").global_position + rig.get_node("PhantomCamera3D").follow_offset
		_check(camera.global_position.distance_to(follow_destination) < follow_gap, "Camera settles after stopping")
		var safe: Rect2 = level.walk_bounds.grow(-0.65)
		for corner in [safe.position, Vector2(safe.end.x, safe.position.y), safe.end, Vector2(safe.position.x, safe.end.y)]:
			player.position = Vector3(corner.x, 0.1, corner.y)
			player.velocity = Vector3.ZERO
			player.reset_physics_interpolation()
			for frame in 55:
				await _frames(1)
				_check(_camera_inside(), "Camera footprint stays inside during edge follow")
			_check(_player_visible(), "Player remains visible in map corners")
		await _capture("factory-%d-edge" % (index + 1))
		# Movement toward the east guardrail must be stopped by real geometry.
		player.position = Vector3(level.walk_bounds.end.x - 1.0, 0.1, 0)
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		Input.action_press("move_right")
		Input.action_press("move_down")
		await _frames(60)
		Input.action_release("move_right")
		Input.action_release("move_down")
		_check(player.position.x < level.walk_bounds.end.x - 0.25, "Guardrail blocks exit")
		_check(player.is_on_floor(), "Player stays grounded at boundary")
		for resolution in [Vector2i(960, 640), Vector2i(640, 480), Vector2i(1280, 480), Vector2i(1280, 720)]:
			root.size = resolution
			await _frames(15)
			_check(_camera_inside(), "No exterior visible after resizing")
			_check(_player_visible(), "Player stays visible after resizing")
		if capture:
			# Temporary overview for inspecting the authored layout; never saved in a level.
			var overview := Camera3D.new()
			level.add_child(overview)
			overview.projection = Camera3D.PROJECTION_ORTHOGONAL
			overview.size = 32
			overview.position = Vector3(25, 38, 25)
			overview.look_at(Vector3.ZERO)
			overview.make_current()
			await _frames(4)
			await _capture("factory-%d-overview" % (index + 1))
		level.queue_free()
		await _frames(3)
	if failures.is_empty():
		print("PASS: 143 props, 3 levels, movement, floors, guardrails, Phantom Camera, corner framing and resizing")
	else:
		print("FAIL: ", failures.size(), " factory checks")
	quit(0 if failures.is_empty() else 1)
