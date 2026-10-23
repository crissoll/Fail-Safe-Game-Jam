@tool
class_name FlappyLevelGenerator
extends TileMapLayer
## Genera un livello "Flappy Bird in verticale" piazzando i tile da solo.
##
## Va messo su un TileMapLayer figlio di EmptyLevel (LevelBoundaries), come
## il nodo "Obstacles" del basic level: legge larghezza e altezza da lì.
##
## [b]Come ragiona l'algoritmo[/b]
## 1. [b]Muri (tubi)[/b]: scendendo, ogni N righe piazza un muro con un buco.
##    Il muro può essere SPIRITO (source 0) o FISICO (source 1).
## 2. [b]Percorso garantito[/b]: il buco di ogni muro si sposta, rispetto al buco
##    precedente, al massimo di quanto il giocatore riesce a spostarsi di lato
##    nel tempo che impiega a cadere fin lì (gruppo "Equità"). Passando per tutti
##    i buchi in ordine il livello è sempre fattibile, in discesa e in risalita.
## 3. [b]Cambi di spirito forzati al ritorno[/b]:
##    - muro FISICO pieno: si passa solo in forma spirito;
##    - muro SPIRITO che si chiude al ritorno: in discesa ha il buco, in risalita
##      il buco viene riempito (tile "ritorno") e si passa solo in forma fisica.
##    Tra due muri che forzano forme opposte ci sono sempre almeno
##    [member min_switch_rows] righe, per avere il tempo di cambiare.
## 4. [b]Creature[/b]: tra i muri piazza le creature di [member obstacle_rules],
##    sempre fuori dal corridoio del percorso garantito.
## 5. [b]Grafica[/b]: i tile dei muri sono solo collisione; sopra il generatore
##    disegna le nuvole: chiare in discesa, scure al ritorno; combinata = muro
##    attivo, blob = muro non attivo (in discesa nascosto del tutto).
##    La grafica si ricostruisce dai tile, quindi segue anche le modifiche a mano.
##
## In editor: premi "Genera livello" nell'inspector, oppure cambia un parametro
## con "Anteprima live" attiva. I tile generati vengono salvati nella scena.

enum WallKind { SPIRIT, PHYSICAL }
enum CellType { NONE = -1, SPIRIT, PHYSICAL, SPIRIT_RETURN }

const LOG_PREFIX := "[FlappyLevelGenerator] "
const _POLL_INTERVAL := 0.3
const _SIGNATURE_PROPS: Array[StringName] = [
	&"level_seed", &"use_level_bounds", &"fallback_width", &"fallback_height",
	&"start_safe_rows", &"end_safe_rows", &"wall_spacing_start", &"wall_spacing_end",
	&"wall_spacing_jitter", &"wall_thickness", &"gap_width_start", &"gap_width_end",
	&"gap_width_jitter", &"min_gap_width", &"center_pull", &"physical_wall_chance",
	&"physical_full_wall_chance", &"spirit_closed_on_return_chance", &"min_switch_rows",
	&"max_same_kind_in_row", &"player_side_speed", &"player_vertical_speed", &"reach_factor",
	&"lane_padding", &"creature_chance_start", &"creature_chance_end",
	&"max_creatures_per_segment", &"creature_spacing", &"placement_attempts",
	&"spirit_wall_source", &"physical_wall_source", &"wall_scene_id", &"return_wall_scene_id",
	&"faded_alpha", &"hide_inactive_on_descent",
]

const DEFAULT_SKIN_PATHS := {
	"descent_solid": ["res://assets/combinata_ white/", false],
	"descent_faded": ["res://assets/blob_bianco/", true],
	"return_solid": ["res://assets/combinata_black/", false],
	"return_faded": ["res://assets/blob nero/", true],
}

@export_tool_button("Genera livello", "Play") var _generate_button := generate
@export_tool_button("Nuovo seed casuale", "RandomNumberGenerator") var _reseed_button := generate_with_random_seed
@export_tool_button("Svuota livello", "Clear") var _clear_button := clear_level
@export_tool_button("Carica regole predefinite", "Reload") var _rules_button := load_default_rules
@export_tool_button("Carica nuvole predefinite", "Texture2D") var _skins_button := load_default_skins

