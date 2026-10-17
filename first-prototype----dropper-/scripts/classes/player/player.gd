class_name Player
extends CharacterBody2D

signal flipped
#vars
@onready var camera: Camera2D = $Camera2D
@onready var temp_stamina_label: Label = $TempStaminaLabel

## lateral movement speed
@export var move_speed := 10.0
## max speed you can reach due to gravity
@export var max_y_speed := 400.0
## min speed you can reach by braking
@export var min_y_speed := 200.0
@export var g := 200.0
@export var camera_change_speed := 1000.0

@export var health_label : Label

@export_group("Components")
@export var stamina_comp: StaminaComponent
@export var brake_comp: BrakeComponent
@export var spirit_comp: SpiritComponent
@export var health_comp: HealtComponent
@export var egg_comp : EggComponent

var spawn_pos: Vector2

var upside_down := false
var reverse_camera := false
var reversed_camera_pos: Vector2

func _ready() -> void:
	reversed_camera_pos = camera.position
	reversed_camera_pos.y *= -1
	
	stamina_comp.stamina_changed.connect(_on_stamina_changed)
	
	health_comp.health_changed.connect(func(health: int): health_label.text = str(health))
	#health_comp.health_changed.emit(health_comp.hearts)
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
	velocity.x = (mov_vec * move_speed)
	_handle_brake_and_g(delta)
	move_and_slide()
	
func _handle_brake_and_g(delta:float) -> void:
	var trying_to_brake = Input.is_action_pressed(&"slow_down")
	
	if trying_to_brake && brake_comp.can_brake():
		if Input.is_action_just_pressed(&"slow_down"):
			brake_comp.start_braking()
		
		stamina_comp.consume(brake_comp.brake_stamina_consumption, delta)
		_apply_brake_force(delta)
		return
	
	_apply_gravity(delta)
	if trying_to_brake:
		brake_comp.brake_jammed = true
		
	if Input.is_action_just_released(&"slow_down"):
		brake_comp.brake_jammed = false
		brake_comp.stop_braking()
	elif stamina_comp.is_depleted:
		brake_comp.stop_braking()
		

func _apply_brake_force(delta: float) -> void:
	if abs(velocity.y) > min_y_speed and abs(velocity.y) < max_y_speed:
		velocity.y -= (1 - 2 * int(upside_down)) * brake_comp.brake_strength * delta

func _apply_gravity(delta: float) -> void:
	if abs(velocity.y) < max_y_speed:
		velocity.y += (1 - 2 * int(upside_down)) * g * delta

func apply_vertical_impulse(impulse_value):
	velocity.y = -1 * impulse_value * (1 - 2 * int(upside_down))

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
	velocity = Vector2.ZERO
	reverse_camera = true
	flipped.emit()

func reset() -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	
	if upside_down:
		if camera:
			camera.position.y *= -1
	upside_down = false
	reverse_camera = false
	
	brake_comp.reset()
	
	if stamina_comp:
		stamina_comp.reset()
	if spirit_comp:
		spirit_comp.reset(self)
	if health_comp:
		health_comp.reset()
	if egg_comp:
		egg_comp.reset()
		
	get_tree().call_group(&"Jellyfish", "reset")
	get_tree().call_group(&"MoveComponents", "reset")
