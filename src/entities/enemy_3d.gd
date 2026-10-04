class_name Enemy3D
extends CharacterBody3D

## Hybrid 3D Enemy controller for OriginalRPG (Ragnarok Online style).
## Features 8-directional animated billboard sprites, ground hugging shadows,
## terrain elevation navigation, and state-machine AI (Patrol -> Aggro -> Attack -> Die).

signal enemy_died(enemy: Enemy3D)
signal targeted(enemy: Enemy3D)
signal attack_performed(target: Node3D)

enum State {
	IDLE,
	PATROL,
	AGGRO,
	ATTACK,
	TAKE_DAMAGE,
	DEAD
}

@export var enemy_id: String = "wolf_small"
@export var move_speed: float = 3.5
@export var patrol_radius: float = 5.0
@export var aggro_range: float = 8.0
@export var attack_range: float = 1.8 # Legacy fallback
@export var body_radius: float = 0.40
@export var melee_attack_range: float = 0.40
@export var attack_cooldown: float = 1.2
@export var debug_combat_gizmos: bool = false
@export var definition: EnemyDefinition = null

@onready var stats: CharacterStatsComponent = $CharacterStatsComponent:
	get:
		if stats == null and has_node("CharacterStatsComponent"):
			stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
		return stats

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D:
	get:
		if animated_sprite == null and has_node("AnimatedSprite3D"):
			animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		return animated_sprite

@onready var collision_shape: CollisionShape3D = $CollisionShape3D:
	get:
		if collision_shape == null and has_node("CollisionShape3D"):
			collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
		return collision_shape

@onready var shadow: MeshInstance3D = $Shadow if has_node("Shadow") else null:
	get:
		if shadow == null and has_node("Shadow"):
			shadow = get_node_or_null("Shadow") as MeshInstance3D
		return shadow

@onready var aim_indicator: Sprite3D = $AimIndicator if has_node("AimIndicator") else null:
	get:
		if aim_indicator == null and has_node("AimIndicator"):
			aim_indicator = get_node_or_null("AimIndicator") as Sprite3D
		return aim_indicator

var is_targeted: bool = false
var is_hovered: bool = false

var current_state: State = State.IDLE
var current_target: Node3D = null

var _patrol_origin: Vector3 = Vector3.ZERO
var _patrol_destination: Vector3 = Vector3.ZERO
var _idle_timer: float = 0.0
var _attack_timer: float = 0.0
var _damage_timer: float = 0.0
var _attack_duration: float = 0.0
var _current_direction: String = "south"
var _gravity: float = 14.0

var _attack_target: Node3D = null
var _attack_has_hit: bool = false
var _attack_lunge_done: bool = false
var _debug_mesh_instance: MeshInstance3D = null

func _enter_tree() -> void:
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(55.0)
	floor_constant_speed = true
	floor_block_on_wall = true
	floor_stop_on_slope = true

func _ready() -> void:
	add_to_group("enemies")
	_resolve_nodes()

	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(55.0)
	floor_constant_speed = true
	floor_block_on_wall = true
	floor_stop_on_slope = true

	if animated_sprite != null and not animated_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		animated_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if stats != null and not stats.died.is_connected(_on_died):
		stats.died.connect(_on_died)

	if definition != null:
		init_from_definition(definition)
	elif not enemy_id.is_empty():
		init_from_id(enemy_id)

	if is_inside_tree():
		_patrol_origin = global_position
	else:
		_patrol_origin = position
	_pick_new_patrol_target()
	_setup_shadow()
	_update_animation("south")

func _process(_delta: float) -> void:
	if aim_indicator != null and aim_indicator.visible:
		aim_indicator.position.y = 1.25 + sin(Time.get_ticks_msec() * 0.006) * 0.05
	_update_debug_gizmos()

func set_targeted(active: bool) -> void:
	is_targeted = active
	_update_aim_indicator()

func set_hovered(active: bool) -> void:
	is_hovered = active
	_update_aim_indicator()

func _update_aim_indicator() -> void:
	if aim_indicator == null:
		return
	if current_state == State.DEAD:
		aim_indicator.visible = false
		return
	aim_indicator.visible = is_targeted or is_hovered
	if is_targeted:
		aim_indicator.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif is_hovered:
		aim_indicator.modulate = Color(1.0, 1.0, 1.0, 0.65)

