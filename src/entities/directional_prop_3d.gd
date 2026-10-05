class_name DirectionalProp3D
extends AnimatedSprite3D

## DirectionalProp3D
## Provides full 8-directional camera perspective tracking for environment props
## (trees, bushes, tall grass stalks).
## As the camera orbits or rotates in 3D space, this prop dynamically updates its
## animation to display the authentic directional view corresponding to the viewing
## angle (e.g. sway_south, sway_south-west, sway_west, sway_north-west, sway_north,
## sway_north-east, sway_east, sway_south-east).
## Preserves animation playback frame and cycle timing during direction transitions.

@export var anim_prefix: String = "sway"
@export var world_facing_yaw: float = 0.0 # Prop's intrinsic world orientation in radians
@export var has_8_directions: bool = true

var _current_direction: String = "south"
var _last_cam_pos: Vector3 = Vector3.INF
var _last_cam_yaw: float = -999.0

func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _ready() -> void:
	_update_direction_from_camera(null, true)

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var cam: Camera3D = vp.get_camera_3d()
	if cam == null or not cam.is_inside_tree():
		return
	_update_direction_from_camera(cam, false)

func get_current_direction() -> String:
	return _current_direction

func set_world_facing_yaw(yaw: float) -> void:
	world_facing_yaw = yaw
	_update_direction_from_camera(null, true)

func update_camera_direction_manual(cam: Camera3D) -> void:
	if cam == null:
		return
	var cam_pos: Vector3 = cam.global_position if cam.is_inside_tree() else cam.position
	var self_pos: Vector3 = global_position if is_inside_tree() else position
	var to_cam: Vector3 = cam_pos - self_pos
	to_cam.y = 0.0
	var dir_norm: Vector3 = to_cam.normalized() if to_cam.length_squared() >= 0.0001 else Vector3(0, 0, 1)

	var prop_forward: Vector3 = Vector3(sin(world_facing_yaw), 0.0, cos(world_facing_yaw))
	var prop_right: Vector3 = Vector3(cos(world_facing_yaw), 0.0, -sin(world_facing_yaw))

	var local_x: float = dir_norm.dot(prop_right)
	var local_z: float = dir_norm.dot(prop_forward)

	_current_direction = _vector_to_direction(local_x, local_z)
	_apply_animation()

func _update_direction_from_camera(cam: Camera3D = null, force: bool = false) -> void:
	if cam == null and is_inside_tree() and get_viewport() != null:
		cam = get_viewport().get_camera_3d()

	if cam == null or not cam.is_inside_tree():
		if force and sprite_frames != null:
			_apply_animation()
		return

	var cam_pos: Vector3 = cam.global_position
	var cam_yaw: float = cam.global_rotation.y

	# Skip calculation if camera hasn't moved or rotated noticeably
	if not force and absf(cam_yaw - _last_cam_yaw) < 0.002 and cam_pos.distance_squared_to(_last_cam_pos) < 0.005:
		return

	_last_cam_pos = cam_pos
	_last_cam_yaw = cam_yaw

	var self_pos: Vector3 = global_position if is_inside_tree() else position
	var to_cam: Vector3 = cam_pos - self_pos
	to_cam.y = 0.0

	var dir_norm: Vector3
	if to_cam.length_squared() < 0.0001:
		# Directly underneath or overlapping, use camera backward ray
		dir_norm = cam.global_transform.basis.z
		dir_norm.y = 0.0
		if dir_norm.length_squared() < 0.0001:
			dir_norm = Vector3(0, 0, 1)
		else:
			dir_norm = dir_norm.normalized()
	else:
		dir_norm = to_cam.normalized()

	# Project viewing ray onto prop's local coordinate frame
	# When world_facing_yaw = 0: prop forward is South (+Z), right is East (+X)
	var prop_forward: Vector3 = Vector3(sin(world_facing_yaw), 0.0, cos(world_facing_yaw))
	var prop_right: Vector3 = Vector3(cos(world_facing_yaw), 0.0, -sin(world_facing_yaw))

	var local_x: float = dir_norm.dot(prop_right)
	var local_z: float = dir_norm.dot(prop_forward)

	var new_dir: String = _vector_to_direction(local_x, local_z)
	if new_dir != _current_direction or force:
		_current_direction = new_dir
		_apply_animation()

func _vector_to_direction(x: float, z: float) -> String:
	# In top-down isometric projection:
	# +Z = South (towards camera)
	# -Z = North (away from camera)
	# +X = East (right)
	# -X = West (left)
	var angle: float = atan2(z, x)
	var deg: float = rad_to_deg(angle)

	if deg >= -22.5 and deg < 22.5:
		return "east"
	elif deg >= 22.5 and deg < 67.5:
		return "south-east"
	elif deg >= 67.5 and deg < 112.5:
		return "south"
	elif deg >= 112.5 and deg < 157.5:
		return "south-west"
	elif deg >= -67.5 and deg < -22.5:
		return "north-east"
	elif deg >= -112.5 and deg < -67.5:
		return "north"
	elif deg >= -157.5 and deg < -112.5:
		return "north-west"
	else:
		return "west"

func _apply_animation() -> void:
	if sprite_frames == null:
		return

	var target_anim: String = "%s_%s" % [anim_prefix, _current_direction]
	if not sprite_frames.has_animation(target_anim):
		if sprite_frames.has_animation(anim_prefix):
			target_anim = anim_prefix
		elif sprite_frames.has_animation("default"):
			target_anim = "default"
		else:
			var all_names: PackedStringArray = sprite_frames.get_animation_names()
			if all_names.size() > 0:
				target_anim = all_names[0]
			else:
				return

	if animation != target_anim:
		var cur_frame: int = frame
		var cur_progress: float = frame_progress
		play(target_anim)
		var max_f: int = sprite_frames.get_frame_count(target_anim)
		if max_f > 0:
			frame = cur_frame % max_f
			frame_progress = cur_progress
	elif not is_playing():
		play(target_anim)
