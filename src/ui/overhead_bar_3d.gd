class_name OverheadBar3D
extends MeshInstance3D

## Overhead floating 3D health and SP bar for Ragnarok Online / Octopath style presentation.
## Uses an unshaded billboard shader to remain pixel-sharp, always oriented to the camera,
## and depth-priority rendered above entity sprites.

@export var bar_width: float = 0.65
@export var bar_height: float = 0.08
@export var show_sp: bool = false

var _mat: ShaderMaterial = null
var _current_hp_ratio: float = 1.0
var _current_sp_ratio: float = 1.0

func _ready() -> void:
	_setup_mesh()

func _setup_mesh() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(bar_width, bar_height)
	mesh = qm

	var shader: Shader = load("res://assets/shaders/overhead_bar.gdshader") as Shader
	if shader != null:
		_mat = ShaderMaterial.new()
		_mat.shader = shader
		_mat.render_priority = 10
		_mat.set_shader_parameter("show_sp", show_sp)
		_mat.set_shader_parameter("hp_ratio", _current_hp_ratio)
		_mat.set_shader_parameter("sp_ratio", _current_sp_ratio)
		material_override = _mat

func set_health(current: int, maximum: int) -> void:
	var ratio: float = 0.0
	if maximum > 0:
		ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	_current_hp_ratio = ratio
	if _mat != null:
		_mat.set_shader_parameter("hp_ratio", _current_hp_ratio)

func set_mana(current: int, maximum: int) -> void:
	var ratio: float = 0.0
	if maximum > 0:
		ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	_current_sp_ratio = ratio
	if _mat != null:
		_mat.set_shader_parameter("sp_ratio", _current_sp_ratio)

func set_show_sp(active: bool) -> void:
	show_sp = active
	if _mat != null:
		_mat.set_shader_parameter("show_sp", show_sp)

func get_hp_ratio() -> float:
	return _current_hp_ratio

func get_sp_ratio() -> float:
	return _current_sp_ratio
