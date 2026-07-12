extends Label
class_name TypeWriter

signal finished

@export var chars_per_seconds := 30.0

var audio: AudioStreamPlayer
var typing := false
var sound: AudioStream = load("res://assets/sounds/SFX_RetroSinglev4.wav")

func _ready() -> void:
	audio = AudioStreamPlayer.new()
	audio.stream = sound
	add_child(audio)

func type_text(msg: String) -> void:
	text = msg
	visible_characters = 0
	typing = true
	for i in msg.length():
		if not typing:
			break
		visible_characters = i + 1
		if msg[i] != " ":
			audio.pitch_scale = randf_range(0.95, 1.08)
			audio.play()
		await get_tree().create_timer(1.0 / chars_per_seconds).timeout
	visible_characters = -1
	typing = false
	finished.emit()

func skip() -> void:
	typing = false
