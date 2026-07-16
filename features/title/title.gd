extends Control

@onready var logo: TextureRect = $Logo
@onready var press_start: Label = $PressStart
@onready var menu: Menu = $Menu

var _armed := false

func _ready() -> void:
	AudioManager.play_music(load("res://assets/audio/title.ogg"))
	menu.hide()
	_build_menu()
	_drop_logo()
	_blink_press_start()

func _build_menu() -> void:
	var options: Array[String]
	if FileAccess.file_exists(GameState.SAVE_PATH):
		options = ["CONTINUAR", "NUEVO JUEGO"]
	else:
		options = ["NUEVO JUEGO"]
	menu.set_options(options)
	menu.selected.connect(_on_selected)

func _drop_logo() -> void:
	var home := logo.position
	logo.position = home - Vector2(0, 500)
	var tw := create_tween()
	tw.tween_property(logo, "position", home, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _blink_press_start() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(press_start, "modulate:a", 0.1, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(press_start, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

func _input(event: InputEvent) -> void:
	if _armed:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_armed = true
		press_start.hide()
		menu.show()
		get_viewport().set_input_as_handled()

func _on_selected(idx: int) -> void:
	if menu.options[idx] == "CONTINUAR":
		GameState.load_game()
	else:
		GameState.new_game()
	Transition.change_scene("res://features/game/game.tscn")
