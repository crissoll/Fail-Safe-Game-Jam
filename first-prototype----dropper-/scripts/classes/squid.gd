extends Obstacle
class_name Squid

func _ready() -> void:
	add_to_group("Jellyfish")

var hittable := true
func _on_body_entered(player: Player) -> void:
	if(hittable):
		SignalManager.squid_hit.emit()
	visible = false
	hittable = false

func reset():
	visible = true
	hittable = true
