class_name Obstacle
extends Area2D

func _process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			body.apply_damage()
