extends Node3D

@onready var player_slot: Marker3D = $PlayerSlot
@onready var enemy_slot: Marker3D = $EnemySlot
@onready var player_name: Label = $UI/PlayerPanel/PlayerBox/PlayerName
@onready var player_hp: ProgressBar = $UI/PlayerPanel/PlayerBox/PlayerHP
@onready var player_hp_text: Label = $UI/PlayerPanel/PlayerBox/PlayerHPText
@onready var player_exp: ProgressBar = $UI/PlayerPanel/PlayerBox/PlayerEXP
@onready var enemy_name: Label = $UI/EnemyPanel/EnemyBox/EnemyName
@onready var enemy_hp: ProgressBar = $UI/EnemyPanel/EnemyBox/EnemyHP
@onready var message_box: PanelContainer = $UI/MessageBox
@onready var message: TypeWriter = $UI/MessageBox/MessageLabel
@onready var command_box: PanelContainer = $UI/CommandBox
@onready var command_menu: Menu = $UI/CommandBox/CommandMenu
@onready var moves_box: PanelContainer = $UI/MovesBox
@onready var moves_menu: Menu = $UI/MovesBox/MovesMenu

var player: Mon
var enemy: Mon
var enemy_index := 0
var prefer_moves := false   # si ya elegiste PELEAR, el turno arranca en los ataques

func _ready() -> void:
	player = GameState.party[0]
	if GameState.trainer:
		enemy = Mon.create(GameState.trainer.team[0])
	else:
		enemy = Mon.create(GameState.wild_species)
	_spawn(player.species, player_slot)
	_spawn(enemy.species, enemy_slot)
	# en salvajes la 2da opción captura; en gimnasios es la mochila (placeholder)
	var second := "MOCHILA" if GameState.trainer else "CAPTURAR"
	command_menu.set_options(["PELEAR", second, "MONS", "HUIR"])
	command_menu.selected.connect(_on_command_selected)
	moves_menu.selected.connect(_on_move_selected)
	moves_menu.cancelled.connect(_show_commands)
	# los moves no cambian durante la batalla → se setean UNA vez (así el menú recuerda el último)
	var move_names: Array[String] = []
	for m in player.species.moves:
		move_names.append(m.display_name)
	moves_menu.set_options(move_names)
	_style_exp_bar()
	_refresh_ui()
	_sync_hp(player, false)
	_sync_hp(enemy, false)
	_sync_exp(false)
	await _message("¡Un %s salvaje apareció!" % enemy.species.display_name)
	_show_turn_menu()

func _spawn(species: MonSpecies, slot: Marker3D) -> void:
	var spr := Sprite3D.new()
	spr.texture = species.sprite
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.05
	slot.add_child(spr)
	_start_float(spr)          # floteo idle constante