@export_group("Generazione")
## Stesso seed = stesso livello.
@export var level_seed: int = 2026
## Rigenera all'avvio del gioco. Se falso usa i tile salvati nella scena
## (quelli che vedi in editor, ritoccabili a mano).
@export var generate_on_run := false
## Livello diverso ad ogni partita (implica la generazione all'avvio).
@export var random_seed_each_run := false
## In editor rigenera da solo quando cambi un parametro.
@export var live_preview := true
## Mostra in editor il corridoio garantito (verde) dopo una generazione.
@export var show_debug_lanes := false:
	set(value):
		show_debug_lanes = value
		queue_redraw()
## Curva di difficoltà: x = profondità (0 inizio, 1 fondo), y = difficoltà 0..1.
## Vuota = cresce in modo lineare.
@export var difficulty_curve: Curve

@export_group("Area di gioco")
## Legge larghezza/altezza dal nodo EmptyLevel (LevelBoundaries) genitore.
@export var use_level_bounds := true
@export var fallback_width := 400.0
@export var fallback_height := 4000.0
## Righe lasciate vuote sotto lo spawn.
@export_range(0, 60) var start_safe_rows := 10
## Righe lasciate vuote prima del fondo (zona di inversione).
@export_range(0, 60) var end_safe_rows := 8

@export_group("Muri (tubi)")
## Distanza in righe tra due muri all'inizio del livello...
@export_range(3, 60) var wall_spacing_start := 14
## ...e in fondo (più piccola = più difficile).
@export_range(3, 60) var wall_spacing_end := 9
## Variazione casuale (+/-) della distanza.
@export_range(0, 10) var wall_spacing_jitter := 1
## Spessore del muro in righe. Con 3 righe (48 px) le nuvole sono in scala 1:1.
@export_range(1, 6) var wall_thickness := 3
## Larghezza del buco (in tile) all'inizio...
@export_range(2, 20) var gap_width_start := 7
## ...e in fondo.
@export_range(2, 20) var gap_width_end := 3
## Variazione casuale (+/-) della larghezza del buco.
@export_range(0, 5) var gap_width_jitter := 1
## Il buco non sarà mai più stretto di così.
@export_range(2, 10) var min_gap_width := 3
## Quanto i buchi vengono attirati verso il centro (0 = per niente, 1 = sempre al centro).
@export_range(0.0, 1.0, 0.05) var center_pull := 0.25
## Probabilità che un muro sia FISICO invece che SPIRITO.
@export_range(0.0, 1.0, 0.01) var physical_wall_chance := 0.4
## Massimo di muri dello stesso tipo di fila (0 = nessun limite).
@export_range(0, 10) var max_same_kind_in_row := 3

@export_group("Cambi di spirito al ritorno")
## Probabilità che un muro FISICO sia pieno: al ritorno si passa solo in forma spirito.
@export_range(0.0, 1.0, 0.01) var physical_full_wall_chance := 0.4
## Probabilità che un muro SPIRITO si chiuda al ritorno: si passa solo in forma fisica.
@export_range(0.0, 1.0, 0.01) var spirit_closed_on_return_chance := 0.5
## Righe libere minime tra due muri che obbligano a forme opposte (tempo per cambiare).
@export_range(1, 20) var min_switch_rows := 4

@export_group("Equità")
## Velocità laterale del giocatore (Player.move_speed).
@export var player_side_speed := 200.0
## Velocità verticale massima del giocatore (Player.max_y_speed).
@export var player_vertical_speed := 400.0
## Quota dello spostamento laterale massimo teorico che si usa (margine di reazione).
@export_range(0.1, 1.0, 0.05) var reach_factor := 0.6
## Tile extra protetti ai lati del corridoio.
@export_range(0, 4) var lane_padding := 1

@export_group("Creature")
## Le creature che il generatore può piazzare.
@export var obstacle_rules: Array[ObstacleSpawnRule] = []
## Probabilità di ogni "slot" creatura tra due muri, all'inizio...
@export_range(0.0, 1.0, 0.01) var creature_chance_start := 0.5
## ...e in fondo.
@export_range(0.0, 1.0, 0.01) var creature_chance_end := 0.9
## Slot creatura tra due muri consecutivi.
@export_range(0, 6) var max_creatures_per_segment := 2
## Tile di distanza minima tra due creature.
@export_range(0, 4) var creature_spacing := 1
## Tentativi di piazzamento per creatura prima di rinunciare.
@export_range(1, 100) var placement_attempts := 25

