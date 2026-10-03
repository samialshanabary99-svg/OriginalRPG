class_name Player3D
extends CharacterBody3D

## Hybrid 3D Player controller for OriginalRPG.
## Combines 3D physics movement & collision with 2D animated pixel-art billboard sprites (Ragnarok Online style).
##
## Decoupled Architecture (ADR-002 & ADR-006):
##   - Stats handled by CharacterStatsComponent
##   - Inventory handled by InventoryComponent
##   - Equipment handled by EquipmentComponent
##   - Visuals handled by AnimatedSprite3D in Y-Billboard mode

signal player_moved_3d(position: Vector3)
signal player_attacked()
signal facing_changed_3d(direction: Vector3)
signal target_changed(new_target: Node)
signal combat_resolved(result: CombatResult)

enum CharacterState {
	ALIVE,
	DEAD,
	STUNNED,
	CASTING,
}

@export var move_speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var attack_cooldown: float = 0.6

@onready var stats: CharacterStatsComponent = $CharacterStatsComponent:
	get:
		if stats == null and has_node("CharacterStatsComponent"):
			stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
		return stats

@onready var inventory: InventoryComponent = $InventoryComponent:
	get:
		if inventory == null and has_node("InventoryComponent"):
			inventory = get_node_or_null("InventoryComponent") as InventoryComponent
		return inventory

@onready var equipment: EquipmentComponent = $EquipmentComponent:
	get:
		if equipment == null and has_node("EquipmentComponent"):
			equipment = get_node_or_null("EquipmentComponent") as EquipmentComponent
		return equipment

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D:
	get:
		if animated_sprite == null and has_node("AnimatedSprite3D"):
			animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		return animated_sprite

@onready var camera_arm: Node3D = $CameraArm if has_node("CameraArm") else null:
	get:
		if camera_arm == null and has_node("CameraArm"):
			camera_arm = get_node_or_null("CameraArm") as Node3D
		return camera_arm

@onready var camera: Camera3D = $CameraArm/Camera3D if has_node("CameraArm/Camera3D") else null:
	get:
		if camera == null and has_node("CameraArm/Camera3D"):
			camera = get_node_or_null("CameraArm/Camera3D") as Camera3D
		return camera

# ── Ragnarok Online Style Orbit Camera Configuration ──────────────────────────
@export var camera_distance_default: float = 12.1
@export var camera_pitch_default: float = deg_to_rad(38.0)
@export var camera_yaw_default: float = 0.0

@export var zoom_min: float = 4.0
@export var zoom_max: float = 24.0
@export var zoom_step: float = 1.4

@export var pitch_min: float = deg_to_rad(28.0)
@export var pitch_max: float = deg_to_rad(68.0)

@export var orbit_sensitivity: float = 0.005
@export var pitch_sensitivity: float = 0.004
@export var camera_smooth_speed: float = 14.0

var _target_yaw: float = 0.0
var _current_yaw: float = 0.0
var _target_pitch: float = deg_to_rad(38.0)
var _current_pitch: float = deg_to_rad(38.0)
var _target_zoom: float = 12.1
var _current_zoom: float = 12.1
var _is_orbiting: bool = false
var _last_rmb_time: float = 0.0
const DOUBLE_CLICK_INTERVAL: float = 0.28

@onready var shadow: MeshInstance3D = $Shadow if has_node("Shadow") else null:
	get:
		if shadow == null and has_node("Shadow"):
			shadow = get_node_or_null("Shadow") as MeshInstance3D
		return shadow

var input_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector3 = Vector3(0, 0, 1) # Default facing South (+Z)
var character_state: CharacterState = CharacterState.ALIVE
var current_target: Node = null
var last_combat_result: CombatResult = null

var _attack_timer: float = 0.0
var _gravity: float = 14.0

func _enter_tree() -> void:
	_resolve_nodes()
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(52.0)
	floor_constant_speed = true
	floor_block_on_wall = true

