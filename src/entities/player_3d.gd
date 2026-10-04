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

# ── Mouse Click-to-Move & Aim Targeting (Ragnarok Online Style) ───────────────
@export var stop_threshold: float = 0.25
@export var attack_reach: float = 2.0 # Legacy fallback
@export var body_radius: float = 0.35
@export var melee_attack_range: float = 0.40
@export var debug_combat_gizmos: bool = false

var move_target_position: Vector3 = Vector3.ZERO
var has_move_target: bool = false
var target_enemy_node: Node3D = null
var cell_cursor: CellCursor3D = null

var _is_lmb_down: bool = false
var _hovered_enemy: Enemy3D = null

var input_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector3 = Vector3(0, 0, 1) # Default facing South (+Z)
var character_state: CharacterState = CharacterState.ALIVE
var current_target: Node = null
var last_combat_result: CombatResult = null

var _attack_timer: float = 0.0
var _damage_timer: float = 0.0
var _current_direction: String = "south"
var _gravity: float = 14.0
var _cam_clearance_y: float = 0.0

var _attack_target_node: Node = null
var _attack_has_hit: bool = false
var _attack_lunge_done: bool = false
var _debug_mesh_instance: MeshInstance3D = null

func _enter_tree() -> void:
	_resolve_nodes()
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(55.0)
	floor_constant_speed = true
	floor_block_on_wall = true
	floor_stop_on_slope = true

func _exit_tree() -> void:
	clear_target_enemy()
	if cell_cursor != null and is_instance_valid(cell_cursor) and cell_cursor.get_parent() != self:
		cell_cursor.queue_free()
		cell_cursor = null

func _ready() -> void:
	add_to_group("player")
	_resolve_nodes()
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(55.0)
	floor_constant_speed = true
	floor_block_on_wall = true
	floor_stop_on_slope = true
	
	if animated_sprite != null and not animated_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		animated_sprite.frame_changed.connect(_on_sprite_frame_changed)

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
	_ensure_cell_cursor()

func _process(delta: float) -> void:
	_update_camera(delta)
	_update_debug_gizmos()

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
		var target_diff: float = maxf(0.0, min_world_y - world_cam_pos.y)
		if delta > 0.0:
			_cam_clearance_y = lerpf(_cam_clearance_y, target_diff, clampf(camera_smooth_speed * delta, 0.0, 1.0))
		else:
			_cam_clearance_y = target_diff
		desired_cam_pos.y += _cam_clearance_y

	camera.position = desired_cam_pos
	camera.rotation.x = -_current_pitch

func reset_camera_view() -> void:
	_target_yaw = camera_yaw_default
	_target_pitch = camera_pitch_default
	_target_zoom = camera_distance_default

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _is_mouse_over_ui():
					return
				_is_lmb_down = true
				_handle_mouse_click(mb.position)
			else:
				_is_lmb_down = false

		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
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

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _is_orbiting:
			var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)
			var ctrl_held: bool = Input.is_key_pressed(KEY_CTRL)

			# Horizontal mouse motion rotates the camera orbit around character (Yaw)
			_target_yaw -= mm.relative.x * orbit_sensitivity

			# Vertical mouse motion adjusts the elevation angle of view (Pitch)
			if shift_held or ctrl_held:
				_target_pitch = clampf(_target_pitch + mm.relative.y * pitch_sensitivity * 1.5, pitch_min, pitch_max)
			else:
				_target_pitch = clampf(_target_pitch + mm.relative.y * pitch_sensitivity, pitch_min, pitch_max)
		elif _is_lmb_down:
			if not _is_mouse_over_ui():
				_handle_mouse_drag(mm.position)
		else:
			_update_enemy_hover(mm.position)

