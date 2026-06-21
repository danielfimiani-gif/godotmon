class_name Battle

static func use_move(attacker: Mon, move: MoveData, defender: Mon) -> int:
	var dmg := Damage.calculate(attacker.species, move, defender.species)
	defender.current_hp = maxi(0, defender.current_hp - dmg)
	return dmg
