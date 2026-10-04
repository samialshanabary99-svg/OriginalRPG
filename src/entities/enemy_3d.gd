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
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.2
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

func _resolve_nodes() -> void:
	if stats == null: stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if animated_sprite == null: animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if collision_shape == null: collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shadow == null: shadow = get_node_or_null("Shadow") as MeshInstance3D

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

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0.0, 0.0, 0.0, 0.40), Color(0.0, 0.0, 0.0, 0.0)])
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
	_current_direction = _vector_to_direction(move_dir)

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

	var dir_to_target: Vector3 = diff.normalized()
	_current_direction = _vector_to_direction(dir_to_target)

	if dist <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_timer <= 0.0:
			_perform_attack()
	else:
		velocity.x = dir_to_target.x * move_speed
		velocity.z = dir_to_target.z * move_speed

func _check_for_player_aggro() -> bool:
	var players: Array[Node] = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	for p: Node in players:
		if p is Node3D:
			var p3d: Node3D = p as Node3D
			var dist: float = (p3d.global_position - global_position).length()
			if dist <= aggro_range:
				current_target = p3d
				current_state = State.AGGRO
				return true
	return false

func _pick_new_patrol_target() -> void:
	var angle: float = randf_range(0, TAU)
	var r: float = randf_range(1.0, patrol_radius)
	var offset: Vector3 = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
	_patrol_destination = _patrol_origin + offset

func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	_attack_duration = 0.65 # Wolf attack animation timing
	emit_signal("attack_performed", current_target)

	if current_target != null and is_instance_valid(current_target) and current_target.has_method("take_damage"):
		var atk_power: int = stats.final_attack if stats != null else (definition.attack if definition != null else 8)
		current_target.take_damage(atk_power, self)

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

func _on_died() -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO
	if collision_shape != null:
		collision_shape.disabled = true

	# Reward XP to attacker / player if present
	var xp: int = definition.xp_reward if definition != null else 25
	var players: Array[Node] = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
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
