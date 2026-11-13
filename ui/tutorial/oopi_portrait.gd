extends SubViewportContainer
## A lit, full-resolution 3D portrait of the factory guide.

func _ready() -> void:
	var viewport: SubViewport = $Viewport
	var model: Node3D = preload("res://factory/glb/oopi.glb").instantiate()
	viewport.add_child(model)
	var bounds := AABB()
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var box := mesh.global_transform * mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(bounds.size.y, bounds.size.z) * 1.1
	viewport.add_child(camera)
	camera.position = bounds.get_center() + Vector3(-1, 0.25, -0.2).normalized() * 10.0
	camera.look_at(bounds.get_center())
	var light := DirectionalLight3D.new()
	viewport.add_child(light)
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.2
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("b9d9ed")
	world.environment.ambient_light_energy = 0.55
	viewport.add_child(world)
	get_viewport().size_changed.connect(_resize_portrait)
	_resize_portrait()

func _resize_portrait() -> void:
	var screen := get_viewport_rect().size
	var portrait_size := minf(720.0, minf(screen.x, screen.y - 244.0))
	portrait_size = maxf(1.0, portrait_size * 0.5)
	offset_bottom = -244.0 + 100.0
	offset_top = offset_bottom - portrait_size
	offset_right = portrait_size
