class_name FaultyMachine
extends StaticBody3D
## Select the fault in the Inspector or change fault_type during gameplay.

enum FaultType { NONE, SMOKE, SPARKS, FIRE }

signal repaired(machine: FaultyMachine)

const FAULT_EFFECT := preload("res://gameplay/props/factory/modules/machine_fault.tscn")
const OUTLINE_SHADER := preload("res://gameplay/props/factory/machine_outline.gdshader")

@export var fault_type: FaultType = FaultType.NONE:
	set(value):
		fault_type = value
		if is_node_ready():
			_update_fault()

@export var fault_origin := Vector3(0.35, 1.2, 0.1):
	set(value):
		fault_origin = value
		if is_instance_valid(_fault_effect):
			_fault_effect.position = value

var _fault_effect: Node3D
var highlighted := false
var answer_choices: Array[int] = []
var _outlines: Array[MeshInstance3D] = []


func _ready() -> void:
	_update_fault()


func _update_fault() -> void:
	if fault_type == FaultType.NONE:
		set_highlighted(false)
	if fault_type == FaultType.NONE and not is_instance_valid(_fault_effect):
		return
	if not is_instance_valid(_fault_effect):
		_fault_effect = FAULT_EFFECT.instantiate()
		_fault_effect.position = fault_origin
		add_child(_fault_effect)
	_fault_effect.set_effects(
		fault_type == FaultType.SMOKE or fault_type == FaultType.FIRE,
		fault_type == FaultType.SPARKS or fault_type == FaultType.FIRE,
		fault_type == FaultType.FIRE
	)


func set_highlighted(enabled: bool) -> void:
	enabled = enabled and fault_type != FaultType.NONE
	if highlighted == enabled:
		return
	highlighted = enabled
	if enabled and _outlines.is_empty():
		var material := ShaderMaterial.new()
		material.shader = OUTLINE_SHADER
		for node in $Visual.find_children("*", "MeshInstance3D", true, false):
			var source := node as MeshInstance3D
			var outline := MeshInstance3D.new()
			outline.name = "InteractionOutline"
			outline.mesh = source.mesh
			outline.material_override = material
			outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			source.add_child(outline)
			_outlines.append(outline)
	for outline in _outlines:
		outline.visible = enabled


func repair() -> void:
	if fault_type == FaultType.NONE:
		return
	fault_type = FaultType.NONE
	repaired.emit(self)