@export_group("Grafica nuvole")
## Discesa: muro attivo per lo spirito del player (nuvole chiare).
@export var descent_solid_skin: CloudWallSkin
## Discesa: muro non attivo (usato solo se hide_inactive_on_descent è falso).
@export var descent_faded_skin: CloudWallSkin
## Ritorno: muro attivo per lo spirito del player (nuvole scure).
@export var return_solid_skin: CloudWallSkin
## Ritorno: muro non attivo, trasparente.
@export var return_faded_skin: CloudWallSkin
## In discesa i muri non attivi sono nascosti del tutto (in editor si vedono comunque).
@export var hide_inactive_on_descent := true
## Trasparenza dei blob (muri non attivi).
@export_range(0.0, 1.0, 0.05) var faded_alpha := 0.6

@export_group("ID del TileSet")
@export var spirit_wall_source := 0
@export var physical_wall_source := 1
## Scena dei muri a nuvola (solo collisione, la grafica la disegna il generatore).
@export var wall_scene_id := 2
## Scena (nella sorgente spirito) del muro che esiste solo al ritorno.
@export var return_wall_scene_id := 3

var _protected: Dictionary = {}  # Vector2i -> true: corridoio garantito
var _walls: Dictionary = {}      # Vector2i -> true: tile di muro
var _creatures: Dictionary = {}  # Vector2i -> true: ingombro delle creature
var _last_signature := ""
var _poll_timer := 0.0
var _visual_root: Node2D
var _visuals_dirty := false
static var _default_skins: Dictionary = {}


func _ready() -> void:
	if Engine.is_editor_hint():
		_last_signature = _signature()
		changed.connect(_queue_visual_rebuild)
		set_process(true)
		_rebuild_visuals()
		return
	set_process(false)
	if random_seed_each_run:
		level_seed = randi() % 1000000
		generate()
	elif generate_on_run:
		generate()
	else:
		_rebuild_visuals()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not live_preview:
		return
	_poll_timer += delta
	if _poll_timer < _POLL_INTERVAL:
		return
	_poll_timer = 0.0
	# Rigenera solo quando la scena del livello è quella aperta in editor
	# (non quando il livello è istanziato dentro main.tscn).
	var edited := get_tree().edited_scene_root
	if edited == null or (edited != self and edited != owner):
		return
	var sig := _signature()
	if sig != _last_signature:
		generate()


# --------------------------------------------------------------------------
# API pubblica
# --------------------------------------------------------------------------

## Cancella e rigenera tutto il livello con il seed corrente.
func generate() -> void:
	if tile_set == null:
		push_warning(LOG_PREFIX + "nessun TileSet assegnato.")
		return
	clear_level()

	var rng := RandomNumberGenerator.new()
	rng.seed = level_seed

	var cell := Vector2(tile_set.tile_size)
	var grid := _grid_bounds()
	var col_min: int = grid.col_min
	var col_max: int = grid.col_max
	var spawn_row: int = grid.row_top
	var row_first := spawn_row + start_safe_rows
	var row_last: int = grid.row_bottom - end_safe_rows
	if col_max - col_min < min_gap_width + 2 or row_last - row_first < wall_thickness:
		push_warning(LOG_PREFIX + "area di gioco troppo piccola per generare il livello.")
		return

	var spawn := {"center": -position.x / cell.x, "row": spawn_row}
	var walls := _place_walls(rng, col_min, col_max, row_first, row_last, cell, spawn)
	_protect_lane(walls, spawn)
	var creatures := _place_creatures(rng, walls, col_min, col_max, row_first, row_last)
	_rebuild_visuals()

	_last_signature = _signature()
	queue_redraw()
	if Engine.is_editor_hint():
		var ei := Engine.get_singleton(&"EditorInterface")
		if ei:
			ei.call(&"mark_scene_as_unsaved")
	var full := walls.filter(func(w): return w.full).size()
	var closing := walls.filter(func(w): return w.closes).size()
	print(LOG_PREFIX + "seed %d -> %d muri (%d fisici pieni, %d spirito chiusi al ritorno), %d creature." \
			% [level_seed, walls.size(), full, closing, creatures])


func generate_with_random_seed() -> void:
	level_seed = randi() % 1000000
	notify_property_list_changed()
	generate()


func clear_level() -> void:
	clear()
	_protected.clear()
	_walls.clear()
	_creatures.clear()
	_rebuild_visuals()
	queue_redraw()


## Riempie [member obstacle_rules] con tutte le creature del TileSet del progetto.
func load_default_rules() -> void:
	obstacle_rules = default_rules()
	notify_property_list_changed()


