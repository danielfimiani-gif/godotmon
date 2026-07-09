extends Node3D

@onready var grass_detector: Area3D = $GrassDetector

const TILE := 1.0
const MOVE_TIME := 0.15
const ENCOUNTER_CHANCE := 0.2

var moving := false
var in_grass := false

func _ready() -> void:
	grass_detector.area_entered.connect(_on_grass_entered)
	grass_detector.area_exited.connect(_on_grass_exited)

func _unhandled_input(event: InputEvent) -> void:
	if moving:
		return
	var dir := Vector3.ZERO
	if event.is_action_pressed("ui_up"): dir = Vector3.FORWARD
	elif event.is_action_pressed("ui_down"): dir = Vector3.BACK
	elif event.is_action_pressed("ui_left"): dir = Vector3.LEFT
	elif event.is_action_pressed("ui_right"): dir = Vector3.RIGHT
	if dir != Vector3.ZERO:
		_step(dir)

func _step(dir: Vector3) -> void:
	moving = true
	var target := position + dir * TILE
	var tween := create_tween()
	tween.tween_property(self, "position", target, MOVE_TIME)
	await tween.finished
	moving = false
	_check_encounter()

func _on_grass_entered(area: Area3D) -> void:
	if area.is_in_group("tall_grass"):
		in_grass = true

func _on_grass_exited(area: Area3D) -> void:
	if area.is_in_group("tall_grass"):
		in_grass = false

func _check_encounter() -> void:
	if in_grass and randf() < ENCOUNTER_CHANCE:
		print("!Un Mon salvaje apareció!")