func _setup_shadow() -> void:
	if shadow == null:
		return
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.render_priority = 2
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.35)

	var tex: Texture2D = load("res://assets/environment/shadows/shadow_oval_soft.png") as Texture2D
	if tex != null:
		mat.albedo_texture = tex
	shadow.material_override = mat
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if _damage_timer > 0.0:
		_damage_timer = maxf(0.0, _damage_timer - delta)

	if character_state == CharacterState.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)
		if not is_on_floor():
			velocity.y -= _gravity * delta
		if is_inside_tree():
			move_and_slide()
		else:
			position += velocity * delta
		_update_animation()
		return

	# Handle gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	var cam_yaw: float = camera_arm.rotation.y if camera_arm != null else 0.0
	var cam_forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw)).normalized()
	var cam_right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw)).normalized()

	# ── Priority 1: Target Enemy Pursuit & Auto-Attack Loop ────────────────────
	if target_enemy_node != null and is_instance_valid(target_enemy_node):
		var enemy_dead: bool = false
		if "current_state" in target_enemy_node and target_enemy_node.current_state == Enemy3D.State.DEAD:
			enemy_dead = true
		elif target_enemy_node.has_method("is_dead") and target_enemy_node.is_dead():
			enemy_dead = true

		if enemy_dead:
			clear_target_enemy()
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
			input_direction = Vector2.ZERO
		else:
			var self_pos: Vector3 = global_position if is_inside_tree() else position
			var enemy_pos: Vector3 = target_enemy_node.global_position if target_enemy_node.is_inside_tree() else target_enemy_node.position
			var edge_dist: float = get_edge_distance_to(target_enemy_node)

			# Face target enemy at all times while engaging in combat
			face_target(enemy_pos)

			if edge_dist > melee_attack_range:
				# Chase towards enemy
				var diff: Vector3 = enemy_pos - self_pos
				diff.y = 0.0
				var move_dir: Vector3 = diff.normalized()
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
				input_direction = Vector2(velocity.x, velocity.z).normalized()
				emit_signal("player_moved_3d", self_pos)
			else:
				# In melee range - halt immediately and attack
				velocity.x = 0.0
				velocity.z = 0.0
				input_direction = Vector2.ZERO
				if _attack_timer <= 0.0:
					attack()

	# ── Priority 2: Ground Destination Movement ───────────────────────────────
	elif has_move_target:
		var self_pos: Vector3 = global_position if is_inside_tree() else position
		var to_dest: Vector3 = move_target_position - self_pos
		to_dest.y = 0.0
		var dist_to_dest: float = to_dest.length()

		if dist_to_dest <= stop_threshold:
			has_move_target = false
			velocity.x = 0.0
			velocity.z = 0.0
			input_direction = Vector2.ZERO
			if cell_cursor != null and is_instance_valid(cell_cursor):
				cell_cursor.hide_target()
		else:
			var move_dir: Vector3 = to_dest.normalized()
			facing_direction = move_dir
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			input_direction = Vector2(velocity.x, velocity.z).normalized()
			emit_signal("facing_changed_3d", facing_direction)
			emit_signal("player_moved_3d", self_pos)

			var screen_x: float = move_dir.dot(cam_right)
			var screen_z: float = -move_dir.dot(cam_forward)
			_current_direction = _vector_to_direction(Vector3(screen_x, 0.0, screen_z))

	# ── Idle Deceleration ─────────────────────────────────────────────────────
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
		input_direction = Vector2.ZERO

	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * delta

	# Align ground shadow flush with terrain surface and slope
	if shadow != null and is_inside_tree():
		if is_on_floor():
			var fn: Vector3 = get_floor_normal()
			if fn.length_squared() > 0.1 and not fn.is_equal_approx(Vector3.UP):
				var v_up: Vector3 = fn.normalized()
				var v_fwd: Vector3 = Vector3.FORWARD
				if abs(v_up.dot(v_fwd)) > 0.9:
					v_fwd = Vector3.RIGHT
				var v_right: Vector3 = v_fwd.cross(v_up).normalized()
				v_fwd = v_up.cross(v_right).normalized()
				shadow.global_basis = Basis(v_right, v_up, v_fwd)
				shadow.global_position = global_position + v_up * 0.02
			else:
				shadow.position = Vector3(0.0, 0.02, 0.0)
				shadow.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)

	_update_animation()

func _is_mouse_over_ui() -> bool:
	var vp: Viewport = get_viewport()
	if vp != null:
		var hovered: Control = vp.gui_get_hovered_control()
		if hovered != null and hovered.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return true
	return false

func _raycast_from_mouse(mouse_pos: Vector2, mask_val: int = 6) -> Dictionary:
	_resolve_nodes()
	if camera == null or not is_inside_tree():
		return {}
	var w3d: World3D = get_world_3d()
	if w3d == null:
		return {}
	var space_state: PhysicsDirectSpaceState3D = w3d.direct_space_state
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_pos)
	var ray_length: float = 300.0

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_normal * ray_length,
		mask_val
	)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	return space_state.intersect_ray(query)

func _extract_enemy(collider: Object) -> Enemy3D:
	if collider == null:
		return null
	if collider is Enemy3D:
		return collider as Enemy3D
	if collider is Node:
		var node: Node = collider as Node
		if node.get_parent() is Enemy3D:
			return node.get_parent() as Enemy3D
		if node.is_in_group("enemies") and node is CharacterBody3D:
			return node as Enemy3D
	return null