func _ready() -> void:
	_resolve_nodes()
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(52.0)
	floor_constant_speed = true
	floor_block_on_wall = true
	
	if stats != null:
		if not stats.died.is_connected(_on_player_died):
			stats.died.connect(_on_player_died)
		ContentRegistry.ensure_initialized()
		var default_char: CharacterDefinition = ContentRegistry.get_character("player_default")
		if default_char != null:
			init_from_character_id("player_default")

	_update_animation("south")
	_setup_shadow()
	_update_camera(0.0)

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	_resolve_nodes()
	if camera_arm == null or camera == null:
		return

	if delta > 0.0:
		_current_yaw = lerp_angle(_current_yaw, _target_yaw, camera_smooth_speed * delta)
		_current_pitch = lerpf(_current_pitch, _target_pitch, camera_smooth_speed * delta)
		_current_zoom = lerpf(_current_zoom, _target_zoom, camera_smooth_speed * delta)
	else:
		_current_yaw = _target_yaw
		_current_pitch = _target_pitch
		_current_zoom = _target_zoom

	camera_arm.rotation.y = _current_yaw

	var desired_cam_pos: Vector3 = Vector3(
		0.0,
		sin(_current_pitch) * _current_zoom,
		cos(_current_pitch) * _current_zoom
	)

	# Ground clearance check: prevent camera from ever sinking beneath the terrain or viewing mesh underside
	if is_inside_tree() and get_parent() != null and get_parent().has_method("_calculate_height"):
		var world_cam_pos: Vector3 = camera_arm.global_transform * desired_cam_pos
		var terrain_h: float = get_parent()._calculate_height(world_cam_pos.x, world_cam_pos.z)
		var min_world_y: float = terrain_h + 1.2
		if world_cam_pos.y < min_world_y:
			var diff_y: float = min_world_y - world_cam_pos.y
			desired_cam_pos.y += diff_y

	camera.position = desired_cam_pos
	camera.rotation.x = -_current_pitch

func reset_camera_view() -> void:
	_target_yaw = camera_yaw_default
	_target_pitch = camera_pitch_default
	_target_zoom = camera_distance_default

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				var current_time: float = Time.get_ticks_msec() / 1000.0
				var ctrl_held: bool = Input.is_key_pressed(KEY_CTRL)
				# Double right-click or Ctrl+RMB resets camera to default view (Ragnarok Online style)
				if ctrl_held or (current_time - _last_rmb_time < DOUBLE_CLICK_INTERVAL):
					reset_camera_view()
					_is_orbiting = false
				else:
					_is_orbiting = true
				_last_rmb_time = current_time
			else:
				_is_orbiting = false

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)
			var ctrl_held: bool = Input.is_key_pressed(KEY_CTRL)
			if shift_held or ctrl_held:
				# Shift/Ctrl + Mouse Wheel adjusts vertical view angle (pitch)
				_target_pitch = clampf(_target_pitch + deg_to_rad(3.5), pitch_min, pitch_max)
			else:
				# Normal Wheel zooms in
				_target_zoom = clampf(_target_zoom - zoom_step, zoom_min, zoom_max)

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)
			var ctrl_held: bool = Input.is_key_pressed(KEY_CTRL)
			if shift_held or ctrl_held:
				# Shift/Ctrl + Mouse Wheel adjusts vertical view angle (pitch)
				_target_pitch = clampf(_target_pitch - deg_to_rad(3.5), pitch_min, pitch_max)
			else:
				# Normal Wheel zooms out
				_target_zoom = clampf(_target_zoom + zoom_step, zoom_min, zoom_max)

	elif event is InputEventMouseMotion and _is_orbiting:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)
		var ctrl_held: bool = Input.is_key_pressed(KEY_CTRL)

		# Horizontal mouse motion rotates the camera orbit around character (Yaw)
		_target_yaw -= mm.relative.x * orbit_sensitivity

		# Vertical mouse motion adjusts the elevation angle of view (Pitch)
		if shift_held or ctrl_held:
			# Shift or Ctrl focuses and boosts pitch adjustment
			_target_pitch = clampf(_target_pitch + mm.relative.y * pitch_sensitivity * 1.5, pitch_min, pitch_max)
		else:
			# Standard RMB drag adjusts both rotation and vertical angle
			_target_pitch = clampf(_target_pitch + mm.relative.y * pitch_sensitivity, pitch_min, pitch_max)

