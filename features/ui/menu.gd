extends VBoxContainer
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
		index = wrapi(index + 1, 0, labels.size()); _refresh()
		_refresh()
		_play_move()
	elif event.is_action_pressed("ui_up"):
		index = wrapi(index - 1, 0, labels.size()); _refresh()
		_refresh()
		_play_move()
	elif event.is_action_pressed("ui_accept"):
		selected.emit(index)
	elif event.is_action_pressed("ui_cancel"):
		cancelled.emit()

func _refresh() -> void:
	for i in labels.size():
		labels[i].text = ("▶ " if i == index else "   ") + options[i]

func _play_move() -> void:
	if move_sound:
		audio.play()
