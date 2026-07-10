extends Area3D

@export_file("*.tscn") var world_path: String
@export var spawn := Vector3.ZERO

func _ready() -> void:
	area_entered.connect(_on_entered)

func _on_entered(_area: Area3D) -> void:
	if world_path:
		GameState.goto(load(world_path), spawn)
