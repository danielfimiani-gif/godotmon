extends Node3D

@onready var grass_detector: Area3D = $GrassDetector
@onready var ray: RayCast3D = $ObstacleRay
@onready var sprite: CharacterSprite = $Sprite3D

const TILE := 1.0
const MOVE_TIME := 0.15
const ENCOUNTER_CHANCE := 0.2

var moving := false
var in_grass := false
var move_tween: Tween
var facing = Vector3.BACK

func _ready() -> void:
	grass_detector.area_entered.connect(_on_grass_entered)
	grass_detector.area_exited.connect(_on_grass_exited)

func _physics_process(_delta: float) -> void:
	if moving or Dialogue.is_active() or Transition.is_active():
		return
	var dir := _input_dir()
	if dir == Vector3.ZERO:
		return
	facing = dir
	if _can_move(dir):
		_step(dir)
	else:
		sprite.face(dir)

func _input_dir() -> Vector3:
	if Input.is_action_pressed("ui_up"): return Vector3.FORWARD
	if Input.is_action_pressed("ui_down"): return Vector3.BACK
	if Input.is_action_pressed("ui_left"): return Vector3.LEFT
	if Input.is_action_pressed("ui_right"): return Vector3.RIGHT
	return Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if moving or Dialogue.is_active() or Transition.is_active():
		return
	if event.is_action_pressed("interact"):
		_try_interact()

func _step(dir: Vector3) -> void:
	moving = true
	sprite.step(dir)
	var target := position + dir * TILE
	move_tween = create_tween()
	move_tween.tween_property(self, "position", target, MOVE_TIME)
	await move_tween.finished
	moving = false
	if _input_dir() == Vector3.ZERO:
		sprite.face(facing)
	_check_encounter()

func _dir_held() -> bool:
	return Input.is_action_pressed("ui_up") or \
		Input.is_action_pressed("ui_down") or \
		Input.is_action_pressed("ui_left") or \
		Input.is_action_pressed("ui_right")

func _on_grass_entered(area: Area3D) -> void:
	if area.is_in_group("tall_grass"):
		in_grass = true

func _on_grass_exited(area: Area3D) -> void:
	if area.is_in_group("tall_grass"):
		in_grass = false

func _check_encounter() -> void:
	if in_grass and randf() < ENCOUNTER_CHANCE:
		GameState.start_wild_encounter()

func _can_move(dir: Vector3) -> bool:
	ray.target_position = dir * TILE
	ray.force_raycast_update()
	return not ray.is_colliding()

func teleport(pos: Vector3) -> void:
	if move_tween and move_tween.is_valid():
		move_tween.kill()
	moving = false
	position = Vector3(roundf(pos.x), pos.y, roundf(pos.z))

func _try_interact() -> void:
	ray.target_position = facing * TILE
	ray.force_raycast_update()
	var target := ray.get_collider()
	if target and target.has_method("interact"):
		get_viewport().set_input_as_handled()
		target.interact()
