extends CanvasLayer
## Transición de pantalla GLOBAL y persistente (autoload).
## Cubre el cambio de escena con un BARRIDO DE RELOJ (clock wipe): el velo se
## cierra girando 360°, cambia la escena, y se abre girando para revelarla.
## Al ser autoload, sobrevive al cambio de escena → puede tapar la carga.

const CLOSE_TIME := 1.3    # el reloj se cierra (tapa la pantalla)
const HOLD := 0.35         # aguante tapado antes de cambiar de escena
const OPEN_TIME := 1.1     # el reloj se abre (revela la escena nueva)
const SHADER := preload("res://assets/shaders/clock_wipe.gdshader")

var _veil: ColorRect
var _mat: ShaderMaterial
var _busy := false

func _ready() -> void:
	layer = 128            # arriba de cualquier UI
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
	_veil.size = size
	_mat.set_shader_parameter("aspect", size.x / size.y)

## Cambia de escena con el barrido de reloj:
## cierra (tapa) → aguanta → carga la escena → abre (revela).
func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await _wipe(1.0, CLOSE_TIME)                        # el reloj se cierra
	await get_tree().create_timer(HOLD).timeout
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame                     # dejar que la nueva escena se instancie
	await _wipe(0.0, OPEN_TIME)                         # el reloj se abre
	_busy = false

func _wipe(to: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(_veil, "material:shader_parameter/progress", to, dur)
	await tw.finished