func _handle_mouse_click(mouse_pos: Vector2) -> void:
	if character_state == CharacterState.DEAD:
		return
	# Raycast mask 6 = 2 (terrain) + 4 (enemies)
	var hit: Dictionary = _raycast_from_mouse(mouse_pos, 6)
	if hit.is_empty():
		return

	var collider: Object = hit.get("collider")
	var hit_enemy: Enemy3D = _extract_enemy(collider)

	if hit_enemy != null and is_instance_valid(hit_enemy) and hit_enemy.current_state != Enemy3D.State.DEAD:
		target_enemy(hit_enemy)
	else:
		var hit_pos: Vector3 = hit.get("position", Vector3.ZERO)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		if get_parent() != null and get_parent().has_method("_calculate_height"):
			hit_pos.y = get_parent()._calculate_height(hit_pos.x, hit_pos.z)
		clear_target_enemy()
		set_move_destination(hit_pos, hit_normal)

func _handle_mouse_drag(mouse_pos: Vector2) -> void:
	if character_state == CharacterState.DEAD:
		return
	if target_enemy_node != null and is_instance_valid(target_enemy_node):
		return
	var hit: Dictionary = _raycast_from_mouse(mouse_pos, 2)
	if hit.is_empty():
		return
	var hit_pos: Vector3 = hit.get("position", Vector3.ZERO)
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
	if get_parent() != null and get_parent().has_method("_calculate_height"):
		hit_pos.y = get_parent()._calculate_height(hit_pos.x, hit_pos.z)
	set_move_destination(hit_pos, hit_normal)

func _update_enemy_hover(mouse_pos: Vector2) -> void:
	if _is_mouse_over_ui():
		_clear_hovered_enemy()
		return
	var hit: Dictionary = _raycast_from_mouse(mouse_pos, 4)
	var new_hover: Enemy3D = null
	if not hit.is_empty():
		new_hover = _extract_enemy(hit.get("collider"))
		if new_hover != null and (!is_instance_valid(new_hover) or new_hover.current_state == Enemy3D.State.DEAD):
			new_hover = null

	if new_hover != _hovered_enemy:
		_clear_hovered_enemy()
		_hovered_enemy = new_hover
		if _hovered_enemy != null and is_instance_valid(_hovered_enemy):
			if _hovered_enemy != target_enemy_node:
				_hovered_enemy.set_hovered(true)

func _clear_hovered_enemy() -> void:
	if _hovered_enemy != null and is_instance_valid(_hovered_enemy):
		if _hovered_enemy != target_enemy_node:
			_hovered_enemy.set_hovered(false)
	_hovered_enemy = null

func target_enemy(enemy: Enemy3D) -> void:
	if target_enemy_node != null and is_instance_valid(target_enemy_node) and target_enemy_node != enemy:
		if target_enemy_node.has_method("set_targeted"):
			target_enemy_node.set_targeted(false)

	target_enemy_node = enemy
	current_target = enemy
	has_move_target = false

	if cell_cursor != null and is_instance_valid(cell_cursor):
		cell_cursor.hide_target()

	if target_enemy_node != null and is_instance_valid(target_enemy_node):
		if target_enemy_node.has_method("set_targeted"):
			target_enemy_node.set_targeted(true)
		emit_signal("target_changed", target_enemy_node)

func clear_target_enemy() -> void:
	if target_enemy_node != null and is_instance_valid(target_enemy_node):
		if target_enemy_node.has_method("set_targeted"):
			target_enemy_node.set_targeted(false)
	target_enemy_node = null
	current_target = null
	emit_signal("target_changed", null)

