extends Node

@export var min_falling_fps := 7.0
@export var max_falling_fps := 10.0

@export var min_gliding_fps := 10.0
@export var max_gliding_fps := 12.0

@export var animation : AnimatedSprite2D
@export var brake_comp : BrakeComponent
@export var spirit_comp : SpiritComponent
@export var player : Player

var bright_color: Color = Color(3.225, 3.225, 3.225)

func _set_modulate(_arg=null) -> void:
	if(spirit_comp.is_spirit):
		animation.modulate = Color.WHITE
	else:
		animation.modulate = bright_color

func _set_flip_v() -> void:
	animation.flip_v = player.upside_down

func play_falling() -> void:
	animation.play("falling_dark")
	_set_flip_v()
	_set_modulate()

func play_gliding() -> void:
	animation.play("gliding_dark")
	_set_flip_v()
	_set_modulate()

func _ready() -> void:
	animation.play("falling_dark")
	brake_comp.brake_started.connect(func():animation.play("gliding_dark"))
	brake_comp.brake_ended.connect(play_falling)
	player.flipped.connect(_set_flip_v)
	spirit_comp.dimension_switched.connect(_set_modulate)
	_set_flip_v()
	_set_modulate()
