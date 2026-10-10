class_name Player
extends RigidBody2D

@export var move_speed := 10.0
@export var max_y_speed := 400.0
@export var g := 200.0

var spawn_pos : Vector2

@onready var camera :Camera2D = $Camera2D
@export var camera_change_speed := 1000.0

var upside_down := false
var reverse_camera := false
var reversed_camera_pos : Vector2

		
func reverse_fall() -> void:
	upside_down = true
	linear_velocity.y = 0
	linear_velocity.y *= -1
	reverse_camera = true
	
func reset() -> void:
	global_position = spawn_pos
	linear_velocity = Vector2.ZERO
	if(upside_down):
		camera.position.y *= -1
	upside_down = false
	
func apply_vertical_impulse(impulse_value):
	linear_velocity.y = impulse_value

func _ready() -> void:
	reversed_camera_pos = camera.position
	reversed_camera_pos.y *= -1
	
func _physics_process(delta: float) -> void:
	if (reverse_camera):
		camera.position.y -= camera_change_speed * delta
		if(camera.position.y < reversed_camera_pos.y):
			reverse_camera = false
			camera.position = reversed_camera_pos
		return
		
	if Input.is_action_just_pressed(&"ui_accept"):
		reset()
	var mov_vec := Input.get_axis(&"left",&"right")
	linear_velocity.x = (mov_vec * move_speed)
	
	if(abs(linear_velocity.y) < max_y_speed):
		linear_velocity.y += (1 - 2 * int(upside_down)) * g * delta

	if(get_contact_count()):
		reset()
