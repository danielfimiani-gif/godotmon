extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var main_menu: Menu = $Panel/Menu
@onready var party_ui: PartyUI = $PartyUI
@onready var message_panel: PanelContainer = $PanelContainer
@onready var message: Label = $PanelContainer/Message

var _open := false
var _busy := false

func _ready() -> void:
	panel.hide()
	party_ui.hide()
	message.hide()
	message_panel.hide()
	main_menu.selected.connect(_on_main_selected)
	main_menu.cancelled.connect(func() -> void: main_menu.selected.emit(-1))

func _input(event: InputEvent) -> void:
	if _busy:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_ESCAPE:
		if _open:
			_close()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()

func _open_menu() -> void:
	_open = true
	get_tree().paused = true
	main_menu.set_options(["MONS", "MOCHILA", "GUARDAR", "SALIR"])
	panel.show()

func _close() -> void:
	_open = false
	get_tree().paused = false
	panel.hide()
	party_ui.hide()

func _on_main_selected(idx: int) -> void:
	if _busy:
		return
	if idx < 0:
		_close()
		return
	_busy = true
	match main_menu.options[idx]:
		"MONS":
			if not GameState.party.is_empty():
				panel.hide()
				await party_ui.open(GameState.party)
				panel.show()
			else:
				await _flash("No tenés Mons todavía.")
		"GUARDAR":
			GameState.save_game()
			await _flash("Partida guardada.")
		"SALIR":
			_close()
			Transition.change_scene("res://features/ui/title.tscn")
		"MOCHILA":
			await _open_bag()
	_busy = false

func _flash(text: String) -> void:
	panel.hide()
	message_panel.show()
	message.text = text
	message.show()
	await get_tree().create_timer(1.0, true).timeout
	message.hide()
	message_panel.hide()
	panel.show()

func _open_bag() -> void:
	if GameState.inventory.is_empty():
		await _flash("La mochila está vacía.")
		return
	var items: Array[ItemData] = []
	var entries: Array[String] = []
	for item in GameState.inventory:
		items.append(item)
		entries.append("%s x%d" % [item.display_name, GameState.inventory[item]])
	main_menu.set_options(entries)
	var idx: int = await main_menu.selected
	main_menu.set_options(["MONS", "MOCHILA", "GUARDAR", "SALIR"])
	if idx < 0:
		return
	var it: ItemData = items[idx]
	if it.effect is CaptureEffect:
		await _flash("No podés usar eso fuera de combate.")
		return
	if GameState.party.is_empty():
		await _flash("No tenés Mons.")
		return
	panel.hide()
	var t: int = await party_ui.open(GameState.party)
	panel.show()
	if t < 0:
		return
	var target: Mon = GameState.party[t]
	if it.effect.use(target):
		GameState.remove_item(it)
		await _flash("%s recuperó salud." % target.species.display_name)
	else:
		await _flash("No tendría ningún efecto.")
