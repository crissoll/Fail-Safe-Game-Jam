extends Obstacle
class_name Oarfish

@onready var oarfish_black: Sprite2D = $oarfishBlack
@onready var oarfish_white: Sprite2D = $oarfishWhite

func _ready() -> void:
	add_to_group("Jellyfish")
	SignalManager.ascension_signal.connect(set_animation)

var hittable := true

func _on_body_entered(player: Player) -> void:
	if(hittable):
		SignalManager.squid_hit.emit()
	visible = false
	hittable = false

func reset():
	visible = true
	hittable = true
	
func set_animation(ascension : bool):
	if !ascension:
		oarfish_white.show()
		oarfish_black.hide()
	else:
		oarfish_white.hide()
		oarfish_black.show()
