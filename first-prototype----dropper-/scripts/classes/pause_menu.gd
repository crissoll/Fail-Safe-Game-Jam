extends CanvasLayer

var pause_panel: Control
var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Pannello principale
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(pause_panel)

	# Sfondo scuro
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	pause_panel.add_child(background)

	# Contenitore centrale
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	pause_panel.add_child(center)

	# Menu verticale
	var menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 20)
	center.add_child(menu)

	# Titolo
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	menu.add_child(title)

	# Pulsante Resume
	var resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(200, 60)
	resume_button.add_theme_font_size_override(
		"font_size", 24
	)
	resume_button.pressed.connect(resume_game)
	menu.add_child(resume_button)

	# Il menu parte nascosto
	pause_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			toggle_pause()


func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused


func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	pause_panel.hide()
