extends Node

var player : Player
var end_pos : Vector2 
var ascension : bool 



func set_player(player_set : Player):
	player = player_set

func set_end_pos(end_pos_set : Vector2):
	end_pos = end_pos_set

func set_ascension(ascension_set : bool):
	print("ascension set to : ", ascension_set)
	ascension = ascension_set
	SignalManager.emit_signal("ascension_signal", ascension)
	
func _physics_process(delta: float) -> void:
	pass
