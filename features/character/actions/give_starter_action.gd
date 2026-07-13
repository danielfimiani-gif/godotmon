extends CharacterAction
class_name GiveStarterAction

@export var starters: Array[MonSpecies]

func execute() -> void:
	if GameState.player_has_party():
		await Dialogue.say("Ya elegiste tu Mon, ve descubrir el mundo!")
		return
	var names: Array[String] = []
	for s in starters:
		names.append(s.display_name)
	var idx := await Dialogue.choose(names)
	var chosen := starters[idx]
	GameState.add_mon(Mon.create(chosen))
	await Dialogue.say("!Elegiste a %s! Cuidalo bien." % chosen.display_name)
