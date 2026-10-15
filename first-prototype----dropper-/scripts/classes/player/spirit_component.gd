class_name SpiritComponent
extends Node

signal dimension_switched(is_spirit: bool)

@export var normal_layer := 4
@export var spirit_layer := 5

var is_spirit := false

func switch_dimension(body: CollisionObject2D) -> void:
	is_spirit = !is_spirit
	body.set_collision_layer_value(normal_layer, !is_spirit)
	body.set_collision_layer_value(spirit_layer, is_spirit)
	

	dimension_switched.emit(is_spirit)

func reset(body: CollisionObject2D) -> void:
	is_spirit = false
	body.set_collision_layer_value(normal_layer, true)
	body.set_collision_layer_value(spirit_layer, false)
	dimension_switched.emit(is_spirit)
