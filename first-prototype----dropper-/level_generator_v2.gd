@tool
extends TileMapLayer

@export var regenerate := false:
	set(value):
		if value:
			generate_level()
		regenerate = false

# cella della TileMap che rappresenta matrix[0][0]
@export var matrix_origin: Vector2i = Vector2i.ZERO

# prefab associati ai valori 1..6
@export var block_1: PackedScene
@export var block_2: PackedScene
@export var block_3: PackedScene
@export var block_4: PackedScene
@export var block_5: PackedScene
@export var block_6: PackedScene

var level_data = [
	[0,0,1,0],
	[2,0,0,3],
	[0,4,5,0],
	[6,0,0,0]
]

const GENERATED_PREFIX := "__generated_"

func generate_level():

	print("Generazione...")

	if not Engine.is_editor_hint():
		return

	_clear_previous()

	var prefab_map := {
		1: block_1,
		2: block_2,
		3: block_3,
		4: block_4,
		5: block_5,
		6: block_6
	}

	var root := get_tree().edited_scene_root

	if root == null:
		return

	for y in range(level_data.size()):

		for x in range(level_data[y].size()):

			var value = level_data[y][x]

			if value == 0:
				continue

			if !prefab_map.has(value):
				continue

			var scene: PackedScene = prefab_map[value]

			if scene == null:
				continue

			var obj = scene.instantiate()

			var cell = matrix_origin + Vector2i(x, y)

			obj.position = map_to_local(cell)

			obj.name = GENERATED_PREFIX + str(x) + "_" + str(y)

			root.add_child(obj)
			obj.owner = root

func _clear_previous():

	var root := get_tree().edited_scene_root

	if root == null:
		return

	for child in root.get_children():

		if child.name.begins_with(GENERATED_PREFIX):
			child.queue_free()
