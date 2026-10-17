extends Node

@export var min_falling_fps := 7.0
@export var max_falling_fps := 10.0

@export var min_gliding_fps := 10.0
@export var max_gliding_fps := 12.0

@export var animation : AnimatedSprite2D
@export var brake_comp : BrakeComponent
@export var player : Player

func play_falling() -> void:
	animation.play("falling_dark")
	animation.flip_v = player.upside_down
func _ready() -> void:
	animation.play("falling_dark")
	brake_comp.brake_started.connect(func():animation.play("gliding_dark"))
	brake_comp.brake_ended.connect(play_falling)
	player.flipped.connect(func(): animation.flip_v = true)
	