func _resolve_nodes() -> void:
	if stats == null: stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if animated_sprite == null: animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if collision_shape == null: collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shadow == null: shadow = get_node_or_null("Shadow") as MeshInstance3D
	if aim_indicator == null: aim_indicator = get_node_or_null("AimIndicator") as Sprite3D

func init_from_id(id: String) -> bool:
	_resolve_nodes()
	ContentRegistry.ensure_initialized()
	var def: EnemyDefinition = ContentRegistry.get_enemy(id)
	if def == null:
		ContentRegistry.load_all()
		def = ContentRegistry.get_enemy(id)
	if def == null:
		# Fallback defaults if definition not found
		if stats != null:
			stats.base_max_health = 45
			stats.max_health = 45
			stats.current_health = 45
			stats.base_attack = 8
			stats.base_defence = 2
			stats._recompute_final_stats()
		return false
	return init_from_definition(def)

func init_from_definition(def: EnemyDefinition) -> bool:
	_resolve_nodes()
	definition = def
	enemy_id = def.enemy_id
	move_speed = def.move_speed
	patrol_radius = def.patrol_radius
	aggro_range = def.aggro_range
	attack_range = def.attack_range
	attack_cooldown = def.attack_cooldown

	if stats != null:
		stats.base_max_health = def.max_health
		stats.max_health = def.max_health
		stats.current_health = def.max_health
		stats.base_attack = def.attack
		stats.base_defence = def.defence
		stats._recompute_final_stats()
	return true

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

func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if _damage_timer > 0.0:
		_damage_timer = maxf(0.0, _damage_timer - delta)
	if _attack_duration > 0.0:
		_attack_duration = maxf(0.0, _attack_duration - delta)

	if current_state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)
		if not is_on_floor():
			velocity.y -= _gravity * delta
		if is_inside_tree():
			move_and_slide()
		_update_animation()
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1

	# If currently performing attack animation or flinching from damage, hold movement
	if _attack_duration > 0.0 or _damage_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
		if is_inside_tree():
			move_and_slide()
		_update_animation()
		return

	# AI state execution
	match current_state:
		State.IDLE:
			_tick_idle(delta)
		State.PATROL:
			_tick_patrol(delta)
		State.AGGRO:
			_tick_aggro(delta)

	if is_inside_tree():
		move_and_slide()

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

func _tick_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)

	# Check for player entering aggro radius
	if _check_for_player_aggro():
		return

	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_pick_new_patrol_target()
		current_state = State.PATROL

func _tick_patrol(_delta: float) -> void:
	if _check_for_player_aggro():
		return

	var diff: Vector3 = _patrol_destination - global_position
	diff.y = 0.0
	var dist: float = diff.length()

	if dist < 0.6:
		current_state = State.IDLE
		_idle_timer = randf_range(1.5, 3.5)
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var move_dir: Vector3 = diff.normalized()
	velocity.x = move_dir.x * (move_speed * 0.5)
	velocity.z = move_dir.z * (move_speed * 0.5)
	face_target(_patrol_destination)

