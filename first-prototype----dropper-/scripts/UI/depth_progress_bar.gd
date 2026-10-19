extends ProgressBar

@onready var player : Player = GameManager.player
@onready var end_pos : Vector2 = GameManager.end_pos
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	value = max_value * player.global_position.y /end_pos.y
