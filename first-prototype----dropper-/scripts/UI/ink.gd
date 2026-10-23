extends TextureRect

@export var fade_duration : float = 10.0

var initial_modulate: Color
var tween: Tween

func _ready() -> void:
	initial_modulate = modulate
	hide()
	SignalManager.squid_hit.connect(show_ink)
	add_to_group("Jellyfish")

func show_ink() -> void:
	show()
	fade_out()

func fade_out() -> void:
	if tween and tween.is_valid():
		tween.kill()

	modulate = initial_modulate

	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(hide)

func reset() -> void:
	if tween and tween.is_valid():
		tween.kill()
	hide()
	modulate = initial_modulate
