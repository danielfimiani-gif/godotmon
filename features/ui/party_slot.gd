extends PanelContainer
class_name PartySlot

@onready var sprite: TextureRect = $HBox/Sprite
@onready var name_lv: Label = $HBox/Info/NameLv
@onready var hp_bar: ProgressBar = $HBox/Info/HPRow/HPBar
@onready var hp_text: Label = $HBox/Info/HPRow/HPText

func set_mon(mon: Mon) -> void:
	sprite.texture = mon.species.sprite
	name_lv.text = "%s  Lv%d" % [mon.species.display_name, mon.level]
	hp_bar.max_value = mon.max_hp()
	hp_bar.value = mon.current_hp
	hp_text.text = "%d/%d" % [mon.current_hp, mon.max_hp()]
	var ratio := float(mon.current_hp) / mon.max_hp()
	var color := Color("48d048") if ratio > 0.5 else Color("f8b820") if ratio > 0.2 else Color("f85838")
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	hp_bar.add_theme_stylebox_override("fill", sb)

func set_selected(on: bool) -> void:
	modulate = Color(1.4, 1.4, 1.0) if on else Color(1, 1, 1)
