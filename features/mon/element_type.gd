class_name ElementType

enum Type {
	NORMAL, FIRE, WATER, GRASS,               # 0-3 (existentes, no mover)
	ELECTRIC, FLYING, BUG, GROUND, ROCK,      # 4-8
	FIGHTING, POISON, STEEL,                  # 9-11
	PSYCHIC, GHOST, DARK, FAIRY, ICE, DRAGON  # 12-17
}

const _CHART := {
	Type.NORMAL:   { Type.ROCK: 0.5, Type.STEEL: 0.5, Type.GHOST: 0.0 },
	Type.FIRE:     { Type.GRASS: 2.0, Type.BUG: 2.0, Type.STEEL: 2.0, Type.ICE: 2.0, Type.FIRE: 0.5, Type.WATER: 0.5, Type.ROCK: 0.5, Type.DRAGON: 0.5 },
	Type.WATER:    { Type.FIRE: 2.0, Type.GROUND: 2.0, Type.ROCK: 2.0, Type.WATER: 0.5, Type.GRASS: 0.5, Type.DRAGON: 0.5 },
	Type.GRASS:    { Type.WATER: 2.0, Type.GROUND: 2.0, Type.ROCK: 2.0, Type.FIRE: 0.5, Type.GRASS: 0.5, Type.POISON: 0.5, Type.FLYING: 0.5, Type.BUG: 0.5, Type.DRAGON: 0.5, Type.STEEL: 0.5 },
	Type.ELECTRIC: { Type.WATER: 2.0, Type.FLYING: 2.0, Type.ELECTRIC: 0.5, Type.GRASS: 0.5, Type.DRAGON: 0.5, Type.GROUND: 0.0 },
	Type.FLYING:   { Type.GRASS: 2.0, Type.FIGHTING: 2.0, Type.BUG: 2.0, Type.ELECTRIC: 0.5, Type.ROCK: 0.5, Type.STEEL: 0.5 },
	Type.BUG:      { Type.GRASS: 2.0, Type.PSYCHIC: 2.0, Type.DARK: 2.0, Type.FIRE: 0.5, Type.FIGHTING: 0.5, Type.POISON: 0.5, Type.FLYING: 0.5, Type.GHOST: 0.5, Type.STEEL: 0.5, Type.FAIRY: 0.5 },
	Type.GROUND:   { Type.FIRE: 2.0, Type.ELECTRIC: 2.0, Type.POISON: 2.0, Type.ROCK: 2.0, Type.STEEL: 2.0, Type.GRASS: 0.5, Type.BUG: 0.5, Type.FLYING: 0.0 },
	Type.ROCK:     { Type.FIRE: 2.0, Type.ICE: 2.0, Type.FLYING: 2.0, Type.BUG: 2.0, Type.FIGHTING: 0.5, Type.GROUND: 0.5, Type.STEEL: 0.5 },
	Type.FIGHTING: { Type.NORMAL: 2.0, Type.ICE: 2.0, Type.ROCK: 2.0, Type.DARK: 2.0, Type.STEEL: 2.0, Type.POISON: 0.5, Type.FLYING: 0.5, Type.PSYCHIC: 0.5, Type.BUG: 0.5, Type.FAIRY: 0.5, Type.GHOST: 0.0 },
	Type.POISON:   { Type.GRASS: 2.0, Type.FAIRY: 2.0, Type.POISON: 0.5, Type.GROUND: 0.5, Type.ROCK: 0.5, Type.GHOST: 0.5, Type.STEEL: 0.0 },
	Type.STEEL:    { Type.ICE: 2.0, Type.ROCK: 2.0, Type.FAIRY: 2.0, Type.FIRE: 0.5, Type.WATER: 0.5, Type.ELECTRIC: 0.5, Type.STEEL: 0.5 },
	Type.PSYCHIC:  { Type.FIGHTING: 2.0, Type.POISON: 2.0, Type.PSYCHIC: 0.5, Type.STEEL: 0.5, Type.DARK: 0.0 },
	Type.GHOST:    { Type.PSYCHIC: 2.0, Type.GHOST: 2.0, Type.DARK: 0.5, Type.NORMAL: 0.0 },
	Type.DARK:     { Type.PSYCHIC: 2.0, Type.GHOST: 2.0, Type.FIGHTING: 0.5, Type.DARK: 0.5, Type.FAIRY: 0.5 },
	Type.FAIRY:    { Type.FIGHTING: 2.0, Type.DRAGON: 2.0, Type.DARK: 2.0, Type.FIRE: 0.5, Type.POISON: 0.5, Type.STEEL: 0.5 },
	Type.ICE:      { Type.GRASS: 2.0, Type.GROUND: 2.0, Type.FLYING: 2.0, Type.DRAGON: 2.0, Type.FIRE: 0.5, Type.WATER: 0.5, Type.ICE: 0.5, Type.STEEL: 0.5 },
	Type.DRAGON:   { Type.DRAGON: 2.0, Type.STEEL: 0.5, Type.FAIRY: 0.0 },
}

static func effectiveness(attacker: Type, defender: Type) -> float:
	return _CHART.get(attacker, {}).get(defender, 1.0)
