extends Node

@export var collision_shape : CollisionShape2D

func display_transition(is_spirit:bool) -> void:
	collision_shape.debug_color = Color.GREEN if is_spirit else Color.BLUE
	if is_spirit: 
		get_tree().call_group(&"spirit_obstacles", "materialize")
		get_tree().call_group(&"obstacles", "fade")
	else: 
		get_tree().call_group(&"obstacles", "materialize")
		get_tree().call_group(&"spirit_obstacles", "fade")

func _ready() -> void:
	call_deferred(&"display_transition",true)
