class_name StaminaDisplayComponent
extends Node

@export
var texture: GradientTexture2D
@export
var stamina_comp : StaminaComponent

func update_stamina()->void:
	var frac := stamina_comp.current_stamina/stamina_comp.max_stamina
	if frac > 0.95:
		texture.gradient.colors[0].a = 0
	texture.gradient.colors[0].a = 0.1 + 0.9 *frac
	texture.gradient.offsets[0] = -2 + 2*frac
	texture.fill_to.x = frac * 0.6 + 0.501 
	

func _process(delta: float) -> void:
	update_stamina()
