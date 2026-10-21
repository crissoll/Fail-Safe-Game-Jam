extends Node

@export var min_falling_fps := 7.0
@export var max_falling_fps := 10.0

@export var min_gliding_fps := 10.0
@export var max_gliding_fps := 12.0

@export var animation : AnimatedSprite2D
@export var brake_comp : BrakeComponent
@export var spirit_comp : SpiritComponent
@export var health_comp : HealtComponent

@export var player : Player

var bright_color: Color = Color(3.225, 3.225, 3.225)

func _set_modulate(_arg=null) -> void:
	if(spirit_comp.is_spirit):
		animation.play("ray_phasing")
	else:
		animation.play("ray_phasing_to_dark")
	await animation.animation_finished
	play_falling()

func _set_flip_v() -> void:
	animation.flip_v = player.upside_down

func play_falling() -> void:
	if spirit_comp.is_spirit:
		animation.play("ray_falling_light")
	else:
		animation.play("falling_dark")
	_set_flip_v()
	#_set_modulate()

func play_gliding() -> void:
	if spirit_comp.is_spirit:
		animation.play("ray_gliding_light")
	else:
		animation.play("gliding_dark")
	_set_flip_v()
	#_set_modulate()


func play_damage(_arg = null) -> void:
	if spirit_comp.is_spirit:
		animation.play("ray_damaged_falling_light")
	else:
		animation.play("ray_damaged_falling_dark")
	await animation.animation_finished
	play_falling()
		

func _ready() -> void:
	animation.play("falling_dark")
	brake_comp.brake_started.connect(play_gliding)
	brake_comp.brake_ended.connect(play_falling)
	player.flipped.connect(_set_flip_v)
	spirit_comp.dimension_switched.connect(_set_modulate)
	health_comp.health_changed.connect(play_damage)
	_set_flip_v()
	#_set_modulate()
