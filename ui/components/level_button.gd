class_name LevelButton
extends Button
## Layout lives in level_button.tscn.

var definition: LevelDefinition

func setup(data: LevelDefinition, accent: Color) -> void:
	definition = data
	%Number.text = "%02d" % data.number
	ThemeSettings.set_accent(%Number, accent)
	accessibility_name = "Nível %d" % data.number

func set_status(status: String) -> void:
	%Status.text = status
	%Status.visible = not status.is_empty()
	accessibility_name = "Nível %d %s" % [definition.number, status]
