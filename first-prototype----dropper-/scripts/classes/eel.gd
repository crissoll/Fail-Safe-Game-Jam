extends Obstacle
class_name Eel


@onready var black: Sprite2D = $black
@onready var white: Sprite2D = $white

func _ready() -> void:
	add_to_group("Jellyfish")
	SignalManager.ascension_signal.connect(set_animation)
	

var hittable := true

func _on_body_entered(player: Player) -> void:
	visible = false
	hittable = false

func reset():
	visible = true
	hittable = true

func set_animation(ascension : bool):
	if !ascension:
		white.show()
		black.hide()
	else:
		white.hide()
		black.show()
