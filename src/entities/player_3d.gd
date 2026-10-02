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

@onready var camera: Camera3D = $CameraArm/Camera3D if has_node("CameraArm/Camera3D") else null:
	get:
		if camera == null and has_node("CameraArm/Camera3D"):
			camera = get_node_or_null("CameraArm/Camera3D") as Camera3D
		return camera

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

	var move_dir: Vector3 = Vector3(raw_x, 0.0, raw_z)
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()

	if move_dir.length_squared() > 0.01:
		facing_direction = move_dir
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		emit_signal("facing_changed_3d", facing_direction)
		var current_pos: Vector3 = global_position if is_inside_tree() else position
		emit_signal("player_moved_3d", current_pos)

		var dir_str: String = _vector_to_direction(move_dir)
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
