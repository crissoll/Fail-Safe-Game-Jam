extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.upside_down == true:
			return
		body.set_direction(true)
