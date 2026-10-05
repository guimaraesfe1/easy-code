extends Control

signal level_selected(level_id: StringName)

const LEVEL_SCENE := preload("res://ui/components/level_button.tscn")
var definition: MapDefinition
var buttons: Dictionary[StringName, LevelButton] = {}

func show_map(data: MapDefinition) -> void:
	definition = data
	%MapTitle.text = data.display_name
	%MapIllustration.texture = data.illustration
	ThemeSettings.set_accent(%MapTitle, data.accent)
	for child in %Levels.get_children():
		%Levels.remove_child(child)
		child.queue_free()
	buttons.clear()
	for level in data.levels:
		var button := LEVEL_SCENE.instantiate() as LevelButton
		%Levels.add_child(button)
		button.setup(level, data.accent)
		button.pressed.connect(func() -> void: level_selected.emit(level.id))
		buttons[level.id] = button
	%Scroll.scroll_vertical = 0
	_update_columns()

func focus_level(level_id: StringName = &"") -> void:
	if buttons.has(level_id):
		buttons[level_id].grab_focus()
	elif not buttons.is_empty():
		buttons.values()[0].grab_focus()

func _update_columns() -> void:
	if not is_node_ready():
		return
	%Levels.columns = 3 if size.x >= 850 else (2 if size.x >= 550 else 1)
