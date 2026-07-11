extends Node3D

const CAM_OFFSET := Vector3(0, 3, 3)

@onready var world_mount: Node3D = $SubViewportContainer/SubViewport/WorldMount
@onready var player: Node3D = $Player
@onready var world_camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D
@onready var sprite_camera: Camera3D = $SpriteViewport/SubViewport/SpriteCamera

@export var initial_world: PackedScene

var current_world: Node3D
var current_world_path: String = ""

func _ready() -> void:
	GameState.world_manager = self
	if GameState.return_world_path != "":
		load_world(load(GameState.return_world_path), GameState.return_pos)
		GameState.return_world_path = ""
	elif initial_world:
		load_world(initial_world, Vector3.ZERO)

func _process(_delta: float) -> void:
	var pos := player.global_position + CAM_OFFSET
	world_camera.global_position = pos
	sprite_camera.global_position = pos

func load_world(scene: PackedScene, spawn: Vector3) -> void:
	if current_world:
		current_world.queue_free()
	current_world = scene.instantiate()
	current_world_path = scene.resource_path
	world_mount.add_child(current_world)
	player.teleport(spawn)
