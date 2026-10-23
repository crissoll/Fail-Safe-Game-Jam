class_name InGameTutorial
extends Node
## Tutorial giocabile, dentro al livello vero.
##
## INIZIO (discesa), molto semplice:
##   1. MOVE  - Ray resta sospeso; premi sinistra e destra.
##   2. GLIDE - ancora sospeso; tieni premuto il tasto dell'aliante.
##   3. GAP   - Ray cade verso il primo muro: passa dal buco. Se lo tocchi -> "Try again",
##              torni all'inizio del passo (cuori pieni) e lo rifai finché non passi.
## RITORNO (dopo la seconda cutscene):
##   1. SWITCH 1 - Ray è sospeso; il primo muro sopra è chiuso per la forma spirito:
##                 premi Spazio per passare alla forma fisica.
##   2. PASS 1   - attraversa il muro. Se lo tocchi, torni al checkpoint (in forma spirito).
##   3. SWITCH 2 - il muro dopo è pieno per la forma fisica: torna spirito.
##   4. PASS 2   - attraversalo. Stessa regola: se sbagli si rifà.
## Per essere sicuro che la lezione funzioni con qualsiasi livello generato, all'inizio
## del ritorno il tutorial sistema quei due muri (il primo chiuso solo al ritorno,
## il secondo fisico pieno): la discesa resta percorribile.
## Ogni tutorial si fa una volta per sessione (non si ripete dopo un Restart).

enum Step { NONE, MOVE, GLIDE, GAP, SWITCH_1, PASS_1, SWITCH_2, PASS_2 }

## Un passo è riuscito (lampo verde).
signal step_passed(step: Step)
## Errore in un passo (lampo rosso), si rifà.
signal step_failed(step: Step)
## Tutorial finito (intro = true per quello iniziale).
signal tutorial_finished(intro: bool)

@export var player: Player
## Se vuoti vengono cercati da soli dentro la scena.
@export var generator: FlappyLevelGenerator
@export var bottom_cutscene: LevelCutsceneTrigger
@export var intro_enabled := true
@export var return_enabled := true
## Secondi da tenere premuto l'aliante nel passo GLIDE.
@export var glide_hold_time := 1.0
## Al ritorno Ray si ferma a questa distanza (px) sotto il primo muro della lezione.
@export var approach_distance := 170.0

@export_group("Testi")
@export var text_move := "Move"
@export var text_glide := "Hold to glide"
@export var text_gap := "Fly through the gap"
@export var text_switch := "Switch form"
@export var text_pass := "Fly through"
@export var text_switch_again := "Switch again"

@export_group("Riscontro visivo")
## Lampo sul livello quando un passo riesce.
@export var success_color := Color(0.15, 0.9, 0.35)
## Lampo sul livello quando si sbaglia.
@export var fail_color := Color(0.95, 0.12, 0.18)
## Font delle scritte (vuoto = font di default del gioco).
@export var font: Font

static var intro_done := false
static var return_done := false


var step: Step = Step.NONE
var ui: TutorialPromptUI

var _hover := false
var _hover_y := 0.0
var _busy := false
var _last_hearts := 0.0
var _checkpoint := Vector2.ZERO
var _checkpoint_spirit := true
var _held_left := 0.0
var _held_right := 0.0
var _glide_time := 0.0
var _gap_wall_bottom := INF
var _wall1_top := -INF
var _wall1_bottom := -INF
var _wall2_top := -INF


func _ready() -> void:
	# Gira dopo il player, così può tenerlo sospeso senza scatti.
	process_physics_priority = 100
	var scene := owner if owner else get_tree().current_scene
	if player == null:
		player = scene.find_children("*", "Player", true, false).front() as Player
	if generator == null:
		var found := scene.find_children("*", "FlappyLevelGenerator", true, false)
		if not found.is_empty():
			generator = found.front()
	if bottom_cutscene == null:
		var found := scene.find_children("*", "LevelCutsceneTrigger", true, false)
		if not found.is_empty():
			bottom_cutscene = found.front()
	ui = TutorialPromptUI.new()
	ui.name = "TutorialUI"
	ui.font = font
	add_child(ui)
	SignalManager.ascension_signal.connect(_on_ascension_changed)
	if intro_enabled and not intro_done:
		_start_intro()


