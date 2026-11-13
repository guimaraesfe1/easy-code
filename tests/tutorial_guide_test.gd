extends SceneTree
## Ensure the guide stays visible and centered as dialogue and window size change.
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _layout() -> void:
	for frame in 8:
		await process_frame

func _run() -> void:
	var guide = load("res://ui/tutorial/tutorial_guide.tscn").instantiate()
	root.add_child(guide)
	for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(800, 600)]:
		root.size = resolution
		for message in ["Olá! Eu sou o Oopi.", "Uma explicação mais longa. ".repeat(30)]:
			guide._say(message, func(): pass)
			await _layout()
			var dialog: Control = guide.get_node("Dialog")
			var text: RichTextLabel = guide.get_node("%Text")
			var center: Control = text.get_parent()
			var screen := root.get_visible_rect()
			_check(dialog.is_visible_in_tree(), "Dialogue must be visible")
			_check(absf(dialog.size.y - 244.0) < 2.0, "Dialogue must have the enlarged height")
			_check(dialog.get_global_rect().position.y >= screen.size.y * 0.5, "Dialogue must leave the upper half of gameplay visible")
			_check(absf(dialog.get_global_rect().end.y - screen.end.y) < 2.0, "Dialogue must stay at the bottom")
			_check(absf(dialog.size.x - screen.size.x) < 2.0, "Dialogue must span the window")
			_check(text.size.y > 0 and text.get_content_height() > 0, "Dialogue text must have a visible height")
			_check(absf(text.get_global_rect().get_center().y - center.get_global_rect().get_center().y) < 2.0, "Text must be vertically centered")
			_check(dialog.get_global_rect().encloses(text.get_global_rect()), "Text must stay inside the dialogue")
	guide._show_step(0)
	for step in 3:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		guide.get_node("Dialog").gui_input.emit(click)
		await _layout()
	_check(not guide._next_action.is_valid(), "Intro must transition to the movement hint")
	_check(guide.get_node("%Text").get_theme_font_size("normal_font_size") == 28, "Dialogue font must be enlarged")
	_check(guide.get_node("Dialog").is_visible_in_tree(), "Hint must keep the dialogue visible")
	guide.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: tutorial visibility, text layout, resizing and intro progression")
	quit(0 if failures.is_empty() else 1)
