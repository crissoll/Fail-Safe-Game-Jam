class_name StaminaComponent
extends Node

signal stamina_changed(current: float)
signal stamina_depleted
signal stamina_recovered

@export var max_stamina := 100.0
@export var _recover_rate := 60.0
@export var cooldown := 0.5
var current_stamina: float
var is_depleted := false

var last_usage : int

@export var player: Player
func _ready() -> void:
	current_stamina = max_stamina

func _physics_process(delta: float) -> void:
	if player.reverse_camera:
		return
	
	if Time.get_ticks_msec() - last_usage > 1000 * cooldown:
		_recover(delta)

func consume(amount: float, delta: float) -> void:
	last_usage = Time.get_ticks_msec()
	if is_depleted: return
	current_stamina -= amount * delta
	
	if current_stamina <= 0:
		current_stamina = 0
		is_depleted = true
		stamina_depleted.emit()
	stamina_changed.emit(current_stamina)

func _recover(delta: float) -> void:
	if current_stamina < max_stamina:
		current_stamina = minf(current_stamina + _recover_rate * delta, max_stamina)
		stamina_changed.emit(current_stamina)
		if is_depleted and current_stamina > 0:
			is_depleted = false
			stamina_recovered.emit()

func reset() -> void:
	current_stamina = max_stamina
	is_depleted = false
	stamina_changed.emit(current_stamina)
