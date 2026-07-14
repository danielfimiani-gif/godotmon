extends Sprite3D
class_name CaptureBall

func _ready() -> void:
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	pixel_size = 0.05

func throw_to(target_pos: Vector3) -> void:
	var start := position
	var mid := (start + target_pos) / 2.0
	mid.y = maxf(start.y, target_pos.y) + 1.2
	var tw := create_tween()
	tw.tween_method(_arc.bind(start, mid, target_pos), 0.0, 1.0, 0.5)
	await tw.finished

func _arc(t: float, a: Vector3, b: Vector3, c: Vector3) -> void:
	position = a.lerp(b, t).lerp(b.lerp(c, t), t)

func wobble(dir: int) -> void:
	var angle := deg_to_rad(22.0) * dir
	var tw := create_tween()
	tw.tween_property(self, "rotation:z", angle, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation:z", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
