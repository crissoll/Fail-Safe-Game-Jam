@tool

class_name Level
extends Node2D

@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var left_wall: Obstacle = $LeftWall
@onready var right_wall: Obstacle = $RightWall
@onready var flip_player_area: PlayerFlipArea = $FlipPlayerArea

@export var width := 400.0:
	set(value):
		width = value
		if(left_wall == null):
			if Engine.is_editor_hint():
				return
			await ready
		left_wall.position.x = - width/2
		right_wall.position.x = width/2

@export var height := 4000.0:
	set(value):
		height = value
		if(flip_player_area == null):
			if Engine.is_editor_hint():
				return
			await ready
		flip_player_area.position.y = height
		
@export_category("Nodes")
@export var player: Player

func _ready() -> void:
	if Engine.is_editor_hint():
		width = width
		height = height
		return
	player.spawn_pos = spawn_marker.position
	player.reset()
	
	

func _on_reverse_area_player_entered(player:Player) -> void:
	player.reverse_fall()
	
