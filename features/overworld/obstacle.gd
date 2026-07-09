@tool
extends StaticBody3D

@export var model: PackedScene:
	set(value):
		model = value
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_node_ready():
		return

	for c in get_children():
		if not (c is CollisionShape3D):
			c.free()
	if model:
		add_child(model.instantiate())
