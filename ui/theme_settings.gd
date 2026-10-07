extends Node
## One shared resource updates every UI scene, including directly launched levels.

signal theme_changed

const SETTINGS_PATH := "user://settings.cfg"
const MENU_THEME := preload("res://ui/menu_theme.tres")
const PIXEL_FONT := preload("res://assets/fonts/Monocraft.ttc")
## Godot only loads the regular face of the collection, so the weight is synthesized.
const PIXEL_FONT_EMBOLDEN := 1.0
const DARK_BACKGROUND := Color.BLACK
const DARK_TEXT := Color("f2f2f2")
const DARK_BUTTON := Color("1c1c1c")
const DARK_PANEL := Color("121212")
const DARK_BORDER := Color("3a3a3a")
var dark_mode := false
var _light_theme: Theme
var _pixel_font: FontVariation

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_light_theme = MENU_THEME.duplicate(true)
	_pixel_font = FontVariation.new()
	_pixel_font.base_font = PIXEL_FONT
	_pixel_font.variation_embolden = PIXEL_FONT_EMBOLDEN
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
	MENU_THEME.set_default_font(_pixel_font)
	if not dark_mode:
		return
	for type in MENU_THEME.get_type_list():
		for name in MENU_THEME.get_color_list(type):
			MENU_THEME.set_color(name, type, DARK_TEXT)
		for name in MENU_THEME.get_stylebox_list(type):
			MENU_THEME.set_stylebox(name, type, _dark_style(name, _light_theme.get_stylebox(name, type)))

func _dark_style(name: StringName, light: StyleBox) -> StyleBox:
	if light is StyleBoxFlat:
		var divider: StyleBoxFlat = light.duplicate()
		divider.bg_color = DARK_BORDER
		return divider
	var style := StyleBoxFlat.new()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, light.get_content_margin(side))
	match name:
		&"focus":
			style.draw_center = false
			style.border_color = DARK_BORDER
			style.set_border_width_all(2)
		&"panel":
			style.bg_color = DARK_PANEL
			style.border_color = DARK_BORDER
			style.set_border_width_all(2)
		_:
			# Flat buttons are shorter than the light theme's sprite buttons.
			style.content_margin_top = minf(style.content_margin_top, 10.0)
			style.content_margin_bottom = minf(style.content_margin_bottom, 10.0)
			style.bg_color = DARK_BUTTON
			if name == &"hover":
				style.bg_color = DARK_BUTTON.lightened(0.08)
			elif name == &"pressed":
				style.bg_color = DARK_BUTTON.lightened(0.16)
	return style

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
		node.color = DARK_BACKGROUND if dark_mode and original.a == 1.0 else original
	if node is Label:
		for key in [&"font_color", &"font_outline_color"]:
			if not node.has_theme_color_override(key):
				continue
			if not node.has_meta(key):
				node.set_meta(key, node.get_theme_color(key))
			var original: Color = node.get_meta(key)
			var color := original
			if dark_mode:
				# Scenes may pin a dark-theme color with "dark_font_color" metadata.
				var dark_key := StringName("dark_" + key)
				if node.has_meta(dark_key):
					color = node.get_meta(dark_key)
				elif key == &"font_outline_color":
					color = DARK_BACKGROUND
				else:
					color = readable_accent(original)
			node.add_theme_color_override(key, color)
	if node is PanelContainer and node.has_theme_stylebox_override("panel"):
		if not node.has_meta("light_panel"):
			node.set_meta("light_panel", node.get_theme_stylebox("panel").duplicate())
		var style: StyleBox = node.get_meta("light_panel").duplicate()
		if dark_mode and style is StyleBoxTexture:
			style.modulate_color = Color("2a2a2a")
		node.add_theme_stylebox_override("panel", style)
