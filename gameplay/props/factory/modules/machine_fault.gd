extends Node3D

var _flicker_time := 0.0


func _ready() -> void:
	_flicker_time = randf() * TAU
	set_process(false)


func set_effects(smoke: bool, sparks: bool, fire: bool) -> void:
	$Smoke.position = Vector3(0, 0.85, 0) if fire else Vector3.ZERO
	_set_emitter($Smoke, smoke)
	_set_emitter($Sparks, sparks)
	_set_emitter($Fire, fire)
	$FireLight.visible = fire
	visible = smoke or sparks or fire
	set_process(fire)


func _set_emitter(emitter: CPUParticles3D, active: bool) -> void:
	var was_emitting := emitter.emitting
	emitter.emitting = active
	emitter.visible = active
	if active and not was_emitting:
		emitter.restart()


func _process(delta: float) -> void:
	_flicker_time += delta
	$FireLight.light_energy = 0.9 + 0.22 * sin(_flicker_time * 19.0) + 0.12 * sin(_flicker_time * 31.0)
