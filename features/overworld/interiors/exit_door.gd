extends Area3D

func _ready() -> void:
	area_entered.connect(_on_entered)

func _on_entered(_area: Area3D) -> void:
	get_tree().change_scene_to_file.call_deferred("res://features/overworld/overworld.tscn")
