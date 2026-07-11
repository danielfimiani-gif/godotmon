extends CanvasLayer

const MODE_CLOCK := 0
const MODE_VERTICAL := 1
const SHADER := preload("res://assets/shaders/clock_wipe.gdshader")

var _veil: ColorRect
var _mat: ShaderMaterial
var _busy := false

func _ready() -> void:
	layer = 128
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("progress", 0.0)
	_veil = ColorRect.new()
	_veil.material = _mat
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var size := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", size.x / size.y)

func change_scene(path: String) -> void:
	await _play(func() -> void: get_tree().change_scene_to_file(path), MODE_CLOCK, 1.3, 0.35, 1.1)

func change_world(action: Callable) -> void:
	await _play(action, MODE_VERTICAL, 0.45, 0.1, 0.45)

func _play(action: Callable, mode: int, close_t: float, hold_t: float, open_t: float) -> void:
	if _busy:
		return
	_busy = true
	_mat.set_shader_parameter("mode", mode)
	await _wipe(1.0, close_t)
	await get_tree().create_timer(hold_t).timeout
	action.call()
	await get_tree().process_frame
	await _wipe(0.0, open_t)
	_busy = false

func _wipe(to: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "material:shader_parameter/progress", to, dur)
	await tw.finished
