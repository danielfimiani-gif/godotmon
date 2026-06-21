extends Resource

class_name Mon

@export var species: MonSpecies
@export var current_hp: int

static func create (from_species: MonSpecies) -> Mon:
	var m := Mon.new()
	m.species = from_species
	m.current_hp = from_species.max_hp
	return m

func is_fainted() -> bool:
	return current_hp <= 0
