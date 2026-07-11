extends Node
## Reproductor de audio GLOBAL y PERSISTENTE (autoload).
## Vive fuera del árbol de escenas → la música NO se corta al cambiar de escena.
## La música fluye continua; las escenas solo piden "poné este track".

const FADE_TIME := 0.6      # segundos de crossfade entre tracks
const SILENCE_DB := -80.0   # volumen "apagado" (silencio efectivo)

# Dos reproductores de música para hacer crossfade: mientras uno baja, el otro sube.
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer          # el que está sonando ahora
var _current_stream: AudioStream        # para no reiniciar el mismo track

# Pool de reproductores de SFX (round-robin) para que dos efectos no se corten entre sí.
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

## Cambia la música con crossfade. Si ya suena ese track, no hace nada
## (así el overworld no se reinicia al volver de una batalla al mismo mundo).
func play_music(stream: AudioStream) -> void:
	if stream == null or stream == _current_stream:
		return
	_current_stream = stream
	var next := _music_b if _active == _music_a else _music_a
	next.stream = stream
	next.volume_db = SILENCE_DB
	next.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(next, "volume_db", 0.0, FADE_TIME)        # el nuevo sube
	tw.tween_property(_active, "volume_db", SILENCE_DB, FADE_TIME)  # el viejo baja
	_active = next

## Corta la música con un fade out suave.
func stop_music() -> void:
	_current_stream = null
	var fading := _active
	var tw := create_tween()
	tw.tween_property(fading, "volume_db", SILENCE_DB, FADE_TIME)
	tw.tween_callback(fading.stop)

## Reproduce un efecto puntual sin cortar los otros (pool round-robin).
func play_sfx(stream: AudioStream) -> void:
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	p.stream = stream
	p.play()