## Assegna le nuvole delle cartelle combinata_* e blob_* del progetto:
## chiare in discesa, scure al ritorno.
func load_default_skins() -> void:
	descent_solid_skin = _get_default_skin("descent_solid")
	descent_faded_skin = _get_default_skin("descent_faded")
	return_solid_skin = _get_default_skin("return_solid")
	return_faded_skin = _get_default_skin("return_faded")
	notify_property_list_changed()
	_rebuild_visuals()


static func default_rules() -> Array[ObstacleSpawnRule]:
	# nome, source, scena, peso, da profondità, sx, dx, su, giù, può stare nel corridoio
	var rules: Array[ObstacleSpawnRule] = [
		ObstacleSpawnRule.make("Medusa", 2, 1, 1.0, 0.0, 1, 1, 2, 2),
		ObstacleSpawnRule.make("Medusa media", 2, 2, 0.7, 0.2, 2, 2, 2, 3),
		ObstacleSpawnRule.make("Medusa forte", 2, 3, 0.5, 0.4, 2, 2, 3, 3),
		ObstacleSpawnRule.make("Calamaro", 3, 1, 0.8, 0.0, 2, 2, 2, 2, true),
		ObstacleSpawnRule.make("Anguilla", 4, 1, 0.8, 0.15, 3, 3, 1, 1),
		ObstacleSpawnRule.make("Regaleco", 5, 1, 0.6, 0.3, 3, 4, 2, 2),
		ObstacleSpawnRule.make("Pesce palla", 6, 1, 0.7, 0.25, 1, 6, 1, 1),
	]
	return rules


# --------------------------------------------------------------------------
# Muri
# --------------------------------------------------------------------------

func _place_walls(rng: RandomNumberGenerator, col_min: int, col_max: int, row_first: int,
		row_last: int, cell: Vector2, spawn: Dictionary) -> Array[Dictionary]:
	var walls: Array[Dictionary] = []
	# Ultimo buco del percorso garantito: si parte dallo spawn.
	var last_gap := spawn
	# Ultima riga di un muro che obbliga alla forma spirito / fisica (per il tempo di cambio).
	var last_force_spirit_row := -1000000
	var last_force_physical_row := -1000000
	# Il buco sta sempre dentro i muri laterali, mai sul tile di bordo.
	var lo := col_min + 1
	var hi := col_max - 1

	var row := row_first
	var last_kind := -1
	var streak := 0
	var first := true
	while true:
		var t := _difficulty(row, row_first, row_last)
		if not first:
			var spacing := roundi(lerpf(wall_spacing_start, wall_spacing_end, t))
			spacing += rng.randi_range(-wall_spacing_jitter, wall_spacing_jitter)
			row += maxi(spacing, wall_thickness + 2)
		first = false
		if row + wall_thickness - 1 > row_last:
			break

		var kind := _pick_wall_kind(rng, last_kind, streak)
		streak = streak + 1 if kind == last_kind else 1
		last_kind = kind
		var bottom := row + wall_thickness - 1

		var wall := {"row": row, "kind": kind, "full": false, "closes": false, "gap_l": 0, "gap_r": -1}
		# Muri che obbligano a una forma al ritorno, solo se c'è tempo per cambiare.
		if kind == WallKind.PHYSICAL:
			wall.full = rng.randf() < physical_full_wall_chance \
					and row - last_force_physical_row - 1 >= min_switch_rows
			if wall.full:
				last_force_spirit_row = bottom
		else:
			wall.closes = rng.randf() < spirit_closed_on_return_chance \
					and row - last_force_spirit_row - 1 >= min_switch_rows
			if wall.closes:
				last_force_physical_row = bottom

		if not wall.full:
			var gap := roundi(lerpf(gap_width_start, gap_width_end, t))
			gap += rng.randi_range(-gap_width_jitter, gap_width_jitter)
			gap = clampi(gap, min_gap_width, hi - lo + 1)

			var max_shift := _max_shift_cells(row - int(last_gap.row), cell)
			var prev_center := float(last_gap.center)
			var center := prev_center + rng.randf_range(-max_shift, max_shift)
			# Tira leggermente verso il centro, così i buchi non restano incollati ai bordi.
			center = lerpf(center, (lo + hi + 1) * 0.5, center_pull)
			center = clampf(center, prev_center - max_shift, prev_center + max_shift)

			var gap_l := clampi(roundi(center - gap * 0.5), lo, hi - gap + 1)
			wall.gap_l = gap_l
			wall.gap_r = gap_l + gap - 1
			last_gap = {"center": (gap_l + gap_l + gap) * 0.5, "row": bottom}

		_paint_wall(wall, col_min, col_max)
		walls.append(wall)
	return walls


