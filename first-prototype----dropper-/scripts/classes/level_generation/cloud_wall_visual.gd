@tool
class_name CloudWallVisual
extends Node2D
## Grafica a nuvola di un tratto di muro, creata dal FlappyLevelGenerator.
##
## Ha due "set" di grafica, uno per la discesa (nuvole chiare) e uno per il
## ritorno (nuvole scure). In ognuno:
## - "solid" (combinata): visibile quando il muro è attivo per lo spirito del player;
## - "faded" (blob): visibile quando il muro non è attivo. In discesa può essere
##   nascosto del tutto (hide_inactive_on_descent).
## Riceve fade()/materialize() dallo SpiritDisplayComponent come gli Obstacle.

enum Kind { SPIRIT, PHYSICAL }
## ALWAYS = sempre; DESCENT_ONLY = solo in discesa; RETURN_ONLY = solo in risalita.
enum Phase { ALWAYS, DESCENT_ONLY, RETURN_ONLY }

const EDITOR_RETURN_ALPHA := 0.35

var kind: Kind = Kind.SPIRIT
var phase: Phase = Phase.ALWAYS
var hide_inactive_on_descent := true
var descent_solid := Node2D.new()
var descent_faded := Node2D.new()
var return_solid := Node2D.new()
var return_faded := Node2D.new()
var materialized := true
var _ascension := false


func setup(p_kind: Kind, p_phase: Phase, faded_alpha: float, p_hide_inactive_on_descent: bool) -> void:
	kind = p_kind
	phase = p_phase
	hide_inactive_on_descent = p_hide_inactive_on_descent
	descent_solid.name = "DescentSolid"
	descent_faded.name = "DescentFaded"
	return_solid.name = "ReturnSolid"
	return_faded.name = "ReturnFaded"
	descent_faded.modulate.a = faded_alpha
	return_faded.modulate.a = faded_alpha
	for node in [descent_faded, descent_solid, return_faded, return_solid]:
		add_child(node)
	# Il player parte in forma spirito: attivi i muri spirito, non attivi quelli fisici.
	materialized = kind == Kind.SPIRIT
	_update()


func _ready() -> void:
	if Engine.is_editor_hint():
		# In editor i muri "solo ritorno" si vedono scuri e trasparenti.
		_ascension = phase == Phase.RETURN_ONLY
		if phase == Phase.RETURN_ONLY:
			modulate.a = EDITOR_RETURN_ALPHA
		_update()
		return
	add_to_group(&"spirit_obstacles" if kind == Kind.SPIRIT else &"obstacles")
	SignalManager.ascension_signal.connect(_on_ascension_changed)
	_ascension = GameManager.ascension
	_update()


func fade() -> void:
	materialized = false
	_update()


func materialize() -> void:
	materialized = true
	_update()


func _on_ascension_changed(ascension: bool) -> void:
	_ascension = ascension
	_update()


func _update() -> void:
	var editor := Engine.is_editor_hint()
	# In editor i muri non attivi si vedono sempre, così il livello resta leggibile.
	var hide_descent_faded := hide_inactive_on_descent and not editor
	descent_solid.visible = not _ascension and materialized
	descent_faded.visible = not _ascension and not materialized and not hide_descent_faded
	return_solid.visible = _ascension and materialized
	return_faded.visible = _ascension and not materialized
	if editor:
		visible = true
		return
	match phase:
		Phase.ALWAYS:
			visible = true
		Phase.DESCENT_ONLY:
			visible = not _ascension
		Phase.RETURN_ONLY:
			visible = _ascension
