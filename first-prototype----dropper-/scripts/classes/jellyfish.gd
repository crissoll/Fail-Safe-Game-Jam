extends Node2D
class_name JellyFish

@export var bounce_velocity : int = 90


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_static_body_2d_body_entered(body: Player) -> void:
	if body is Player and body.has_method("apply_vertical_impulse"):
		body.apply_vertical_impulse(bounce_velocity)
		print("entered")
		queue_free()
