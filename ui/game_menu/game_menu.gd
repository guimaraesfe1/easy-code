extends CanvasLayer
## Shared pause controls, including when a level is run directly with F6.

var _leaving := false
var _interaction_blocked := false

func _input(event: InputEvent) -> void:
	if _interaction_blocked:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_set_open(not %PauseOverlay.visible)
		get_viewport().set_input_as_handled()

func _set_open(open: bool) -> void:
	if _leaving or _interaction_blocked:
		return
	%PauseOverlay.visible = open
	%Gear.visible = not open
	get_tree().paused = open
	if open:
		%MainMenu.grab_focus()
	else:
		%Gear.grab_focus()

func set_interaction_blocked(blocked: bool) -> void:
	_interaction_blocked = blocked
	%Gear.visible = not blocked and not %PauseOverlay.visible

func _on_gear_pressed() -> void:
	_set_open(true)

func _on_close_pressed() -> void:
	_set_open(false)

func _on_main_menu_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().paused = false
	var error := get_tree().change_scene_to_file("res://app/app.tscn")
	if error != OK:
		_leaving = false
		get_tree().paused = true
		push_error("Could not return to main menu")

func _on_quit_pressed() -> void:
	get_tree().quit()
