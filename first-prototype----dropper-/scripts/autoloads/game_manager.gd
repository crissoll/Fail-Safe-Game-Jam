extends Node

var player : Player
var end_pos : Vector2 
var ascension : bool 

func set_player(player_set : Player):
	player = player_set

func set_end_pos(end_pos_set : Vector2):
	end_pos = end_pos_set

func set_ascension(ascension_set : bool):
	ascension = ascension_set
	
func _physics_process(delta: float) -> void:
	print(ascension)
