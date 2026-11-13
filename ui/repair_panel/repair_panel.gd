extends Control

signal closed
signal solved

const PLATE := preload("res://ui/repair_panel/industrial_plate.gd")
const TRUTH_CHOICE := preload("res://ui/repair_panel/truth_choice.gd")
## Each variable is shown as a colored Oopi; colors avoid the green/red answers.
const OOPIS := {
	"p": preload("res://ui/repair_panel/oopi_blue.png"),
	"q": preload("res://ui/repair_panel/oopi_yellow.png"),
	"r": preload("res://ui/repair_panel/oopi_lilac.png"),
}

var puzzle: LogicPuzzle
var answer_fields: Array[OptionButton] = []
var _submitted := false


func _ready() -> void:
	resized.connect(_fit_panel)
	_fit_panel()


func _fit_panel() -> void:
	var compact := puzzle == null or puzzle.rows.size() == 4
	var panel_size := Vector2(minf(1000 if compact else 1180, size.x - 32), minf(740 if compact else 880, size.y - 32))
	$Margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	$Margin.position = (size - panel_size) / 2
	$Margin.size = panel_size


func open_puzzle(data: LogicPuzzle, saved_choices: Array[int]) -> void:
	puzzle = data
	_submitted = false
	%Proposition.text = _rich(data.expression, 44)
	%Feedback.text = ""
	for child in %Table.get_children():
		%Table.remove_child(child)
		child.queue_free()
	answer_fields.clear()
	%Table.columns = data.headers.size()
	for part in data.header_parts:
		var plate := PLATE.new()
		plate.kind = PLATE.Kind.HEADER
		plate.custom_minimum_size = Vector2(132, 56)
		plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.text = _header(part)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.add_theme_font_size_override("normal_font_size", 18)
		plate.add_child(label)
		%Table.add_child(plate)
	for index in data.rows.size():
		for value in data.rows[index]:
			var cell := PLATE.new()
			cell.kind = PLATE.Kind.DISPLAY
			cell.value = 1 if value else 2
			cell.custom_minimum_size = Vector2(132, 60)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(_lamp(PLATE.GREEN if value else PLATE.RED))
			%Table.add_child(cell)
		var socket := PLATE.new()
		socket.kind = PLATE.Kind.DISPLAY
		socket.custom_minimum_size = Vector2(132, 60)
		socket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var choice := TRUTH_CHOICE.new()
		choice.alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice.add_theme_font_size_override("font_size", 28)
		choice.add_item("—")
		choice.add_icon_item(TRUTH_CHOICE.swatch(PLATE.GREEN), "")
		choice.set_item_tooltip(1, "Verdadeiro")
		choice.add_icon_item(TRUTH_CHOICE.swatch(PLATE.RED), "")
		choice.set_item_tooltip(2, "Falso")
		choice.accessibility_name = "Resultado da linha %d" % (index + 1)
		if saved_choices.size() == data.rows.size():
			choice.select(clampi(saved_choices[index], 0, 2))
		socket.value = choice.selected
		socket.add_child(choice)
		%Table.add_child(socket)
		answer_fields.append(choice)
	%TableScroll.scroll_horizontal = 0
	%TableScroll.scroll_vertical = 0
	visible = true
	_fit_panel()
	_set_focus_cycle()
	answer_fields[0].grab_focus.call_deferred()


func _rich(node: Variant, icon_size: int, nested := false) -> String:
	return LogicPuzzle.format_expression(node, nested, func(variable: String) -> String:
		return "[img=%d valign=center,center]%s[/img]" % [icon_size, OOPIS[variable].resource_path])


## Long headers break once, before the main operator, instead of mid-group.
func _header(node: Variant) -> String:
	const ICON := 32
	if _operator_count(node) < 3:
		return _rich(node, ICON)
	if node[0] == "not":
		return "%s\n%s" % [LogicPuzzle.WORDS["not"], _rich(node[1], ICON, true)]
	return "%s\n%s %s" % [_rich(node[1], ICON, true), LogicPuzzle.WORDS[node[0]], _rich(node[2], ICON, true)]


func _operator_count(node: Variant) -> int:
	if node is String:
		return 0
	var count := 1
	for index in range(1, node.size()):
		count += _operator_count(node[index])
	return count


## Colored lamps replace V/F so children read the value at a glance.
func _lamp(color: Color) -> Panel:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.shadow_color = Color(color, 0.45)
	style.shadow_size = 6
	var lamp := Panel.new()
	lamp.custom_minimum_size = Vector2(56, 28)
	lamp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lamp.add_theme_stylebox_override("panel", style)
	return lamp


func get_choices() -> Array[int]:
	var choices: Array[int] = []
	for field in answer_fields:
		choices.append(field.selected)
	return choices


func _on_submit_pressed() -> void:
	if _submitted or puzzle == null:
		return
	var choices := get_choices()
	if 0 in choices:
		%Feedback.text = "Complete todas as linhas."
		answer_fields[choices.find(0)].grab_focus()
		return
	if not puzzle.accepts(choices):
		%Feedback.text = "Há valores incorretos. Revise a última coluna."
		return
	_submitted = true
	solved.emit()


func _on_close_pressed() -> void:
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		# Escape first closes an OptionButton popup, then closes this panel.
		for field in answer_fields:
			if field.get_popup().visible:
				field.get_popup().hide()
				get_viewport().set_input_as_handled()
				return
		closed.emit()
		get_viewport().set_input_as_handled()


func _set_focus_cycle() -> void:
	var controls: Array[Control] = []
	controls.assign(answer_fields)
	controls.append(%Close)
	controls.append(%Submit)
	for index in controls.size():
		var control := controls[index]
		control.focus_next = control.get_path_to(controls[(index + 1) % controls.size()])
		control.focus_previous = control.get_path_to(controls[posmod(index - 1, controls.size())])
