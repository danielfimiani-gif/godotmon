extends Node3D
class_name MonActor

var _sprite: Sprite3D

func spawn(species: MonSpecies) -> void:
	_sprite = Sprite3D.new()
	_sprite.texture = species.sprite
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.pixel_size = 0.05
	add_child(_sprite)
	_start_float()

func _start_float() -> void:
	var base_y := _sprite.position.y
	var tw := create_tween().set_loops()
	tw.tween_property(_sprite, "position:y", base_y + 0.1, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_sprite, "position:y", base_y, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func respawn(species: MonSpecies) -> void:
	if _sprite:
		_sprite.queue_free()
	spawn(species)

func lunge_at(target: MonActor) -> void:
	var origin := position
	var dir := target.position - origin
	dir.y = 0.0
	dir = dir.normalized() * 0.4
	var tw := create_tween()
	tw.tween_property(self, "position", origin + dir, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", origin, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func shake() -> void:
	var origin_x = position.x
	var tw = create_tween()
	for i in 6:
		var dx := 0.06 if i % 2 == 0 else -0.06
		tw.tween_property(self, "position:x", origin_x + dx, 0.04)
	tw.tween_property(self, "position:x", origin_x, 0.04)
	await tw.finished
