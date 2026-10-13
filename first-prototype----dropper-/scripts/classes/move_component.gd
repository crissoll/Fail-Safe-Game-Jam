class_name MoveTowardTargetComponent
extends Node2D

@export var target : Node2D
@export var speed: float = 100.0
@export var start_moving_on_load := true

var start_position: Vector2
var target_position : Vector2

var cur_target_position: Vector2


var path_len : float

var moving: bool = true
var returning_to_start: bool = false

var parent : Node2D

func _ready() -> void:
	parent = get_parent()
	if(parent == null):
		printerr("invalid parent node")
		set_physics_process(false)
		return
	start_position = parent.global_position
	if(target == null):
		printerr("invalid target node")
		set_physics_process(false)
		return
	target_position = target.global_position
	add_to_group(&"MoveComponents")
	
	moving = start_moving_on_load

	cur_target_position = target_position
	path_len = target_position.distance_squared_to(start_position)

func set_motion(value:bool) -> void:
	moving = value

func is_path_ended() -> bool:
	var progress: float;
	if(!returning_to_start):
		progress = parent.global_position.distance_squared_to(start_position)
	else:
		progress = parent.global_position.distance_squared_to( target_position)
	return progress >= path_len

func change_direction() -> void:
	returning_to_start = !returning_to_start
	if(returning_to_start):
		cur_target_position = start_position
	else:
		cur_target_position = target_position
	

func _physics_process(delta: float) -> void:
	if moving == false:
		return
	
	parent.global_position = parent.global_position.move_toward(
		cur_target_position, speed * delta
	)
	if is_path_ended():
		change_direction()

func reset() -> void:
	parent.global_position = start_position
	moving = start_moving_on_load
	cur_target_position = target_position
