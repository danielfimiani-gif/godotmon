extends ItemEffect
class_name HealEffect

@export var amount: int = 20

func use(target: Mon) -> bool:
	if target.current_hp >= target.max_hp():
		return false
	target.current_hp = min(target.current_hp + amount, target.max_hp())
	return true
