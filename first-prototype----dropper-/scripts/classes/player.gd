class_name Player
extends RigidBody2D

@onready var paraglider: Polygon2D = $Paraglider

@export var max_stamina := 100.0
var stamina := max_stamina
@export var brake_stamina_constumption_per_second := 100.0
@export var stamina_recover := 60.0
@export var brake_cooldown := 0.5
var cur_brake_cooldown = 0.0

@export var move_speed := 10.0

@export var max_y_speed := 400.0
@export var min_y_speed := 200.0

@export var brake_strength := 300.0
@export var g := 200.0

var spawn_pos : Vector2
var stamina_runnout := false

@onready var camera :Camera2D = $Camera2D
@export var camera_change_speed := 1000.0
@onready var temp_stamina_label: Label = $TempStaminaLabel
@onready var star: Polygon2D = $Star

var upside_down := false
var reverse_camera := false
var reversed_camera_pos : Vector2

var spirit := false
		
func reverse_fall() -> void:
	upside_down = true
	linear_velocity = Vector2.ZERO
	reverse_camera = true
	
func reset() -> void:
	global_position = spawn_pos
	linear_velocity = Vector2.ZERO
	if(upside_down):
		camera.position.y *= -1
	upside_down = false
	spirit = false
	update_spirit_form()
	if(paraglider != null):
		paraglider.hide()
	if(star != null):
		star.hide()
	stamina = max_stamina
	cur_brake_cooldown = 0
	stamina_runnout = false
	reverse_camera = false
	
	#every time the level resets, jellyfish are visible and monitoring again
	for i:JellyFish in get_tree().get_nodes_in_group("Jellyfish"):
		i.visible = true
		i.area_2d.set_deferred("monitoring", true)
	
func apply_vertical_impulse(impulse_value):
	linear_velocity.y = -1 * impulse_value * (1 - 2 * int(upside_down))

func update_spirit_form() ->void:
	set_collision_layer_value(4,!spirit)
	set_collision_layer_value(5,spirit)
	if(spirit):
		$CollisionShape2D.debug_color = Color.GREEN
	else:
		$CollisionShape2D.debug_color = Color.BLUE
func switch_dimension() -> void:
	spirit = !spirit
	print(spirit)
	
	update_spirit_form()
	
	

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
	if Input.is_action_just_pressed(&"reset_level"):
		reset()
		return
	
	if Input.is_action_just_pressed(&"switch_dimension"):
		switch_dimension()
	
	temp_stamina_label.text = str(int(stamina))
	var mov_vec := Input.get_axis(&"left",&"right")
	linear_velocity.x = (mov_vec * move_speed)
	
	if Input.is_action_just_pressed(&"slow_down") and !stamina_runnout and cur_brake_cooldown <= 0:
		paraglider.show()
	
	elif Input.is_action_just_released(&"slow_down"):
		cur_brake_cooldown = brake_cooldown
		star.show()
		paraglider.hide()
		stamina_runnout = false
	elif stamina < 0:
		cur_brake_cooldown = brake_cooldown
		star.show()
		paraglider.hide()
	print(stamina," ",cur_brake_cooldown)
	
	if Input.is_action_pressed(&"slow_down") and (stamina > 0) and !stamina_runnout and cur_brake_cooldown <= 0:
		stamina -= brake_stamina_constumption_per_second * delta
		if(stamina < 0):
			stamina_runnout = true
		if(abs(linear_velocity.y) > min_y_speed && abs(linear_velocity.y) < max_y_speed ):
			linear_velocity.y -= (1 - 2 * int(upside_down)) * brake_strength * delta
	else:
		if(cur_brake_cooldown > 0):
			cur_brake_cooldown -= delta
		else:
			star.hide()
		if(stamina < max_stamina):
			stamina += stamina_recover * delta
		
		if(abs(linear_velocity.y) < max_y_speed):
			linear_velocity.y += (1 - 2 * int(upside_down)) * g * delta
		

func apply_damage():
	reset()