func _pick_wall_kind(rng: RandomNumberGenerator, last_kind: int, streak: int) -> WallKind:
	var kind := WallKind.PHYSICAL if rng.randf() < physical_wall_chance else WallKind.SPIRIT
	if max_same_kind_in_row > 0 and kind == last_kind and streak >= max_same_kind_in_row:
		kind = WallKind.SPIRIT if kind == WallKind.PHYSICAL else WallKind.PHYSICAL
	return kind


## Quanti tile può spostarsi di lato il giocatore mentre cade per [param rows] righe.
func _max_shift_cells(rows: int, cell: Vector2) -> float:
	var fall_time := maxf(rows, 1) * cell.y / maxf(player_vertical_speed, 1.0)
	# -0.5 compensa l'arrotondamento del buco alla griglia.
	return maxf(0.0, fall_time * player_side_speed * reach_factor / cell.x - 0.5)


func _paint_wall(wall: Dictionary, col_min: int, col_max: int) -> void:
	var source := spirit_wall_source if wall.kind == WallKind.SPIRIT else physical_wall_source
	for r in range(wall.row, wall.row + wall_thickness):
		for c in range(col_min, col_max + 1):
			var coords := Vector2i(c, r)
			if not wall.full and c >= wall.gap_l and c <= wall.gap_r:
				_protected[coords] = true
				if wall.closes:
					set_cell(coords, spirit_wall_source, Vector2i.ZERO, return_wall_scene_id)
				continue
			set_cell(coords, source, Vector2i.ZERO, wall_scene_id)
			_walls[coords] = true


# --------------------------------------------------------------------------
# Corridoio garantito
# --------------------------------------------------------------------------

## Protegge il corridoio che collega, in ordine, lo spawn e tutti i buchi.
func _protect_lane(walls: Array[Dictionary], spawn: Dictionary) -> void:
	var c := floori(float(spawn.center))
	var prev := {"gap_l": c - 1, "gap_r": c, "bottom": int(spawn.row)}
	for wall in walls:
		if wall.full:
			continue
		_protect_corridor(prev.gap_l, prev.gap_r, prev.bottom, wall.gap_l, wall.gap_r, wall.row)
		prev = {"gap_l": wall.gap_l, "gap_r": wall.gap_r, "bottom": wall.row + wall_thickness - 1}


## Protegge un corridoio "inclinato" tra il buco A (sopra) e il buco B (sotto).
func _protect_corridor(a_l: int, a_r: int, a_bottom: int, b_l: int, b_r: int, b_top: int) -> void:
	var r0 := a_bottom + 1
	var r1 := b_top - 1
	for r in range(r0, r1 + 1):
		var k := float(r - r0 + 1) / float(r1 - r0 + 2)
		var l := floori(lerpf(a_l, b_l, k)) - lane_padding
		var rr := ceili(lerpf(a_r, b_r, k)) + lane_padding
		for col in range(l, rr + 1):
			_protected[Vector2i(col, r)] = true


# --------------------------------------------------------------------------
# Creature
# --------------------------------------------------------------------------

func _place_creatures(rng: RandomNumberGenerator, walls: Array[Dictionary], col_min: int,
		col_max: int, row_first: int, row_last: int) -> int:
	var rules := _valid_rules()
	if rules.is_empty() or walls.is_empty():
		return 0
	var counts := {}
	var placed := 0
	for i in walls.size():
		var seg_top: int = walls[i].row + wall_thickness
		var seg_bottom: int = (walls[i + 1].row - 1) if i + 1 < walls.size() else row_last
		if seg_bottom < seg_top:
			continue
		var t := _difficulty((seg_top + seg_bottom) / 2, row_first, row_last)
		var chance := lerpf(creature_chance_start, creature_chance_end, t)
		for slot in max_creatures_per_segment:
			if rng.randf() >= chance:
				continue
			var rule := _pick_rule(rng, rules, t, counts)
			if rule == null:
				continue
			if _try_place(rng, rule, col_min, col_max, seg_top, seg_bottom):
				counts[rule] = counts.get(rule, 0) + 1
				placed += 1
	return placed


