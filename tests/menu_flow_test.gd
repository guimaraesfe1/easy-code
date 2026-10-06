extends SceneTree
## Run: godot --headless --path . --script res://tests/menu_flow_test.gd
## Add -- --capture with a graphical display to save previews under /tmp.

var app: Control
var failures: Array[String] = []
var capture := false

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()

func _settle() -> void:
	for frame in 4:
		await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await _settle()

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await _settle()

func _preview(filename: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_check(image.save_png("/tmp/easy-code-" + filename + ".png") == OK, "Save preview " + filename)

func _check_layout() -> void:
	for node in app.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree():
			_check(label.size.x + 1 >= label.get_minimum_size().x, "Clipped label: " + str(label.get_path()))
	for node in app.find_children("*", "ScrollContainer", true, false):
		var scroll := node as ScrollContainer
		if scroll.is_visible_in_tree():
			_check(scroll.get_child(0).size.x <= scroll.size.x + 1, "Horizontal overflow: " + str(scroll.get_path()))

func _reference_previews() -> void:
	# Desktop window managers may clamp a requested 1920x1080 window. Render
	# exact reference sizes offscreen with the same 1280x720 canvas scaling.
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.size_2d_override = Vector2i(1280, 720)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var preview: Control = load("res://app/app.tscn").instantiate()
		viewport.add_child(preview)
		await _settle()
		for screen in ["menu", "maps", "levels"]:
			if screen == "maps":
				preview.get_node("%MainMenu").play_requested.emit()
			elif screen == "levels":
				preview.get_node("%MapSelection").map_selected.emit(&"forest")
			await _settle()
			await RenderingServer.frame_post_draw
			var image := viewport.get_texture().get_image()
			_check(image.get_size() == resolution, "Exact preview resolution")
			image.save_png("/tmp/easy-code-%s-%dx%d.png" % [screen, resolution.x, resolution.y])
		viewport.queue_free()
		await _settle()

func _run() -> void:
	app = load("res://app/app.tscn").instantiate()
	# Keep this menu test inside the UI even as more playable scenes are added.
	for index in app.maps.size():
		app.maps[index] = app.maps[index].duplicate(true)
		for level in app.maps[index].levels:
			level.scene_path = ""
	root.add_child(app)
	await _settle()
	var menu: Control = app.get_node("%MainMenu")
	var maps_screen: Control = app.get_node("%MapSelection")
	var levels_screen: Control = app.get_node("%LevelSelection")
	var details: Control = app.get_node("%LevelDetails")
	var back: Button = app.get_node("%Back")
	_check(menu.visible and not maps_screen.visible and not details.visible, "Startup must show only the main menu")
	_check(root.gui_get_focus_owner() == menu.get_node("%Play"), "Jogar must receive initial keyboard focus")
	var original_dark_mode: bool = root.get_node("ThemeSettings").dark_mode
	await _click(menu.get_node("%Options"))
	var options: Control = app.get_node("%OptionsMenu")
	_check(options.visible and not menu.visible, "Options must open its own screen")
	await _click(options.get_node("%DarkMode"))
	_check(root.get_node("ThemeSettings").dark_mode != original_dark_mode, "Theme toggle must change the global preference")
	var theme: Theme = load("res://ui/menu_theme.tres")
	root.get_node("ThemeSettings").set_dark_mode(true)
	_check(app.get_node("Background").color == Color("111923"), "Dark mode must update the application background")
	_check(menu.theme == theme and maps_screen.theme == theme and details.theme == theme, "All screens must share the global theme")
	_check(theme.get_stylebox("panel", "PanelContainer").modulate_color == Color("29374a"), "Dark mode must update panel surfaces")
	var pause_menu: CanvasLayer = load("res://ui/game_menu/game_menu.tscn").instantiate()
	root.add_child(pause_menu)
	await _settle()
	_check(pause_menu.get_node("Controls").theme == theme, "Gameplay pause must inherit the selected theme")
	pause_menu.queue_free()
	await _settle()
	root.get_node("ThemeSettings").set_dark_mode(original_dark_mode)
	await _key(KEY_ESCAPE)
	_check(menu.visible and not options.visible, "Escape from options must return to menu")
	await _key(KEY_ESCAPE)
	_check(menu.visible, "Escape must keep the main menu open")
	_check_layout()
	await _preview("menu-1280")
	await _key(KEY_ENTER)
	_check(maps_screen.visible and maps_screen.cards.size() == 3, "Enter on Jogar must open all three maps")
	_check_layout()
	await _preview("maps-1280")
	var ids: Dictionary = {}
	for map in app.maps:
		_check(not ids.has(map.id), "Duplicate map ID")
		ids[map.id] = true
		await _click(maps_screen.cards[map.id])
		_check(levels_screen.visible and levels_screen.definition == map, "Card must open matching map")
		_check(levels_screen.buttons.size() == 6, "Every map must have six selectable levels")
		_check_layout()
		await _preview(String(map.id) + "-levels")
		for level in map.levels:
			_check(not ids.has(level.id), "Duplicate level ID")
			ids[level.id] = true
			var button: Button = levels_screen.buttons[level.id]
			_check(button.disabled == not root.get_node("GameProgress").is_level_unlocked(map.id, level.number), "Level availability follows progression")
			if button.disabled:
				continue
			if not level.scene_path.is_empty():
				continue # Playable scenes are exercised in gameplay_menu_test.gd.
			await _click(button)
			_check(details.visible, "Level must open its details")
			_check(details.get_node("%LevelTitle").text == "Nível %02d" % level.number, "Details must show selected level")
			_check(details.get_node("%MapName").text == map.display_name.to_upper(), "Details must show selected map")
			await _click(back)
			_check(details.visible and levels_screen.visible, "Modal must block background clicks")
			await _key(KEY_TAB)
			_check(root.gui_get_focus_owner() == details.get_node("%Close"), "Modal must keep keyboard focus inside")
			if level.number == 1:
				_check_layout()
				await _preview(String(map.id) + "-details")
			if level.number % 2 == 0:
				await _key(KEY_ESCAPE)
			else:
				await _click(details.get_node("%Close"))
			_check(not details.visible and levels_screen.visible, "Closing details must return to levels")
			_check(root.gui_get_focus_owner() == button, "Closing details must restore selected level focus")
		await _key(KEY_ESCAPE)
		_check(maps_screen.visible, "Escape from levels must return to maps")
		_check(root.gui_get_focus_owner() == maps_screen.cards[map.id], "Back must restore map focus")
	await _click(back)
	_check(menu.visible, "Back from maps must return to main menu")
	for resolution in [Vector2i(1920, 1080), Vector2i(960, 640), Vector2i(640, 480)]:
		root.size = resolution
		await _settle()
		_check_layout()
		await _preview("menu-%d" % resolution.x)
		await _click(menu.get_node("%Play"))
		_check_layout()
		await _preview("maps-%d" % resolution.x)
		# Focus scrolling makes every card and level accessible at narrow widths.
		maps_screen.focus_map(&"forest")
		await _settle()
		await _key(KEY_ENTER)
		_check(levels_screen.visible, "Keyboard must reach levels at all resolutions")
		_check_layout()
		levels_screen.focus_level(&"forest_06")
		await _settle()
		await _key(KEY_ENTER)
		_check(details.visible, "Keyboard must reach the last level")
		_check_layout()
		await _preview("details-%d" % resolution.x)
		await _key(KEY_ESCAPE)
		await _key(KEY_ESCAPE)
		await _key(KEY_ESCAPE)
	# A new application instance must forget navigation and start in the menu.
	app.queue_free()
	await _settle()
	app = load("res://app/app.tscn").instantiate()
	root.add_child(app)
	await _settle()
	_check(app.get_node("%MainMenu").visible, "A fresh launch must start in the menu")
	if capture:
		await _reference_previews()
	if failures.is_empty():
		print("PASS: startup, 3 maps, 18 levels, modal isolation, keyboard, focus restoration, resizing and restart")
	else:
		print("FAIL: ", failures.size(), " menu flow checks")
		quit(1)
		return
	# This must actually exit the application through the Sair button's signal.
	await _click(app.get_node("%MainMenu").get_node("%Quit"))
	await create_timer(2.0).timeout
	push_error("Sair did not quit the application")
	quit(1)
