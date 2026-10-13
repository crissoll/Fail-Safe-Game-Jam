extends Area2D

var speed: float = 100.0
var distance: float = 200.0

var start_position: Vector2
var target_position: Vector2
var moving_right: bool = true

func _ready() -> void:
	start_position = global_position
	target_position = start_position + Vector2(distance, 0)


func _process(delta: float) -> void:
	if moving_right:
		global_position = global_position.move_toward(
			target_position, speed * delta
		)

		if global_position.x >= target_position.x:
			global_position = target_position
			moving_right = false

	else:
		global_position = global_position.move_toward(
			start_position, speed * delta
		)

		if global_position.x <= start_position.x:
			global_position = start_position
			moving_right = true

	for body in get_overlapping_bodies():
		if body is Player:
			body.apply_damage()