# --------------------------------------------------------------------------
# Ciclo principale
# --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if step == Step.NONE or player == null:
		return
	if _hover:
		player.global_position.y = _hover_y
		player.velocity.y = 0.0
	if _busy:
		return

	# Errore = tocca un muro solido per la sua forma, oppure perde un cuore.
	var hearts: float = player.health_comp.hearts
	var hurt := hearts < _last_hearts
	_last_hearts = hearts
	if step in [Step.GAP, Step.PASS_1, Step.PASS_2] and (hurt or _touching_active_wall()):
		_fail()
		return

	match step:
		Step.MOVE:
			if Input.is_action_pressed(&"left"):
				_held_left += delta
			if Input.is_action_pressed(&"right"):
				_held_right += delta
			if _held_left > 0.15:
				ui.mark_done(&"left")
			if _held_right > 0.15:
				ui.mark_done(&"right")
			if _held_left > 0.15 and _held_right > 0.15:
				_advance(Step.GLIDE)
		Step.GLIDE:
			if Input.is_action_pressed(&"slow_down"):
				_glide_time += delta
				ui.set_progress(_glide_time / glide_hold_time)
			if _glide_time >= glide_hold_time:
				ui.mark_done(&"slow_down")
				_advance(Step.GAP)
		Step.GAP:
			if player.global_position.y > _gap_wall_bottom + 20.0:
				_finish(true)
		Step.SWITCH_1:
			if not player.spirit_comp.is_spirit:
				ui.mark_done(&"switch_dimension")
				_advance(Step.PASS_1)
		Step.PASS_1:
			if player.global_position.y < _wall1_top - 20.0:
				_checkpoint = player.global_position
				_checkpoint_spirit = false
				_advance(Step.SWITCH_2)
		Step.SWITCH_2:
			if player.spirit_comp.is_spirit:
				ui.mark_done(&"switch_dimension")
				_advance(Step.PASS_2)
		Step.PASS_2:
			if player.global_position.y < _wall2_top - 20.0:
				_finish(false)


func _set_step(new_step: Step) -> void:
	step = new_step
	_last_hearts = player.health_comp.hearts
	match new_step:
		Step.MOVE:
			_held_left = 0.0
			_held_right = 0.0
			_set_hover(true, _checkpoint.y)
			ui.show_prompt([[["A", &"left"], ["D", &"right"]], [["←", &"left"], ["→", &"right"]]], text_move)
		Step.GLIDE:
			_glide_time = 0.0
			_set_hover(true, _checkpoint.y)
			ui.show_prompt([[["W", &"slow_down"]], [["↑", &"slow_down"]]], text_glide, false, true)
		Step.GAP:
			_set_hover(false)
			ui.show_prompt([[["A", &"left"], ["W", &"slow_down"], ["D", &"right"]]], text_gap)
		Step.SWITCH_1:
			_set_hover(true, _checkpoint.y)
			ui.show_prompt([[["Space", &"switch_dimension"]]], text_switch, true)
		Step.PASS_1, Step.PASS_2:
			_set_hover(false)
			ui.show_prompt([], text_pass, true)
		Step.SWITCH_2:
			_set_hover(true, _checkpoint.y)
			ui.show_prompt([[["Space", &"switch_dimension"]]], text_switch_again, true)


func _advance(next: Step) -> void:
	_busy = true
	ui.flash_screen(success_color)
	step_passed.emit(step)
	await get_tree().create_timer(0.45, false).timeout
	_busy = false
	if step != Step.NONE:
		_set_step(next)


