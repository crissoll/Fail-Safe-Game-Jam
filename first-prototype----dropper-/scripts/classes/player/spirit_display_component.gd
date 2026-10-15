extends Node

@export var collision_shape : CollisionShape2D

func display_transition(is_spirit:bool) -> void:
	collision_shape.debug_color = Color.GREEN if is_spirit else Color.BLUE
