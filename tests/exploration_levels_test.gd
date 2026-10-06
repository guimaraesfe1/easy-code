extends SceneTree
## Forest and dungeon regression checks: props, floors, barriers, waypoints and camera.
## -- --capture saves rendered previews.

const MAPS := {
	"forest": ["forest_01_glade", "forest_02_creek", "forest_03_camp", "forest_04_canyon", "forest_05_lake", "forest_06_deepwood"],
	"dungeon": ["dungeon_01_cellar", "dungeon_02_mine", "dungeon_03_hall", "dungeon_04_prison", "dungeon_05_vault", "dungeon_06_lair"],
}
const PROP_COUNTS := {"forest": 22, "dungeon": 30}
const MODULES := {"forest": ["campfire", "shelter", "watchtower"], "dungeon": ["brazier"]}
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
		if not root.get_visible_rect().has_point(camera.unproject_position(player.global_position + Vector3.UP * height)):
			return false
	return true

func _place(player: CharacterBody3D, position: Vector3) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()

func _check_props(map: String) -> void:
	var folder := "res://gameplay/props/%s/" % map
	var count := 0
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".tscn"):
			continue
		var prop: Node3D = load(folder + file).instantiate()
		_check(prop.has_node("Visual"), "Prop retains a model reference: " + file)
		_check(prop.get_meta("source_asset", "") != "", "Prop records its source model: " + file)
		if prop is StaticBody3D:
			_check(prop.has_node("Collision") and prop.get_node("Collision").shape != null, "Solid prop has a shape: " + file)
		prop.free()
		count += 1
	_check(count == PROP_COUNTS[map], "Every %s model has a reusable prop" % map)
	for module in MODULES[map]:
		_check(ResourceLoader.exists(folder + "modules/" + module + ".tscn"), "Module exists: " + module)

func _run() -> void:
	for map in MAPS:
		_check_props(map)
		var definition: MapDefinition = load("res://content/maps/%s.tres" % map)
		for index in MAPS[map].size():
			var name: String = MAPS[map][index]
			var path := "res://gameplay/levels/%s/%s.tscn" % [map, name]
			_check(definition.levels[index].scene_path == path, "Level %s is selectable from the menu" % name)
			level = load(path).instantiate()
			root.add_child(level)
			current_scene = level
			await _frames(40)
			var player: CharacterBody3D = level.get_node("Player")
			var camera: Camera3D = level.get_node("CameraRig/Camera3D")
			var walk: Rect2 = level.walk_bounds.grow(0.4)
			_check(level.floor_bounds.encloses(level.walk_bounds), name + ": walkable area lies inside the map")
			_check(player.is_on_floor(), name + ": player stands on the ground")
			_check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, name + ": orthographic projection")
			_check(level.get_node("CameraRig/PhantomCamera3D").is_active(), name + ": Phantom Camera controls the camera")
			_check(_camera_inside(), name + ": initial viewport stays inside the map")
			_check(_player_visible(), name + ": player is visible at spawn")
			await _capture(name + "-spawn")
			var spawn := player.global_position
			# Walking in any direction must end at real geometry, never outside the level.
			var moved := 0.0
			for action in ["move_up", "move_right", "move_down", "move_left"]:
				_place(player, spawn)
				await _frames(2)
				Input.action_press(action)
				for frame in 150:
					await _frames(1)
					if frame % 10 == 0:
						_check(_camera_inside(), name + ": camera footprint stays inside while walking " + action)
				Input.action_release(action)
				moved = maxf(moved, player.global_position.distance_to(spawn))
				_check(walk.has_point(Vector2(player.global_position.x, player.global_position.z)), name + ": barriers contain the player walking " + action)
				_check(player.is_on_floor() and absf(player.global_position.y) < 0.3, name + ": player stays grounded walking " + action)
				_check(_player_visible(), name + ": player stays in view walking " + action)
			_check(moved > 2.0, name + ": player can leave the spawn point")
			var waypoints := level.get_node("Waypoints").get_children()
			_check(waypoints.size() >= 2, name + ": has points of interest")
			for marker in waypoints:
				_place(player, marker.global_position)
				await _frames(70) # The damped camera needs time to catch up after a jump.
				_check(player.is_on_floor() and absf(player.global_position.y) < 0.3, name + ": waypoint is on open ground")
				_check(player.global_position.distance_to(marker.global_position) < 0.4, name + ": waypoint is not inside a prop")
				_check(_camera_inside(), name + ": camera stays inside at waypoints")
				_check(_player_visible(), name + ": player is visible at waypoints")
			await _capture(name + "-waypoint")
			_place(player, spawn)
			await _frames(70)
			for resolution in [Vector2i(960, 640), Vector2i(640, 480), Vector2i(1280, 480), Vector2i(1280, 720)]:
				root.size = resolution
				await _frames(30)
				_check(_camera_inside(), name + ": no exterior visible after resizing")
				_check(_player_visible(), name + ": player stays visible after resizing")
			if capture:
				# Temporary overview for inspecting the authored layout; never saved in a level.
				var overview := Camera3D.new()
				level.add_child(overview)
				overview.projection = Camera3D.PROJECTION_ORTHOGONAL
				overview.size = level.floor_bounds.size.x * 0.82
				overview.far = 200.0
				overview.position = Vector3(30, 52, 30)
				overview.look_at(Vector3.ZERO)
				overview.make_current()
				await _frames(4)
				await _capture(name + "-overview")
			level.queue_free()
			await _frames(3)
	if failures.is_empty():
		print("PASS: 52 props, 4 modules, 12 levels, floors, barriers, waypoints, Phantom Camera and resizing")
	else:
		print("FAIL: ", failures.size(), " exploration checks")
	quit(0 if failures.is_empty() else 1)
