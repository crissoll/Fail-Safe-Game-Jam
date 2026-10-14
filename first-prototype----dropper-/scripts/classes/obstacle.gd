class_name Obstacle
extends Area2D

@export var damage := 1

func _process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			body.health_comp.apply_damage(damage)
