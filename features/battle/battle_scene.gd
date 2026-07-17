extends Node3D

@onready var player_actor: MonActor = $PlayerActor
@onready var enemy_actor: MonActor = $EnemyActor
@onready var hud: BattleHud = $UI

var player: Mon
var enemy: Mon
var enemy_index := 0
var prefer_moves := false
var bag_items: Array[ItemData] = []
var _participants: Array[Mon] = []

func _ready() -> void:
	var living := _living_party()
	player = living[0] if not living.is_empty() else GameState.party[0]
	_mark_participant(player)
	if GameState.trainer:
		enemy = Mon.create(GameState.trainer.team[0], GameState.trainer.team_level)
	else:
		enemy = Mon.create(GameState.wild_species, GameState.wild_level)
	player_actor.spawn(player.species)
	enemy_actor.spawn(enemy.species)
	hud.command_selected.connect(_on_command_selected)
	hud.move_selected.connect(_on_move_selected)
	hud.setup(player, enemy, ["PELEAR", "MOCHILA", "MONS", "HUIR"])
	hud.item_selected.connect(_on_item_selected)
	await hud.show_message("¡Un %s salvaje apareció!" % enemy.species.display_name)
	_show_turn_menu()

func _show_turn_menu() -> void:
	if prefer_moves:
		hud.show_moves()
	else:
		hud.show_commands()

func _on_command_selected(idx: int) -> void:
	match idx:
		0:
			prefer_moves = true
			hud.show_moves()
		1:
			_open_bag()
		2:
			await _open_party()
		3:
			if GameState.trainer:
				await hud.show_message("¡No podés escapar de un combate de entrenador!")
				hud.show_commands()
			else:
				hud.hide_menus()
				await hud.show_message("Huiste de la batalla...")
				_end_battle()

func _on_move_selected(idx: int) -> void:
	hud.hide_menus()
	await _player_turn(player.species.moves[idx])

func _player_turn(move: MoveData) -> void:
	await _do_turn(player, move, enemy)
	if enemy.is_fainted():
		await _victory()
		return
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await _handle_player_fainted()
		return
	_show_turn_menu()

func _victory() -> void:
	await hud.show_message("¡%s se debilitó!" % enemy.species.display_name)
	var final_win := not (GameState.trainer and enemy_index + 1 < GameState.trainer.team.size())
	if final_win:
		var jingle := "victory_leader" if GameState.trainer else "victory_wild"
		AudioManager.play_music(load("res://assets/audio/%s.ogg" % jingle))
	var total_xp := enemy.level * 15
	var recipients := _xp_recipients()
	var count := maxi(1, recipients.size())
	var xp_each := maxi(1, int(total_xp / float(count)))
	var before_level := player.level
	var before_species := player.species
	var before_exp := player.xp
	player.gain_xp(xp_each)
	await hud.type_message("%s ganó %d de experiencia." % [before_species.display_name, xp_each])
	var on_level_up := func(new_level: int) -> void:
		AudioManager.play_sfx(load("res://assets/audio/level_up.ogg"))
		await hud.show_message("¡%s subió de nivel %d!" % [player.species.display_name, new_level])
	await hud.animate_exp_gain(before_level, before_exp, on_level_up)
	hud.refresh_names()
	hud.sync_hp(player, false)
	var bench_before := {}
	for m in recipients:
		if m != player:
			bench_before[m] = m.species
			m.gain_xp(xp_each)
	var evolved: Array = []
	if player.species != before_species:
		evolved.append([before_species.display_name, player.species.display_name])
	for m in bench_before:
		if m.species != bench_before[m]:
			evolved.append([bench_before[m].display_name, m.species.display_name])
	if not evolved.is_empty() and final_win:
		AudioManager.play_music(load("res://assets/audio/evolution.ogg"))
	for e in evolved:
		await hud.show_message("¡%s evolucionó a %s!" % [e[0], e[1]])
	if not final_win:
		enemy_index += 1
		enemy = Mon.create(GameState.trainer.team[enemy_index], GameState.trainer.team_level)
		enemy_actor.respawn(enemy.species)
		hud.set_enemy(enemy)
		hud.refresh_names()
		hud.sync_hp(enemy, false)
		await hud.show_message("¡%s saca a %s!" % [GameState.trainer.display_name, GameState.trainer.team[enemy_index].display_name])
		_show_turn_menu()
		return
	await hud.show_message("¡Ganaste!")
	if GameState.trainer and GameState.trainer.badge:
		GameState.award_badge(GameState.trainer.badge)
		await hud.show_message("Obtuviste la %s!" % GameState.trainer.badge.display_name)
	if GameState.trainer:
		GameState.mark_trainer_defeated(GameState.trainer_battle_id)
	if GameState.all_badges_collected():
		GameState.trainer = null
		Transition.change_scene("res://features/ui/credits.tscn")
		return
	GameState.autosave_pending = true
	_end_battle()

func _do_turn(attacker: Mon, move: MoveData, defender: Mon) -> void:
	await hud.show_message("%s usó %s" % [attacker.species.display_name, move.display_name])
	var atk := player_actor if attacker == player else enemy_actor
	var def := player_actor if defender == player else enemy_actor
	atk.lunge_at(def)
	var dmg := Battle.use_move(attacker, move, defender)
	var eff := ElementType.effectiveness(move.element, defender.species.element)
	var note := ""
	if eff > 1.0: note = "  ¡Es muy eficaz!"
	elif eff < 1.0: note = "   No es muy eficaz..."
	def.shake()
	await hud.type_message("%s recibió %d de daño.%s" % [defender.species.display_name, dmg, note])
	await hud.sync_hp(defender, true)
	await get_tree().create_timer(0.4).timeout

