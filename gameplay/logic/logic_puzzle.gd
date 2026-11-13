class_name LogicPuzzle
extends RefCounted
## Expressions are trees, so displayed columns and answers share explicit semantics.

## Words instead of symbols keep the propositions readable for children.
const WORDS := {"not": "NÃO", "and": "E", "or": "OU"}
const EXPRESSIONS := [
	[["and", "p", "q"], ["or", "p", "q"], ["not", "p"]],
	[["and", "p", ["not", "q"]], ["or", ["not", "p"], "q"], ["not", ["and", "p", "q"]]],
	[["and", ["not", "p"], ["not", "q"]], ["not", ["or", "p", "q"]], ["or", ["and", "p", "q"], ["not", "p"]]],
	[["or", ["not", "p"], ["not", "q"]], ["and", ["or", "p", "q"], ["not", "p"]], ["not", ["and", "p", ["not", "q"]]]],
	[["and", ["or", "p", "q"], ["not", "q"]], ["or", ["and", "p", "q"], ["not", "q"]], ["not", ["or", ["not", "p"], "q"]]],
	[["not", ["and", ["not", "p"], "q"]], ["or", ["not", ["and", "p", "q"]], "q"], ["and", ["or", ["not", "p"], "q"], "p"]],
]

var expression: Array
var proposition: String
var headers: Array[String] = []
## Expression of each header, so the panel can draw variables as icons.
var header_parts: Array = []
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
	puzzle.header_parts.assign(variables)
	puzzle.header_parts.append_array(intermediates)
	puzzle.header_parts.append(puzzle.expression)
	for part in puzzle.header_parts:
		puzzle.headers.append(format_expression(part))
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
	assert(false, "Unknown logical operator")
	return false


## Only nested E/OU groups get parentheses, so headers stay short.
## `variable` turns each variable name into display text, such as an image tag.
static func format_expression(node: Variant, nested: bool = false, variable: Callable = Callable()) -> String:
	if node is String:
		return variable.call(node) if variable.is_valid() else node
	if node[0] == "not":
		return "%s %s" % [WORDS["not"], format_expression(node[1], true, variable)]
	var text := "%s %s %s" % [format_expression(node[1], true, variable), WORDS[node[0]], format_expression(node[2], true, variable)]
	return "(%s)" % text if nested else text


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
