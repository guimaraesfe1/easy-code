extends OptionButton
## Retain native popup/keyboard behavior while showing the selected signal color.

const GREEN := Color("62ff87")
const RED := Color("ff626b")
const IDLE := Color("99b6ca")
var _last_selected := -1


## Rounded color block shown in place of V/F text.
static func swatch(color: Color, swatch_size := Vector2i(56, 28), radius := 6) -> ImageTexture:
	var image := Image.create_empty(swatch_size.x, swatch_size.y, false, Image.FORMAT_RGBA8)
	for y in swatch_size.y:
		for x in swatch_size.x:
			var corner := Vector2(clampf(x + 0.5, radius, swatch_size.x - radius), clampf(y + 0.5, radius, swatch_size.y - radius))
			if Vector2(x + 0.5, y + 0.5).distance_to(corner) <= radius:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _process(_delta: float) -> void:
	if selected == _last_selected:
		return
	_last_selected = selected
	var tint := GREEN if selected == 1 else RED if selected == 2 else IDLE
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		add_theme_color_override(state, tint)
	get_parent().value = selected
	get_parent().queue_redraw()
