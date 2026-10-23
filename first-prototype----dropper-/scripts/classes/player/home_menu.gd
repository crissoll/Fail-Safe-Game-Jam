
extends Control

const GAME_SCENE_PATH := "res://scenes/main.tscn"
## Cutscene mostrata dopo Play; a fine cutscene si passa a GAME_SCENE_PATH.
const INTRO_CUTSCENE_PATH := "res://scenes/scenes/cutscene_1.tscn"
const SAVE_PATH := "user://settings.cfg"
const MUSIC_BUS_NAME: StringName = &"Music"
const DEFAULT_MUSIC_VOLUME := 80.0

var image = preload("res://assets/Obstacles/Untitled_Artwork.png")
var menu_container: VBoxContainer
var settings_container: VBoxContainer
var music_slider: HSlider
var music_value_label: Label

var music_volume: float = DEFAULT_MUSIC_VOLUME


func _ready() -> void:
	_load_music_volume()
	_build_menu()

	# Mostra il valore già salvato senza richiamare value_changed.
	music_slider.set_value_no_signal(music_volume)
	_update_music_label(music_volume)


func _build_menu() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.texture = image
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var pages := VBoxContainer.new()
	pages.custom_minimum_size = Vector2(340, 0)
	center.add_child(pages)

	menu_container = VBoxContainer.new()
	menu_container.add_theme_constant_override("separation", 16)
	pages.add_child(menu_container)

	var title := Label.new()
	title.text = "RAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	menu_container.add_child(title)

	var play_button := _make_button("Play")
	play_button.pressed.connect(_on_play_pressed)
	menu_container.add_child(play_button)

	var settings_button := _make_button("Settings")
	settings_button.pressed.connect(_on_settings_pressed)
	menu_container.add_child(settings_button)

	var quit_button := _make_button("Exit")
	quit_button.pressed.connect(_on_quit_pressed)
	menu_container.add_child(quit_button)

	settings_container = VBoxContainer.new()
	settings_container.add_theme_constant_override("separation", 16)
	pages.add_child(settings_container)

	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 28)
	settings_container.add_child(settings_title)

	var music_label := Label.new()
	music_label.text = "Music Volume"
	settings_container.add_child(music_label)

	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	music_slider.custom_minimum_size = Vector2(300, 30)
	music_slider.value = music_volume
	music_slider.value_changed.connect(_on_music_volume_changed)
	settings_container.add_child(music_slider)

	music_value_label = Label.new()
	music_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_container.add_child(music_value_label)

	var back_button := _make_button("Indietro")
	back_button.pressed.connect(_on_back_pressed)
	settings_container.add_child(back_button)

	settings_container.hide()


func _make_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(300, 50)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 20)
	return button


func _on_play_pressed() -> void:
	# Prima la cutscene (che poi carica il gioco); se manca, direttamente il gioco.
	var target := INTRO_CUTSCENE_PATH
	if not ResourceLoader.exists(target):
		target = GAME_SCENE_PATH
	if not ResourceLoader.exists(target):
		push_error("Scena di gioco non trovata: " + target)
		return

	var error := get_tree().change_scene_to_file(target)

	if error != OK:
		push_error(
			"Impossibile caricare main.tscn. Codice errore: "
			+ str(error)
		)


func _on_settings_pressed() -> void:
	menu_container.hide()
	settings_container.show()

	# Aggiorna il cursore con il valore attuale del bus.
	# Utile anche se il volume è stato cambiato in un'altra scena.
	_load_music_volume()
	music_slider.set_value_no_signal(music_volume)
	_update_music_label(music_volume)


func _on_back_pressed() -> void:
	settings_container.hide()
	menu_container.show()


func _on_music_volume_changed(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	_apply_music_volume()
	_save_music_volume()
	_update_music_label(music_volume)


func _update_music_label(value: float) -> void:
	if is_instance_valid(music_value_label):
		music_value_label.text = str(int(value)) + "%"


func _apply_music_volume() -> void:
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS_NAME)

	if bus_index == -1:
		push_warning(
			"Bus audio Music non trovato. Crealo nel pannello Audio."
		)
		return

	if music_volume <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_linear(
			bus_index,
			music_volume / 100.0
		)


func _save_music_volume() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)

	var error := config.save(SAVE_PATH)

	if error != OK:
		push_warning("Impossibile salvare il volume musicale.")


func _load_music_volume() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error == OK:
		music_volume = float(
			config.get_value(
				"audio",
				"music_volume",
				DEFAULT_MUSIC_VOLUME
			)
		)
	else:
		music_volume = DEFAULT_MUSIC_VOLUME

	_apply_music_volume()


func _on_quit_pressed() -> void:
	get_tree().quit()
