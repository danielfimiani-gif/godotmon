extends Node

var party: Array[Mon] = []
var wild_species: MonSpecies
var trainer: TrainerData
var world_manager: Node
var return_world_path: String = ""
var return_pos: Vector3 = Vector3.ZERO

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
	trainer = null
	_save_return()
	var pool := [
		load("res://data/mon/finsplash.tres"),
		load("res://data/mon/leafhop.tres")
	]
	wild_species = pool.pick_random()
	get_tree().change_scene_to_file.call_deferred("res://features/battle/battle.tscn")

func start_trainer_battle(t: TrainerData) -> void:
	trainer = t
	_save_return()
	get_tree().change_scene_to_file.call_deferred("res://features/battle/battle.tscn")

func goto(world: PackedScene, spawn: Vector3) -> void:
	if world_manager:
		world_manager.load_world.call_deferred(world, spawn)

func _save_return() -> void:
	if world_manager:
		return_world_path = world_manager.current_world_path
		return_pos = world_manager.player.global_position
