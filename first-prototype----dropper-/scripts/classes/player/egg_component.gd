extends Node
class_name EggComponent


@export var egg_scene: PackedScene 
@export var distance_delay: int = 15 
@export var initial_offset : Vector2

var player : Player 
var max_lives : int
var active_eggs: Array[Egg] = []
var position_history: Array[Vector2] = []

func _ready() -> void:
	player = get_parent().get_parent()
	max_lives = player.health_comp.hearts
	player.health_comp.health_changed.connect(take_damage)
	
	for i in range(max_lives):
		var new_egg = egg_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(new_egg)
		new_egg.global_position = player.global_position + initial_offset
		active_eggs.append(new_egg)


func _physics_process(delta: float) -> void:
	position_history.push_front(player.global_position + initial_offset)
	
	var max_history_needed = max_lives * distance_delay + 1
	if position_history.size() > max_history_needed:
		position_history.pop_back()
		
	for i in range(active_eggs.size()):
		var history_index = (i + 1) * distance_delay
		if history_index < position_history.size():
			active_eggs[i].global_position = position_history[history_index]
	
func take_damage(amount = 1):
	print("danno")
	if active_eggs.size() > 0:
		var lost_egg = active_eggs.pop_back()
		lost_egg.detach_and_break()
		
func reset():
	for i in range(player.health_comp.hearts):
		var new_egg = egg_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(new_egg)
		new_egg.global_position = player.global_position
		active_eggs.append(new_egg)
		
