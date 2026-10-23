@tool
class_name ObstacleSpawnRule
extends Resource
## Regola usata da [FlappyLevelGenerator] per piazzare una creatura/ostacolo.
##
## Ogni regola punta a un tile del TileSet (source_id + scene_id) e dice
## quanto spesso compare, da che profondità in poi e quanto spazio occupa.
## Il nome mostrato nell'inspector è [member Resource.resource_name].

@export var enabled := true

@export_group("Tile")
## ID della sorgente nel TileSet (es. 2 = Jellyfish, 3 = Squid, 4 = Eel...).
@export var source_id := 2
## ID della scena dentro la sorgente (es. Jellyfish: 1 normale, 2 medium, 3 strong).
@export var scene_id := 1

@export_group("Probabilità")
## Peso relativo rispetto alle altre regole (0 = mai).
@export_range(0.0, 10.0, 0.05) var weight := 1.0
## Compare solo da questa profondità in poi (0 = inizio, 1 = fondo).
@export_range(0.0, 1.0, 0.01) var min_progress := 0.0
## Non compare oltre questa profondità.
@export_range(0.0, 1.0, 0.01) var max_progress := 1.0
## Numero massimo nel livello (-1 = illimitato).
@export var max_count := -1

@export_group("Ingombro (in tile)")
## Tile occupati a sinistra del punto di piazzamento.
@export_range(0, 12) var extent_left := 1
## Tile occupati a destra (conta anche il movimento, es. il pesce palla che si sposta).
@export_range(0, 12) var extent_right := 1
## Tile occupati sopra (conta anche l'oscillazione delle meduse).
@export_range(0, 12) var extent_up := 1
## Tile occupati sotto.
@export_range(0, 12) var extent_down := 1
## Se vero può stare nel corridoio garantito (usalo solo per ostacoli innocui, es. il calamaro).
@export var can_block_lane := false


static func make(
		p_name: String, p_source: int, p_scene: int, p_weight: float, p_min_progress: float,
		p_left: int, p_right: int, p_up: int, p_down: int, p_can_block_lane := false
) -> ObstacleSpawnRule:
	var rule := ObstacleSpawnRule.new()
	rule.resource_name = p_name
	rule.source_id = p_source
	rule.scene_id = p_scene
	rule.weight = p_weight
	rule.min_progress = p_min_progress
	rule.extent_left = p_left
	rule.extent_right = p_right
	rule.extent_up = p_up
	rule.extent_down = p_down
	rule.can_block_lane = p_can_block_lane
	return rule


## Stringa che cambia quando cambia un parametro (serve all'anteprima live).
func signature() -> String:
	return var_to_str([
		enabled, source_id, scene_id, weight, min_progress, max_progress, max_count,
		extent_left, extent_right, extent_up, extent_down, can_block_lane,
	])
