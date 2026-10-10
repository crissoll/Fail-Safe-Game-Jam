class_name Player
extends RigidBody2D

@export var move_speed := 10.0
@export var max_y_speed := 400.0
@export var g := 200.0
@export var start_pos : Node2D
@export var start_pos_reversed: Node2D
@export var camera : Camera2D
@export var camera_change_speed := 1000.0
@export var reset_to_real_start := false

var upside_down := false
var reverse_camera := false
var reversed_camera_pos : Vector2

func set_direction(reversed := false)-> void:
	upside_down = reversed
	linear_velocity.y = 0
	if reversed:
		linear_velocity.y *= -1
		reverse_camera = true
		
	
	
func reset() -> void:
	global_position = start_pos.global_position
	if(upside_down):
		global_position = start_pos_reversed.global_position
	linear_velocity = Vector2.ZERO
func _ready() -> void:
	reset()
	reversed_camera_pos = camera.position
	reversed_camera_pos.y *= -1
	
func _process(delta: float) -> void:
	if (reverse_camera):
		print("!")
		camera.position.y -= camera_change_speed * delta
		if(camera.position.y < reversed_camera_pos.y):
			reverse_camera = false
			camera.position = reversed_camera_pos
		return
	if Input.is_action_just_pressed(&"ui_accept"):
		reset()
	var mov_vec := Input.get_axis(&"ui_left",&"ui_right")
	linear_velocity.x = (mov_vec * move_speed)
	
	if(abs(linear_velocity.y) < max_y_speed):
		linear_velocity.y += (1 - 2 * int(upside_down)) * g * delta

	if(get_contact_count()):
		reset()
