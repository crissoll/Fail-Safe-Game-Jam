
extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/main.tscn"
@export var music_bus_name: StringName = &"Music"

var menu_content: VBoxContainer
var music_slider: HSlider
var music_value_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_show_home_menu()


func _clear_interface() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _prepare_page(title_text: String) -> void:
	_clear_interface()

	var background = ColorRect.new()
	background.color = Color(0.07, 0.09, 0.15, 1.0)
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(center)

	menu_content = VBoxContainer.new()
	menu_content.custom_minimum_size = Vector2(420, 0)
	menu_content.add_theme_constant_override("separation", 12)
	center.add_child(menu_content)

	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	menu_content.add_child(title)

	menu_content.add_child(HSeparator.new())


func _add_button(
	button_text: String,
	callback: Callable
) -> void:
	var button = Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 48)
	menu_content.add_child(button)
	button.pressed.connect(callback)


func _show_home_menu() -> void:
	_prepare_page("MY GAME")

	var subtitle = Label.new()
	subtitle.text = "Main Menu"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_content.add_child(subtitle)

	_add_button("Play", _on_play_pressed)
	_add_button("Settings", _show_settings)


func _on_play_pressed() -> void:
	if not ResourceLoader.exists(game_scene_path):
		push_error("Game scene not found: " + game_scene_path)
		return

	get_tree().paused = false
	var error = get_tree().change_scene_to_file(game_scene_path)

	if error != OK:
		push_error("Unable to load the game scene.")


func _show_settings() -> void:
	_prepare_page("SETTINGS")

	var music_label = Label.new()
	music_label.text = "Music Volume"
	menu_content.add_child(music_label)

	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.custom_minimum_size = Vector2(0, 32)
	menu_content.add_child(music_slider)

	music_value_label = Label.new()
	music_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_content.add_child(music_value_label)

	var bus_index = AudioServer.get_bus_index(music_bus_name)

	if bus_index < 0:
		bus_index = AudioServer.get_bus_index("Master")

	if bus_index >= 0:
		music_slider.value = (
			AudioServer.get_bus_volume_linear(bus_index) * 100.0
		)
	else:
		music_slider.value = 100.0

	music_slider.value_changed.connect(_on_music_volume_changed)
	_on_music_volume_changed(music_slider.value)

	_add_button("Key Bindings", _show_key_bindings)
	_add_button("Back", _show_home_menu)


func _on_music_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(music_bus_name)

	if bus_index < 0:
		bus_index = AudioServer.get_bus_index("Master")

	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(
			bus_index,
			value / 100.0
		)

	music_value_label.text = "%d%%" % int(value)


func _show_key_bindings() -> void:
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

	_add_button("Back to Settings", _show_settings)
	_add_button("Back to Home", _show_home_menu)
