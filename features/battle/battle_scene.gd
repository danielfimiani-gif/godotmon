extends Node3D

@onready var player_slot: Marker3D = $PlayerSlot
@onready var enemy_slot: Marker3D = $EnemySlot

@onready var player_name: Label = $UI/PlayerPanel/PlayerBox/PlayerName
@onready var player_hp: ProgressBar = $UI/PlayerPanel/PlayerBox/PlayerHP
@onready var enemy_name: Label = $UI/EnemyPanel/EnemyBox/EnemyName
@onready var enemy_hp: ProgressBar = $UI/EnemyPanel/EnemyBox/EnemyHP
@onready var message: Label = $UI/MessageLabel
@onready var moves_box: GridContainer = $UI/MovesPanel
@onready var capture_button: Button = $UI/CaptureButton
@onready var flee_button: Button = $UI/FleeButton

var player: Mon
var enemy: Mon
var enemy_index := 0

func _ready() -> void:
	player = GameState.party[0]
	if GameState.trainer:
		enemy = Mon.create(GameState.trainer.team[0])
		capture_button.hide()
		flee_button.hide()
	else:
		enemy = Mon.create(GameState.wild_species)
	_spawn(player.species, player_slot)
	_spawn(enemy.species, enemy_slot)
	_build_move_buttons()
	capture_button.pressed.connect(_on_capture_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	_refresh_ui()
	message.text = "!%s salvaje apareció!" % enemy.species.display_name

func _spawn(species: MonSpecies, slot: Marker3D) -> void:
	var spr := Sprite3D.new()
	spr.texture = species.sprite
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.texture_filter= BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.05
	slot.add_child(spr)
	
func _build_move_buttons() -> void:
	for move in player.species.moves:
		var b := Button.new()
		b.text = move.display_name
		b.pressed.connect(_on_move_pressed.bind(move))
		moves_box.add_child(b)

func _on_move_pressed(move: MoveData) -> void:
	_set_buttons_enabled(false)
	await _do_turn(player, move, enemy)
	if enemy.is_fainted():
		if GameState.trainer and enemy_index + 1 < GameState.trainer.team.size():
			enemy_index += 1
			enemy = Mon.create(GameState.trainer.team[enemy_index])
			_spawn_enemy()
			_refresh_ui()
			message.text = "!%s saca a %s" % [GameState.trainer.display_name, GameState.trainer.team[enemy_index].display_name]
			_set_buttons_enabled(true)
			return
		message.text = "!Ganaste!"
		_end_battle()
		return
	
	var enemy_move: MoveData = _enemy_best_move()
	await _do_turn(enemy, enemy_move, player)
	if player.is_fainted():
		_end_battle()
		message.text = "!%s se debilitó Perdiste" % player.species.display_name
		return
	_set_buttons_enabled(true)

func _do_turn(attacker: Mon, move: MoveData, defender: Mon) -> void:
	message.text = "%s usó %s" % [attacker.species.display_name, move.display_name]
	await get_tree().create_timer(0.8).timeout

	var dmg := Battle.use_move(attacker, move, defender)
	var eff := ElementType.effectiveness(move.element, defender.species.element)
	_refresh_ui()

	var note := ""
	if eff > 1.0: note = "  !Es muy eficaz!"
	elif eff < 1.0: note = "   No es muy eficaz..."
	message.text = "%s recibió %d de daño.%s" % [defender.species.display_name, dmg, note]
	await get_tree().create_timer(0.8).timeout

func _set_buttons_enabled(enabled: bool) -> void:
	for b in moves_box.get_children():
		b.disabled = not enabled
	capture_button.disabled = not enabled
	flee_button.disabled = not enabled

func _refresh_ui() -> void:
	player_name.text = player.species.display_name
	enemy_name.text = enemy.species.display_name
	_set_hp_bar(player_hp, player)
	_set_hp_bar(enemy_hp, enemy)

func _set_hp_bar(bar: ProgressBar, mon: Mon) -> void:
	bar.max_value = mon.species.max_hp
	bar.value = mon.current_hp

func _on_capture_pressed() -> void:
	_set_buttons_enabled(false)
	message.text = "Lanzaste una Esfera..."
	await get_tree().create_timer(0.8).timeout

	if Capture.attempt(enemy):
		message.text = "!Capturaste a %s!" % enemy.species.display_name
		GameState.add_mon(enemy)
		_end_battle()
		return

	message.text = "!%s se escapó" % enemy.species.display_name
	await get_tree().create_timer(0.8).timeout
	await _do_turn(enemy, _enemy_best_move(), player)
	if player.is_fainted():
		message.text = "!%s se debilitó Perdiste" % player.species.display_name
		_end_battle()
		return
	_set_buttons_enabled(true)

func _on_flee_pressed() -> void:
	_set_buttons_enabled(false)
	message.text = "Huiste de la batalla..."
	await get_tree().create_timer(0.8).timeout
	_end_battle()

func _enemy_best_move() -> MoveData:
	var best: MoveData = enemy.species.moves[0]
	var best_dmg := 0
	for m in enemy.species.moves:
		var d := Damage.calculate(enemy.species, m, player.species)
		if d > best_dmg:
			best_dmg = d
			best = m
	return best

func _end_battle() -> void:
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://features/game/game.tscn")

func _spawn_enemy() -> void:
	for c in enemy_slot.get_children():
		c.queue_free()
	_spawn(enemy.species, enemy_slot)
