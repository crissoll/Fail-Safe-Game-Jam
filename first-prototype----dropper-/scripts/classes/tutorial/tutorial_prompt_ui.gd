class_name TutorialPromptUI
extends CanvasLayer
## Interfaccia del tutorial, nello stile del gioco: tasti "pixel" nei colori delle
## nuvole (lavanda / blu notte) che si abbassano quando li premi, poche parole,
## una barra opzionale e un lampo di luce sul livello (verde = giusto, rosso = sbagliato).

## Font per le scritte. Vuoto = il font di default del gioco (lo stesso dei menu).
@export var font: Font

const KEY_BG := Color("d9d4ff")          # lavanda chiara (nuvole)
const KEY_BG_PRESSED := Color("aea3ff")  # lavanda accesa
const KEY_BG_DONE := Color("8f84e8")     # lavanda piena: tasto già usato
const KEY_TEXT := Color("221d45")        # blu notte (bordi delle nuvole scure)
const KEY_TEXT_DONE := Color("f4f2ff")
const KEY_BORDER := Color("221d45")
const TEXT_COLOR := Color("f4f2ff")
const TEXT_OUTLINE := Color("221d45")
const FLASH_LAYER := 450  # sopra livello e sfondo (100), sotto la GUI (500)

var _root: Control
var _box: VBoxContainer
var _keys_row: HBoxContainer
var _label: Label
var _progress: ProgressBar
var _keycaps: Array[Dictionary] = []  # {panel, style, label, action, done}
var _flash: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	layer = 550
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 10)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_box)

	_keys_row = HBoxContainer.new()
	_keys_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_keys_row.add_theme_constant_override("separation", 10)
	_box.add_child(_keys_row)

	_label = _make_label(24)
	_box.add_child(_label)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(150, 12)
	_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_progress.show_percentage = false
	_progress.max_value = 1.0
	_progress.add_theme_stylebox_override("background", _pixel_box(Color("221d45", 0.55), KEY_BORDER, 2, 2))
	_progress.add_theme_stylebox_override("fill", _pixel_box(KEY_BG_PRESSED, KEY_BORDER, 2, 2))
	_box.add_child(_progress)

	# Lampo di colore sul livello.
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = FLASH_LAYER
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(0, 0, 0, 0)
	flash_layer.add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	hide_prompt()


func _process(_delta: float) -> void:
	for key in _keycaps:
		var pressed: bool = key.action != &"" and Input.is_action_pressed(key.action)
		var style: StyleBoxFlat = key.style
		style.bg_color = KEY_BG_PRESSED if pressed else (KEY_BG_DONE if key.done else KEY_BG)
		# Tasto premuto: il bordo sotto si assottiglia e la scritta "scende".
		style.border_width_bottom = 3 if pressed else 7
		style.content_margin_top = 9 if pressed else 5
		(key.label as Label).add_theme_color_override("font_color",
				KEY_TEXT_DONE if key.done and not pressed else KEY_TEXT)


## groups: lista di gruppi di tasti, es. [[["A", &"left"], ["D", &"right"]], [["←", &"left"], ["→", &"right"]]]
## I gruppi vengono separati da una "/".
func show_prompt(groups: Array, text: String, at_top := false, show_progress := false) -> void:
	for child in _keys_row.get_children():
		child.queue_free()
	_keycaps.clear()
	for g in groups.size():
		if g > 0:
			var sep := _make_label(24)
			sep.text = "/"
			_keys_row.add_child(sep)
		for k in groups[g]:
			_keys_row.add_child(_make_keycap(k[0], k[1]))
	_keys_row.visible = not groups.is_empty()
	_label.text = text
	_label.visible = text != ""
	_progress.visible = show_progress
	_progress.value = 0.0
	_box.visible = true
	_place.call_deferred(at_top)
	_box.modulate.a = 0.0
	create_tween().tween_property(_box, "modulate:a", 1.0, 0.2)


func hide_prompt() -> void:
	_box.visible = false
	_keycaps.clear()


func set_progress(value: float) -> void:
	_progress.value = clampf(value, 0.0, 1.0)


func mark_done(action: StringName) -> void:
	for key in _keycaps:
		if key.action == action:
			key.done = true


## Lampo di luce su tutto il livello (verde se giusto, rosso se sbagliato).
func flash_screen(color: Color, strength := 0.36, duration := 0.55) -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.color = Color(color.r, color.g, color.b, 0.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", strength, 0.08)
	_flash_tween.tween_property(_flash, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _place(at_top: bool) -> void:
	var size := _box.get_combined_minimum_size()
	_box.set_anchors_preset(Control.PRESET_CENTER_TOP if at_top else Control.PRESET_CENTER_BOTTOM)
	_box.offset_left = -size.x * 0.5
	_box.offset_right = size.x * 0.5
	if at_top:
		_box.offset_top = 70.0
		_box.offset_bottom = 70.0 + size.y
	else:
		_box.offset_top = -90.0 - size.y
		_box.offset_bottom = -90.0


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 8)
	return label


func _make_keycap(text: String, action: StringName) -> Control:
	var style := _pixel_box(KEY_BG, KEY_BORDER, 3, 3)
	style.border_width_bottom = 7
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(24, 32)
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", KEY_TEXT)
	panel.add_child(label)
	_keycaps.append({"panel": panel, "style": style, "label": label, "action": action, "done": false})
	return panel


## Riquadro dai bordi netti, stile pixel art.
func _pixel_box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = false
	return style
