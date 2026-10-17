extends CanvasLayer

@export_file("*.tscn") var menu_scene_path: String = "res://scenes/main_menu.tscn"
@export var music_bus_name: StringName = &"Music"

var is_pause_open: bool = false
var current_page: String = "pause"

var ui_root: Control
var menu_panel: PanelContainer
var menu_content: VBoxContainer
var music_slider: HSlider
var music_value_label: Label


func _ready() -> void:
	# Il menu funziona anche quando il gioco e' in pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	_create_interface()
	_show_pause_menu()

	# All'inizio il menu e' nascosto.
	ui_root.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_pause_open:
				_close_pause_menu()
			else:
				_open_pause_menu()

			get_viewport().set_input_as_handled()

func _create_interface() -> void:
	ui_root = Control.new()
	ui_root.name = "PauseUI"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_root)

	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	background.color = Color(0.0, 0.0, 0.0, 0.70)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(background)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	ui_root.add_child(center)

	menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(menu_panel)


func _prepare_page(title_text: String) -> void:
	for child in menu_panel.get_children():
		child.queue_free()

	menu_content = VBoxContainer.new()
	menu_content.add_theme_constant_override("separation", 12)
	menu_panel.add_child(menu_content)

	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	menu_content.add_child(title)

	menu_content.add_child(HSeparator.new())


func _add_button(
	label_text: String,
	callback: Callable
) -> Button:
	var button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	menu_content.add_child(button)

	return button


func _open_pause_menu() -> void:
	if is_pause_open:
		return

	is_pause_open = true
	ui_root.visible = true
	get_tree().paused = true

	_show_pause_menu()


func _close_pause_menu() -> void:
	is_pause_open = false
	ui_root.visible = false
	get_tree().paused = false


func _show_pause_menu() -> void:
	current_page = "pause"
	_prepare_page("PAUSE MENU")
	_add_button("Back to Home Menu", _back_to_menu)
	_add_button("Restart Level", _restart_level)
	_add_button("Settings", _show_settings)
	_add_button("Key Bindings", _show_key_bindings)
	_add_button("Close Game", _close_game)
	_add_button("Close Pause Menu", _close_pause_menu)


func _show_settings() -> void:
	current_page = "settings"
	_prepare_page("SETTINGS")

	var music_label = Label.new()
	music_label.text = "Music Volume"
	menu_content.add_child(music_label)

	var bus_index = AudioServer.get_bus_index(music_bus_name)

	if bus_index < 0:
		push_warning(
            "Music bus not found. Using Master instead."
		)
		bus_index = AudioServer.get_bus_index("Master")

	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	music_slider.custom_minimum_size = Vector2(0, 32)
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if bus_index >= 0:
		music_slider.value = (
			AudioServer.get_bus_volume_linear(bus_index) * 100.0
		)

	menu_content.add_child(music_slider)

	music_value_label = Label.new()
	music_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_content.add_child(music_value_label)

	music_slider.value_changed.connect(_on_music_volume_changed)
	_on_music_volume_changed(music_slider.value)

	_add_button("Back", _show_pause_menu)


func _on_music_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(music_bus_name)

	if bus_index < 0:
		bus_index = AudioServer.get_bus_index("Master")

	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(
			bus_index,
			value / 100.0
		)

	if is_instance_valid(music_value_label):
		music_value_label.text = "%d%%" % int(value)



func _show_key_bindings() -> void:
	current_page = "keys"
	_prepare_page("KEY BINDINGS")

	var key_bindings = [
		{"action": "Right", "keys": "D / →"},
		{"action": "Left", "keys": "A / ←"},
		{"action": "Glider", "keys": "W / ↑"},
		{"action": "Change Mode", "keys": "Space Bar"}
	]

	for binding in key_bindings:
		var row = HBoxContainer.new()
		menu_content.add_child(row)

		var action_label = Label.new()
		action_label.text = binding["action"]
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(action_label)

		var key_label = Label.new()
		key_label.text = binding["keys"]
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(key_label)

	_add_button("Back", _show_pause_menu)



func _back_to_menu() -> void:
	# Percorso della scena Home Menu
	var home_scene_path = "res://scenes/home_menu.tscn"

	if not ResourceLoader.exists(home_scene_path):
		push_error("Home Menu scene not found: " + home_scene_path)
		return

	# Riprende il gioco prima di cambiare scena
	get_tree().paused = false
	is_pause_open = false

	# Torna alla schermata iniziale
	var error = get_tree().change_scene_to_file(home_scene_path)

	if error != OK:
		push_error("Unable to return to Home Menu.")



func _restart_level() -> void:
	get_tree().paused = false
	is_pause_open = false

	var error = get_tree().reload_current_scene()

	if error != OK:
		push_error("Could not restart the current level.")


func _close_game() -> void:
	get_tree().quit()
