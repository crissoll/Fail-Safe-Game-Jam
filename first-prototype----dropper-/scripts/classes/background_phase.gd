class_name BackgroundPhase
extends Node2D
## Cambia la grafica dello sfondo quando il player arriva in fondo (inizio della
## risalita): muri, nuvole e gradiente. Quando si ricomincia (morte / reset)
## torna la grafica della discesa.

@export_group("Grafica della risalita")
@export var ascension_clouds_back: Texture2D
@export var ascension_clouds_front: Texture2D
@export var ascension_walls_back: Texture2D
@export var ascension_walls_front: Texture2D
## Colore del gradiente in alto.
@export var ascension_gradient_top := Color("#A6C4CF")
## Colore del gradiente in basso.
@export var ascension_gradient_bottom := Color("#698DB2")
## Se vero, il gradiente della risalita va dal colore in alto al colore in basso
## lungo l'altezza del livello (altrimenti lungo tutta la TextureRect).
@export var fit_gradient_to_level := true

@export_group("Nodi dello sfondo")
@export var clouds_back: Sprite2D
@export var clouds_front: Sprite2D
@export var walls_back: Sprite2D
@export var walls_front: Sprite2D
@export var gradient_rect: TextureRect

var _descent_textures: Dictionary = {}  # Sprite2D -> Texture2D
var _descent_gradient: Texture2D
var _ascension_gradient: GradientTexture2D


func _ready() -> void:
	for sprite in _sprites():
		if sprite:
			_descent_textures[sprite] = sprite.texture
	if gradient_rect:
		_descent_gradient = gradient_rect.texture
	SignalManager.ascension_signal.connect(_apply_phase)
	_apply_phase(GameManager.ascension)


func _sprites() -> Array:
	return [clouds_back, clouds_front, walls_back, walls_front]


func _apply_phase(ascension: bool) -> void:
	var new_textures := [ascension_clouds_back, ascension_clouds_front, ascension_walls_back, ascension_walls_front]
	var sprites := _sprites()
	for i in sprites.size():
		var sprite: Sprite2D = sprites[i]
		if sprite == null:
			continue
		if ascension and new_textures[i]:
			sprite.texture = new_textures[i]
		elif _descent_textures.has(sprite):
			sprite.texture = _descent_textures[sprite]
	if gradient_rect:
		gradient_rect.texture = _get_ascension_gradient() if ascension else _descent_gradient


func _get_ascension_gradient() -> Texture2D:
	if _ascension_gradient:
		return _ascension_gradient
	var gradient := Gradient.new()
	gradient.set_color(0, ascension_gradient_top)
	gradient.set_color(1, ascension_gradient_bottom)
	if fit_gradient_to_level:
		var end := _level_end_offset()
		if end > 0.0 and end < 1.0:
			gradient.set_offset(1, end)
	if _descent_gradient is GradientTexture2D:
		_ascension_gradient = (_descent_gradient as GradientTexture2D).duplicate()
	else:
		_ascension_gradient = GradientTexture2D.new()
	_ascension_gradient.gradient = gradient
	return _ascension_gradient


## Punto (0..1) della TextureRect in cui si trova il fondo del livello.
## La TextureRect è ruotata di 90°: la sua larghezza corre verso il basso.
func _level_end_offset() -> float:
	var level := get_parent() as LevelBoundaries
	if level == null or gradient_rect.size.x <= 0.0:
		return -1.0
	var top_y := gradient_rect.position.y
	return (level.height - top_y) / gradient_rect.size.x
