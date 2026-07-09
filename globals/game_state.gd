extends Node

var party: Array[Mon] = []
var wild_species: MonSpecies

func _ready() -> void:
	if party.is_empty():
		add_mon(Mon.create(load("res://data/mon/emberkit.tres")))

func add_mon(mon: Mon) -> void:
	party.append(mon)
	print("Party: %d mon(s)" % party.size())

func heal_all() -> void:
	for mon in party:
		mon.current_hp = mon.species.max_hp

func start_wild_encounter() -> void:
	var pool := [
		load("res://data/mon/finsplash.tres"),
		load("res://data/mon/leafhop.tres")
	]
	wild_species = pool.pick_random()
	get_tree().change_scene_to_file("res://features/battle/battle.tscn")