## Errore: si torna al checkpoint (cuori pieni) e si rifà il passo.
func _fail() -> void:
	_busy = true
	ui.flash_screen(fail_color)
	step_failed.emit(step)
	var retry_step := step
	match step:
		Step.PASS_1:
			retry_step = Step.SWITCH_1
		Step.PASS_2:
			retry_step = Step.SWITCH_2
	await get_tree().create_timer(0.35, false).timeout
	if step == Step.NONE:
		return
	player.global_position = _checkpoint
	player.velocity = Vector2.ZERO
	player.health_comp.reset()
	if player.spirit_comp.is_spirit != _checkpoint_spirit:
		player.spirit_comp.switch_dimension(player)
	_set_hover(true, _checkpoint.y)
	await get_tree().create_timer(0.6, false).timeout
	_busy = false
	if step != Step.NONE:
		_set_step(retry_step)


func _finish(intro: bool) -> void:
	step_passed.emit(step)
	step = Step.NONE
	_set_hover(false)
	ui.hide_prompt()
	ui.flash_screen(success_color, 0.4, 0.8)
	if intro:
		intro_done = true
	else:
		return_done = true
	tutorial_finished.emit(intro)


func _set_hover(on: bool, y := 0.0) -> void:
	_hover = on
	_hover_y = y


# --------------------------------------------------------------------------
# Inizio
# --------------------------------------------------------------------------

func _start_intro() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_checkpoint = player.global_position
	_checkpoint_spirit = player.spirit_comp.is_spirit
	_gap_wall_bottom = _find_first_wall_below(_checkpoint.y)
	# Niente creature nella zona della lezione: l'unico ostacolo è il muro.
	_clear_creatures(_row_of(_checkpoint.y) - 2, _row_of(_gap_wall_bottom) + 4)
	_set_step(Step.MOVE)


## Fondo (in coordinate globali) del primo muro spirito sotto a y.
func _find_first_wall_below(y: float) -> float:
	if generator == null:
		return y + 400.0
	var start_row := generator.local_to_map(generator.to_local(Vector2(0, y))).y
	var rows: Array = []
	for cell in generator.get_used_cells():
		if cell.y > start_row and generator.get_cell_source_id(cell) == generator.spirit_wall_source \
				and generator.get_cell_alternative_tile(cell) == generator.wall_scene_id:
			rows.append(cell.y)
	if rows.is_empty():
		return y + 400.0
	rows.sort()
	var last: int = rows[0]
	for r in rows:
		if r > last + 1:
			break
		last = r
	return _row_edge(last, false)


# --------------------------------------------------------------------------
# Ritorno
# --------------------------------------------------------------------------

func _on_ascension_changed(ascension: bool) -> void:
	if ascension:
		if return_enabled and not return_done and step == Step.NONE:
			_start_return()
	elif step in [Step.SWITCH_1, Step.PASS_1, Step.SWITCH_2, Step.PASS_2]:
		# Reset durante il tutorial del ritorno: si riprova la prossima volta in fondo.
		step = Step.NONE
		_set_hover(false)
		ui.hide_prompt()


func _start_return() -> void:
	# Aspetta la fine della cutscene e del giro di camera.
	await get_tree().process_frame
	while get_tree().paused or (bottom_cutscene and bottom_cutscene._overlay != null):
		await get_tree().process_frame
	while player.reverse_camera:
		await get_tree().physics_frame
	if not GameManager.ascension or step != Step.NONE:
		return
	if player.spirit_comp.is_spirit == false:
		player.spirit_comp.switch_dimension(player)
	if not _prepare_return_walls():
		return_done = true
		return
	# Lascia salire Ray finché il primo muro non è ben visibile, poi la ferma lì.
	_checkpoint = Vector2(player.global_position.x, minf(player.global_position.y, _wall1_bottom + approach_distance))
	var t := 0.0
	while player.global_position.y > _checkpoint.y and t < 6.0 and GameManager.ascension:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	if not GameManager.ascension or step != Step.NONE:
		return
	_checkpoint = player.global_position
	_checkpoint_spirit = true
	_set_step(Step.SWITCH_1)


