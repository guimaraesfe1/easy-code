extends SceneTree
## Check authored faults and transitions between healthy and faulty machines.

const MACHINE := preload("res://gameplay/props/factory/faulty_machine.gd")
const PROPS := ["machine", "machine_window", "machine_fortified", "machine_window_bar"]
const LEVELS := [
	"res://gameplay/levels/factory/factory_06_final.tscn",
	"res://gameplay/levels/factory/factory_02_coolant.tscn",
	"res://gameplay/levels/factory/factory_03_dispatch.tscn",
]

var failures: Array[String] = []
var capture := false


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _emits(machine: Node3D) -> bool:
	if not machine.has_node("MachineFault"):
		return false
	var effect := machine.get_node("MachineFault")
	for name in ["Smoke", "Sparks", "Fire"]:
		var emitter: CPUParticles3D = effect.get_node(name)
		if emitter.emitting and emitter.is_visible_in_tree():
			return true
	return false


func _run() -> void:
	for scene_path in [
		"res://gameplay/props/factory/modules/machine_fault.tscn",
		"res://gameplay/props/factory/modules/steam_vent.tscn",
		"res://gameplay/effects/repair_success.tscn",
		"res://gameplay/props/forest/modules/campfire.tscn",
		"res://gameplay/props/dungeon/modules/brazier.tscn",
	]:
		var effect: Node3D = load(scene_path).instantiate()
		root.add_child(effect)
		for emitter in effect.find_children("*", "CPUParticles3D", true, false):
			var texture: Texture2D = emitter.mesh.material.albedo_texture
			_check(texture != null and texture.resource_path.begins_with("res://assets/"), "Particle emitter uses an existing asset: " + scene_path)
		if effect.has_node("Flame/Fire"):
			_check(effect.get_node("Flame/Fire").emitting, "Decorative fire starts emitting automatically")
		await process_frame
		await process_frame
		effect.free()
	for prop_name in PROPS:
		var machine: StaticBody3D = load("res://gameplay/props/factory/%s.tscn" % prop_name).instantiate()
		root.add_child(machine)
		_check(not _emits(machine), "Healthy machine emits no fault particles: " + prop_name)
		for fault in [MACHINE.FaultType.SMOKE, MACHINE.FaultType.SPARKS, MACHINE.FaultType.FIRE]:
			machine.fault_type = fault
			_check(_emits(machine), "Every active fault emits visible particles: " + prop_name)
			_check(machine.get_node("MachineFault").position == machine.fault_origin, "Emission starts on the machine")
			_check(machine.get_node("MachineFault/FireLight").visible == (fault == MACHINE.FaultType.FIRE), "Fire lighting follows the fault")
		machine.fault_origin = Vector3(0.6, 1.1, 0)
		_check(machine.get_node("MachineFault").position == machine.fault_origin, "Fault origin can be moved")
		machine.fault_type = MACHINE.FaultType.NONE
		_check(not _emits(machine), "Repair stops and hides the particles: " + prop_name)
		_check(not machine.get_node("MachineFault/FireLight").visible, "Repair stops fire lighting")
		machine.fault_type = MACHINE.FaultType.FIRE
		_check(_emits(machine), "A new fault restarts the effect after repair")
		machine.repair()
		_check(not _emits(machine), "Successful repair clears the fault")
		var celebration := machine.get_node("RepairSuccess")
		var stars: CPUParticles3D = celebration.get_node("Stars")
		_check(stars.emitting and stars.one_shot, "Repair starts a single particle burst")
		_check(celebration.position == machine.fault_origin, "Repair burst starts on the repaired machine")
		var tint: Color = stars.color_ramp.sample(0.2)
		_check(tint.r > 0.9 and tint.g > 0.7 and tint.b < 0.2, "Repair particles are yellow")
		machine.repair()
		_check(machine.find_children("RepairSuccess*", "Node3D", false, false).size() == 1, "Repairing a healthy machine does not repeat the burst")
		paused = true
		_check(stars.can_process(), "Final repair burst continues during completion pause")
		await create_timer(1.8, true).timeout
		_check(not is_instance_valid(celebration), "Repair burst cleans itself up while paused")
		paused = false
		await process_frame
		await process_frame
		machine.free()
	for scene_path in LEVELS:
		var level: Node3D = load(scene_path).instantiate()
		root.add_child(level)
		current_scene = level
		await process_frame
		var broken_count := 0
		var healthy_count := 0
		for machine in level.get_node("Workstations").get_children():
			if not machine is MACHINE:
				continue
			if machine.fault_type == MACHINE.FaultType.NONE:
				healthy_count += 1
				_check(not _emits(machine), "Healthy machine remains clear in " + scene_path)
			else:
				broken_count += 1
				_check(_emits(machine), "Authored faulty machine emits particles in " + scene_path)
		_check(broken_count > 0 and healthy_count > 0, "Factory has both faulty and healthy machines: " + scene_path)
		if capture:
			root.mode = Window.MODE_WINDOWED
			root.size = Vector2i(1280, 720)
			await create_timer(1.5).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/easy-code-fault-%s.png" % level.name)
			if level.name == "Factory06Final":
				var overview := Camera3D.new()
				level.add_child(overview)
				overview.projection = Camera3D.PROJECTION_ORTHOGONAL
				overview.size = 7.0
				overview.position = Vector3(10, 7, 10)
				overview.look_at(Vector3(6, 1.5, 5.3))
				overview.make_current()
				await create_timer(0.5).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("/tmp/easy-code-fault-fire-closeup.png")
		level.queue_free()
		await process_frame
	if failures.is_empty():
		print("PASS: particle assets, decorative fires, factory faults, yellow repair burst, pause cleanup and emission origins")
	quit(0 if failures.is_empty() else 1)
