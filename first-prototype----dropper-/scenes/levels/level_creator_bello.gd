extends Node2D

@export var tile_size: Vector2 = Vector2(64, 64)   # distanza tra una cella e l'altra
@export var offset: Vector2 = Vector2.ZERO         # sposta tutta la griglia
@export var block_scale: Vector2 = Vector2.ONE     # ingrandisce ogni blocco
@export var center_blocks: bool = false            # true se il centro del blocco è il suo punto (0,0)

@export var obstacle_1: PackedScene
@export var obstacle_2: PackedScene
@export var obstacle_3: PackedScene

var level_matrix = [
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0],
[ 1, 2, 2, 2, 1,1, 1 ],
[ 1, 2, 2, 2, 1,1, 1 ],
[ 1, 2, 2, 2, 1,1, 1 ],
[ 1, 2, 2, 2, 1,1, 1 ],
[ 1, 2, 2, 2, 1,1, 1 ],
[ 1, 2, 2, 2, 1,1, 1 ],
[ 1, 2, 2, 2, 1,1, 1 ],
]


func _ready():
	generate_level()

func generate_level():
	for y in range(level_matrix.size()):
		for x in range(level_matrix[y].size()):

			var cell = level_matrix[y][x]
			var scene: PackedScene = null

			match cell:
				1: scene = obstacle_1
				2: scene = obstacle_2
				3: scene = obstacle_3

			if scene:
				var obstacle = scene.instantiate()
				var pos = offset + Vector2(x * tile_size.x, y * tile_size.y)
				if center_blocks:
					pos += tile_size / 2.0
				obstacle.position = pos
				obstacle.scale = block_scale
				add_child(obstacle)
