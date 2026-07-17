extends Control

const LINES := [
	"GODOTMON",
	"",
	"",
	"¡Te coronaste Campeón!",
	"",
	"",
	"— Diseño y Programación —",
	"Daniel Fimiani",
	"",
	"— Hecho con —",
	"Godot Engine 4",
	"",
	"",
	"",
	"¡Gracias por jugar!",
]

var _done := false

func _ready() -> void:
	AudioManager.play_music(load("res://assets/audio/title.ogg"))
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vp := get_viewport_rect().size
	var label := Label.new()
	label.text = "\n".join(LINES)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.custom_minimum_size.x = vp.x
	add_child(label)
	var h := label.get_minimum_size().y
	label.position = Vector2(0, vp.y)
	var tw := create_tween()
	tw.tween_property(label, "position:y", -h, 14.0)
	tw.tween_callback(_finish)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	Transition.change_scene("res://features/ui/title.tscn")
