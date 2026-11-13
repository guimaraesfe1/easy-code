extends CanvasLayer
## Oopi guide for the first factory level: explains the goal, then walks the
## player through each row of the truth table. The level calls the hooks below.

const ICONS := {"p": "res://ui/repair_panel/oopi_blue.png", "q": "res://ui/repair_panel/oopi_yellow.png"}
const NAMES := {"p": "o Oopi azul", "q": "o Oopi amarelo"}
const OPERATOR_RULES := {
	"and": "[b]E[/b] só fica verde quando os dois lados estão verdes.",
	"or": "[b]OU[/b] fica verde quando pelo menos um lado está verde.",
	"not": "[b]NÃO[/b] troca a cor: verde vira vermelho e vermelho vira verde.",
}

var panel: Control
var puzzle: LogicPuzzle
var _intro: Array[String] = []
var _row := -1
var _repairs := 0
var _next_action := Callable()


func _ready() -> void:
	ThemeSettings.theme_changed.connect(_sync_theme)
	_sync_theme()
	_intro = [
		"Olá! Eu sou o Oopi. Algumas máquinas da fábrica quebraram e precisam de conserto.",
		"Use [b]W A S D[/b] ou as [b]setas[/b] para andar. Segure [b]Shift[/b] para correr.",
		"As setas amarelas na tela mostram onde estão as máquinas quebradas. Siga uma delas!",
	]
	$Dialog.gui_input.connect(_on_dialog_input)
	_show_step(0)


func _sync_theme() -> void:
	%Text.add_theme_color_override("default_color", Color("f2f2f2") if ThemeSettings.dark_mode else Color("17384d"))


func _show_step(index: int) -> void:
	if index < _intro.size():
		_say(_intro[index], _show_step.bind(index + 1))
	else:
		_say("Chegue perto de uma máquina com fumaça até ela ficar com a borda verde. Depois aperte [b]E[/b] ou clique nela.")


func _say(text: String, action := Callable()) -> void:
	%Text.text = "[center]" + text + "[/center]"
	$Dialog.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if action.is_valid() else Control.CURSOR_ARROW
	%ClickHint.visible = action.is_valid()
	_next_action = action
	visible = true


func _on_dialog_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		$Dialog.accept_event()
		if _next_action.is_valid():
			var action := _next_action
			_next_action = Callable()
			action.call()


func _icon(variable: String) -> String:
	return "[img=28 valign=center,center]%s[/img]" % ICONS[variable]


func _color(value: bool) -> String:
	return "[color=#62ff87]verde[/color]" if value else "[color=#ff626b]vermelho[/color]"


## The operand's name: an Oopi, or the column that already shows its result.
func _operand(node: Variant, values: Dictionary) -> String:
	if node is String:
		return "%s %s" % [NAMES[node], _icon(node)]
	var text := LogicPuzzle.format_expression(node, false, _icon)
	return "a coluna «%s»" % text


func on_panel_opened(data: LogicPuzzle, repair_panel: Control) -> void:
	puzzle = data
	panel = repair_panel
	for index in panel.answer_fields.size():
		panel.answer_fields[index].item_selected.connect(_on_row_answered.bind(index))
	var operator: String = puzzle.expression[0]
	var proposition := LogicPuzzle.format_expression(puzzle.expression, false, _icon)
	_say(
		"Esta é a tabela da máquina. Cada linha mostra se %s %s e %s %s estão %s ou %s. Você só precisa preencher a última coluna: [b]%s[/b].\n%s"
		% [NAMES["p"], _icon("p"), NAMES["q"], _icon("q"), _color(true), _color(false), proposition, OPERATOR_RULES[operator]],
		_guide_row.bind(0)
	)


func _guide_row(index: int) -> void:
	_row = index
	if index >= puzzle.rows.size():
		_say("Todas as linhas estão certas! Clique em [b]Consertar[/b].")
		return
	if panel.answer_fields[index].selected == (1 if puzzle.answers[index] else 2):
		_guide_row(index + 1)
		return
	var values := {"p": puzzle.rows[index][0], "q": puzzle.rows[index][1]}
	_say("Linha %d: %s" % [index + 1, _explain_row(values, "Qual cor fica? Escolha na última coluna.")])
	panel.answer_fields[index].grab_focus()


func _explain_row(values: Dictionary, question: String) -> String:
	var expression: Array = puzzle.expression
	var operator: String = expression[0]
	var left := _operand(expression[1], values)
	var left_value := LogicPuzzle.evaluate(expression[1], values)
	if operator == "not":
		return "%s está %s. NÃO troca a cor. %s" % [left, _color(left_value), question]
	var right := _operand(expression[2], values)
	var right_value := LogicPuzzle.evaluate(expression[2], values)
	return "%s está %s e %s está %s. %s %s" % [left, _color(left_value), right, _color(right_value), OPERATOR_RULES[operator], question]


func _on_row_answered(choice: int, index: int) -> void:
	if index != _row or puzzle == null:
		return
	if choice == (1 if puzzle.answers[index] else 2):
		_say("Isso mesmo!")
		await get_tree().create_timer(0.6).timeout
		if _row == index and puzzle != null:
			_guide_row(index + 1)
	elif choice != 0:
		var values := {"p": puzzle.rows[index][0], "q": puzzle.rows[index][1]}
		_say("Quase! " + _explain_row(values, "Então a cor certa é %s. Tente de novo." % _color(puzzle.answers[index])))


func on_panel_closed() -> void:
	_disconnect_rows()
	_show_step(_intro.size())


func on_machine_repaired() -> void:
	_disconnect_rows()
	_repairs += 1
	if _repairs == 1:
		_say("Muito bem, a máquina voltou a funcionar! Agora conserte as outras. Eu ajudo em cada uma.", _show_step.bind(_intro.size()))
	else:
		_say("Mais uma consertada! Siga as setas até a próxima.")


func on_level_completed() -> void:
	_say("Você consertou todas as máquinas! Parabéns!")


func _disconnect_rows() -> void:
	if panel != null:
		for index in panel.answer_fields.size():
			var field: OptionButton = panel.answer_fields[index]
			if field.item_selected.is_connected(_on_row_answered):
				field.item_selected.disconnect(_on_row_answered)
	puzzle = null
	_row = -1
