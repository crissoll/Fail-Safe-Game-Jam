extends CharacterBody2D

@export var lane_count := 9
@export var current_lane := 4

var matrix := []

func _ready():
	add_row()

func _input(event):

	# Aggiunge una nuova riga
	if event.is_action_pressed("ui_accept"): # invio
		add_row()

	# Salva il json
	if event.is_action_pressed("ui_cancel"): # esc
		save_json()

func add_row():

	var row = []

	for i in range(lane_count):
		row.append(0)

	row[current_lane] = 67

	matrix.append(row)

	print(row)

func save_json():

	var data = {
		"matrix": matrix
	}

	var file = FileAccess.open(
		"res://player_path.json",
		FileAccess.WRITE
	)

	file.store_string(JSON.stringify(data, "\t"))

	print("Salvato:", matrix.size(), "righe")
