extends StaticBody3D
class_name Character

@export var data: CharacterData

@onready var _sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	if data: 
		_sprite.texture = data.sprite_ow

func interact() -> void:
	await Dialogue.say(data.dialogue)
	if data.action:
		data.action.execute()
