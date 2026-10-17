extends Node2D
class_name JellyFish

@export var bounce_velocity: int = 90

@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	add_to_group("Jellyfish")


<<<<<<< Updated upstream
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and body.has_method("apply_vertical_impulse"):
		body.apply_vertical_impulse(bounce_velocity)
		visible = false
		area_2d.set_deferred("monitoring", false)
=======

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.set_glider_input_locked(true)
		body.apply_vertical_impulse(bounce_velocity)
		visible = false
		area_2d.set_deferred("monitoring", false)



func reset() -> void:
	visible = true
	area_2d.set_deferred("monitoring", true)
>>>>>>> Stashed changes
