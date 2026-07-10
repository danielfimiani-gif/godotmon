class_name Capture

static func chance(target: Mon) -> float :
	var hp_ratio := float(target.current_hp) / target.max_hp()
	return clampf(1.0 - hp_ratio * 0.8, 0.1, 1.0)

static func attempt(target: Mon) -> bool:
	return randf() < chance(target)
