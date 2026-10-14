extends Node
class_name HealtComponent

signal die
signal health_changed(to : int)

@export_range(0, 10, 1, "suffix:hearts", "hide_slider") var max_hearts: int = 2
var hearts := max_hearts
@export_range(0.1,10,0.1,"suffix:s") var invincibility_duration : float = 0.5
@export var die_on_zero_hearts : bool = true

@export var velocity_multiplier_on_damage := 0.5

@export var player : Player

var last_damage_time : float

func apply_damage(damage:=1):
	if(float(Time.get_ticks_msec())/1000 - last_damage_time <= invincibility_duration):
		return
	
	player.linear_velocity.y *= velocity_multiplier_on_damage
	last_damage_time = float(Time.get_ticks_msec())/1000
	hearts -= damage;
	if(hearts <= 0):
		hearts = 0
		die.emit()
	health_changed.emit(hearts)
	player.modulate.a = 0.6
	await get_tree().create_timer(invincibility_duration).timeout
	player.modulate.a = 1
	

func reset():
	hearts = max_hearts
	last_damage_time = 0
