extends Node

const SAVE_PATH := "user://save.json"

var party: Array[Mon] = []
var wild_species: MonSpecies
var trainer: TrainerData
var world_manager: Node
var return_world_path: String = ""
var return_pos: Vector3 = Vector3.ZERO
var respawn_world: String = ""
var respawn_pos: Vector3 = Vector3.ZERO
var overworld_scene: PackedScene
var overworld_pos: Vector3 = Vector3.ZERO
var defeated_trainers: Array[String] = []
var wild_pool: Array[MonSpecies] = []
var badges: Array[BadgeData] = []
var inventory: Dictionary = {}
var wild_level: int = 5

func _ready() -> void:
	_build_wild_pool()

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
	wild_level = _wild_level()
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

func enter_interior(interior: PackedScene, spawn: Vector3) -> void:
	if world_manager:
		overworld_scene = world_manager.current_world_scene
		overworld_pos = world_manager.player.global_position
	goto(interior, spawn)

func exit_interior() -> void:
	if overworld_scene:
		goto(overworld_scene, overworld_pos)

func _save_return() -> void:
	if world_manager:
		return_world_path = world_manager.current_world_path
		return_pos = world_manager.player.global_position

func set_respawn() -> void:
	if world_manager:
		respawn_world = world_manager.current_world_path
		respawn_pos = world_manager.player.global_position

func whiteout() -> void:
	heal_all()
	return_world_path = respawn_world
	return_pos = respawn_pos

func party_level() -> int:
	if party.is_empty():
		return 1
	var total := 0
	for m in party:
		total += m.level
	return int(round(float(total) / party.size()))

func _wild_level() -> int:
	return maxi(2, party_level() + randi_range(-1, 1))

func _build_wild_pool() -> void:
	_scan_mons("res://data/mon")

func _scan_mons(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := path + "/" + entry
		if dir.current_is_dir():
			_scan_mons(full)
		elif entry.ends_with(".tres"):
			var sp: MonSpecies = load(full)
			for _i in sp.spawn_weight:
				wild_pool.append(sp)
		entry = dir.get_next()
	dir.list_dir_end()

func award_badge(badge: BadgeData) -> void:
	if badge and not badges.has(badge):
		badges.append(badge)

func player_has_party() -> bool:
	return !party.is_empty()

func player_has_badge(badge: BadgeData) -> bool:
	return badges.has(badge)

func is_level_unlocked(level: LevelData) -> bool:
	return level.unlock_badge == null or player_has_badge(level.unlock_badge)

func is_level_completed(level: LevelData) -> bool:
	return level.own_badge != null and player_has_badge(level.own_badge)

func is_trainer_defeated(id: String) -> bool:
	return defeated_trainers.has(id)

func mark_trainer_defeated(id: String) -> void:
	if id != "" and not defeated_trainers.has(id):
		defeated_trainers.append(id)

func save_game() -> void:
	var mons: Array = []
	for m in party:
		mons.append(m.to_dict())
	var badge_paths: Array = []
	for b in badges:
		badge_paths.append(b.resource_path)
	var items := {}
	for item in inventory:
		items[item.resource_path] = inventory[item]
	var pos := Vector3.ZERO
	var world := ""
	if world_manager:
		pos = world_manager.player.global_position
		world = world_manager.current_world_path
	var data := {
		"party": mons,
		"badges": badge_paths,
		"inventory": items,
		"world": world,
		"pos": [pos.x, pos.y, pos.z],
		"respawn_world": respawn_world,
		"respawn_pos": [respawn_pos.x, respawn_pos.y, respawn_pos.z],
		"defeated_trainers": defeated_trainers,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	print("Partida guardada.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	party.clear()
	for d in data["party"]:
		party.append(Mon.from_dict(d))
	badges.clear()
	for p in data["badges"]:
		badges.append(load(p))
	inventory.clear()
	for path in data["inventory"]:
		inventory[load(path)] = int(data["inventory"][path])
	return_world_path = data["world"]
	var p = data["pos"]
	return_pos = Vector3(p[0], p[1], p[2])
	respawn_world = data.get("respawn_world", "")
	var rp = data.get("respawn_pos", [0, 0, 0])
	respawn_pos = Vector3(rp[0], rp[1], rp[2])
	defeated_trainers.assign(data.get("defeated_trainers", []))
	return true

func new_game() -> void:
	party.clear()
	badges.clear()
	inventory.clear()
	trainer = null
	return_world_path = ""
	return_pos = Vector3.ZERO
	respawn_world = ""
	respawn_pos = Vector3.ZERO
	defeated_trainers.clear()