func set_move_destination(pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	clear_target_enemy()
	move_target_position = pos
	has_move_target = true
	_ensure_cell_cursor()
	if cell_cursor != null and is_instance_valid(cell_cursor):
		cell_cursor.set_target_cell(pos, normal)

func stop_moving() -> void:
	has_move_target = false
	velocity.x = 0.0
	velocity.z = 0.0
	input_direction = Vector2.ZERO
	if cell_cursor != null and is_instance_valid(cell_cursor):
		cell_cursor.hide_target()

func _ensure_cell_cursor() -> void:
	if cell_cursor != null and is_instance_valid(cell_cursor):
		return
	var scene: PackedScene = load("res://scenes/entities/cell_cursor_3d.tscn") as PackedScene
	if scene != null:
		cell_cursor = scene.instantiate() as CellCursor3D
		if get_parent() != null:
			get_parent().add_child.call_deferred(cell_cursor)
		elif is_inside_tree():
			get_tree().root.add_child.call_deferred(cell_cursor)

func _update_animation(dir_name: String = "") -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not dir_name.is_empty():
		_current_direction = dir_name

	var anim_prefix: String = "idle"
	if character_state == CharacterState.DEAD:
		anim_prefix = "die"
	elif _damage_timer > 0.0:
		anim_prefix = "damage"
	elif _attack_timer > 0.0:
		anim_prefix = "attack"
	elif is_moving():
		anim_prefix = "walk"
	else:
		anim_prefix = "idle"

	# If dead and death animation finished, switch to static "dead" frame
	if character_state == CharacterState.DEAD and animated_sprite.animation.begins_with("die") and not animated_sprite.is_playing():
		if animated_sprite.sprite_frames.has_animation("dead"):
			animated_sprite.play("dead")
			return

	var anim_name: String = "%s_%s" % [anim_prefix, _current_direction]
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames.has_animation(anim_prefix):
		if animated_sprite.animation != anim_prefix or not animated_sprite.is_playing():
			animated_sprite.play(anim_prefix)
	elif animated_sprite.sprite_frames.has_animation("idle_" + _current_direction):
		animated_sprite.play("idle_" + _current_direction)
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

func get_edge_distance_to(target: Node3D) -> float:
	if target == null:
		return 999.0
	var self_pos: Vector3 = global_position if is_inside_tree() else position
	var target_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
	var diff: Vector3 = target_pos - self_pos
	diff.y = 0.0
	var center_dist: float = diff.length()
	var target_radius: float = 0.35
	if "body_radius" in target:
		target_radius = target.body_radius
	return maxf(0.0, center_dist - (body_radius + target_radius))

func face_target(target_pos: Vector3) -> void:
	var self_pos: Vector3 = global_position if is_inside_tree() else position
	var diff: Vector3 = target_pos - self_pos
	diff.y = 0.0
	if diff.length_squared() < 0.001:
		return
	var dir_norm: Vector3 = diff.normalized()
	facing_direction = dir_norm

	var cam: Camera3D = null
	if camera != null and camera.is_inside_tree():
		cam = camera
	elif is_inside_tree() and get_viewport() != null:
		cam = get_viewport().get_camera_3d()

	var screen_x: float = dir_norm.x
	var screen_z: float = dir_norm.z

	if cam != null and cam.is_inside_tree():
		var cam_yaw: float = cam.global_rotation.y
		var cam_forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw)).normalized()
		var cam_right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw)).normalized()
		screen_x = dir_norm.dot(cam_right)
		screen_z = -dir_norm.dot(cam_forward)

	_current_direction = _vector_to_direction(Vector3(screen_x, 0.0, screen_z))
	emit_signal("facing_changed_3d", facing_direction)
	_update_animation()

func apply_knockback(_impulse: Vector3) -> void:
	pass

func attack() -> void:
	if _attack_timer > 0.0 or character_state != CharacterState.ALIVE:
		return
	_attack_timer = attack_cooldown
	_attack_has_hit = false
	_attack_lunge_done = false
	emit_signal("player_attacked")

	var target_enemy: Node = target_enemy_node if target_enemy_node != null else current_target
	if target_enemy == null or not is_instance_valid(target_enemy):
		target_enemy = _find_nearest_enemy_in_reach(melee_attack_range + 0.3)

	_attack_target_node = target_enemy
	if _attack_target_node != null and is_instance_valid(_attack_target_node) and _attack_target_node is Node3D:
		var t_pos: Vector3 = (_attack_target_node as Node3D).global_position if (_attack_target_node as Node3D).is_inside_tree() else (_attack_target_node as Node3D).position
		face_target(t_pos)

	_update_animation()

func _on_sprite_frame_changed() -> void:
	if animated_sprite == null:
		return
	var anim: String = animated_sprite.animation
	if not anim.begins_with("attack"):
		return

	var cur_frame: int = animated_sprite.frame

	# Wind-up lunge on frames 1-3 toward target (~0.12m)
	if (cur_frame >= 1 and cur_frame <= 3) and not _attack_lunge_done:
		_attack_lunge_done = true
		if _attack_target_node != null and is_instance_valid(_attack_target_node) and _attack_target_node is Node3D:
			var self_pos: Vector3 = global_position if is_inside_tree() else position
			var tgt_pos: Vector3 = (_attack_target_node as Node3D).global_position if (_attack_target_node as Node3D).is_inside_tree() else (_attack_target_node as Node3D).position
			var to_t: Vector3 = tgt_pos - self_pos
			to_t.y = 0.0
			if to_t.length_squared() > 0.001:
				var lunge_vec: Vector3 = to_t.normalized() * 0.12
				if is_inside_tree():
					global_position += lunge_vec
				else:
					position += lunge_vec

	# Hit frame at frame 4
	if cur_frame == 4 and not _attack_has_hit:
		_apply_attack_hit()