func _enemy_best_move() -> MoveData:
	var best: MoveData = enemy.species.moves[0]
	var best_dmg := 0
	for m in enemy.species.moves:
		var d := Damage.calculate(enemy, m, player)
		if d > best_dmg:
			best_dmg = d
			best = m
	return best

func _end_battle() -> void:
	await get_tree().create_timer(1.2).timeout
	Transition.change_scene("res://features/game/game.tscn")

func _open_bag() -> void:
	bag_items.clear()
	var entries: Array[String] = []
	for item in GameState.inventory.keys():
		bag_items.append(item)
		entries.append("%s x%d" % [item.display_name, GameState.inventory[item]])
	if bag_items.is_empty():
		await hud.show_message("La mochila está vacía.")
		hud.show_commands()
		return
	hud.show_bag(entries)

func _on_item_selected(idx: int) -> void:
	hud.hide_menus()
	await _use_item(bag_items[idx])

func _use_item(item: ItemData) -> void:
	if item.effect is CaptureEffect:
		await _throw_ball(item)
	else:
		await _use_on_self(item)

func _throw_ball(item: ItemData) -> void:
	if GameState.trainer:
		await hud.show_message("¡No podés atrapar el Mon de otro entrenador!")
		_open_bag()
		return
	GameState.remove_item(item)
	await hud.show_message("¡Lanzaste una %s!" % item.display_name)
	var caught := (item.effect as CaptureEffect).roll(enemy)
	await _play_capture(item, caught)
	if caught:
		AudioManager.play_music(load("res://assets/audio/victory_wild.ogg"))
		GameState.add_mon(enemy)
		await hud.show_message("¡Atrapaste a %s!" % enemy.species.display_name)
		_end_battle()
		return
	await hud.show_message("¡%s se escapó!" % enemy.species.display_name)
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await _handle_player_fainted()
		return
	_show_turn_menu()

func _play_capture(item: ItemData, caught: bool) -> void:
	var ball := CaptureBall.new()
	ball.texture = item.icon
	add_child(ball)
	ball.position = player_actor.position + Vector3(0, 1, 0)
	await ball.throw_to(enemy_actor.position)
	await enemy_actor.absorb()
	var shakes := 3 if caught else randi_range(1, 3)
	for i in shakes:
		await get_tree().create_timer(0.35).timeout
		await ball.wobble(1 if i % 2 == 0 else -1)
	await get_tree().create_timer(0.35).timeout
	if caught:
		return
	await enemy_actor.release()
	ball.queue_free()

func _use_on_self(item: ItemData) -> void:
	var idx := await hud.choose_mon(GameState.party)
	if idx < 0:
		_open_bag()
		return
	var target := GameState.party[idx]
	if not item.effect.use(target):
		await hud.show_message("No tendría ningún efecto.")
		_open_bag()
		return
	GameState.remove_item(item)
	await hud.show_message("¡%s recuperó salud con %s!" % [target.species.display_name, item.display_name])
	if target == player:
		await hud.sync_hp(player, true)
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await _handle_player_fainted()
		return
	_show_turn_menu()

func _open_party() -> void:
	var idx := await hud.choose_mon(GameState.party)
	if idx < 0:
		hud.show_commands()
		return
	var chosen := GameState.party[idx]
	if chosen == player:
		await hud.show_message("¡%s ya está en batalla!" % chosen.species.display_name)
		hud.show_commands()
		return
	if chosen.is_fainted():
		await hud.show_message("¡%s no puede pelear!" % chosen.species.display_name)
		hud.show_commands()
		return
	hud.hide_menus()
	await _switch_to(idx)
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await _handle_player_fainted()
		return
	_show_turn_menu()

func _switch_to(idx: int) -> void:
	player = GameState.party[idx]
	_mark_participant(player)
	player_actor.respawn(player.species)
	hud.set_player(player)
	hud.refresh_names()
	hud.refresh_moves()
	hud.sync_hp(player, false)
	hud.sync_exp(false)
	await hud.show_message("¡Adelante, %s!" % player.species.display_name)

func _handle_player_fainted() -> void:
	await hud.show_message("¡%s se debilitó!" % player.species.display_name)
	if not _has_usable_mon():
		await hud.show_message("¡Te quedaste sin fuerzas!")
		GameState.whiteout()
		_end_battle()
		return
	await _force_switch()
	_show_turn_menu()

func _has_usable_mon() -> bool:
	for m in GameState.party:
		if not m.is_fainted():
			return true
	return false

func _mark_participant(m: Mon) -> void:
	if m and not _participants.has(m):
		_participants.append(m)

func _xp_recipients() -> Array[Mon]:
	var out: Array[Mon] = []
	for m in _participants:
		if not m.is_fainted():
			out.append(m)
	return out

func _living_party() -> Array[Mon]:
	var alive: Array[Mon] = []
	for m in GameState.party:
		if not m.is_fainted():
			alive.append(m)
	return alive

func _force_switch() -> void:
	var idx := -1
	while idx < 0 or GameState.party[idx].is_fainted():
		idx = await hud.choose_mon(GameState.party)
	await _switch_to(idx)
