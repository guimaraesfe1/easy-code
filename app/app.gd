extends Control
## Navigation only. Screens and components are authored as scenes.

enum Screen { MENU, MAPS, LEVELS, OPTIONS }

@export var maps: Array[MapDefinition] = []

var current_screen: Screen = Screen.MENU
var selected_map: MapDefinition
var selected_level: StringName
var _opening_level := false
var _saved_focus_modes: Dictionary[Control, int] = {}

func _ready() -> void:
	%MapSelection.populate(maps)
	_show_screen(Screen.MENU)
	get_window().min_size = Vector2i(640, 480)

func _show_screen(screen: Screen) -> void:
	current_screen = screen
	%MainMenu.visible = screen == Screen.MENU
	%MapSelection.visible = screen == Screen.MAPS
	%LevelSelection.visible = screen == Screen.LEVELS
	%OptionsMenu.visible = screen == Screen.OPTIONS
	%Back.visible = screen != Screen.MENU
	%Header.visible = screen != Screen.MENU
	match screen:
		Screen.OPTIONS:
			%OptionsMenu.focus_default.call_deferred()
		Screen.MENU:
			%MainMenu.focus_default.call_deferred()
		Screen.MAPS:
			%MapSelection.focus_map.call_deferred(selected_map.id if selected_map else &"")
		Screen.LEVELS:
			%LevelSelection.focus_level.call_deferred(selected_level)

func _on_play_requested() -> void:
	_show_screen(Screen.MAPS)

func _on_options_requested() -> void:
	_show_screen(Screen.OPTIONS)

func _on_quit_requested() -> void:
	get_tree().quit()

func _on_map_selected(map_id: StringName) -> void:
	for map in maps:
		if map.id == map_id:
			selected_map = map
			selected_level = &""
			%LevelSelection.show_map(map)
			_show_screen(Screen.LEVELS)
			return

func _on_level_selected(level_id: StringName) -> void:
	if _opening_level or %LevelDetails.visible or selected_map == null:
		return
	for level in selected_map.levels:
		if level.id == level_id:
			selected_level = level_id
			if not level.scene_path.is_empty():
				_opening_level = true
				var error := get_tree().change_scene_to_file(level.scene_path)
				if error != OK:
					_opening_level = false
					push_error("Could not open level: %s" % level.scene_path)
				return
			for node in %Frame.find_children("*", "BaseButton", true, false):
				var control := node as Control
				_saved_focus_modes[control] = control.focus_mode
				control.focus_mode = Control.FOCUS_NONE
			%LevelDetails.open_details(selected_map, level)
			return

func _on_details_closed() -> void:
	%LevelDetails.hide()
	for control in _saved_focus_modes:
		if is_instance_valid(control):
			control.focus_mode = _saved_focus_modes[control]
	_saved_focus_modes.clear()
	%LevelSelection.focus_level(selected_level)

func _on_back_pressed() -> void:
	if %LevelDetails.visible:
		_on_details_closed()
	elif current_screen == Screen.LEVELS:
		_show_screen(Screen.MAPS)
	elif current_screen == Screen.MAPS or current_screen == Screen.OPTIONS:
		_show_screen(Screen.MENU)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
