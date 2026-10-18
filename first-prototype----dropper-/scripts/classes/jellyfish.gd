
extends Obstacle
class_name JellyFish

@export var bounce_velocity: int = 90


func fade() -> void:
	modulate.a = 0.1


func materialize() -> void:
	modulate.a = 1


func _ready() -> void:
	super()
	add_to_group("Jellyfish")


func reset() -> void:
	visible = true
	set_deferred("monitoring", true)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Blocca il freno fino a quando il giocatore
		# non comincia a cadere.
		body.lock_brake_until_falling()

		# Applica il rimbalzo.
		body.apply_vertical_impulse(bounce_velocity)

		# Nasconde la medusa e disattiva temporaneamente
		# il rilevamento dei contatti.
		visible = false
		set_deferred("monitoring", false)