# ---------- animaciones de sprite ----------
# Floteo idle: sube y baja suave en loop, para que el sprite "respire".
# Va sobre el SPRITE (position:y); los impactos van sobre el SLOT → no se pisan.
func _start_float(spr: Sprite3D) -> void:
	var base_y := spr.position.y
	var tw := create_tween().set_loops()
	tw.tween_property(spr, "position:y", base_y + 0.1, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(spr, "position:y", base_y, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Embestida: el atacante se lanza hacia el rival (solo en XZ) y vuelve.
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

# Sacudón: el que recibe el golpe tiembla un instante (solo en X).
func _shake(slot: Marker3D) -> void:
	var origin_x := slot.position.x
	var tw := create_tween()
	for i in 6:
		var dx := 0.06 if i % 2 == 0 else -0.06
		tw.tween_property(slot, "position:x", origin_x + dx, 0.04)
	tw.tween_property(slot, "position:x", origin_x, 0.04)
	await tw.finished

# ---------- menús ----------
func _show_commands() -> void:
	message_box.hide()          # el menú REEMPLAZA la barra de mensajes
	moves_box.hide()
	command_box.show()

func _show_moves() -> void:
	message_box.hide()
	command_box.hide()
	moves_box.show()

# Al empezar TU turno: si ya elegiste PELEAR alguna vez, va directo a los ataques.
func _show_turn_menu() -> void:
	if prefer_moves:
		_show_moves()
	else:
		_show_commands()

func _hide_menus() -> void:
	command_box.hide()
	moves_box.hide()

func _on_command_selected(idx: int) -> void:
	match idx:
		0:  # PELEAR → submenú de moves; a partir de acá el turno arranca acá
			prefer_moves = true
			_show_moves()
		1:  # MOCHILA → capturar (solo salvajes)
			if GameState.trainer:
				await _message("No podés usar eso ahora.")
				_show_commands()
			else:
				_hide_menus()
				await _do_capture()
		2:  # MONS
			await _message("¡Todavía no podés cambiar de Mon!")
			_show_commands()
		3:  # HUIR
			if GameState.trainer:
				await _message("¡No podés escapar de un combate de Líder!")
				_show_commands()
			else:
				_hide_menus()
				await _message("Huiste de la batalla...")
				_end_battle()

func _on_move_selected(idx: int) -> void:
	_hide_menus()
	await _player_turn(player.species.moves[idx])

# ---------- flujo de turno ----------
func _player_turn(move: MoveData) -> void:
	await _do_turn(player, move, enemy)
	if enemy.is_fainted():
		await _victory()
		return
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await _message("¡%s se debilitó! Perdiste..." % player.species.display_name)
		_end_battle()
		return
	_show_turn_menu()

func _victory() -> void:
	await _message("¡%s se debilitó!" % enemy.species.display_name)
	player.gain_xp(enemy.level * 15)
	await message.type_text("%s ganó %d de experiencia." % [player.species.display_name, enemy.level * 15])
	await _sync_exp(true)          # la barra de EXP sube animada
	_refresh_ui()                   # por si subió de nivel
	_sync_hp(player, false)
	if GameState.trainer and enemy_index + 1 < GameState.trainer.team.size():
		enemy_index += 1
		enemy = Mon.create(GameState.trainer.team[enemy_index])
		_spawn_enemy()
		_refresh_ui()
		_sync_hp(enemy, false)
		await _message("¡%s saca a %s!" % [GameState.trainer.display_name, GameState.trainer.team[enemy_index].display_name])
		_show_turn_menu()
		return
	await _message("¡Ganaste!")
	_end_battle()                   # recién ahora vuelve al overworld

func _do_capture() -> void:
	await _message("Lanzaste una Esfera...")
	if Capture.attempt(enemy):
		await _message("¡Capturaste a %s!" % enemy.species.display_name)
		GameState.add_mon(enemy)
		_end_battle()
		return
	await _message("¡%s se escapó!" % enemy.species.display_name)
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		await _message("¡%s se debilitó! Perdiste..." % player.species.display_name)
		_end_battle()
		return
	_show_turn_menu()

func _do_turn(attacker: Mon, move: MoveData, defender: Mon) -> void:
	await _message("%s usó %s" % [attacker.species.display_name, move.display_name])
	# quién es quién en la escena (embestida el atacante, sacudón el defensor)
	var atk_slot := player_slot if attacker == player else enemy_slot
	var def_slot := player_slot if defender == player else enemy_slot
	await _lunge(atk_slot, def_slot)        # embestida
	var dmg := Battle.use_move(attacker, move, defender)
	var eff := ElementType.effectiveness(move.element, defender.species.element)
	var note := ""
	if eff > 1.0: note = "  ¡Es muy eficaz!"
	elif eff < 1.0: note = "   No es muy eficaz..."
	_shake(def_slot)                        # sacudón en paralelo con el mensaje de daño
	await message.type_text("%s recibió %d de daño.%s" % [defender.species.display_name, dmg, note])
	await _sync_hp(defender, true)          # la barra de HP baja de a poco
	await get_tree().create_timer(0.4).timeout

## Muestra un mensaje y espera un toque (después será typewriter).
func _message(text: String) -> void:
	command_box.hide()          # la barra REEMPLAZA a los menús
	moves_box.hide()
	message_box.show()
	await message.type_text(text)          # se escribe letra por letra con el tic
	await get_tree().create_timer(0.4).timeout

# ---------- UI ----------
func _refresh_ui() -> void:
	player_name.text = "%s  Lv%d" % [player.species.display_name, player.level]
	enemy_name.text = "%s  Lv%d" % [enemy.species.display_name, enemy.level]

func _sync_hp(mon: Mon, animate: bool) -> void:
	var bar := player_hp if mon == player else enemy_hp
	var maxv := mon.max_hp()
	bar.max_value = maxv
	var target := float(mon.current_hp)
	if animate:
		var tw := create_tween()
		tw.tween_method(_apply_hp.bind(bar, maxv, mon), bar.value, target, 0.4)
		await tw.finished
	else:
		_apply_hp(target, bar, maxv, mon)

func _apply_hp(v: float, bar: ProgressBar, maxv: float, mon: Mon) -> void:
	bar.value = v
	var ratio := v / maxv
	# verde > 50% > amarillo > 20% > rojo (como Esmeralda)
	var color := Color("48d048") if ratio > 0.5 else Color("f8b820") if ratio > 0.2 else Color("f85838")
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	bar.add_theme_stylebox_override("fill", sb)
	if mon == player:
		player_hp_text.text = "%d/%d" % [ceili(v), maxv]

func _sync_exp(animate: bool) -> void:
	player_exp.max_value = player.xp_to_next()
	if animate:
		var tw := create_tween()
		tw.tween_property(player_exp, "value", float(player.xp), 0.6)
		await tw.finished
	else:
		player_exp.value = player.xp

func _style_exp_bar() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f8d030")
	player_exp.add_theme_stylebox_override("fill", sb)

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
