extends CharacterAction
class_name HealAction 

func execute() -> void:
	if !GameState.player_has_party():
		await Dialogue.say("No tienes Mons que curar")
		return
	GameState.heal_all()
	AudioManager.play_sfx_alone(load("res://assets/audio/heal.ogg"))
	await Dialogue.say("Tus Mons fueron curados!")
