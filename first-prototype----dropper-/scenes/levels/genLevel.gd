@tool
extends TileMapLayer

@export var generate := false:
	set(value):
		if value:
			generate_level()
		generate = false

@export_file("*.json")
var level_file: String

# Cella della TileMap che corrisponde a matrix[0][0]
@export var matrix_origin: Vector2i = Vector2i.ZERO

# Scene associate ai valori 1..6
@export var block_1: PackedScene
@export var block_2: PackedScene
@export var block_3: PackedScene
@export var block_4: PackedScene
@export var block_5: PackedScene
@export var block_6: PackedScene

const GENERATED_GROUP := "generated_level"


func generate_level():

	if not Engine.is_editor_hint():
		return

	print("Generazione livello")

	var matrix := _load_matrix()

	if matrix.is_empty():
		push_error("JSON vuoto o non valido")
		return

	_clear_previous()

	var scene_map := {
		1: block_1,
		2: block_2,
		3: block_3,
		4: block_4,
		5: block_5,
		6: block_6
	}

	var root := get_tree().edited_scene_root

	if root == null:
		push_error("edited_scene_root nullo")
		return

	for y in range(matrix.size()):

		for x in range(matrix[y].size()):

			var value := int(matrix[y][x])

			if value == 0:
				continue

			var packed_scene: PackedScene = scene_map.get(value)

			if packed_scene == null:
				push_warning("Nessun prefab assegnato per ID %d" % value)
				continue

			var instance := packed_scene.instantiate()

			var map_cell := matrix_origin + Vector2i(2*x, 2*y)

			if instance is Node2D:
				instance.position = map_to_local(map_cell)

			root.add_child(instance)
			instance.owner = root
			instance.add_to_group(GENERATED_GROUP)

	print("Livello generato")


func _load_matrix() -> Array:

	if level_file.is_empty():
		return []

	if not FileAccess.file_exists(level_file):
		return []

	var file := FileAccess.open(level_file, FileAccess.READ)

	if file == null:
		return []

	var text := file.get_as_text()

	var data = JSON.parse_string(text)

	if typeof(data) != TYPE_DICTIONARY:
		return []

	if not data.has("matrix"):
		return []

	return data["matrix"]


func _clear_previous():

	var root := get_tree().edited_scene_root

	if root == null:
		return

	for node in root.get_children():

		if node.is_in_group(GENERATED_GROUP):
			node.free()
