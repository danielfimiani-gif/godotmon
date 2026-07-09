@tool
extends StaticBody3D

@onready var door_trigger: Area3D = $DoorTigger

@export var interior: PackedScene

func _ready() -> void:
	if not Engine.is_editor_hint():
		door_trigger.area_entered.connect(_on_door_entered)

func _on_door_entered(_area: Area3D) -> void:
	if interior:
		get_tree().change_scene_to_packed.call_deferred(interior)
