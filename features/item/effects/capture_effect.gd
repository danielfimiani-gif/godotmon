extends ItemEffect
class_name CaptureEffect

func roll(target: Mon) -> bool:
	return Capture.attempt(target)
