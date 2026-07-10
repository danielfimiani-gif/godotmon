extends Resource

class_name MonSpecies

@export var display_name: String
@export var max_hp: int = 20
@export var attack: int = 10
@export var defense: int = 10
@export var sprite: Texture2D
@export var element: ElementType.Type = ElementType.Type.NORMAL
@export var moves: Array[MoveData] = []