func _try_place(rng: RandomNumberGenerator, rule: ObstacleSpawnRule, col_min: int, col_max: int,
		seg_top: int, seg_bottom: int) -> bool:
	var r_min := seg_top + rule.extent_up
	var r_max := seg_bottom - rule.extent_down
	var c_min := col_min + rule.extent_left
	var c_max := col_max - rule.extent_right
	if r_max < r_min or c_max < c_min:
		return false
	for attempt in placement_attempts:
		var at := Vector2i(rng.randi_range(c_min, c_max), rng.randi_range(r_min, r_max))
		if _can_place(rule, at):
			set_cell(at, rule.source_id, Vector2i.ZERO, rule.scene_id)
			for c in range(at.x - rule.extent_left, at.x + rule.extent_right + 1):
				for r in range(at.y - rule.extent_up, at.y + rule.extent_down + 1):
					_creatures[Vector2i(c, r)] = true
			return true
	return false


func _can_place(rule: ObstacleSpawnRule, at: Vector2i) -> bool:
	var m := creature_spacing
	for c in range(at.x - rule.extent_left - m, at.x + rule.extent_right + m + 1):
		for r in range(at.y - rule.extent_up - m, at.y + rule.extent_down + m + 1):
			var p := Vector2i(c, r)
			# Distanza minima solo dalle altre creature...
			if _creatures.has(p):
				return false
			var inside := c >= at.x - rule.extent_left and c <= at.x + rule.extent_right \
					and r >= at.y - rule.extent_up and r <= at.y + rule.extent_down
			if not inside:
				continue
			# ...mentre l'ingombro vero non deve toccare muri né corridoio.
			if _walls.has(p):
				return false
			if not rule.can_block_lane and _protected.has(p):
				return false
	return true


func _pick_rule(rng: RandomNumberGenerator, rules: Array[ObstacleSpawnRule], t: float,
		counts: Dictionary) -> ObstacleSpawnRule:
	var candidates: Array[ObstacleSpawnRule] = []
	var total := 0.0
	for rule in rules:
		if t < rule.min_progress or t > rule.max_progress:
			continue
		if rule.max_count >= 0 and counts.get(rule, 0) >= rule.max_count:
			continue
		candidates.append(rule)
		total += rule.weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for rule in candidates:
		roll -= rule.weight
		if roll <= 0.0:
			return rule
	return candidates.back()


func _valid_rules() -> Array[ObstacleSpawnRule]:
	var valid: Array[ObstacleSpawnRule] = []
	for rule in obstacle_rules:
		if rule == null or not rule.enabled or rule.weight <= 0.0:
			continue
		if not _has_scene_tile(rule.source_id, rule.scene_id):
			push_warning(LOG_PREFIX + "regola '%s': tile %d/%d non trovato nel TileSet." \
					% [rule.resource_name, rule.source_id, rule.scene_id])
			continue
		valid.append(rule)
	return valid


func _has_scene_tile(source_id: int, scene_id: int) -> bool:
	if tile_set == null or not tile_set.has_source(source_id):
		return false
	var source := tile_set.get_source(source_id) as TileSetScenesCollectionSource
	return source != null and source.has_scene_tile_id(scene_id)


# --------------------------------------------------------------------------
# Grafica a nuvola (ricostruita dai tile)
# --------------------------------------------------------------------------

func _queue_visual_rebuild() -> void:
	if _visuals_dirty:
		return
	_visuals_dirty = true
	_rebuild_visuals.call_deferred()


