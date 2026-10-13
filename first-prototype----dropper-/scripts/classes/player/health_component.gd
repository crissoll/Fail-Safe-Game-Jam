extends Node
class_name HealtComponent

signal die
signal health_changed(to : int)

@export var max_hearts_number : int

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass


func apply_damage():
	die.emit()
