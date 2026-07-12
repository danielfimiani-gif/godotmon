extends CharacterAction
class_name HealAction 

func execute() -> void:
	GameState.heal_all()
	AudioManager.play_sfx_alone(load("res://assets/audio/heal.ogg"))
	await Dialogue.say("Tus Mons fueron curados!")
