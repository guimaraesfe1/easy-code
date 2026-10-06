extends Node
## Only a fully repaired level unlocks the next factory level.

signal changed

const FACTORY_LEVELS := 6
var storage_path := "user://progress.cfg"
var completed_factory_level := 0


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	var config := ConfigFile.new()
	completed_factory_level = 0
	if config.load(storage_path) == OK:
		var saved: Variant = config.get_value("factory", "completed_level", 0)
		if saved is int:
			completed_factory_level = clampi(saved, 0, FACTORY_LEVELS)
	changed.emit()


func is_level_unlocked(map_id: StringName, number: int) -> bool:
	if map_id != &"factory":
		return true
	return number >= 1 and number <= mini(completed_factory_level + 1, FACTORY_LEVELS)


func complete_factory_level(number: int) -> void:
	if number != completed_factory_level + 1 or number > FACTORY_LEVELS:
		return
	completed_factory_level = number
	var config := ConfigFile.new()
	config.set_value("factory", "completed_level", completed_factory_level)
	if config.save(storage_path) != OK:
		push_warning("Não foi possível salvar o progresso.")
	changed.emit()
