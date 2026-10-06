@tool
extends PanelContainer
## Native, resizable metalwork; the table and its controls remain editable nodes.

enum Kind { CHASSIS, BOARD, DISPLAY, HEADER }

const GREEN := Color("62ff87")
const RED := Color("ff626b")
const IDLE := Color("668b9c")

@export var kind: Kind = Kind.CHASSIS
@export_range(0, 2) var value := 0

var _circuit_state: Array = []


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	if kind != Kind.BOARD:
		return
	var table := get_node_or_null("Table") as GridContainer
	if table == null:
		return
	var state: Array = [size, table.position, table.size, table.columns]
	for cell in table.get_children():
		state.append(cell.position)
		state.append(cell.size)
		state.append(cell.value)
	if state != _circuit_state:
		_circuit_state = state
		queue_redraw()


func _outline(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var end := rect.end
	return PackedVector2Array([
		p + Vector2(cut, 0), Vector2(end.x - cut, p.y),
		Vector2(end.x, p.y + cut), end - Vector2(0, cut),
		end - Vector2(cut, 0), Vector2(p.x + cut, end.y),
		Vector2(p.x, end.y - cut), p + Vector2(0, cut),
	])


func _plate(rect: Rect2, cut: float, color: Color, edge: Color) -> void:
	var points := _outline(rect, cut)
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, edge, 1.5, true)


func _screw(center: Vector2, radius: float = 5.0) -> void:
	draw_circle(center + Vector2(0, 1.5), radius + 1, Color("090f1b"))
	draw_circle(center, radius, Color("53677f"))
	draw_arc(center, radius - 1, PI, TAU, 12, Color("8293a9"), 1, true)
	draw_line(center - Vector2(radius * 0.5, 0), center + Vector2(radius * 0.5, 0), Color("142033"), 1.5, true)


func _draw() -> void:
	if size.x < 12 or size.y < 12:
		return
	var bounds := Rect2(Vector2.ZERO, size)
	match kind:
		Kind.CHASSIS:
			_plate(bounds.grow(-2), 22, Color("101a2a"), Color("09101b"))
			_plate(bounds.grow(-5), 20, Color("34465f"), Color("71839d"))
			_plate(bounds.grow(-10), 16, Color("29394f"), Color("405574"))
			_plate(bounds.grow(-21), 14, Color("0d1625"), Color("080d17"))
			_plate(bounds.grow(-24), 12, Color("172235"), Color("53647b"))
			for x in [17.0, size.x - 17.0]:
				for y in [17.0, size.y - 17.0]:
					_screw(Vector2(x, y))
			var led_y := size.y - 13
			_plate(Rect2(size.x / 2 - 53, led_y - 8, 106, 16), 6, Color("0b1320"), Color("415570"))
			for offset in [-22.0, 0.0, 22.0]:
				var led := Rect2(size.x / 2 + offset - 4, led_y - 3, 8, 6)
				draw_rect(led.grow(3), Color(0.15, 1, 0.3, 0.08))
				draw_rect(led, GREEN)
		Kind.BOARD:
			_plate(bounds.grow(-1), 10, Color("0b1320"), Color("35465e"))
			for x in range(30, int(size.x), 110):
				draw_line(Vector2(x, 3), Vector2(x, size.y - 3), Color(0.3, 0.4, 0.55, 0.05), 1)
			_draw_wires()
		Kind.DISPLAY, Kind.HEADER:
			_plate(bounds.grow(-1), 8, Color("253a50"), Color("07101c"))
			_plate(bounds.grow(-3), 6, Color("3d5770"), Color("6b859b"))
			_plate(bounds.grow(-7), 4, Color("1a293c"), Color("162032"))
			var screen := Rect2(12, 10, size.x - 24, size.y - 20)
			var tint := GREEN if value == 1 else RED if value == 2 else IDLE
			var background := Color("182a40") if kind == Kind.HEADER else Color("061216")
			_plate(screen, 3, background, Color("080f1a"))
			if kind == Kind.DISPLAY and value != 0:
				for step in range(8, 0, -1):
					var glow := screen.grow(-float(step))
					draw_rect(glow, Color(tint.r, tint.g, tint.b, 0.014))
			for x in [6.0, size.x - 6.0]:
				_screw(Vector2(x, size.y / 2), 2.2)


func _draw_wires() -> void:
	var table := get_node_or_null("Table") as GridContainer
	if table == null or table.columns < 1:
		return
	var cells := table.get_children()
	for start in range(table.columns, cells.size(), table.columns):
		var last: Control = cells[start + table.columns - 1]
		var tint := GREEN if last.value == 1 else RED if last.value == 2 else IDLE
		var y: float = table.position.y + last.position.y + last.size.y / 2
		var wire := PackedVector2Array([Vector2(8, y + 4), Vector2(18, y + 4)])
		for column in table.columns:
			var cell: Control = cells[start + column]
			var left: float = table.position.x + cell.position.x
			wire.append(Vector2(left - 8, y))
			wire.append(Vector2(left + cell.size.x + 8, y))
		wire.append(Vector2(size.x - 8, y + 4))
		draw_polyline(wire, Color("030a10"), 10, true)
		draw_polyline(wire, tint.darkened(0.65), 7, true)
		draw_polyline(wire, tint.darkened(0.18), 3, true)
		draw_polyline(wire, Color(tint.r, tint.g, tint.b, 0.3), 1, true)
		for column in table.columns:
			var cell: Control = cells[start + column]
			for x in [table.position.x + cell.position.x - 5, table.position.x + cell.position.x + cell.size.x + 5]:
				draw_rect(Rect2(x - 4, y - 9, 8, 18), Color("31485c"))
				draw_line(Vector2(x - 3, y - 7), Vector2(x + 3, y - 7), Color("70859a"), 1)