func _rebuild_visuals() -> void:
	_visuals_dirty = false
	if _visual_root and is_instance_valid(_visual_root):
		remove_child(_visual_root)
		_visual_root.queue_free()
	_visual_root = Node2D.new()
	_visual_root.name = "CloudWalls"
	add_child(_visual_root, false, Node.INTERNAL_MODE_FRONT)
	if tile_set == null:
		return

	# Raggruppa i tile di muro per riga.
	var rows := {}
	for coords in get_used_cells():
		var type := _cell_type(coords)
		if type == CellType.NONE:
			continue
		if not rows.has(coords.y):
			rows[coords.y] = {}
		rows[coords.y][coords.x] = type
	var row_ids := rows.keys()
	row_ids.sort()

	# Unisce righe consecutive identiche (muri spessi) in blocchi.
	var blocks: Array[Dictionary] = []
	for r in row_ids:
		if not blocks.is_empty() and blocks.back().r1 == r - 1 \
				and (blocks.back().cells as Dictionary).recursive_equal(rows[r], 1):
			blocks.back().r1 = r
		else:
			blocks.append({"r0": r, "r1": r, "cells": rows[r]})

	var grid := _grid_bounds()
	for block in blocks:
		var cells: Dictionary = block.cells
		if cells.values().has(CellType.SPIRIT_RETURN):
			_add_runs(block, [CellType.SPIRIT], CloudWallVisual.Kind.SPIRIT,
					CloudWallVisual.Phase.DESCENT_ONLY, grid)
			_add_runs(block, [CellType.SPIRIT, CellType.SPIRIT_RETURN], CloudWallVisual.Kind.SPIRIT,
					CloudWallVisual.Phase.RETURN_ONLY, grid)
		else:
			_add_runs(block, [CellType.SPIRIT], CloudWallVisual.Kind.SPIRIT,
					CloudWallVisual.Phase.ALWAYS, grid)
		_add_runs(block, [CellType.PHYSICAL], CloudWallVisual.Kind.PHYSICAL,
				CloudWallVisual.Phase.ALWAYS, grid)


func _cell_type(coords: Vector2i) -> CellType:
	var source := get_cell_source_id(coords)
	var alt := get_cell_alternative_tile(coords)
	if source == spirit_wall_source and alt == wall_scene_id:
		return CellType.SPIRIT
	if source == spirit_wall_source and alt == return_wall_scene_id:
		return CellType.SPIRIT_RETURN
	if source == physical_wall_source and alt == wall_scene_id:
		return CellType.PHYSICAL
	return CellType.NONE


## Crea una nuvola per ogni tratto continuo di celle dei tipi indicati.
func _add_runs(block: Dictionary, types: Array, kind: CloudWallVisual.Kind,
		phase: CloudWallVisual.Phase, grid: Dictionary) -> void:
	var cols: Array = []
	for c in block.cells:
		if types.has(block.cells[c]):
			cols.append(c)
	if cols.is_empty():
		return
	cols.sort()
	var start: int = cols[0]
	var prev: int = cols[0]
	for i in range(1, cols.size() + 1):
		if i < cols.size() and cols[i] == prev + 1:
			prev = cols[i]
			continue
		_make_cloud(start, prev, block.r0, block.r1, kind, phase, grid)
		if i < cols.size():
			start = cols[i]
			prev = cols[i]


func _make_cloud(c0: int, c1: int, r0: int, r1: int, kind: CloudWallVisual.Kind,
		phase: CloudWallVisual.Phase, grid: Dictionary) -> void:
	var visual := CloudWallVisual.new()
	visual.name = "Cloud_%d_%d" % [c0, r0]
	visual.setup(kind, phase, faded_alpha, hide_inactive_on_descent)
	_visual_root.add_child(visual)

	var ts := Vector2(tile_set.tile_size)
	var rect := Rect2(map_to_local(Vector2i(c0, r0)) - ts * 0.5,
			Vector2((c1 - c0 + 1) * ts.x, (r1 - r0 + 1) * ts.y))
	var variant := hash(Vector3i(c0, r0, c1))
	# Se il tratto tocca il bordo del livello la nuvola "entra" nel muro laterale.
	var open_left := c0 <= int(grid.col_min)
	var open_right := c1 >= int(grid.col_max)
	var sets := [
		[visual.descent_solid, _skin(descent_solid_skin, "descent_solid")],
		[visual.descent_faded, _skin(descent_faded_skin, "descent_faded")],
		[visual.return_solid, _skin(return_solid_skin, "return_solid")],
		[visual.return_faded, _skin(return_faded_skin, "return_faded")],
	]
	for pair in sets:
		_fill_cloud(pair[0], rect, pair[1], variant, open_left, open_right)


