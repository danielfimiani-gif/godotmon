@tool
extends Sprite3D
class_name CharacterSprite

const CELL := Vector2(18, 26)

@export var char_col: int = 0: set = set_char_col
@export var char_row: int = 1: set = set_char_row

var _dir: int = 0
var _step_parity: int = 0

func _ready() -> void:
	region_enabled = true
	_apply(1)

func set_char_col(v: int) -> void:
	char_col = v
	region_enabled = true
	_apply(1)

func set_char_row(v: int) -> void:
	char_row = v
	region_enabled = true
	_apply(1)

func face(facing: Vector3) -> void:
	_dir = _dir_index(facing)
	_apply(1)

func step(facing: Vector3) -> void:
	_dir = _dir_index(facing)
	_step_parity = 1 - _step_parity
	_apply(_step_parity * 2)

func _dir_index(faing: Vector3) -> int:
	if faing == Vector3.FORWARD: return 3
	if faing == Vector3.LEFT: return 1
	if faing == Vector3.RIGHT: return 2
	return 0

func _apply(col: int) -> void:
	var x := (char_col * 3 + col) * CELL.x
	var y := (char_row * 4 + _dir) * CELL.y
	region_rect = Rect2(x, y, CELL.x, CELL.y)
