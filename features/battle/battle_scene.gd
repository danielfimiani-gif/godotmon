extends Node3D

@onready var player_slot: Marker3D = $PlayerSlot
@onready var enemy_slot: Marker3D = $EnemySlot
@onready var hud: BattleHud = $UI

var player: Mon
var enemy: Mon
var enemy_index := 0
var prefer_moves := false

func _ready() -> void:
	player = GameState.party[0]
	if GameState.trainer:
		enemy = Mon.create(GameState.trainer.team[0])
	else:
		enemy = Mon.create(GameState.wild_species)
	_spawn(player.species, player_slot)
	_spawn(enemy.species, enemy_slot)
	var move_names: Array[String] = []
	for m in player.species.moves:
		move_names.append(m.display_name)
	hud.command_selected.connect(_on_command_selected)
	hud.move_selected.connect(_on_move_selected)
	var second := "MOCHILA" if GameState.trainer else "CAPTURAR"
	hud.setup(player, enemy, ["PELEAR", second, "MONS", "HUIR"], move_names)
	await hud.show_message("¡Un %s salvaje apareció!" % enemy.species.display_name)
	_show_turn_menu()

func _spawn(species: MonSpecies, slot: Marker3D) -> void:
	var spr := Sprite3D.new()
	spr.texture = species.sprite
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.05
	slot.add_child(spr)
	_start_float(spr)

func _start_float(spr: Sprite3D) -> void:
	var base_y := spr.position.y
	var tw := create_tween().set_loops()
	tw.tween_property(spr, "position:y", base_y + 0.1, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(spr, "position:y", base_y, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _lunge(slot: Marker3D, toward: Marker3D) -> void:
	var origin := slot.position
	var dir := toward.position - origin
	dir.y = 0.0
	dir = dir.normalized() * 0.4
	var tw := create_tween()
	tw.tween_property(slot, "position", origin + dir, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot, "position", origin, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

func _shake(slot: Marker3D) -> void:
	var origin_x := slot.position.x
	var tw := create_tween()
	for i in 6:
		var dx := 0.06 if i % 2 == 0 else -0.06
		tw.tween_property(slot, "position:x", origin_x + dx, 0.04)
	tw.tween_property(slot, "position:x", origin_x, 0.04)
	await tw.finished

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
			if GameState.trainer:
				await hud.show_message("No podés usar eso ahora.")
				hud.show_commands()
			else:
				hud.hide_menus()
				await _do_capture()
		2:
			await hud.show_message("!Todavia no podes cambiar de Mons")
			hud.show_commands()
		3:
			if GameState.trainer:
				await hud.show_message("¡No podés escapar de un combate de Líder!")
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
		await hud.show_message("¡%s se debilitó! Perdiste..." % player.species.display_name)
		_end_battle()
		return
	_show_turn_menu()

func _victory() -> void:
	await hud.show_message("¡%s se debilitó!" % enemy.species.display_name)
	var final_win := not (GameState.trainer and enemy_index + 1 < GameState.trainer.team.size())
	if final_win:
		var jingle := "victory_leader" if GameState.trainer else "victory_wild"
		AudioManager.play_music(load("res://assets/audio/%s.ogg" % jingle))
	var before_level := player.level
	var before_species := player.species
	player.gain_xp(enemy.level * 15)
	await hud.type_message("%s ganó %d de experiencia." % [before_species.display_name, enemy.level * 15])
	await hud.sync_exp(true)
	hud.refresh_names()
	hud.sync_hp(player, false)
	if player.level > before_level:
		AudioManager.play_sfx(load("res://assets/audio/level_up.ogg"))
		await hud.show_message("¡%s subió al nivel %d!" % [player.species.display_name, player.level])
	if player.species != before_species:
		if final_win:
			AudioManager.play_music(load("res://assets/audio/evolution.ogg"))
		await hud.show_message("¡%s evolucionó a %s!" % [before_species.display_name, player.species.display_name])
	if not final_win:
		enemy_index += 1
		enemy = Mon.create(GameState.trainer.team[enemy_index])
		_spawn_enemy()
		hud.set_enemy(enemy)
		hud.refresh_names()
		hud.sync_hp(enemy, false)
		await hud.show_message("¡%s saca a %s!" % [GameState.trainer.display_name, GameState.trainer.team[enemy_index].display_name])
		_show_turn_menu()
		return
	await hud.show_message("¡Ganaste!")
	_end_battle()

func _do_capture() -> void:
	await hud.show_message("Lanzaste una Esfera...")
	if Capture.attempt(enemy):
		await hud.show_message("¡Capturaste a %s!" % enemy.species.display_name)
		GameState.add_mon(enemy)
		_end_battle()
		return
	await hud.show_message("¡%s se escapó!" % enemy.species.display_name)
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await hud.show_message("¡%s se debilitó! Perdiste..." % player.species.display_name)
		_end_battle()
		return
	_show_turn_menu()

func _do_turn(attacker: Mon, move: MoveData, defender: Mon) -> void:
	await hud.show_message("%s usó %s" % [attacker.species.display_name, move.display_name])
	var atk_slot := player_slot if attacker == player else enemy_slot
	var def_slot := player_slot if defender == player else enemy_slot
	await _lunge(atk_slot, def_slot)
	var dmg := Battle.use_move(attacker, move, defender)
	var eff := ElementType.effectiveness(move.element, defender.species.element)
	var note := ""
	if eff > 1.0: note = "  ¡Es muy eficaz!"
	elif eff < 1.0: note = "   No es muy eficaz..."
	_shake(def_slot)
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

func _spawn_enemy() -> void:
	for c in enemy_slot.get_children():
		c.queue_free()
	_spawn(enemy.species, enemy_slot)