func _apply_attack_hit() -> void:
	_attack_has_hit = true
	var target_enemy: Node = _attack_target_node
	if target_enemy == null or not is_instance_valid(target_enemy):
		target_enemy = target_enemy_node if target_enemy_node != null else current_target
	if target_enemy == null or not is_instance_valid(target_enemy):
		target_enemy = _find_nearest_enemy_in_reach(melee_attack_range + 0.3)

	if target_enemy != null and is_instance_valid(target_enemy) and target_enemy is Node3D:
		var edge_dist: float = get_edge_distance_to(target_enemy as Node3D)
		# Melee contact check: must be in range at hit frame (with 1.5x buffer)
		if edge_dist <= melee_attack_range * 1.5:
			if target_enemy.has_method("take_damage"):
				var dmg: int = stats.final_attack if stats != null else 10
				target_enemy.take_damage(dmg, self)

func _find_nearest_enemy_in_reach(reach_dist: float) -> Node:
	if not is_inside_tree():
		return null
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var best_enemy: Node = null
	var best_dist: float = reach_dist
	for e: Node in enemies:
		if e is Node3D and is_instance_valid(e):
			var e3d: Node3D = e as Node3D
			var edge_dist: float = get_edge_distance_to(e3d)
			if edge_dist <= best_dist:
				best_dist = edge_dist
				best_enemy = e
	return best_enemy

func take_damage(amount: int, attacker: Node = null) -> void:
	if character_state != CharacterState.ALIVE:
		return
	var def_val: int = stats.final_defence if stats != null else 0
	var final_dmg: int = maxi(1, amount - def_val)
	if stats != null:
		stats.current_health = maxi(0, stats.current_health - final_dmg)
		if stats.current_health <= 0:
			_on_player_died()
			return
	_damage_timer = 0.40

	# Turn to face attacker if idle or fighting
	if attacker != null and is_instance_valid(attacker) and not is_moving():
		if attacker is Node3D:
			var atk_pos: Vector3 = (attacker as Node3D).global_position if (attacker as Node3D).is_inside_tree() else (attacker as Node3D).position
			face_target(atk_pos)

func _try_attack() -> void:
	attack()

func _on_player_died() -> void:
	character_state = CharacterState.DEAD
	velocity = Vector3.ZERO
	clear_target_enemy()
	if cell_cursor != null and is_instance_valid(cell_cursor):
		cell_cursor.hide_target()
	_update_animation()

func _update_debug_gizmos() -> void:
	if not debug_combat_gizmos:
		if _debug_mesh_instance != null:
			_debug_mesh_instance.visible = false
		return

	if _debug_mesh_instance == null:
		_debug_mesh_instance = MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		_debug_mesh_instance.material_override = mat
		add_child(_debug_mesh_instance)

	_debug_mesh_instance.visible = true
	var imm := ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)

	var segs := 16
	for i in range(segs):
		var a1 := (TAU / segs) * i
		var a2 := (TAU / segs) * (i + 1)
		imm.surface_set_color(Color.CYAN)
		imm.surface_add_vertex(Vector3(cos(a1) * body_radius, 0.05, sin(a1) * body_radius))
		imm.surface_add_vertex(Vector3(cos(a2) * body_radius, 0.05, sin(a2) * body_radius))

	var total_range := body_radius + melee_attack_range
	for i in range(segs):
		var a1 := (TAU / segs) * i
		var a2 := (TAU / segs) * (i + 1)
		imm.surface_set_color(Color.ORANGE)
		imm.surface_add_vertex(Vector3(cos(a1) * total_range, 0.05, sin(a1) * total_range))
		imm.surface_add_vertex(Vector3(cos(a2) * total_range, 0.05, sin(a2) * total_range))

	if target_enemy_node != null and is_instance_valid(target_enemy_node):
		var to_tgt: Vector3 = target_enemy_node.global_position - global_position
		to_tgt.y = 0.05
		var edge_dist: float = get_edge_distance_to(target_enemy_node)
		var in_range: bool = edge_dist <= melee_attack_range
		var line_col: Color = Color.GREEN if in_range else Color.RED
		imm.surface_set_color(line_col)
		imm.surface_add_vertex(Vector3(0.0, 0.05, 0.0))
		imm.surface_add_vertex(to_tgt)
		print("[%s] -> [%s] edge_dist=%.2f, facing=%s, in_range=%s" % [name, target_enemy_node.name, edge_dist, _current_direction, in_range])

	imm.surface_end()
	_debug_mesh_instance.mesh = imm

