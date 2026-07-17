extends CanvasLayer

@onready var map: TextureRect = $TextureRect
@onready var name_label: Label = $NameLevel

var _levels: Array[LevelData] = []
var _nodes: Array[Panel] = []
var _index := 0

func _ready() -> void:
	visible = false
	_style_label()

func _style_label() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.24, 0.95)
	sb.set_border_width_all(3)
	sb.border_color = Color("4aa8ff")
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	name_label.add_theme_stylebox_override("normal", sb)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(Control.PRESET_TOP_LEFT)

func open() -> void:
	_levels = _load_levels()
	if _levels.is_empty():
		return
	_build_nodes()
	_index = 0
	_refresh()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_accept"):
		_confirm()
	elif event.is_action_pressed("ui_cancel"):
		close()
	get_viewport().set_input_as_handled()

func _move(d: int) -> void:
	_index = clampi(_index + d, 0, _nodes.size() - 1)
	_refresh()

func _refresh() -> void:
	for i in _nodes.size():
		_nodes[i].scale = Vector2(1.5, 1.5) if i == _index else Vector2.ONE
	var lvl := _levels[_index]
	name_label.text = lvl.display_name if GameState.is_level_unlocked(lvl) else lvl.display_name + "  (cerrada)"
	var node := _nodes[_index]
	name_label.reset_size()
	name_label.global_position = node.global_position + Vector2(node.size.x / 2.0 - name_label.size.x / 2.0, node.size.y + 8.0)

func _confirm() -> void:
	var lvl: LevelData = _levels[_index]
	if not GameState.is_level_unlocked(lvl):
		return
	close()
	GameState.goto(lvl.scene, lvl.spawn)

func _build_nodes() -> void:
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	for lvl in _levels:
		var node := _make_node(lvl)
		map.add_child(node)
		node.position = lvl.map_position - node.size / 2.0
		_nodes.append(node)

func _make_node(lvl: LevelData) -> Panel:
	var p := Panel.new()
	p.size = Vector2(28, 28)
	p.pivot_offset = p.size / 2.0
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color.BLACK
	if GameState.is_level_completed(lvl):
		sb.bg_color = Color("f0c000")
	elif GameState.is_level_unlocked(lvl):
		sb.bg_color = Color("40d040")
	else:
		sb.bg_color = Color("606060")
	p.add_theme_stylebox_override("panel", sb)
	return p

func _load_levels() -> Array[LevelData]:
	var out: Array[LevelData] = []
	var dir := DirAccess.open("res://data/levels")
	if dir:
		for f in dir.get_files():
			if f.ends_with(".tres"):
				out.append(load("res://data/levels/" + f))
	out.sort_custom(func(a: LevelData, b: LevelData) -> bool: return a.order < b.order)
	return out
