extends SceneTree
## Renders the factory Oopi model as flat-colored icons for the repair panel.
## Run with a display: godot --path . --script res://tools/render_oopi.gd

const COLORS := {"blue": Color("4f8dff"), "yellow": Color("ffd23f"), "lilac": Color("b48cff")}
const SIZE := 256
const COLORMAP := preload("res://factory/_Textures/variation-a.png")


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var model: Node3D = load("res://factory/glb/oopi.glb").instantiate()
	viewport.add_child(model)
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var bounds := AABB()
	for mesh: MeshInstance3D in meshes:
		var box := mesh.global_transform * mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(bounds.size.x, bounds.size.y) * 1.05
	var center := bounds.get_center()
	var direction := Vector3(-1, 0.25, -0.2)
	camera.position = center + direction.normalized() * 10
	viewport.add_child(camera)
	camera.look_at(center)
	var light := DirectionalLight3D.new()
	viewport.add_child(light)
	light.rotation_degrees = Vector3(-40, 30, 0)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	viewport.add_child(environment)
	var names := ["original"] + COLORS.keys()
	for name in names:
		for mesh: MeshInstance3D in meshes:
			if name == "original":
				mesh.material_override = null
			else:
				mesh.material_override = _tinted(COLORS[name])
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		# The untinted Oopi is the tutorial guide; tinted ones are the variables.
		var path := "res://ui/tutorial/oopi_guide.png" if name == "original" else "res://ui/repair_panel/oopi_%s.png" % name
		var image := viewport.get_texture().get_image()
		# Crop to the model so inline icons fill their requested size.
		image.get_region(image.get_used_rect()).save_png(path)
	quit()


## Only the teal creature takes the color; the white helmet and dark eyes stay,
## so no part keeps the original teal, which reads as the green "true" signal.
func _tinted(color: Color) -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
uniform sampler2D colormap : source_color, filter_nearest;
uniform vec3 tint : source_color;
void fragment() {
	vec3 base = texture(colormap, UV).rgb;
	float saturation = max(base.r, max(base.g, base.b)) - min(base.r, min(base.g, base.b));
	float shade = clamp(max(base.r, max(base.g, base.b)) / 0.8, 0.0, 1.2);
	ALBEDO = mix(base, tint * shade, smoothstep(0.15, 0.3, saturation));
	ROUGHNESS = 0.7;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("colormap", COLORMAP)
	material.set_shader_parameter("tint", color)
	return material
