extends Node
## One shared resource updates every UI scene, including directly launched levels.

signal theme_changed

const SETTINGS_PATH := "user://settings.cfg"
const MENU_THEME := preload("res://ui/menu_theme.tres")
var dark_mode := false
var _light_theme: Theme

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_light_theme = MENU_THEME.duplicate(true)
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		dark_mode = settings.get_value("appearance", "dark_mode", false) == true
	_update_theme()
	get_tree().node_added.connect(_on_node_added)

func set_dark_mode(enabled: bool) -> void:
	if dark_mode == enabled:
		return
	dark_mode = enabled
	_update_theme()
	_refresh(get_tree().root)
	theme_changed.emit()
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("appearance", "dark_mode", dark_mode)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Não foi possível salvar a preferência de tema.")

func readable_accent(color: Color) -> Color:
	return color.lightened(0.45) if dark_mode else color

func set_accent(label: Label, color: Color) -> void:
	label.set_meta("font_color", color)
	label.add_theme_color_override("font_color", readable_accent(color))

func _update_theme() -> void:
	MENU_THEME.merge_with(_light_theme)
	if not dark_mode:
		return
	for type in MENU_THEME.get_type_list():
		for name in MENU_THEME.get_color_list(type):
			MENU_THEME.set_color(name, type, Color("edf3fa"))
		for name in MENU_THEME.get_stylebox_list(type):
			var style: StyleBox = _light_theme.get_stylebox(name, type).duplicate()
			if style is StyleBoxTexture and name != &"focus":
				var tint := Color("29374a")
				if type == &"PrimaryButton":
					tint = Color("276fa8")
				if name == &"hover":
					tint = tint.lightened(0.12)
				elif name == &"pressed":
					tint = tint.darkened(0.15)
				style.modulate_color = tint
			elif style is StyleBoxFlat:
				style.bg_color = Color("46576d")
			MENU_THEME.set_stylebox(name, type, style)

func _on_node_added(node: Node) -> void:
	_apply.call_deferred(node)

func _refresh(node: Node) -> void:
	_apply(node)
	for child in node.get_children():
		_refresh(child)

func _apply(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	if node is ColorRect:
		if not node.has_meta("light_color"):
			node.set_meta("light_color", node.color)
		var original: Color = node.get_meta("light_color")
		node.color = Color("111923") if dark_mode and original.a == 1.0 else original
	if node is Label:
		for key in [&"font_color", &"font_outline_color"]:
			if not node.has_theme_color_override(key):
				continue
			if not node.has_meta(key):
				node.set_meta(key, node.get_theme_color(key))
			var original: Color = node.get_meta(key)
			var color := original
			if dark_mode:
				color = Color("111923") if key == &"font_outline_color" else readable_accent(original)
			node.add_theme_color_override(key, color)
	if node is PanelContainer and node.has_theme_stylebox_override("panel"):
		if not node.has_meta("light_panel"):
			node.set_meta("light_panel", node.get_theme_stylebox("panel").duplicate())
		var style: StyleBox = node.get_meta("light_panel").duplicate()
		if dark_mode and style is StyleBoxTexture:
			style.modulate_color = Color("243448")
		node.add_theme_stylebox_override("panel", style)
