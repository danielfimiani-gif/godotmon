extends Resource

class_name MonSpecies

@export var display_name: String
@export var sprite: Texture2D
@export var element: ElementType.Type = ElementType.Type.NORMAL
@export var moves: Array[MoveData] = []

@export_group("Stats Base")
@export var base_hp: int =20
@export var base_attack: int = 10
@export var base_defense: int = 10

@export_group("Evolve")
@export var evolves_to: MonSpecies
@export var evolves_at_level: int = 0
