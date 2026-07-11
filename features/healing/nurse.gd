extends Area3D

func _ready() -> void:
	area_entered.connect(_on_entered)

func _on_entered(_area: Area3D) -> void:
	GameState.heal_all()
	AudioManager.play_sfx(load("res://assets/audio/heal.ogg"))
	print("!Tu equipo está como nuevo")

