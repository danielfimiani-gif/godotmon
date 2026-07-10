class_name Damage

static func calculate(attacker: Mon, move: MoveData, defender: Mon) -> int :
	var effectiveness := ElementType.effectiveness(move.element, defender.species.element)
	var base := (2.0 * attacker.level / 5.0 + 2.0) * move.power * attacker.attack() / defender.defense() / 50.0 + 2.0
	return maxi(1, int(base * effectiveness))
