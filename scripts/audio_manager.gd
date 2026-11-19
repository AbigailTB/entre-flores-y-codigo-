extends Node

const SAVE_PATH := "user://ajustes.json"
const MUSIC_DIR := "res://assets/audio/music/"

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var music_enabled := true
var sfx_enabled := true
var music_volume := 0.8
var sfx_volume := 0.8

var _current_track := ""
var _sfx_cache := {}
var _fade: Tween

func _ready() -> void:
	load_settings()
	_apply_music_volume()

func play_track(track: String) -> void:
	if track == _current_track and music_player.playing:
		return
	# Acepta .ogg / .mp3 / .wav (la primera que exista)
	var path := ""
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(MUSIC_DIR + track + ext):
			path = MUSIC_DIR + track + ext
			break
	if path == "":
		return
	_current_track = track
	var stream = load(path)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		var bytes_per_sample := 2 * (2 if stream.stereo else 1)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / bytes_per_sample
	if _fade:
		_fade.kill()
	if music_player.playing:
		_fade = create_tween()
		_fade.tween_property(music_player, "volume_db", -60.0, 0.5)
		_fade.tween_callback(_start_stream.bind(stream))
	else:
		_start_stream(stream)

func _start_stream(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.volume_db = -60.0
	music_player.play()
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(music_player, "volume_db", _target_music_db(), 0.8)

func _target_music_db() -> float:
	if not music_enabled:
		return -80.0
	return linear_to_db(max(music_volume, 0.0001))

func play_music(stream: AudioStream, _loop_music: bool = true) -> void:
	if stream == null:
		return
	music_player.stream = stream
	music_player.play()
	_apply_music_volume()

func stop_music() -> void:
	music_player.stop()
	_current_track = ""

func play_named(sfx_name: String, extra_db: float = 0.0) -> void:
	if not sfx_enabled:
		return
	if not _sfx_cache.has(sfx_name):
		var path := "res://assets/audio/sfx/%s.wav" % sfx_name
		_sfx_cache[sfx_name] = load(path) if ResourceLoader.exists(path) else null
	var stream = _sfx_cache[sfx_name]
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(max(sfx_volume, 0.0001)) + extra_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_sfx(stream: AudioStream) -> void:
	if stream == null or not sfx_enabled:
		return
	sfx_player.stream = stream
	sfx_player.volume_db = linear_to_db(max(sfx_volume, 0.0001))
	sfx_player.play()

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_apply_music_volume()
	save_settings()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_music_volume()
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	save_settings()

func _apply_music_volume() -> void:
	if _fade and _fade.is_running():
		_fade.kill()
	music_player.volume_db = _target_music_db()

func save_settings() -> void:
	var data := {
		"music_enabled": music_enabled,
		"sfx_enabled": sfx_enabled,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	music_enabled = parsed.get("music_enabled", true)
	sfx_enabled = parsed.get("sfx_enabled", true)
	music_volume = parsed.get("music_volume", 0.8)
	sfx_volume = parsed.get("sfx_volume", 0.8)

func _exit_tree() -> void:
	if _fade:
		_fade.kill()
	music_player.stop()
	music_player.stream = null
	_sfx_cache.clear()
