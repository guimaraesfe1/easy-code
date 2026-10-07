extends Node
## Shared click feedback for menus and dynamically created gameplay buttons.

const CLICK_SOUND := preload("res://assets/kenney_ui-audio/Audio/click1.ogg")

var _click_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_click_player = AudioStreamPlayer.new()
	_click_player.stream = CLICK_SOUND
	_click_player.volume_db = -8.0
	_click_player.max_polyphony = 8
	add_child(_click_player)
	get_tree().node_added.connect(_connect_button)
	_connect_existing(get_tree().root)

func _connect_existing(node: Node) -> void:
	_connect_button(node)
	for child in node.get_children():
		_connect_existing(child)

func _connect_button(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(_play_click):
		node.pressed.connect(_play_click)

func _play_click() -> void:
	_click_player.play()
