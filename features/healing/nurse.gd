extends Area3D

func _ready() -> void:
	area_entered.connect(_on_entered)

func _on_entered(area: Area3D) -> void:
	GameState.heal_all()
	print("!Tu equipo está como nuevo")