func _setup_shadow() -> void:
	if shadow == null:
		return
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0.0, 0.0, 0.0, 0.42), Color(0.0, 0.0, 0.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])

	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64

	mat.albedo_texture = tex
	shadow.material_override = mat

func _resolve_nodes() -> void:
	if stats == null: stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if inventory == null: inventory = get_node_or_null("InventoryComponent") as InventoryComponent
	if equipment == null: equipment = get_node_or_null("EquipmentComponent") as EquipmentComponent
	if animated_sprite == null: animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if camera_arm == null: camera_arm = get_node_or_null("CameraArm") as Node3D
	if camera == null: camera = get_node_or_null("CameraArm/Camera3D") as Camera3D
	if shadow == null: shadow = get_node_or_null("Shadow") as MeshInstance3D

func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)

	if character_state == CharacterState.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)
		if not is_on_floor():
			velocity.y -= _gravity * delta
		if is_inside_tree():
			move_and_slide()
		else:
			position += velocity * delta
		return

	# Handle gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	# Read movement input (WASD / Arrows)
	var raw_x: float = Input.get_axis("move_left", "move_right")
	var raw_z: float = Input.get_axis("move_up", "move_down")
	if is_zero_approx(raw_x):
		raw_x = Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(raw_z):
		raw_z = Input.get_axis("ui_up", "ui_down")
	input_direction = Vector2(raw_x, raw_z)

	# Compute camera-relative movement vectors so WASD follows camera orientation
	var cam_yaw: float = camera_arm.rotation.y if camera_arm != null else 0.0
	var cam_forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw)).normalized()
	var cam_right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw)).normalized()

	var move_dir: Vector3 = cam_right * raw_x + cam_forward * (-raw_z)
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()

	if move_dir.length_squared() > 0.01:
		facing_direction = move_dir
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		emit_signal("facing_changed_3d", facing_direction)
		var current_pos: Vector3 = global_position if is_inside_tree() else position
		emit_signal("player_moved_3d", current_pos)

		# Screen-relative billboard facing (Ragnarok Online style)
		var screen_x: float = move_dir.dot(cam_right)
		var screen_z: float = -move_dir.dot(cam_forward)
		var dir_str: String = _vector_to_direction(Vector3(screen_x, 0.0, screen_z))
		_update_animation(dir_str)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)

	if Input.is_action_just_pressed("attack"):
		_try_attack()

	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * delta

func _update_animation(dir_name: String) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var anim_name: String = "idle_" + dir_name
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _vector_to_direction(vec: Vector3) -> String:
	# In Godot 3D top-down isometric:
	# +Z = South (towards camera)
	# -Z = North (away from camera)
	# +X = East (right)
	# -X = West (left)
	var angle: float = atan2(vec.z, vec.x)
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

func init_from_character_id(char_id: String) -> bool:
	_resolve_nodes()
	if stats == null:
		return false
	var def: CharacterDefinition = ContentRegistry.get_character(char_id)
	if def == null:
		return false
	stats.definition = def
	stats._apply_definition()
	stats._recompute_final_stats()
	return true

func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length_squared() > 0.01

func attack() -> void:
	if _attack_timer > 0.0 or character_state != CharacterState.ALIVE:
		return
	_attack_timer = attack_cooldown
	emit_signal("player_attacked")

func _try_attack() -> void:
	attack()

func _on_player_died() -> void:
	character_state = CharacterState.DEAD
	velocity = Vector3.ZERO
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("dead"):
		animated_sprite.play("dead")
