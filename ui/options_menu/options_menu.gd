extends Control

func _ready() -> void:
	%DarkMode.set_pressed_no_signal(ThemeSettings.dark_mode)
	ThemeSettings.theme_changed.connect(_sync_theme)

func _sync_theme() -> void:
	%DarkMode.set_pressed_no_signal(ThemeSettings.dark_mode)

func _on_dark_mode_toggled(enabled: bool) -> void:
	ThemeSettings.set_dark_mode(enabled)

func focus_default() -> void:
	%DarkMode.grab_focus()
