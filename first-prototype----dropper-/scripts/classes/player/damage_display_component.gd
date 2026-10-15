extends Node

@export var player : Player
func disappear() -> void:
	player.modulate.a = 0.6

func reappear() -> void:
	player.modulate.a = 1