## Copre [param rect] con bordo sinistro + centri ripetuti + bordo destro.
func _fill_cloud(parent: Node2D, rect: Rect2, skin: CloudWallSkin, variant: int,
		open_left: bool, open_right: bool) -> void:
	if skin == null or not skin.is_valid():
		return
	var lefts := skin.middle if open_left else skin.left
	var rights := skin.middle if open_right else skin.right
	var tex_size := skin.middle[0].get_size()
	var s := rect.size.y / tex_size.y  # scala: la nuvola è alta quanto il muro
	var piece := tex_size.x * s

	if rect.size.x >= piece * 2.0:
		var x := rect.position.x + piece
		var i := 1
		while x < rect.end.x - piece:
			_add_piece(parent, CloudWallSkin.pick(skin.middle, variant + i), Vector2(x, rect.position.y), s)
			x += piece
			i += 1
		_add_piece(parent, CloudWallSkin.pick(lefts, variant), rect.position, s)
		_add_piece(parent, CloudWallSkin.pick(rights, variant + 7),
				Vector2(rect.end.x - piece, rect.position.y), s)
	else:
		# Tratto corto: metà sinistra del bordo sinistro + metà destra del bordo destro.
		var half := floorf(rect.size.x * 0.5 / s)
		_add_piece(parent, CloudWallSkin.pick(lefts, variant), rect.position, s,
				Rect2(0, 0, half, tex_size.y))
		_add_piece(parent, CloudWallSkin.pick(rights, variant + 7),
				Vector2(rect.end.x - half * s, rect.position.y), s,
				Rect2(tex_size.x - half, 0, half, tex_size.y))


func _add_piece(parent: Node2D, tex: Texture2D, pos: Vector2, s: float, region := Rect2()) -> void:
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = pos
	sprite.scale = Vector2(s, s)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if region.has_area():
		sprite.region_enabled = true
		sprite.region_rect = region
	parent.add_child(sprite)


func _skin(assigned: CloudWallSkin, default_key: String) -> CloudWallSkin:
	if assigned and assigned.is_valid():
		return assigned
	return _get_default_skin(default_key)


static func _get_default_skin(key: String) -> CloudWallSkin:
	if _default_skins.has(key):
		return _default_skins[key]
	var folder: String = DEFAULT_SKIN_PATHS[key][0]
	var with_variants: bool = DEFAULT_SKIN_PATHS[key][1]
	var parts: Array[PackedStringArray] = []
	for piece in ["1", "2", "3"]:
		var paths := PackedStringArray([folder + "combinata_%s.png" % piece])
		if with_variants:
			for v in range(1, 6):
				var p := folder + "combinata_%s_%d.png" % [piece, v]
				if ResourceLoader.exists(p):
					paths.append(p)
		parts.append(paths)
	var skin := CloudWallSkin.from_paths(parts[0], parts[1], parts[2])
	_default_skins[key] = skin
	return skin


# --------------------------------------------------------------------------
# Utility
# --------------------------------------------------------------------------

## Colonne/righe della griglia dentro l'area di gioco (coordinate del layer).
func _grid_bounds() -> Dictionary:
	var cell := Vector2(tile_set.tile_size) if tile_set else Vector2(16, 16)
	var size := _get_level_size()
	var left := -size.x * 0.5 - position.x
	var right := size.x * 0.5 - position.x
	var top := -position.y
	var bottom := size.y - position.y
	return {
		"col_min": floori(left / cell.x),
		"col_max": ceili(right / cell.x) - 1,
		"row_top": floori(top / cell.y),
		"row_bottom": ceili(bottom / cell.y) - 1,
	}


func _difficulty(row: int, row_first: int, row_last: int) -> float:
	var t := clampf(inverse_lerp(float(row_first), float(row_last), float(row)), 0.0, 1.0)
	if difficulty_curve:
		t = clampf(difficulty_curve.sample(t), 0.0, 1.0)
	return t


func _get_level_size() -> Vector2:
	var parent := get_parent()
	if use_level_bounds and parent is LevelBoundaries:
		return Vector2(parent.width, parent.height)
	return Vector2(fallback_width, fallback_height)


func _signature() -> String:
	var values: Array = []
	for prop in _SIGNATURE_PROPS:
		values.append(get(prop))
	values.append(_get_level_size())
	values.append(position)
	values.append(tile_set.get_instance_id() if tile_set else 0)
	if difficulty_curve:
		for i in difficulty_curve.point_count:
			values.append(difficulty_curve.get_point_position(i))
	for rule in obstacle_rules:
		values.append(rule.signature() if rule else "null")
	for skin in [descent_solid_skin, descent_faded_skin, return_solid_skin, return_faded_skin]:
		values.append(skin.signature() if skin else "null")
	return var_to_str(values)


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_debug_lanes or tile_set == null:
		return
	var size := Vector2(tile_set.tile_size)
	for coords in _protected:
		draw_rect(Rect2(map_to_local(coords) - size * 0.5, size), Color(0.2, 1.0, 0.4, 0.22))
