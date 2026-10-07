class_name LogicPuzzle
extends RefCounted
## Expressions are trees, so displayed columns and answers share explicit semantics.

const SYMBOLS := {"not": "¬", "and": "∧", "or": "∨", "implies": "→", "iff": "↔"}
const EXPRESSIONS := [
	[["and", "p", "q"], ["or", "p", "q"], ["implies", "p", "q"]],
	[["or", ["not", "p"], "q"], ["and", "p", ["not", "q"]], ["implies", ["not", "p"], "q"]],
	[["implies", ["or", "p", "q"], "p"], ["implies", "p", ["not", "q"]], ["implies", ["and", "p", "q"], "q"]],
	[["iff", ["not", "p"], "q"], ["iff", ["and", "p", "q"], "p"], ["iff", ["or", "p", "q"], "q"]],
	[["or", ["and", "p", "q"], "p"], ["and", ["implies", "p", "q"], "p"], ["and", ["or", "p", "q"], "q"]],
	[["or", ["not", ["and", "p", "q"]], "q"], ["implies", ["and", "p", ["not", "q"]], "q"], ["iff", ["or", "p", "q"], ["not", "p"]]],
]

var expression: Array
var proposition: String
var headers: Array[String] = []
var rows: Array[Array] = []
var answers: Array[bool] = []


static func create(level_number: int, variant: int) -> LogicPuzzle:
	var puzzle := LogicPuzzle.new()
	var difficulty := clampi(level_number, 1, EXPRESSIONS.size())
	puzzle.expression = EXPRESSIONS[difficulty - 1][posmod(variant, 3)]
	puzzle.proposition = format_expression(puzzle.expression)
	var variables: Array[String] = ["p", "q"]
	var intermediates: Array[Array] = []
	_collect_intermediates(puzzle.expression, intermediates, true)
	puzzle.headers.assign(variables)
	for part in intermediates:
		puzzle.headers.append(format_expression(part))
	puzzle.headers.append(puzzle.proposition)
	for row_number in (1 << variables.size()):
		var values := {}
		var row: Array = []
		for index in variables.size():
			var value := (row_number & (1 << (variables.size() - index - 1))) == 0
			values[variables[index]] = value
			row.append(value)
		for part in intermediates:
			row.append(evaluate(part, values))
		puzzle.rows.append(row)
		puzzle.answers.append(evaluate(puzzle.expression, values))
	return puzzle


static func evaluate(node: Variant, values: Dictionary) -> bool:
	if node is String:
		return values[node]
	var left := evaluate(node[1], values)
	if node[0] == "not":
		return not left
	var right := evaluate(node[2], values)
	match node[0]:
		"and": return left and right
		"or": return left or right
		"implies": return not left or right
		"iff": return left == right
	assert(false, "Unknown logical operator")
	return false


static func format_expression(node: Variant) -> String:
	if node is String:
		return node
	if node[0] == "not":
		return "¬" + format_expression(node[1])
	return "(%s %s %s)" % [format_expression(node[1]), SYMBOLS[node[0]], format_expression(node[2])]


static func _collect_intermediates(node: Variant, parts: Array[Array], is_root: bool = false) -> void:
	if node is String:
		return
	for index in range(1, node.size()):
		_collect_intermediates(node[index], parts)
	if not is_root and not parts.has(node):
		parts.append(node)


func accepts(choices: Array[int]) -> bool:
	if choices.size() != answers.size():
		return false
	for index in answers.size():
		if choices[index] != (1 if answers[index] else 2):
			return false
	return true
