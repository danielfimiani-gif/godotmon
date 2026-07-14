extends Node

var party: Array[Mon] = []
var wild_species: MonSpecies
var trainer: TrainerData
var world_manager: Node
var return_world_path: String = ""
var return_pos: Vector3 = Vector3.ZERO
var wild_pool: Array[MonSpecies] = []
var badges: Array[BadgeData] = []
var inventory: Dictionary = {}

func _ready() -> void:
	_build_wild_pool()
	add_item(load("res://data/items/potion_item_data.tres"), 3)
	print(inventory.size())

func add_mon(mon: Mon) -> void:
	party.append(mon)
	print("Party: %d mon(s)" % party.size())

func add_item(item: ItemData, amount: int = 1) -> void:
	inventory[item] = inventory.get(item, 0) + amount

func remove_item(item: ItemData, amount: int = 1) -> void:
	if not inventory.has(item):
		return
	inventory[item] -= amount
	if inventory[item] <= 0:
		inventory.erase(item)

func heal_all() -> void:
	for mon in party:
		mon.current_hp = mon.max_hp()

func start_wild_encounter() -> void:
	if party.is_empty():
		return
	trainer = null
	_save_return()
	wild_species = wild_pool.pick_random()
	AudioManager.play_music(load("res://assets/audio/battle_wild.ogg"))
	Transition.change_scene("res://features/battle/battle.tscn")

func start_trainer_battle(t: TrainerData) -> void:
	if party.is_empty():
		return
	trainer = t
	_save_return()
	AudioManager.play_music(load("res://assets/audio/battle_leader.ogg"))
	Transition.change_scene("res://features/battle/battle.tscn")

func goto(world: PackedScene, spawn: Vector3) -> void:
	if world_manager:
		Transition.change_world(func() -> void: world_manager.load_world(world, spawn))

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

func award_badge(badge: BadgeData) -> void:
	if badge and not badges.has(badge):
		badges.append(badge)

func player_has_party() -> bool:
	return !party.is_empty()

func player_has_badge(badge: BadgeData) -> bool:
	return badges.has(badge)
