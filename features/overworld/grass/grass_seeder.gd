extends MultiMeshInstance3D

@export var area_size := Vector2(30, 30)
@export var blades := 20000

func _ready() -> void:
	multimesh.instance_count = blades
	for i in blades:
		var pos := Vector3(
			randf_range(-area_size.x * 0.5, area_size.x * 0.5),
			0.0,
			randf_range(-area_size.y * 0.5, area_size.y * 0.5)
		)
		multimesh.set_instance_transform(i, Transform3D(Basis(), pos))
