extends SceneTree
## End-to-end repair, selection, modal isolation, all six levels and saved unlocks.

const PROGRESS_SCRIPT := preload("res://gameplay/progression/game_progress.gd")
const FACTORY := preload("res://content/maps/factory.tres")
var failures: Array[String] = []
var progress: Node
var capture := false
var original_storage: String
var original_completed: int


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for frame in 4:
		await process_frame
		await physics_frame


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await _settle()


func _click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await _settle()


func _preview(name: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/easy-code-repair-%s.png" % name)


func _operator_count(node: Variant) -> int:
	if node is String:
		return 0
	var count := 1
	for index in range(1, node.size()):
		count += _operator_count(node[index])
	return count


func _test_logic() -> void:
	var expected := {
		"and": [true, false, false, false],
		"or": [true, true, true, false],
		"implies": [true, false, true, true],
		"iff": [true, false, false, true],
	}
	var pairs := [[true, true], [true, false], [false, true], [false, false]]
	for op in expected:
		for index in pairs.size():
			var values := {"p": pairs[index][0], "q": pairs[index][1]}
			_check(LogicPuzzle.evaluate([op, "p", "q"], values) == expected[op][index], "Truth table for " + op)
	_check(LogicPuzzle.evaluate(["not", "p"], {"p": false}), "Negation of false")
	_check(not LogicPuzzle.evaluate(["not", "p"], {"p": true}), "Negation of true")
	_check(LogicPuzzle.create(3, 0).answers == [true, true, false, true], "Simple compound implication has correct answers")
	_check(LogicPuzzle.create(3, 0).rows[0] == [true, true, true], "Subpropositions are already solved")
	for variant in 3:
		var previous_complexity := 0
		for number in range(1, 7):
			var puzzle := LogicPuzzle.create(number, variant)
			_check(puzzle.rows.size() == 4, "Every exercise stays at two variables and four rows")
			var complexity := _operator_count(puzzle.expression)
			_check(complexity <= 3, "Propositions remain relatively simple")
			_check(complexity >= previous_complexity, "Progression stays gradual")
			_check(puzzle.headers.size() <= 5, "Intermediate results keep the table compact")
			previous_complexity = complexity
			for row in puzzle.rows:
				_check(row.size() == puzzle.headers.size() - 1, "Only the final column is left unanswered")
			_check(not puzzle.accepts([]), "An incomplete table cannot repair a machine")


func _run() -> void:
	progress = root.get_node("GameProgress")
	_test_logic()
	original_storage = progress.storage_path
	original_completed = progress.completed_factory_level
	progress.storage_path = "/tmp/easy-code-repair-progress-%d.cfg" % OS.get_process_id()
	progress.completed_factory_level = 0
	var app: Control = load("res://app/app.tscn").instantiate()
	root.add_child(app)
	current_scene = app
	await _settle()
	app._on_map_selected(&"factory")
	await _settle()
	_check(not app.get_node("%LevelSelection").buttons[&"factory_01"].disabled, "First level is available")
	_check(app.get_node("%LevelSelection").buttons[&"factory_02"].disabled, "Next level is initially locked")
	app._on_level_selected(&"factory_02")
	_check(current_scene == app, "Direct selection cannot bypass a locked level")
	await _preview("locked-levels")
	app._on_level_selected(&"factory_01")
	await _settle()
	for number in range(1, 7):
		var level: Node3D = current_scene
		_check(level.level_number == number, "Next phase opens the matching level")
		_check(not paused, "New level resumes movement")
		var faulty: Array[FaultyMachine] = []
		for machine in level.machines:
			if machine.fault_type != FaultyMachine.FaultType.NONE:
				faulty.append(machine)
		_check(not faulty.is_empty(), "Each level contains faulty machines")
		for index in faulty.size():
			var machine := faulty[index]
			var player: CharacterBody3D = level.get_node("Player")
			player.global_position = Vector3(0, 0.08, 0)
			player.velocity = Vector3.ZERO
			player.reset_physics_interpolation()
			await _settle()
			_check(not level.select_machine(machine), "Distant machine cannot be selected")
			player.global_position = machine.global_position + Vector3(0, 0.08, 1.65)
			player.velocity = Vector3.ZERO
			player.reset_physics_interpolation()
			await _settle()
			_check(machine.highlighted, "Nearby faulty machine has a contrasting outline")
			if number == 1 and index == 0:
				if capture:
					# Let the camera finish following the test's teleport before capture.
					for frame in 60:
						await process_frame
						await physics_frame
				await _preview("outline")
			await _key(KEY_E)
			var panel: Control = level.repair_panel
			_check(panel.visible and paused, "E selects a nearby machine and pauses movement")
			_check(not level.get_node("GameMenu").get_node("%Gear").visible, "Repair modal isolates the pause menu")
			if not panel.visible:
				break
			if number == 6 and index == 0:
				for resolution in [Vector2i(640, 480), Vector2i(1280, 720)]:
					root.size = resolution
					await _settle()
					var submit: Button = panel.get_node("%Submit")
					_check(panel.get_global_rect().encloses(submit.get_global_rect()), "Submit remains inside the panel after resizing")
					_check(panel.get_node("%TableScroll").size.y > 100, "Truth table has a scrollable area at narrow sizes")
				panel.answer_fields[0].grab_focus()
				for step in panel.answer_fields.size() + 2:
					await _key(KEY_TAB)
					_check(panel.is_ancestor_of(root.gui_get_focus_owner()), "Keyboard focus stays inside repair")
			panel._on_submit_pressed()
			_check(machine.fault_type != FaultyMachine.FaultType.NONE, "Blank answers do not repair")
			for row in panel.answer_fields.size():
				panel.answer_fields[row].select(2 if panel.puzzle.answers[row] else 1)
			panel._on_submit_pressed()
			_check(panel.visible and machine.fault_type != FaultyMachine.FaultType.NONE, "Wrong answers keep the machine faulty")
			if number == 1 and index == 0:
				await _key(KEY_ESCAPE)
				_check(not panel.visible and not paused, "Escape closes repair and resumes the level")
				_check(not level.get_node("GameMenu").get_node("%PauseOverlay").visible, "Escape does not also open pause")
				var camera: Camera3D = level.get_node("CameraRig/Camera3D")
				await _click(camera.unproject_position(machine.global_position + Vector3(0, 0.7, 0)))
				_check(panel.visible, "Click selects the nearby outlined machine")
				if not panel.visible:
					level.select_machine(machine)
				_check(panel.get_choices() == machine.answer_choices, "Closing preserves an attempt")
			await _preview("table-level-%d" % number)
			for row in panel.answer_fields.size():
				panel.answer_fields[row].select(1 if panel.puzzle.answers[row] else 2)
			panel._on_submit_pressed()
			await _settle()
			_check(machine.fault_type == FaultyMachine.FaultType.NONE, "Correct completed table repairs the machine")
			_check(not machine.highlighted and not level.select_machine(machine), "Repaired machine loses its outline and cannot be selected")
			_check(not machine.get_node("MachineFault").visible, "Repair removes fault particles")
		_check(level.repair_ui.get_node("%Completion").visible and paused, "Repairing all machines completes the phase")
		_check(progress.completed_factory_level == number, "Only completion advances saved progression")
		var reloaded := PROGRESS_SCRIPT.new()
		reloaded.storage_path = progress.storage_path
		root.add_child(reloaded)
		_check(reloaded.completed_factory_level == number, "Progress survives reloading from disk")
		reloaded.queue_free()
		await _settle()
		await _preview("completed-level-%d" % number)
		if number < 6:
			_check(progress.is_level_unlocked(&"factory", number + 1), "Next level is unlocked")
			if number < 5:
				_check(not progress.is_level_unlocked(&"factory", number + 2), "Later levels remain locked")
			level.repair_ui.get_node("%NextLevel").pressed.emit()
			await _settle()
		else:
			_check(not level.repair_ui.get_node("%NextLevel").visible, "Final level has no nonexistent successor")
			level.repair_ui.get_node("%MainMenu").pressed.emit()
			await _settle()
	_check(not paused and current_scene.get_node("%MainMenu").visible, "Campaign completion returns to the menu unpaused")
	current_scene._on_map_selected(&"factory")
	await _settle()
	for button in current_scene.get_node("%LevelSelection").buttons.values():
		_check(not button.disabled and button.get_node("%Status").text == "Concluído", "Completed campaign is reflected in level selection")
	progress.storage_path = original_storage
	progress.completed_factory_level = original_completed
	if failures.is_empty():
		print("PASS: truth tables, outline, proximity, mouse/E selection, retry, repair, six phases and saved unlocks")
	quit(0 if failures.is_empty() else 1)
