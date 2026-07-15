extends CharacterAction
class_name BattleAction

@export var trainer: TrainerData

func execute() -> void:
	if GameState.player_has_badge(trainer.badge):
		return
	if trainer.min_level > 0 and GameState.party_level() < trainer.min_level:
		await Dialogue.say("Tu nivel es muy bajo aún para enfrentarme. Volvé cuando seas más fuerte.")
		return
	GameState.start_trainer_battle(trainer)
