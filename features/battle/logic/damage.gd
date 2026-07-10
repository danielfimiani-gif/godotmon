class_name Damage

const DAMAGE_SCALE := 120.0

static func calculate(attacker: Mon, move: MoveData, defender: Mon) -> int :
	var effectiveness := ElementType.effectiveness(move.element, defender.species.element)
	var base := (2.0 * attacker.level / 5.0 + 2.0) * move.power * attacker.attack() / defender.defense() / DAMAGE_SCALE + 2.0
	return maxi(1, int(base * effectiveness))