func _tick_aggro(_delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
		current_state = State.IDLE
		_idle_timer = 1.0
		return

	var diff: Vector3 = current_target.global_position - global_position
	diff.y = 0.0
	var dist: float = diff.length()

	# Lost target if player moves far away
	if dist > aggro_range * 1.5:
		current_target = null
		current_state = State.IDLE
		_idle_timer = 1.5
		return

	# Face target camera-relative every frame while chasing or engaging
	face_target(current_target.global_position if current_target.is_inside_tree() else current_target.position)

	var edge_dist: float = get_edge_distance_to(current_target)
	if edge_dist <= melee_attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_timer <= 0.0:
			_perform_attack()
	else:
		var dir_to_target: Vector3 = diff.normalized()
		velocity.x = dir_to_target.x * move_speed
		velocity.z = dir_to_target.z * move_speed

func _check_for_player_aggro() -> bool:
	var players: Array[Node] = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	for p: Node in players:
		if p is Node3D:
			var p3d: Node3D = p as Node3D
			var self_pos: Vector3 = global_position if is_inside_tree() else position
			var p_pos: Vector3 = p3d.global_position if p3d.is_inside_tree() else p3d.position
			var dist: float = (p_pos - self_pos).length()
			if dist <= aggro_range:
				current_target = p3d
				current_state = State.AGGRO
				face_target(p_pos)
				return true
	return false

func _pick_new_patrol_target() -> void:
	var angle: float = randf_range(0, TAU)
	var r: float = randf_range(1.0, patrol_radius)
	var offset: Vector3 = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
	_patrol_destination = _patrol_origin + offset

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

	var cam: Camera3D = null
	if is_inside_tree() and get_viewport() != null:
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
	_update_animation()

func apply_knockback(impulse: Vector3) -> void:
	if current_state == State.DEAD:
		return
	impulse.y = 0.0
	position += impulse

func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	_attack_duration = 0.65 # Wolf attack animation timing
	_attack_has_hit = false
	_attack_lunge_done = false
	_attack_target = current_target
	if _attack_target != null and is_instance_valid(_attack_target):
		face_target(_attack_target.global_position if _attack_target.is_inside_tree() else _attack_target.position)
	emit_signal("attack_performed", current_target)
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
		if _attack_target != null and is_instance_valid(_attack_target):
			var self_pos: Vector3 = global_position if is_inside_tree() else position
			var tgt_pos: Vector3 = _attack_target.global_position if _attack_target.is_inside_tree() else _attack_target.position
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
	var target: Node3D = _attack_target if _attack_target != null else current_target
	if target != null and is_instance_valid(target):
		var edge_dist: float = get_edge_distance_to(target)
		# Melee contact check: target must be in range (1.5x buffer) at hit frame
		if edge_dist <= melee_attack_range * 1.5:
			if target.has_method("take_damage"):
				var atk_power: int = stats.final_attack if stats != null else (definition.attack if definition != null else 8)
				target.take_damage(atk_power, self)
			var self_pos: Vector3 = global_position if is_inside_tree() else position
			var tgt_pos: Vector3 = target.global_position if target.is_inside_tree() else target.position
			var to_t: Vector3 = tgt_pos - self_pos
			to_t.y = 0.0
			if to_t.length_squared() > 0.001 and target.has_method("apply_knockback"):
				target.apply_knockback(to_t.normalized() * 0.15)

func take_damage(amount: int, attacker: Node3D = null) -> void:
	if current_state == State.DEAD:
		return

	var def_val: int = stats.final_defence if stats != null else (definition.defence if definition != null else 2)
	var final_dmg: int = maxi(1, amount - def_val)

	if stats != null:
		stats.current_health = maxi(0, stats.current_health - final_dmg)
		if stats.current_health <= 0:
			_on_died()
			return

	_damage_timer = 0.40 # Flinch duration
	if attacker != null and is_instance_valid(attacker):
		current_target = attacker
		current_state = State.AGGRO
		face_target(attacker.global_position if attacker.is_inside_tree() else attacker.position)

func _on_died() -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO
	is_targeted = false
	is_hovered = false
	if aim_indicator != null:
		aim_indicator.visible = false
	if collision_shape != null:
		collision_shape.disabled = true

	# Reward XP to attacker / player if present
	var xp: int = definition.xp_reward if definition != null else 25
	var players: Array = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	for p: Node in players:
		if p.has_node("CharacterStatsComponent"):
			var p_stats: CharacterStatsComponent = p.get_node("CharacterStatsComponent") as CharacterStatsComponent
			if p_stats != null:
				p_stats.gain_xp(xp)

	emit_signal("enemy_died", self)

func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length_squared() > 0.04

func _update_animation(dir_name: String = "") -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not dir_name.is_empty():
		_current_direction = dir_name

	var anim_prefix: String = "idle"
	if current_state == State.DEAD:
		anim_prefix = "die"
	elif _damage_timer > 0.0:
		anim_prefix = "damage"
	elif _attack_duration > 0.0:
		anim_prefix = "attack"
	elif is_moving():
		anim_prefix = "walk"
	else:
		anim_prefix = "idle"

	# If dead and death animation finished, switch to static "dead" frame
	if current_state == State.DEAD and animated_sprite.animation.begins_with("die") and not animated_sprite.is_playing():
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

	if current_target != null and is_instance_valid(current_target):
		var to_tgt: Vector3 = current_target.global_position - global_position
		to_tgt.y = 0.05
		var edge_dist: float = get_edge_distance_to(current_target)
		var in_range: bool = edge_dist <= melee_attack_range
		var line_col: Color = Color.GREEN if in_range else Color.RED
		imm.surface_set_color(line_col)
		imm.surface_add_vertex(Vector3(0.0, 0.05, 0.0))
		imm.surface_add_vertex(to_tgt)
		print("[%s] -> [%s] edge_dist=%.2f, facing=%s, in_range=%s" % [name, current_target.name, edge_dist, _current_direction, in_range])

	imm.surface_end()
	_debug_mesh_instance.mesh = imm
