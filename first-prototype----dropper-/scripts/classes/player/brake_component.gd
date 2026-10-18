
class_name BrakeComponent
extends Node

signal brake_started
signal brake_ended

@export var brake_strength := 300.0
@export var brake_stamina_consumption := 100.0

@export var stamina_comp: StaminaComponent

## Evita la riattivazione automatica della frenata
## quando la stamina si recupera mentre il tasto è premuto.
var brake_jammed := false

# Blocco della frenata dopo il rimbalzo
var brake_input_locked: bool = false
var bounce_active: bool = false


func can_brake() -> bool:
	return (
		not stamina_comp.is_depleted
		and not brake_jammed
		and not brake_input_locked
	)


func set_brake_input_locked(locked: bool) -> void:
	brake_input_locked = locked
	bounce_active = locked

	if locked:
		stop_braking()


func update_bounce_state(vertical_velocity: float, upside_down: bool) -> void:
	if not brake_input_locked or not bounce_active:
		return

	# Sblocca la frenata quando il personaggio ricomincia a cadere.
	if not upside_down and vertical_velocity >= 0.0:
		brake_input_locked = false
		bounce_active = false
	elif upside_down and vertical_velocity <= 0.0:
		brake_input_locked = false
		bounce_active = false


func stop_braking() -> void:
	brake_ended.emit()


func start_braking() -> void:
	if can_brake():
		brake_started.emit()


func reset() -> void:
	brake_input_locked = false
	bounce_active = false
	brake_jammed = false
	brake_ended.emit()
