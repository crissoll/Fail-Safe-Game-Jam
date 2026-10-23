class_name ReturnOnlyObstacle
extends Obstacle
## Ostacolo attivo solo durante la risalita (GameManager.ascension == true).
## Usato dal FlappyLevelGenerator per chiudere i buchi di alcuni muri spirito
## al ritorno, così il player è costretto a passare in forma fisica.


func _ready() -> void:
	super()
	SignalManager.ascension_signal.connect(_set_active)
	_set_active(GameManager.ascension)


func _set_active(ascension: bool) -> void:
	set_deferred(&"monitoring", ascension)
