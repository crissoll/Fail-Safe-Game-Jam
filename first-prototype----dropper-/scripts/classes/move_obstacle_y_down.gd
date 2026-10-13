extends Area2D

var speed: float = 100.0
var distance: float = 200.0

var start_position: Vector2
var target_position: Vector2
var moving_down: bool = true

func _ready() -> void:
	start_position = global_position
	target_position = start_position + Vector2(0, distance)

func _process(delta: float) -> void:
	if moving_down:
		global_position = global_position.move_toward(
			target_position, speed * delta
		)

		if global_position.distance_to(target_position) < 1.0:
			moving_down = false
	else:
		global_position = global_position.move_toward(
			start_position, speed * delta
		)

		if global_position.distance_to(start_position) < 1.0:
			moving_down = true

	for body in get_overlapping_bodies():
		if body is Player:
			body.apply_damage()
