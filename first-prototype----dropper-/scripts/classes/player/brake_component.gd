class_name BrakeComponent
extends Node

signal brake_started
signal brake_ended

@export var paraglider : Polygon2D
@export var brake_strength := 300.0
@export var stamina_comp : StaminaComponent

## property used to avoid automatic brake usage on stamina recover while holding
## down the brake key
var brake_jammed := false

func can_brake() -> bool:
	return !stamina_comp.is_depleted && !brake_jammed

func stop_braking() -> void:
	brake_ended.emit()

func start_braking() -> void:
	brake_started.emit()
