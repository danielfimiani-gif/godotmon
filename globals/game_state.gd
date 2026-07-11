extends Node

var party: Array[Mon] = []
var wild_species: MonSpecies
var trainer: TrainerData
var world_manager: Node
var return_world_path: String = ""
var return_pos: Vector3 = Vector3.ZERO
var wild_pool: Array[MonSpecies] = []

func _ready() -> void:
	if party.is_empty():
		add_mon(Mon.create(load("res://data/mon/emberkit.tres")))
	_build_wild_pool()

func add_mon(mon: Mon) -> void:
	party.append(mon)
	print("Party: %d mon(s)" % party.size())

func heal_all() -> void:
	for mon in party:
		mon.current_hp = mon.max_hp()

func start_wild_encounter() -> void:
	trainer = null
	_save_return()
	wild_species = wild_pool.pick_random()
	# la música arranca YA, en el overworld, y sobrevive el cambio de escena (autoload)
	AudioManager.play_music(load("res://assets/audio/battle_wild.ogg"))
	# el flash del velo ya difiere la ejecución fuera del physics callback → sin call_deferred
	Transition.change_scene("res://features/battle/battle.tscn")

func start_trainer_battle(t: TrainerData) -> void:
	trainer = t
	_save_return()
	AudioManager.play_music(load("res://assets/audio/battle_leader.ogg"))
	Transition.change_scene("res://features/battle/battle.tscn")

func goto(world: PackedScene, spawn: Vector3) -> void:
	if world_manager:
		world_manager.load_world.call_deferred(world, spawn)

func _save_return() -> void:
	if world_manager:
		return_world_path = world_manager.current_world_path
		return_pos = world_manager.player.global_position

func _build_wild_pool() -> void:
	var dir := DirAccess.open("res://data/mon")
	if dir == null:
		return
	for f in dir.get_files():
		if f.ends_with(".tres"):
			var sp: MonSpecies = load("res://data/mon/" + f)
			for _i in sp.spawn_weight:
				wild_pool.append(sp)
