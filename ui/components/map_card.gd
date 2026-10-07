class_name MapCard
extends Button
## Layout lives in map_card.tscn; this script only binds content.

var definition: MapDefinition

func setup(data: MapDefinition) -> void:
	definition = data
	%MapName.text = data.display_name
	%Illustration.texture = data.illustration
	var background: StyleBox = %ArtPanel.get_theme_stylebox("panel").duplicate()
	if background is StyleBoxTexture:
		background.modulate_color = data.accent.lightened(0.88)
	%ArtPanel.add_theme_stylebox_override("panel", background)
	accessibility_name = data.display_name
