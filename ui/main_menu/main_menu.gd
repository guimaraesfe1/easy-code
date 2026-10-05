extends Control

signal play_requested
signal options_requested
signal quit_requested

func _on_options_pressed() -> void:
	options_requested.emit()

func _on_play_pressed() -> void:
	play_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()

func focus_default() -> void:
	%Play.grab_focus()
