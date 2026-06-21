class_name Damage

static func calculate(attacker: MonSpecies, move: MoveData, defender: MonSpecies) -> int :
	var effectiveness := ElementType.effectiveness(move.element, defender.element)
	var raw := float(move.power * attacker.attack) / defender.defense
	return maxi(1, int(raw * 0.25 * effectiveness))

