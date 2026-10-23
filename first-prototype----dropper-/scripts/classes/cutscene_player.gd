class_name CutscenePlayer
extends Node
## Fa partire l'animazione della cutscene e, quando finisce, carica la scena di gioco.
## Si può saltare con Invio/Spazio/Esc o un clic.

## Scena da caricare a fine cutscene.
@export_file("*.tscn") var next_scene := "res://scenes/main.tscn"
## AnimationPlayer della cutscene (se vuoto lo cerca tra i figli).
@export var animation_player: AnimationPlayer
## Animazione da riprodurre.
@export var animation_name: StringName = &"cutscene"
## Permette di saltare la cutscene.
@export var can_skip := true

var _leaving := false


func _ready() -> void:
	if animation_player == null:
		animation_player = find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	if animation_player == null or not animation_player.has_animation(animation_name):
		push_warning("Cutscene: animazione '%s' non trovata, passo al gioco." % animation_name)
		_go_to_next_scene()
		return
	animation_player.animation_finished.connect(_on_animation_finished)
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)


func _unhandled_input(event: InputEvent) -> void:
	if not can_skip or _leaving:
		return
	var skip := event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel")
	if event is InputEventMouseButton and event.pressed:
		skip = true
	if skip:
		get_viewport().set_input_as_handled()
		_go_to_next_scene()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		_go_to_next_scene()


func _go_to_next_scene() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file.call_deferred(next_scene)
