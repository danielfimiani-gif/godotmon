extends CanvasLayer
class_name BattleHud

signal command_selected(idx: int)
signal item_selected(idx: int)
signal move_selected(idx: int)

@onready var player_name: Label = $PlayerPanel/PlayerBox/PlayerName
@onready var player_hp: ProgressBar = $PlayerPanel/PlayerBox/PlayerHP
@onready var player_hp_text: Label = $PlayerPanel/PlayerBox/PlayerHPText
@onready var player_exp: ProgressBar = $PlayerPanel/PlayerBox/PlayerEXP

@onready var enemy_name: Label = $EnemyPanel/EnemyBox/EnemyName
@onready var enemy_hp: ProgressBar = $EnemyPanel/EnemyBox/EnemyHP

@onready var message_box: PanelContainer = $MessageBox
@onready var typewriter: TypeWriter = $MessageBox/MessageLabel
@onready var command_box: PanelContainer = $CommandBox
@onready var command_menu: Menu = $CommandBox/CommandMenu
@onready var moves_box: PanelContainer = $MovesBox
@onready var moves_menu: Menu = $MovesBox/MovesMenu
@onready var bag_box: PanelContainer = $BagBox
@onready var bag_menu: Menu = $BagBox/BagMenu

var _player: Mon
var _enemy: Mon

func setup(player: Mon, enemy: Mon, command_options: Array[String], move_options: Array[String]) -> void:
	_player = player
	_enemy = enemy
	command_menu.set_options(command_options)
	command_menu.selected.connect(func(idx: int) -> void: command_selected.emit(idx))
	moves_menu.set_options(move_options)
	moves_menu.selected.connect(func(idx: int) -> void: move_selected.emit(idx))
	moves_menu.cancelled.connect(show_commands)
	bag_menu.selected.connect(func(idx: int) -> void: item_selected.emit(idx))
	bag_menu.cancelled.connect(show_commands)
	_style_exp_bar()
	refresh_names()
	sync_hp(player, false)
	sync_hp(enemy, false)
	sync_exp(false)

func set_enemy(enemy: Mon) -> void:
	_enemy = enemy

func refresh_names() -> void:
	player_name.text = "%s Lv%d" % [_player.species.display_name, _player.level]
	enemy_name.text = "%s Lv%d" % [_enemy.species.display_name, _enemy.level]

func sync_hp(mon: Mon, animate: bool) -> void:
	var bar := player_hp if mon == _player else enemy_hp
	var maxv := mon.max_hp()
	bar.max_value = maxv
	var target := float(mon.current_hp)
	if animate:
		var tw := create_tween()
		tw.tween_method(_apply_hp.bind(bar, maxv, mon), bar.value, target, 0.4)
		await tw.finished
	_apply_hp(target, bar, maxv, mon)

func sync_exp(animate: bool) -> void:
	player_exp.max_value = _player.xp_to_next()
	if animate:
		var tw := create_tween()
		tw.tween_property(player_exp, "value", float(_player.xp), 0.4)
		await tw.finished
	else:
		player_exp.value = _player.xp

func animate_exp_gain(from_level: int, from_xp: int, on_level_up: Callable) -> void:
	player_exp.max_value = _player.xp_for_level(from_level)
	player_exp.value = from_xp
	var lvl := from_level
	while lvl < _player.level:
		player_exp.max_value = _player.xp_for_level(lvl)
		var tw := create_tween()
		tw.tween_property(player_exp, "value",  player_exp.max_value, 0.4)
		await tw.finished
		await on_level_up.call(lvl + 1)
		player_exp.value = 0
		lvl += 1
	player_exp.max_value = _player.xp_to_next()
	var tw2 := create_tween()
	tw2.tween_property(player_exp, "value", float(_player.xp), 0.4)
	await tw2.finished

func show_message(text: String) -> void:
	command_box.hide()
	moves_box.hide()
	bag_box.hide()
	message_box.show()
	await typewriter.type_text(text)
	await get_tree().create_timer(0.4).timeout

func type_message(text: String) ->  void:
	await typewriter.type_text(text)

func show_commands() -> void:
	message_box.hide()
	moves_box.hide()
	command_box.show()
	bag_box.hide()

func show_moves() -> void:
	message_box.hide()
	command_box.hide()
	moves_box.show()
	bag_box.hide()

func hide_menus() -> void:
	command_box.hide()
	moves_box.hide()
	bag_box.hide()

func show_bag(entries: Array[String]) -> void:
	message_box.hide()
	command_box.hide()
	moves_box.hide()
	bag_menu.set_options(entries)
	bag_box.show()

func _apply_hp(v: float, bar: ProgressBar, maxv: float, mon: Mon) -> void:
	bar.value = v
	var ratio := v / maxv
	var color := Color("48d048") if ratio > 0.5 else Color("f8b820") if ratio > 0.2 else Color("f85838")
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	bar.add_theme_stylebox_override("fill", sb)
	if mon == _player:
		player_hp_text.text = "%d/%d" % [ceili(v), maxv]

func _style_exp_bar() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f8d030")
	player_exp.add_theme_stylebox_override("fill", sb)
