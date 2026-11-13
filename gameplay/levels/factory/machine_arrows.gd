extends Control
## Yellow arrows over each faulty machine; machines off screen get an arrow
## at the edge pointing toward them.

const FILL := Color("ffd23f")
const EDGE := Color("3a2a00")
const MARGIN := 48.0

var machines: Array[FaultyMachine] = []


func _process(_delta: float) -> void:
	visible = not get_tree().paused
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var bounds := get_viewport_rect().grow(-MARGIN)
	var bob := sin(Time.get_ticks_msec() / 250.0) * 6.0
	for machine in machines:
		if not is_instance_valid(machine) or machine.fault_type == FaultyMachine.FaultType.NONE:
			continue
		var target := camera.unproject_position(machine.global_position + Vector3.UP * 2.2)
		if bounds.has_point(target):
			_arrow(target + Vector2(0, -36 + bob), PI / 2)
		else:
			var center := bounds.get_center()
			var direction := (target - center).normalized()
			var edge := center + direction * _edge_distance(bounds, direction)
			_arrow(edge, direction.angle())


## Distance from the rect center to its edge along `direction`.
func _edge_distance(rect: Rect2, direction: Vector2) -> float:
	var half := rect.size / 2
	var x := half.x / absf(direction.x) if direction.x != 0 else INF
	var y := half.y / absf(direction.y) if direction.y != 0 else INF
	return minf(x, y)


func _arrow(position_on_screen: Vector2, angle: float) -> void:
	var points := PackedVector2Array([Vector2(22, 0), Vector2(-14, -18), Vector2(-6, 0), Vector2(-14, 18)])
	for index in points.size():
		points[index] = position_on_screen + points[index].rotated(angle)
	draw_colored_polygon(points, FILL)
	points.append(points[0])
	draw_polyline(points, EDGE, 3.0, true)
