extends CharacterAction
class_name BattleAction

@export var trainer: TrainerData

func execute() -> void:
	if GameState.player_has_badge(trainer.badge):
		return
	GameState.start_trainer_battle(trainer)
