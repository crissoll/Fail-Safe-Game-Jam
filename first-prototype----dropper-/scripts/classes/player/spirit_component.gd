class_name SpiritComponent
extends Node

signal dimension_switched(is_spirit: bool)

@export var normal_layer := 4
@export var spirit_layer := 5

var is_spirit := true

func switch_dimension(body: CollisionObject2D) -> void:
	is_spirit = !is_spirit #inverting the spirit mode ---> is_spirit = false
	body.set_collision_layer_value(normal_layer, !is_spirit) #---> normal_layer = true
	body.set_collision_layer_value(spirit_layer, is_spirit) #---> spirit_layer = false
	

	dimension_switched.emit(is_spirit)

func reset(body: CollisionObject2D) -> void:
	is_spirit = true
	body.set_collision_layer_value(normal_layer, false)
	body.set_collision_layer_value(spirit_layer, true)
	dimension_switched.emit(is_spirit)
