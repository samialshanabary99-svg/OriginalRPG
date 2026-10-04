class_name CellCursor3D
extends Node3D

## Ragnarok Online style green cell square target preview for ground click-to-move.
## Aligns to terrain elevation/normal, pulses on click, and tracks active destination.

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D if has_node("MeshInstance3D") else null

var _is_active: bool = false
var _alpha: float = 1.0
var _pulse_time: float = 0.0
var _mat: StandardMaterial3D = null

func _ready() -> void:
	if mesh_instance == null and has_node("MeshInstance3D"):
		mesh_instance = get_node("MeshInstance3D") as MeshInstance3D

	if mesh_instance != null:
		var tex: Texture2D = load("res://assets/ui/cursors/cell_target_cursor.png") as Texture2D
		_mat = StandardMaterial3D.new()
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.render_priority = 5
		_mat.albedo_texture = tex
		_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		mesh_instance.material_override = _mat

	visible = false

func set_target_cell(pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	visible = true
	_is_active = true
	_alpha = 1.0
	_pulse_time = 0.0
	scale = Vector3(1.25, 1.25, 1.25)

	# Place slightly above terrain surface along ground normal
	var target_pos: Vector3 = pos + normal * 0.03
	if is_inside_tree():
		global_position = target_pos
	else:
		position = target_pos

	# Orient mesh flat along terrain normal
	if normal.length_squared() > 0.01 and not normal.is_equal_approx(Vector3.UP):
		var v_up: Vector3 = normal.normalized()
		var v_fwd: Vector3 = Vector3.FORWARD
		if abs(v_up.dot(v_fwd)) > 0.9:
			v_fwd = Vector3.RIGHT
		var v_right: Vector3 = v_fwd.cross(v_up).normalized()
		v_fwd = v_up.cross(v_right).normalized()
		if is_inside_tree():
			global_basis = Basis(v_right, v_up, v_fwd)
		else:
			basis = Basis(v_right, v_up, v_fwd)
	else:
		if is_inside_tree():
			global_basis = Basis.IDENTITY
		else:
			basis = Basis.IDENTITY

	if _mat != null:
		_mat.albedo_color.a = 1.0

func hide_target() -> void:
	_is_active = false

func _process(delta: float) -> void:
	if not visible:
		return

	if _is_active:
		_pulse_time += delta
		# Settle scale down from initial click punch
		scale = scale.move_toward(Vector3.ONE, delta * 3.5)
		# Gentle breathing pulse
		var pulse: float = 0.88 + sin(_pulse_time * 6.0) * 0.12
		if _mat != null:
			_mat.albedo_color.a = pulse
	else:
		# Fade out when destination reached
		_alpha = move_toward(_alpha, 0.0, delta * 4.0)
		if _mat != null:
			_mat.albedo_color.a = _alpha
		if _alpha <= 0.01:
			visible = false
