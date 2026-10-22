extends HBoxContainer

const HEART_TEXTURE := preload("res://assets/UI/egg_dark.png")

@onready var max_hearts: int = GameManager.player.health_comp.max_hearts

var arr_hearts: Array[TextureRect] = []

func _ready() -> void:
	SignalManager.on_player_health_changed.connect(update_hearts)
	_set_hearts(GameManager.player.health_comp.hearts)


func update_hearts(_max_health: int, current_health: int) -> void:
	_set_hearts(current_health)


func _set_hearts(target: int) -> void:
	target = clampi(target, 0, max_hearts)

	while arr_hearts.size() < target:
		var tex := TextureRect.new()
		tex.texture = HEART_TEXTURE
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(40, 40)
		add_child(tex)
		arr_hearts.append(tex)
		
	while arr_hearts.size() > target:
		var heart: TextureRect = arr_hearts.pop_back()
		heart.queue_free()
	
