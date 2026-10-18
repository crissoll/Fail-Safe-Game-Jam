extends Obstacle
class_name JellyFish

@export var bounce_velocity : int = 90

func fade() -> void:
	modulate.a = 0.1

func materialize() -> void:
	modulate.a = 1

func _ready() -> void:
	super()
	add_to_group("Jellyfish")
	
func reset() -> void:
	visible = true
	set_deferred("monitoring", true)

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.apply_vertical_impulse(bounce_velocity)
		visible = false
		set_deferred("monitoring", false)
