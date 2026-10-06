class_name LogicPuzzle
extends RefCounted
## Expressions are trees, so displayed columns and answers share explicit semantics.

const SYMBOLS := {"not": "¬", "and": "∧", "or": "∨", "implies": "→", "iff": "↔"}
const EXPRESSIONS := [
	[["and", "p", "q"], ["or", "p", "q"], ["implies", "p", "q"]],
	[["or", ["not", "p"], "q"], ["and", "p", ["not", "q"]], ["implies", ["not", "p"], "q"]],
	[["implies", ["and", "p", "q"], ["not", "p"]], ["iff", ["or", "p", "q"], ["not", "q"]], ["or", ["not", "p"], ["and", "p", "q"]]],
	[["or", ["and", "p", "q"], ["not", "r"]], ["implies", ["or", "p", "q"], ["not", "r"]], ["iff", ["and", "p", "q"], ["not", "r"]]],
	[["implies", ["or", ["and", "p", "q"], "r"], ["iff", "p", "q"]], ["iff", ["and", ["implies", "p", "q"], "r"], ["or", "p", "q"]], ["or", ["and", ["not", "p"], "q"], ["implies", "q", "r"]]],
	[["iff", ["and", ["implies", "p", "q"], ["implies", "q", "r"]], ["or", ["not", "p"], "r"]], ["implies", ["iff", ["and", "p", "q"], ["or", "q", "r"]], ["and", ["not", "p"], "r"]], ["iff", ["or", ["not", "p"], ["and", "q", "r"]], ["and", ["implies", "p", "q"], "r"]]],
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
	if difficulty >= 4:
		variables.append("r")
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
