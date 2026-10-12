class_name Player
extends RigidBody2D

#components
@export var stamina_comp: StaminaComponent
@export var brake_comp: BrakeComponent
@export var spirit_comp: SpiritComponent
@export var health_comp: HealtComponent

#vars
@onready var paraglider: Polygon2D = $Paraglider
@onready var star: Polygon2D = $Star
@onready var camera: Camera2D = $Camera2D
@onready var temp_stamina_label: Label = $TempStaminaLabel

#exports
@export var move_speed := 10.0
@export var max_y_speed := 400.0
@export var min_y_speed := 200.0
@export var g := 200.0
@export var brake_stamina_consumption := 100.0
@export var camera_change_speed := 1000.0

var spawn_pos: Vector2
var upside_down := false
var reverse_camera := false
var reversed_camera_pos: Vector2

func _ready() -> void:
	reversed_camera_pos = camera.position
	reversed_camera_pos.y *= -1
	
	stamina_comp.stamina_changed.connect(_on_stamina_changed)
	
	brake_comp.brake_started.connect(func(): paraglider.show())
	brake_comp.brake_ended.connect(func(): 
		paraglider.hide()
		star.show()
	)
	brake_comp.cooldown_ended.connect(func(): star.hide())
	
	health_comp.die.connect(reset)

func _physics_process(delta: float) -> void:
	if reverse_camera:
		_handle_camera_transition(delta)
		return
		
	_handle_input()
	_apply_physics(delta)

func _handle_input() -> void:
	if Input.is_action_just_pressed(&"reset_level"):
		reset()
		return
		
	if Input.is_action_just_pressed(&"switch_dimension"):
		spirit_comp.switch_dimension(self)

func _apply_physics(delta: float) -> void:
	
	var mov_vec := Input.get_axis(&"left", &"right")
	linear_velocity.x = (mov_vec * move_speed)
	
	var trying_to_brake = Input.is_action_pressed(&"slow_down")
	
	#if slow_down is pressed and we can brake (not in cooldown state) and stamina is not depleted -> shows paraglider
	if Input.is_action_just_pressed(&"slow_down") and brake_comp.can_brake() and !stamina_comp.is_depleted:
		brake_comp.start_braking()
	
	#if we keep pressing slow_down and we can brake (not in cooldown state) and stamina is not depleted -> we consume stamina and we slow down
	if trying_to_brake and brake_comp.can_brake() and !stamina_comp.is_depleted:
		stamina_comp.consume(brake_stamina_consumption, delta)
		_apply_brake_force(delta)
	else: #in any other cases we are recovering stamina and applying regular gravity
		stamina_comp.recover(delta)
		_apply_gravity(delta)
		
	#as soon as we release slow_down or stamina is depleted -> cooldown timer resets and starts decreasing, we show the star and we hide the paraglider
	if Input.is_action_just_released(&"slow_down") or stamina_comp.is_depleted:
		brake_comp.start_cooldown()

func _apply_brake_force(delta: float) -> void:
	if abs(linear_velocity.y) > min_y_speed and abs(linear_velocity.y) < max_y_speed:
		linear_velocity.y -= (1 - 2 * int(upside_down)) * brake_comp.brake_strength * delta

func _apply_gravity(delta: float) -> void:
	if abs(linear_velocity.y) < max_y_speed:
		linear_velocity.y += (1 - 2 * int(upside_down)) * g * delta

func apply_vertical_impulse(impulse_value):
	linear_velocity.y = -1 * impulse_value * (1 - 2 * int(upside_down))

func _on_stamina_changed(current: float) -> void:
	temp_stamina_label.text = str(int(current))

func _handle_camera_transition(delta: float) -> void:
	if camera:
		camera.position.y -= camera_change_speed * delta
		if camera.position.y < reversed_camera_pos.y:
			reverse_camera = false
			camera.position = reversed_camera_pos

func reverse_fall() -> void:
	upside_down = true
	linear_velocity = Vector2.ZERO
	reverse_camera = true

func reset() -> void:
	global_position = spawn_pos
	linear_velocity = Vector2.ZERO
	
	if upside_down:
		if camera:
			camera.position.y *= -1
	upside_down = false
	reverse_camera = false
	
	if paraglider:
		paraglider.hide()
	if star:
		star.hide()
	
	if stamina_comp:
		stamina_comp.reset()
	if brake_comp:
		brake_comp.reset()
	if spirit_comp:
		spirit_comp.reset(self)
		
	get_tree().call_group("Jellyfish", "reset_jellyfish")
