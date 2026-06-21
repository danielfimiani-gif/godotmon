extends Node3D

@export var player_species: MonSpecies
@export var enemy_species: MonSpecies
@onready var player_slot: Marker3D = $PlayerSlot
@onready var enemy_slot: Marker3D = $EnemySlot

@onready var player_name: Label = $UI/PlayerPanel/PlayerBox/PlayerName
@onready var player_hp: ProgressBar = $UI/PlayerPanel/PlayerBox/PlayerHP
@onready var enemy_name: Label = $UI/EnemyPanel/EnemyBox/EnemyName
@onready var enemy_hp: ProgressBar = $UI/EnemyPanel/EnemyBox/EnemyHP
@onready var message: Label = $UI/MessageLabel
@onready var moves_box: GridContainer = $UI/MovesPanel

var player: Mon
var enemy: Mon

func _ready() -> void:
	player = Mon.create(player_species)
	enemy = Mon.create(enemy_species)
	_spawn(player_species, player_slot)
	_spawn(enemy_species, enemy_slot)
	_build_move_buttons()
	_refresh_ui()
	message.text = "!%s salvaje apareció!" % enemy.species.display_name

func _spawn(species: MonSpecies, slot: Marker3D) -> void:
	slot.add_child(species.model.instantiate())

func _build_move_buttons() -> void:
	for move in player.species.moves:
		var b := Button.new()
		b.text = move.display_name
		b.pressed.connect(_on_move_pressed.bind(move))
		moves_box.add_child(b)

func _on_move_pressed(move: MoveData) -> void:
	_set_buttons_enabled(false)
	var dmg = Battle.use_move(player, move, enemy)
	_refresh_ui()
	if enemy.is_fainted():
		message.text = "!%s se debilitó! Ganaste " % enemy.species.display_name
		return
	
	var enemy_move: MoveData = enemy.species.moves[0]
	var edmg := Battle.use_move(enemy, enemy_move, player)
	_refresh_ui()
	if player.is_fainted():
		message.text = "!%s se debilitó! Perdiste" % player.species.display_name
		return

	message.text = "%s: %d dmg | %s: %d dmg" % [move.display_name, dmg, enemy_move.display_name, edmg]
	_set_buttons_enabled(true)

func _set_buttons_enabled(enabled: bool) -> void:
	for b in moves_box.get_children():
		b.disabled = not enabled

func _refresh_ui() -> void:
	player_name.text = player.species.display_name
	enemy_name.text = enemy.species.display_name
	_set_hp_bar(player_hp, player)
	_set_hp_bar(enemy_hp, enemy)

func _set_hp_bar(bar: ProgressBar, mon: Mon) -> void:
	bar.max_value = mon.species.max_hp
	bar.value = mon.current_hp
