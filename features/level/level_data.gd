extends Resource
class_name LevelData

@export var display_name: String
@export var scene: PackedScene
@export var spawn := Vector3.ZERO
@export var unlock_badge: BadgeData
@export var own_badge: BadgeData
@export var map_position := Vector2.ZERO
@export var order := 0
@export var max_wild_level: int = 10
