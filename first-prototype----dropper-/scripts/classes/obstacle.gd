class_name Obstacle
extends Area2D

enum SpiritDisplayMode{
	PHYSICAL,
	SPIRIT,
	BOTH,
}

@export var damage := 1
@export var spirit_display_mode :  SpiritDisplayMode = SpiritDisplayMode.BOTH

func fade() -> void:
	modulate.a = 0.1

func materialize() -> void:
	modulate.a = 1

func _process(delta: float) -> void:
	if monitoring:
		for body in get_overlapping_bodies():
			if body is Player:
				body.health_comp.apply_damage(damage)

func _ready() -> void:
	if spirit_display_mode == SpiritDisplayMode.SPIRIT:
		add_to_group(&"spirit_obstacles")
	elif spirit_display_mode == SpiritDisplayMode.PHYSICAL:
		add_to_group(&"obstacles")
