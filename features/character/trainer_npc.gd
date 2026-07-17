@tool
extends StaticBody3D
class_name TrainerNPC

const TILE := 1.0

enum Look { DOWN, UP, LEFT, RIGHT }

@export var trainer: TrainerData
@export var id: String
@export var dialogue := "¡Te desafío!"
@export var char_col := 0: set = _set_col
@export var char_row := 1: set = _set_row
@export var look: Look = Look.DOWN: set = _set_look
@export var sight_range := 5

@onready var sprite: CharacterSprite = $CharacterSprite

var _triggered := false
var _facing := Vector3.BACK
var _alert: Label3D

func _ready() -> void:
	_facing = _look_dir()
	sprite.char_col = char_col
	sprite.char_row = char_row
	sprite.face(_facing)
	if Engine.is_editor_hint():
		return
	_alert = _make_alert()

func _look_dir() -> Vector3:
	match look:
		Look.UP: return Vector3.FORWARD
		Look.LEFT: return Vector3.LEFT
		Look.RIGHT: return Vector3.RIGHT
		_: return Vector3.BACK

func _set_col(v: int) -> void:
	char_col = v
	if is_node_ready() and sprite:
		sprite.char_col = v

func _set_row(v: int) -> void:
	char_row = v
	if is_node_ready() and sprite:
		sprite.char_row = v

func _set_look(v: Look) -> void:
	look = v
	_facing = _look_dir()
	if is_node_ready() and sprite:
		sprite.face(_facing)

func _make_alert() -> Label3D:
	var l := Label3D.new()
	l.text = "!"
	l.font_size = 96
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.85, 0.15)
	l.outline_size = 20
	l.outline_modulate = Color.BLACK
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.layers = 2
	l.position = Vector3(0, 1.15, 0)
	l.visible = false
	add_child(l)
	return l

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _triggered or Dialogue.is_active() or Transition.is_active():
		return
	if not trainer or GameState.is_trainer_defeated(_battle_id()) or GameState.party.is_empty():
		return
	if _sees_player():
		_challenge()

func _battle_id() -> String:
	return id if id != "" else String(name)

func _sees_player() -> bool:
	var wm := GameState.world_manager
	if not wm or not wm.player:
		return false
	var to_p: Vector3 = wm.player.global_position - global_position
	to_p.y = 0.0
	var fwd: float = to_p.dot(_facing)
	if fwd < 0.5 or fwd > sight_range * TILE:
		return false
	var side: float = (to_p - _facing * fwd).length()
	return side < 0.6

func _challenge() -> void:
	_triggered = true
	await _show_alert()
	await Dialogue.say(dialogue)
	GameState.start_trainer_battle(trainer, _battle_id())

func _show_alert() -> void:
	_alert.visible = true
	_alert.scale = Vector3.ZERO
	var tw := create_tween()
	tw.tween_property(_alert, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.5).timeout
