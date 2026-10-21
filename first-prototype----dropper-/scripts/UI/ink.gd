extends TextureRect

@export var time_show_ink : float
@export var fade_duration : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	SignalManager.squid_hit.connect(show_ink)
	add_to_group("Jellyfish")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func show_ink() -> void:
	show()
	await get_tree().create_timer(time_show_ink).timeout
	fade_out()
	


func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	hide()
	modulate.a = 1

func reset():
	hide()
