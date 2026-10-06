extends Node3D
## Free-roam level metadata for forest and dungeon; layout lives in the .tscn.

@export var floor_bounds := Rect2(-22, -18, 44, 36)
@export var walk_bounds := Rect2(-18, -14, 36, 28)

func _ready() -> void:
	$CameraRig.map_bounds = floor_bounds
