extends GridContainer
class_name Menu

signal selected(index: int)
signal cancelled

@export var move_sound: AudioStream

var options: Array[String] = []
var index := 0
var labels: Array[Label] = []
var audio: AudioStreamPlayer

func _ready() -> void:
	audio = AudioStreamPlayer.new()
	audio.stream = move_sound
	add_child(audio)

func set_options(opts: Array[String]) -> void:
	options = opts
	index = 0
	for c in get_children():
		if c is Label:
			c.queue_free()
	labels.clear()
	for _o in options:
		var l := Label.new()
		add_child(l)
		labels.append(l)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or labels.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		_move(columns)      # bajar una fila = +columns
	elif event.is_action_pressed("ui_up"):
		_move(-columns)
	elif event.is_action_pressed("ui_right"):
		_move(1)
	elif event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_accept"):
		selected.emit(index)
	elif event.is_action_pressed("ui_cancel") or _is_back(event):
		cancelled.emit()   # Escape (ui_cancel) o Backspace → volver atrás

func _move(delta: int) -> void:
	var new_index := index + delta
	if new_index >= 0 and new_index < labels.size():
		index = new_index
		_refresh()
		_play_move()

func _refresh() -> void:
	for i in labels.size():
		labels[i].text = ("▶ " if i == index else "   ") + options[i]

func _play_move() -> void:
	if move_sound:
		audio.play()

func _is_back(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE
