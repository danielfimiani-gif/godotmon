extends Resource
class_name Mon

@export var species: MonSpecies
@export var level: int = 5
@export var xp: int = 0
@export var current_hp: int

static func create (from_species: MonSpecies, at_level:int = 5) -> Mon:
	var m := Mon.new()
	m.species = from_species
	m.level = at_level
	m.current_hp = m.max_hp()
	return m

func max_hp() -> int:
	return int(2.0 * species.base_hp * level / 100.0) + level + 10

func attack() -> int:
	return int(2.0 * species.base_attack * level / 100.0) + 5

func defense() -> int:
	return int(2.0 * species.base_defense * level / 100.0) + 5

func is_fainted() -> bool:
	return current_hp <= 0

func xp_to_next() -> int:
	return xp_for_level(level)

func xp_for_level(lvl: int) -> int:
	return lvl * 20

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		_level_up()

func _level_up() -> void:
	var old_max := max_hp()
	level += 1
	current_hp += max_hp() - old_max
	print("%s subió de nivel %d!" % [species.display_name, level])
	_try_evolve()

func _try_evolve() -> void:
	if species.evolves_to and species.evolves_at_level > 0 and level >= species.evolves_at_level:
		var old_name := species.display_name
		var old_max := max_hp()
		species = species.evolves_to
		current_hp += max_hp() - old_max
		print("%s evolucionó a %s!" % [old_name, species.display_name])
