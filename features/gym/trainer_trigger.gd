extends Area3D

@export var trainer: TrainerData

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(_area: Area3D) -> void:
	GameState.start_trainer_battle(trainer)
