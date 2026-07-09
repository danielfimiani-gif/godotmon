extends Node3D

const CAM_OFFSET := Vector3(0, 3, 3)

@onready var player: Node3D = $Player
@onready var world_camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D
@onready var sprite_camera: Camera3D = $SpriteViewport/SubViewport/SpriteCamera

func _process(_delta: float) -> void:
	var pos := player.global_position + CAM_OFFSET
	world_camera.global_position = pos
	sprite_camera.global_position = pos
