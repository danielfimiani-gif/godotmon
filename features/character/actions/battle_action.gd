extends CharacterAction
class_name BattleAction

@export var trainer: TrainerData

func execute() -> void:
	GameState.start_trainer_battle(trainer)
