extends Node
## Musica di sottofondo del gioco (autoload "MusicManager").
##
## COME AGGIUNGERE LA MUSICA: metti i due file nella cartella res://audio/ con questi nomi:
##   - descent.ogg  -> parte all'avvio del gioco (menu, prima cutscene, discesa)
##   - ascent.ogg   -> parte quando il player arriva in fondo (seconda cutscene e risalita)
## Vanno bene anche .mp3 o .wav. Se un file manca, quel brano semplicemente non suona.
## I brani ripartono da capo quando finiscono e passano dall'uno all'altro con una dissolvenza.
## Il volume si regola dalle impostazioni del gioco (bus audio "Music").

const MUSIC_FOLDER := "res://audio/"
const DESCENT_TRACK := "descent"
const ASCENT_TRACK := "ascent"
const EXTENSIONS: PackedStringArray = ["ogg", "mp3", "wav"]
const BUS := &"Music"
## Durata della dissolvenza tra i due brani (secondi).
const CROSSFADE_TIME := 1.5

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _current_track := ""
var _tweens: Array[Tween] = [null, null]
var _cache: Dictionary = {}


func _ready() -> void:
	# La musica continua anche a gioco in pausa (cutscene, tutorial, menu Esc).
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus := BUS if AudioServer.get_bus_index(BUS) != -1 else &"Master"
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		player.volume_db = -80.0
		player.finished.connect(_on_finished.bind(i))
		add_child(player)
		_players.append(player)
	SignalManager.ascension_signal.connect(_on_ascension_changed)
	# Si torna alla musica della discesa quando si rientra nel menu principale.
	get_tree().scene_changed.connect(_on_scene_changed)
	play_track(DESCENT_TRACK)


## Fa partire un brano per nome (es. "descent"), con dissolvenza dal brano attuale.
func play_track(track: String) -> void:
	if track == _current_track:
		return
	_current_track = track
	var stream := _load_track(track)
	var old := _players[_active]
	_active = 1 - _active
	var new := _players[_active]
	_fade(1 - _active, old, -80.0, true)
	if stream == null:
		return
	new.stream = stream
	new.volume_db = -80.0
	new.play()
	_fade(_active, new, 0.0, false)


func stop() -> void:
	_current_track = ""
	for i in 2:
		_fade(i, _players[i], -80.0, true)


func _on_ascension_changed(ascension: bool) -> void:
	play_track(ASCENT_TRACK if ascension else DESCENT_TRACK)


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path.ends_with("home_menu.tscn"):
		play_track(DESCENT_TRACK)


func _on_finished(index: int) -> void:
	# Ripete il brano attivo (funziona con ogg, mp3 e wav).
	if index == _active and _players[index].stream:
		_players[index].play()


func _fade(index: int, player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	if _tweens[index] and _tweens[index].is_valid():
		_tweens[index].kill()
	if not player.playing:
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_db", to_db, CROSSFADE_TIME)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[index] = tween


func _load_track(track: String) -> AudioStream:
	if _cache.has(track):
		return _cache[track]
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path := MUSIC_FOLDER + track + "." + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null:
		print("MusicManager: nessun file per '%s' in %s (atteso %s.ogg/.mp3/.wav)." % [track, MUSIC_FOLDER, track])
	_cache[track] = stream
	return stream
