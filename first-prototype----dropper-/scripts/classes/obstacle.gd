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

func _physics_process(delta: float) -> void:
	if monitoring:
		for body in get_overlapping_bodies():
			if body is Player:
				body.health_comp.apply_damage(damage)

func _ready() -> void:
	if spirit_display_mode == SpiritDisplayMode.SPIRIT:
		add_to_group(&"spirit_obstacles") 
		set_collision_mask_value(5,true)
		set_collision_mask_value(4,false)
	elif spirit_display_mode == SpiritDisplayMode.PHYSICAL: 
		set_collision_mask_value(5,false)
		set_collision_mask_value(4,true)
		add_to_group(&"obstacles")
	else:
		set_collision_mask_value(5,true)
		set_collision_mask_value(4,true)
		#add_to_group(&"obstacles")
		#add_to_group(&"spirit_obstacles")
