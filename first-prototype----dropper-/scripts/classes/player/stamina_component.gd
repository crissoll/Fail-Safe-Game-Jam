class_name StaminaComponent
extends Node

signal stamina_changed(current: float)
signal stamina_depleted
signal stamina_recovered

@export var max_stamina := 100.0
@export var recover_rate := 60.0
var current_stamina: float
var is_depleted := false

func _ready() -> void:
	current_stamina = max_stamina

func consume(amount: float, delta: float) -> void:
	if is_depleted: return
	current_stamina -= amount * delta
	stamina_changed.emit(current_stamina)
	
	if current_stamina <= 0:
		current_stamina = 0
		is_depleted = true
		stamina_depleted.emit()

func recover(delta: float) -> void:
	if current_stamina < max_stamina:
		current_stamina = minf(current_stamina + recover_rate * delta, max_stamina)
		stamina_changed.emit(current_stamina)
		if is_depleted and current_stamina > 0:
			is_depleted = false
			stamina_recovered.emit()

func reset() -> void:
	current_stamina = max_stamina
	is_depleted = false
	stamina_changed.emit(current_stamina)
