class_name LevelCutsceneTrigger
extends Node
## Quando il player arriva in fondo al livello (inizio della risalita) mette in
## pausa il gioco e mostra una cutscene sopra di esso. A fine cutscene la toglie
## e il gioco riprende esattamente da dove si era fermato.
##
## La cutscene viene disegnata in un SubViewport a parte, quindi la sua Camera2D
## e i suoi sprite non interferiscono con il livello.

signal cutscene_started
signal cutscene_finished

## Scena della cutscene (la radice dovrebbe usare CutscenePlayer con next_scene vuoto).
@export var cutscene: PackedScene
## Mostrala solo la prima volta (non dopo una morte e un nuovo tentativo).
@export var play_once := true
## Layer su cui disegnarla: deve stare sopra ai muri dello sfondo (100) e alla GUI (500).
@export var canvas_layer := 600

var _played := false
var _overlay: CanvasLayer
var _instance: Node


func _ready() -> void:
	# Deve funzionare anche a gioco in pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalManager.ascension_signal.connect(_on_ascension_changed)


func _process(_delta: float) -> void:
	# Se durante la cutscene qualcuno toglie la pausa (es. il menu Esc), la rimette.
	if _overlay and not get_tree().paused:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	# Durante la cutscene Esc non apre il menu di pausa (finirebbe sotto la cutscene):
	# se la cutscene si può saltare, la salta.
	if _overlay == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _instance is CutscenePlayer and _instance.can_skip:
			_instance._go_to_next_scene()


func _on_ascension_changed(ascension: bool) -> void:
	if not ascension or cutscene == null or _overlay != null:
		return
	if play_once and _played:
		return
	# Il segnale arriva durante la fisica: meglio aspettare la fine del frame.
	play_cutscene.call_deferred()


func play_cutscene() -> void:
	if _overlay != null or cutscene == null:
		return
	_played = true

	_overlay = CanvasLayer.new()
	_overlay.name = "CutsceneOverlay"
	_overlay.layer = canvas_layer
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	var container := SubViewportContainer.new()
	container.stretch = true
	_overlay.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var viewport := SubViewport.new()
	viewport.handle_input_locally = true
	container.add_child(viewport)

	var instance := cutscene.instantiate()
	_instance = instance
	if instance is CutscenePlayer:
		instance.finished.connect(_on_cutscene_finished, CONNECT_ONE_SHOT)
	else:
		# Scena senza CutscenePlayer: aspetta la fine della prima animazione trovata.
		var players := instance.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			push_warning("LevelCutsceneTrigger: la cutscene non ha un AnimationPlayer.")
			_on_cutscene_finished.call_deferred()
		else:
			(players.front() as AnimationPlayer).animation_finished.connect(
					func(_n): _on_cutscene_finished(), CONNECT_ONE_SHOT)
	viewport.add_child(instance)

	get_tree().paused = true
	cutscene_started.emit()


func _on_cutscene_finished() -> void:
	if _overlay == null:
		return
	_overlay.queue_free()
	_overlay = null
	_instance = null
	get_tree().paused = false
	cutscene_finished.emit()
