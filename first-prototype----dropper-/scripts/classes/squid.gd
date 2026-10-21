extends Obstacle
class_name Squid


func _on_body_entered(player: Player) -> void:
	SignalManager.squid_hit.emit()
	queue_free()
