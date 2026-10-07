extends Control

signal play_requested
signal options_requested
signal quit_requested

func _ready() -> void:
	ThemeSettings.theme_changed.connect(_sync_theme)
	_sync_theme()

## The dark theme uses the compact black layout; the light one keeps the sprite buttons.
func _sync_theme() -> void:
	var dark: bool = ThemeSettings.dark_mode
	%Title.add_theme_constant_override("separation", 0 if dark else 14)
	for label in %Title.get_children():
		label.add_theme_constant_override("outline_size", 0 if dark else 6)
		label.add_theme_font_size_override("font_size", 86 if dark else 68)
	%Actions.add_theme_constant_override("separation", 10 if dark else 18)
	for button in %Actions.get_children():
		button.custom_minimum_size = Vector2(500, 56) if dark else Vector2(320, 72)
		button.add_theme_font_size_override("font_size", 30 if dark else 26)

func _on_options_pressed() -> void:
	options_requested.emit()

func _on_play_pressed() -> void:
	play_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()

func focus_default() -> void:
	%Play.grab_focus()