## Sistema i primi due muri sopra al player per la lezione. Falso se non ci sono.
func _prepare_return_walls() -> bool:
	if generator == null:
		return false
	var grid := generator.grid_bounds()
	var player_row := generator.local_to_map(generator.to_local(player.global_position)).y
	var rows := {}
	for cell in generator.get_used_cells():
		if cell.y < player_row and _is_wall_cell(cell):
			rows[cell.y] = true
	var sorted := rows.keys()
	sorted.sort()
	sorted.reverse()
	# Raggruppa righe consecutive in muri (dal più vicino al più lontano).
	var blocks: Array = []
	for r in sorted:
		if not blocks.is_empty() and blocks.back().back() == r + 1:
			blocks.back().append(r)
		else:
			blocks.append([r])
	if blocks.size() < 2:
		return false
	# Muro 1: chiuso per la forma spirito solo al ritorno (in discesa resta com'era).
	for r in blocks[0]:
		for c in range(grid.col_min, grid.col_max + 1):
			var cell := Vector2i(c, r)
			var is_spirit_wall := generator.get_cell_source_id(cell) == generator.spirit_wall_source \
					and generator.get_cell_alternative_tile(cell) == generator.wall_scene_id
			if not is_spirit_wall:
				generator.set_cell(cell, generator.spirit_wall_source, Vector2i.ZERO, generator.return_wall_scene_id)
	# Muro 2: fisico pieno (in discesa non fa danno alla forma spirito).
	for r in blocks[1]:
		for c in range(grid.col_min, grid.col_max + 1):
			generator.set_cell(Vector2i(c, r), generator.physical_wall_source, Vector2i.ZERO, generator.wall_scene_id)
	# Niente creature nella zona della lezione: gli unici ostacoli sono i due muri.
	_clear_creatures(blocks[1].back() - 6, player_row + 2)
	generator.rebuild_visuals()
	_wall1_top = _row_edge(blocks[0].back(), true)
	_wall1_bottom = _row_edge(blocks[0].front(), false)
	_wall2_top = _row_edge(blocks[1].back(), true)
	return true


## Vero se Ray tocca un muro che in questo momento è solido per la sua forma.
## Non dipende dai cuori: funziona anche durante l'invincibilità dopo un colpo.
func _touching_active_wall() -> bool:
	if generator == null:
		return false
	var spirit: bool = player.spirit_comp.is_spirit
	for offset in [Vector2.ZERO, Vector2(-8, 0), Vector2(8, 0), Vector2(0, -8), Vector2(0, 8)]:
		var cell := generator.local_to_map(generator.to_local(player.global_position + offset))
		var source := generator.get_cell_source_id(cell)
		var alt := generator.get_cell_alternative_tile(cell)
		if spirit and source == generator.spirit_wall_source:
			if alt == generator.wall_scene_id or (alt == generator.return_wall_scene_id and GameManager.ascension):
				return true
		elif not spirit and source == generator.physical_wall_source and alt == generator.wall_scene_id:
			return true
	return false


## Toglie le creature (tutto ciò che non è un muro) tra due righe della griglia.
func _clear_creatures(row_from: int, row_to: int) -> void:
	if generator == null:
		return
	for cell in generator.get_used_cells():
		if cell.y < row_from or cell.y > row_to:
			continue
		var source := generator.get_cell_source_id(cell)
		if source != generator.spirit_wall_source and source != generator.physical_wall_source:
			generator.erase_cell(cell)


func _row_of(global_y: float) -> int:
	return generator.local_to_map(generator.to_local(Vector2(0, global_y))).y if generator else 0


func _is_wall_cell(cell: Vector2i) -> bool:
	var source := generator.get_cell_source_id(cell)
	var alt := generator.get_cell_alternative_tile(cell)
	if source == generator.spirit_wall_source:
		return alt == generator.wall_scene_id or alt == generator.return_wall_scene_id
	return source == generator.physical_wall_source and alt == generator.wall_scene_id


## Bordo superiore (top) o inferiore di una riga della griglia, in coordinate globali.
func _row_edge(row: int, top: bool) -> float:
	var half := generator.tile_set.tile_size.y * 0.5
	var center := generator.to_global(generator.map_to_local(Vector2i(0, row))).y
	return center - half if top else center + half
