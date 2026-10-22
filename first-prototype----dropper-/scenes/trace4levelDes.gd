@tool
extends CharacterBody2D

const INTERVALLO := 0.3

var timer := 0.0

func _process(delta):
	if not Engine.is_editor_hint() and not Input.is_key_pressed(KEY_Q):
		return

	if Input.is_key_pressed(KEY_Q):
		timer += delta

		if timer >= INTERVALLO:
			timer = 0.0
			_crea_punto()

func _crea_punto():
	var punto := PuntoPersistente.new()

	punto.position = position

	# Aggiunge il punto alla scena principale
	get_tree().edited_scene_root.add_child(punto)
	punto.owner = get_tree().edited_scene_root

	# Aggiorna il file scena nell'editor
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
