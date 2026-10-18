
extends Node

const MUSIC_BUS_NAME := "Music"
const SAVE_PATH := "user://settings.cfg"
const DEFAULT_VOLUME := 80.0

var music_volume: float = DEFAULT_VOLUME


func _ready() -> void:
	var config := ConfigFile.new()

	if config.load(SAVE_PATH) == OK:
		music_volume = float(
			config.get_value("audio", "music_volume", DEFAULT_VOLUME)
		)

	_apply_volume()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	_apply_volume()

	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)

	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Impossibile salvare il volume musicale.")


func get_music_volume() -> float:
	return music_volume


func _apply_volume() -> void:
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS_NAME)

	if bus_index == -1:
		push_warning(
			"Bus Music non trovato. Crealo nel pannello Audio di Godot."
		)
		return

	AudioServer.set_bus_mute(bus_index, music_volume <= 0.0)

	if music_volume > 0.0:
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(music_volume / 100.0)
		)
