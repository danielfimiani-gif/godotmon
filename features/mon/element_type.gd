class_name ElementType

enum Type { NORMAL, FIRE, WATER, GRASS }

const _CHART := {
	Type.FIRE: { Type.GRASS: 2.0, Type.WATER: 0.5 },
	Type.WATER: { Type.FIRE: 2.0, Type.GRASS: 0.5 },
	Type.GRASS: { Type.WATER: 2.0, Type.FIRE: 0.5 },
}

static func effectiveness(attacker: Type, defender: Type) -> float:
	return _CHART.get(attacker, {}).get(defender, 1.0)
