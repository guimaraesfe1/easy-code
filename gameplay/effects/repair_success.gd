extends Node3D
## Keep the celebration visible even when the final repair pauses the level.

func _ready() -> void:
	$Stars.finished.connect(queue_free)
	$Stars.restart()
	$Puff.restart()
	var fade := create_tween()
	fade.tween_property($Light, "light_energy", 0.0, 0.45)
