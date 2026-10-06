extends Node3D
## Proximity, repair exercises and completion; room layouts remain in scenes.

const REPAIR_UI := preload("res://ui/repair_panel/factory_repair_ui.tscn")
const FACTORY_MAP := preload("res://content/maps/factory.tres")

@export var floor_bounds := Rect2(-16, -14, 32, 28)
@export var walk_bounds := Rect2(-9, -7, 18, 14)
@export_range(1, 6) var level_number := 1
@export_range(1.0, 4.0) var interaction_distance := 2.3

var machines: Array[FaultyMachine] = []
var nearest_machine: FaultyMachine
var _active_machine: FaultyMachine
var _initial_faults := 0
var _completed := false
var _changing_scene := false
var repair_ui: CanvasLayer
var repair_panel: Control

func _ready() -> void:
	$CameraRig.map_bounds = floor_bounds
	repair_ui = REPAIR_UI.instantiate()
	add_child(repair_ui)
	repair_panel = repair_ui.get_node("%RepairPanel")
	repair_panel.closed.connect(_on_puzzle_closed)
	repair_panel.solved.connect(_on_puzzle_solved)
	repair_ui.get_node("%NextLevel").pressed.connect(_on_next_level_pressed)
	repair_ui.get_node("%MainMenu").pressed.connect(_on_main_menu_pressed)
	repair_ui.get_node("%Level").text = "Fábrica · Nível %02d" % level_number
	for child in $Workstations.get_children():
		if child is FaultyMachine:
			machines.append(child)
			child.repaired.connect(_on_machine_repaired)
			if child.fault_type != FaultyMachine.FaultType.NONE:
				_initial_faults += 1
	_update_counter()


func _physics_process(_delta: float) -> void:
	_update_proximity()


func _update_proximity() -> void:
	nearest_machine = null
	var shortest := INF
	for machine in machines:
		var nearby := can_select(machine)
		machine.set_highlighted(nearby)
		if nearby:
			var distance := _distance_to(machine)
			if distance < shortest:
				shortest = distance
				nearest_machine = machine
	repair_ui.get_node("%RepairPrompt").visible = nearest_machine != null


func _distance_to(machine: FaultyMachine) -> float:
	var offset: Vector3 = machine.global_position - $Player.global_position
	return Vector2(offset.x, offset.z).length()


func can_select(machine: FaultyMachine) -> bool:
	return (
		is_instance_valid(machine) and machines.has(machine)
		and machine.fault_type != FaultyMachine.FaultType.NONE
		and _distance_to(machine) <= interaction_distance
		and _active_machine == null and not _completed and not get_tree().paused
	)


func select_machine(machine: FaultyMachine) -> bool:
	if not can_select(machine):
		return false
	_active_machine = machine
	var puzzle := LogicPuzzle.create(level_number, machines.find(machine))
	repair_panel.open_puzzle(puzzle, machine.answer_choices)
	repair_ui.get_node("%RepairPrompt").hide()
	$Player.velocity = Vector3.ZERO
	_set_modal(true)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		if select_machine(nearest_machine):
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera := get_viewport().get_camera_3d()
		var origin := camera.project_ray_origin(event.position)
		var ray := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(event.position) * 100.0, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and hit.collider is FaultyMachine and select_machine(hit.collider):
			get_viewport().set_input_as_handled()


func _on_puzzle_closed() -> void:
	if _active_machine == null:
		return
	_active_machine.answer_choices = repair_panel.get_choices()
	_active_machine = null
	repair_panel.hide()
	_set_modal(false)
	_update_proximity()


func _on_puzzle_solved() -> void:
	if not is_instance_valid(_active_machine):
		return
	var machine := _active_machine
	_active_machine = null
	repair_panel.hide()
	_set_modal(false)
	machine.repair()
	_update_proximity()


func _on_machine_repaired(_machine: FaultyMachine) -> void:
	_update_counter()
	for machine in machines:
		if machine.fault_type != FaultyMachine.FaultType.NONE:
			return
	if _initial_faults > 0 and not _completed:
		_completed = true
		GameProgress.complete_factory_level(level_number)
		repair_ui.get_node("%CompletionTitle").text = "Fábrica concluída" if level_number == 6 else "Nível %02d concluído" % level_number
		var has_next := level_number < 6 and GameProgress.is_level_unlocked(&"factory", level_number + 1)
		repair_ui.get_node("%NextLevel").visible = has_next
		repair_ui.get_node("%Completion").show()
		_set_modal(true)
		var next: Button = repair_ui.get_node("%NextLevel")
		var menu: Button = repair_ui.get_node("%MainMenu")
		next.focus_next = next.get_path_to(menu)
		menu.focus_next = menu.get_path_to(next if has_next else menu)
		next.focus_previous = next.get_path_to(menu)
		menu.focus_previous = menu.get_path_to(next if has_next else menu)
		(next if has_next else menu).grab_focus.call_deferred()


func _update_counter() -> void:
	var remaining := 0
	for machine in machines:
		if machine.fault_type != FaultyMachine.FaultType.NONE:
			remaining += 1
	repair_ui.get_node("%Counter").text = "Máquinas: %d / %d" % [_initial_faults - remaining, _initial_faults]


func _set_modal(open: bool) -> void:
	$GameMenu.set_interaction_blocked(open)
	get_tree().paused = open


func _on_next_level_pressed() -> void:
	if _completed and level_number < 6 and GameProgress.is_level_unlocked(&"factory", level_number + 1):
		_change_scene(FACTORY_MAP.levels[level_number].scene_path)


func _on_main_menu_pressed() -> void:
	_change_scene("res://app/app.tscn")


func _change_scene(path: String) -> void:
	if _changing_scene:
		return
	_changing_scene = true
	_set_modal(false)
	if get_tree().change_scene_to_file(path) != OK:
		_changing_scene = false
		_set_modal(true)
		repair_ui.get_node("%CompletionStatus").text = "Não foi possível abrir a fase."


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false
