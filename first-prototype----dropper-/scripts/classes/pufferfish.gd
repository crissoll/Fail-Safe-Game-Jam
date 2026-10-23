extends Obstacle
class_name Pufferfish


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var current_anim : Animation

func _ready() -> void:
	add_to_group("Jellyfish")
	SignalManager.ascension_signal.connect(set_animation)


var hittable := true

func _on_body_entered(player: Player) -> void:
	var ascension = GameManager.ascension
	print(ascension)
	if !ascension:
		print("sto scendendo")
		animated_sprite_2d.stop()
		animated_sprite_2d.play("default_white_anim")
	else:
		print("sto salendo")
		animated_sprite_2d.stop()
		animated_sprite_2d.play("black_anim")
		
	
	await animated_sprite_2d.animation_finished
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
		
