extends CanvasLayer

signal _confirmed

@onready var _box: PanelContainer = $Box
@onready var _text: TypeWriter = $Box/Text

var _active := false

func _ready() -> void:
	_box.hide()

func say(text: String) -> void:
	_active = true
	_box.show()
	await _text.type_text(text)
	await _confirmed
	_box.hide()
	_active = false

func is_active() -> bool:
	return _active

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact"):
		if _text.typing:
			_text.skip()
		else:
			_confirmed.emit()
		get_viewport().set_input_as_handled()
