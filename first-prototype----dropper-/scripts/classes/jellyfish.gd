
extends Obstacle
class_name JellyFish

@export var bounce_velocity: int = 90
@export var amplitude_oscillation : float = 20
@export var velocity_oscillation : float = 2

@onready var collision_shape_head: CollisionShape2D = $CollisionShapeHead
@onready var collision_shape_tentacles: CollisionShape2D = $CollisionShapeTentacles

var elapsed_time: float = 0.0
var y_initial: float = 0.0


func fade() -> void:
	modulate.a = 0.1


func materialize() -> void:
	modulate.a = 1


func _ready() -> void:
	super()
	add_to_group("Jellyfish")
	
	y_initial = position.y


func reset() -> void:
	visible = true
	set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	elapsed_time += delta
	position.y = y_initial + (sin(elapsed_time * velocity_oscillation) * amplitude_oscillation)

#func _on_body_entered(body: Node2D) -> void:
	#if body is Player:
		## Blocca il freno fino a quando il giocatore
		## non comincia a cadere.
		#body.lock_brake_until_falling()
#
		## Applica il rimbalzo.
		#body.apply_vertical_impulse(bounce_velocity)
#
		## Nasconde la medusa e disattiva temporaneamente
		## il rilevamento dei contatti.
		#visible = false
		#set_deferred("monitoring", false)


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body is Player:
		var shape_owner_id = shape_find_owner(local_shape_index)
		var shape_colpita = shape_owner_get_owner(shape_owner_id)
		
		if shape_colpita == collision_shape_head and !GameManager.ascension:
			print("colpita la testa")
			body.lock_brake_until_falling()

			# Applica il rimbalzo.
			body.apply_vertical_impulse(bounce_velocity)

			# Nasconde la medusa e disattiva temporaneamente
			# il rilevamento dei contatti.
			visible = false
			set_deferred("monitoring", false)
			
		elif shape_colpita == collision_shape_tentacles and GameManager.ascension:
			print("colpiti i tentacoli")
			GameManager.player.health_comp.apply_damage(damage)
			
			
