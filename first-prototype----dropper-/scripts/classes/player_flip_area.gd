class_name PlayerFlipArea
extends Area2D

signal player_entered(player:Player)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.upside_down == true:
			return
		player_entered.emit(body)
