extends OptionButton
## Retain native popup/keyboard behavior while showing the selected signal color.

const GREEN := Color("62ff87")
const RED := Color("ff626b")
const IDLE := Color("99b6ca")
var _last_selected := -1


func _process(_delta: float) -> void:
	if selected == _last_selected:
		return
	_last_selected = selected
	var tint := GREEN if selected == 1 else RED if selected == 2 else IDLE
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		add_theme_color_override(state, tint)
	get_parent().value = selected
	get_parent().queue_redraw()
