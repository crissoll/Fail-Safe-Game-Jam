extends TextureRect

@export var time_show_ink : float
@export var fade_duration : float = 10.0

var initial_modulate: Color
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_modulate = modulate
	hide()
	SignalManager.squid_hit.connect(show_ink)
	add_to_group("Jellyfish")

func _process(delta: float) -> void:
	if (is_fading):
		modulate.a -= delta / fade_duration

func show_ink() -> void:
	show()
	fade_out()
	
var is_fading := false

var tween : Tween

func fade_out():
	if(tween == null):
		tween = create_tween()
	if(is_fading):
		tween.stop()
	is_fading = true
	modulate = initial_modulate
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	is_fading = false
	hide()
	

func reset():
	hide()
	modulate = initial_modulate
