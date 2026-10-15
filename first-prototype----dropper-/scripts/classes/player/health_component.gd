extends Node
class_name HealtComponent

signal die
signal health_changed(to : int)
signal invincibility_started
signal invincibility_ended

@export_range(0, 10, 1, "suffix:hearts", "hide_slider") var max_hearts: int = 2
var hearts: float
@export_range(0.1,10,0.1,"suffix:s") var invincibility_duration : float = 0.5
@export var die_on_zero_hearts : bool = true

@export var velocity_multiplier_on_damage := 0.5

@export var player : Player

var last_damage_time : float

func _ready() -> void:
	hearts = max_hearts
	#health_changed.emit(hearts)
	

func apply_damage(damage:=1):
	if(float(Time.get_ticks_msec())/1000 - last_damage_time < invincibility_duration):
		return
	
	player.velocity.y *= velocity_multiplier_on_damage
	last_damage_time = float(Time.get_ticks_msec())/1000
	hearts -= damage;
	if(hearts <= 0) && die_on_zero_hearts:
		hearts = 0
		die.emit()
	health_changed.emit(hearts)
	SignalManager.on_player_health_changed.emit(max_hearts, hearts)
	invincibility_started.emit()
	await get_tree().create_timer(invincibility_duration).timeout
	invincibility_ended.emit()
	
	print(hearts)
	

func reset():
	invincibility_ended.emit()
	hearts = max_hearts
	SignalManager.on_player_health_changed.emit(max_hearts,max_hearts)
