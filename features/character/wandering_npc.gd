@tool
extends StaticBody3D
class_name WanderingNPC

const TILE := 1.0
const STEP_TIME := 0.2

@export var data: CharacterData
@export var char_col := 0: set = _set_col
@export var char_row := 1: set = _set_row
@export var wander := true
@export var wander_interval := 2.0
@export var wander_radius := 3

@onready var sprite: CharacterSprite = $CharacterSprite
@onready var ray: RayCast3D = $ObstacleRay

var _origin: Vector3
var _moving := false
var _talking := false
var _timer := 0.0

func _ready() -> void:
	sprite.char_col = char_col
	sprite.char_row = char_row
	sprite.face(Vector3.BACK)
	if Engine.is_editor_hint():
		return
	_origin = position
	_timer = wander_interval * randf()
	ray.add_exception(self)

func _set_col(v: int) -> void:
	char_col = v
	if is_node_ready() and sprite:
		sprite.char_col = v

func _set_row(v: int) -> void:
	char_row = v
	if is_node_ready() and sprite:
		sprite.char_row = v

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not wander or _talking or _moving:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = wander_interval
		_try_wander()

func _try_wander() -> void:
	var dirs := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var dir: Vector3 = dirs[randi() % 4]
	sprite.face(dir)
	var target := position + dir * TILE
	if _can_move(dir) and _origin.distance_to(target) <= wander_radius * TILE:
		_step(dir)

func _step(dir: Vector3) -> void:
	_moving = true
	sprite.step(dir)
	var target := position + dir * TILE
	var tw := create_tween()
	tw.tween_property(self, "position", target, STEP_TIME)
	await tw.finished
	sprite.face(dir)
	_moving = false

func _can_move(dir: Vector3) -> bool:
	ray.target_position = dir * TILE
	ray.force_raycast_update()
	return not ray.is_colliding()

func interact() -> void:
	_talking = true
	await Dialogue.say(data.dialogue)
	if data.action:
		data.action.execute()
	_talking = false
