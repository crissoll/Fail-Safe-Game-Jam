class_name BrakeComponent
extends Node

signal brake_started
signal brake_ended
signal cooldown_ended

@export var brake_strength := 300.0
@export var cooldown_time := 0.5
var current_cooldown := 0.0

func _process(delta: float) -> void:
	if current_cooldown > 0:
		current_cooldown -= delta
		if current_cooldown <= 0:
			cooldown_ended.emit()

func can_brake() -> bool:
	return current_cooldown <= 0

func start_cooldown() -> void:
	current_cooldown = cooldown_time
	brake_ended.emit()

func start_braking() -> void:
	brake_started.emit()

func reset() -> void:
	current_cooldown = 0
