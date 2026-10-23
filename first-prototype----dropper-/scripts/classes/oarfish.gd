extends Obstacle
class_name Oarfish

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


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
		animated_sprite_2d.play("white")
	else:
		animated_sprite_2d.play("black")
