extends Node2D
class_name Egg

var is_detached: bool = false
var velocity: Vector2 = Vector2.ZERO
var last_frame_position: Vector2 = Vector2.ZERO

var gravity: float = 980.0 
var bounce_factor: float = 0.5 

func _ready():
	last_frame_position = global_position

func _physics_process(delta):
	if not is_detached:
		velocity = (global_position - last_frame_position) / delta
		last_frame_position = global_position
	else:
		global_position += velocity * delta
		
		rotation += 5.0 * delta 

func detach_and_break():
	is_detached = true
	velocity.y -= 150.0
	if is_inside_tree():
		await get_tree().create_timer(1).timeout
		queue_free()
