extends PanelContainer
class_name PartyUI

signal chosen(idx: int)

const SLOT := preload("res://features/ui/party_slot.tscn")

@onready var list: VBoxContainer = $List

var _slots: Array[PartySlot] = []
var _index := 0

func open(party: Array[Mon]) -> int:
	_populate(party)
	show()
	var idx: int = await chosen
	hide()
	return idx

func _populate(party: Array[Mon]) -> void:
	for c in list.get_children():
		c.queue_free()
	_slots.clear()
	for mon in party:
		var slot := SLOT.instantiate() as PartySlot
		list.add_child(slot)
		slot.set_mon(mon)
		_slots.append(slot)
	_index = 0
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _slots.is_empty():
		return
	if event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_accept"):
		chosen.emit(_index)
	elif event.is_action_pressed("ui_cancel") or _is_back(event):
		chosen.emit(-1)

func _is_back(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE

func _move(delta: int) -> void:
	_index = clampi(_index + delta, 0, _slots.size() - 1)
	_refresh()

func _refresh() -> void:
	for i in _slots.size():
		_slots[i].set_selected(i == _index)
