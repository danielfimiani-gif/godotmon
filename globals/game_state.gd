extends Node

var party: Array[Mon] = []

func add_mon(mon: Mon) -> void:
	party.append(mon)
	print("Party: %d mon(s)" % party.size())

func heal_all() -> void:
	for mon in party:
		mon.current_hp = mon.species.max_hp
