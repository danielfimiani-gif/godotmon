extends Node

const FADE_TIME := 0.6
const SILENCE_DB := -80.0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_stream: AudioStream

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0

func _ready() -> void:
	_music_a = _make_player(SILENCE_DB)
	_music_b = _make_player(SILENCE_DB)
	_active = _music_a
	for _i in 4:
		_sfx_pool.append(_make_player(0.0))

func _make_player(vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol
	add_child(p)
	return p

func play_music(stream: AudioStream) -> void:
	if stream == null or stream == _current_stream:
		return
	_current_stream = stream
	var next := _music_b if _active == _music_a else _music_a
	next.stream = stream
	next.volume_db = SILENCE_DB
	next.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(next, "volume_db", 0.0, FADE_TIME)
	tw.tween_property(_active, "volume_db", SILENCE_DB, FADE_TIME)
	_active = next

func stop_music() -> void:
	_current_stream = null
	var fading := _active
	var tw := create_tween()
	tw.tween_property(fading, "volume_db", SILENCE_DB, FADE_TIME)
	tw.tween_callback(fading.stop)

func play_sfx(stream: AudioStream) -> void:
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	p.stream = stream
	p.play()

func play_sfx_alone(stream: AudioStream) -> void:
	_active.stream_paused = true
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	p.stream = stream
	p.play()
	await p.finished
	_active.stream_paused = false
