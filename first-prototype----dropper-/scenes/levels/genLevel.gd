@tool
extends TileMapLayer

@export var generate := false:
	set(value):
		if value:
			generate_level()
		generate = false

@export_file("*.json") var level_file: String

## Cella del layer dove viene disegnato matrix[0][0]
@export var matrix_origin := Vector2i.ZERO

## Se attivo, svuota il layer prima di disegnare
@export var clear_before := true

## Valore nella matrice -> Vector2i(ID sorgente del TileSet, ID della scena nella raccolta)
## ESEMPIO: da adattare ai tuoi ID reali
@export var tiles := {
	1: Vector2i(2, 1), # jellyfish
	2: Vector2i(2, 2), # jellyfish - medium bounce
	3: Vector2i(2, 3), # jellyfish - strong bounce
	# 4: Vector2i(1, 1), # un tile della sorgente "Obstacles"
	# 5: Vector2i(0, 1), # un tile della sorgente "Spiritual Obstacles"
}

func generate_level() -> void:
	if not Engine.is_editor_hint():
		return

	var matrix := _load_matrix()
	if matrix.is_empty():
		push_error("JSON vuoto o non valido")
		return

	if clear_before:
		clear()

	for y in matrix.size():
		for x in matrix[y].size():
			var value := int(matrix[y][x])
			var cell := matrix_origin + Vector2i(x, y)

			if value == 0:
				erase_cell(cell)
				continue

			if not tiles.has(value):
				push_warning("Nessun tile assegnato per il valore %d" % value)
				continue

			var entry: Vector2i = tiles[value]
			# raccolta di scene: atlas_coords sempre (0,0), la scena è l'alternative_tile
			set_cell(cell, entry.x, Vector2i.ZERO, entry.y)

	print("Livello generato")

func _load_matrix() -> Array:
	if level_file.is_empty() or not FileAccess.file_exists(level_file):
		return []

	var file := FileAccess.open(level_file, FileAccess.READ)
	if file == null:
		return []

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("matrix"):
		return []

	return data["matrix"]
