extends Node3D

const TILE := 1.0
const MOVE_TIME := 0.15

var moving := false

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
