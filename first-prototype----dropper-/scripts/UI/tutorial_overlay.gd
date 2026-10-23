class_name TutorialOverlay
extends Node
## Breve tutorial a pagine mostrato sopra al gioco. Mentre è aperto il gioco è in pausa.
## Si va avanti con un tasto qualsiasi (o un clic); all'ultima pagina si chiude e il
## gioco riprende. I testi si modificano dall'inspector (supportano il BBCode).

signal closed

enum ShowMode {
	ON_READY, ## Appena la scena parte.
	MANUAL,   ## Quando qualcuno chiama open() (es. un segnale collegato).
}

@export var show_mode: ShowMode = ShowMode.ON_READY
## Mostralo solo una volta per sessione di gioco (non dopo un restart).
@export var once_per_session := true
## Un titolo per pagina.
@export var titles: PackedStringArray = []
## Il testo di ogni pagina (BBCode).
@export_multiline var pages: PackedStringArray = []
## Layer di disegno: sopra GUI (500) e cutscene (600), sotto il menu di pausa (1000).
@export var canvas_layer := 800
## Secondi in cui l'input viene ignorato dopo l'apertura (evita di saltarlo per sbaglio).
@export var input_delay := 0.5

static var _shown_ids: Dictionary = {}

var _page := 0
var _layer: CanvasLayer
var _title: Label
var _body: RichTextLabel
var _footer: Label
var _panel: Control
var _opened_at := 0.0
var _closing := false
var _paused_by_me := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if show_mode == ShowMode.ON_READY:
		open.call_deferred()


func is_open() -> bool:
	return _layer != null


func open() -> void:
	if is_open() or pages.is_empty():
		return
	var id := _session_id()
	if once_per_session and _shown_ids.has(id):
		closed.emit()
		return
	_shown_ids[id] = true
	_page = 0
	_closing = false
	_build()
	_show_page()
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	_opened_at = Time.get_ticks_msec() / 1000.0
	_panel.modulate.a = 0.0
	_tween().tween_property(_panel, "modulate:a", 1.0, 0.25)


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	# Finché il tutorial è aperto si prende tutto l'input (anche Esc).
	get_viewport().set_input_as_handled()
	if _closing or Time.get_ticks_msec() / 1000.0 - _opened_at < input_delay:
		return
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton or event is InputEventJoypadButton:
		pressed = event.pressed
	if not pressed:
		return
	if _page < pages.size() - 1:
		_page += 1
		_show_page()
	else:
		_close()


func _close() -> void:
	_closing = true
	var tween := _tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	_layer.queue_free()
	_layer = null
	# Un attimo di attesa: il tasto premuto per chiudere non deve arrivare al player.
	await get_tree().create_timer(0.1, true).timeout
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	closed.emit()


func _show_page() -> void:
	_title.text = titles[_page] if _page < titles.size() else ""
	_body.text = pages[_page]
	var is_last := _page == pages.size() - 1
	var hint := "Press any key to start" if is_last else "Press any key to continue"
	_footer.text = hint if pages.size() == 1 else "%s   (%d/%d)" % [hint, _page + 1, pages.size()]


func _tween() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


func _session_id() -> String:
	return str(owner.scene_file_path if owner else "") + "/" + str(name)


func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = canvas_layer
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = root

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.22, 0.94)
	style.border_color = Color(0.70, 0.66, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.86, 0.84, 1.0))
	box.add_child(_title)

	box.add_child(HSeparator.new())

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(560, 0)
	_body.add_theme_font_size_override("normal_font_size", 19)
	_body.add_theme_font_size_override("bold_font_size", 19)
	_body.add_theme_constant_override("line_separation", 6)
	box.add_child(_body)

	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_font_size_override("font_size", 15)
	_footer.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9, 0.8))
	box.add_child(_footer)
