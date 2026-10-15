extends TextureProgressBar


func _ready() -> void:
	SignalManager.on_player_health_changed.connect(change_value)
	value = max_value


func _process(delta: float) -> void:
	pass


func change_value(max_hearts : int, hearts : int):
	value = max_value / max_hearts * hearts
