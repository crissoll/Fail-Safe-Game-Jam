extends Area2D

var speed: float = 100.0
var distance: float = 180.0

var start_position: Vector2
var target_position: Vector2
var moving_left: bool = true

func _ready() -> void:
	start_position = global_position
	target_position = start_position - Vector2(distance, 0)

func _process(delta: float) -> void:
	if moving_left:
		global_position = global_position.move_toward(
			target_position, speed * delta
		)

		if global_position.distance_to(target_position) < 1.0:
			moving_left = false
	else:
		global_position = global_position.move_toward(
			start_position, speed * delta
		)

		if global_position.distance_to(start_position) < 1.0:
			moving_left = true

	for body in get_overlapping_bodies():
		if body is Player:
			body.apply_damage()
