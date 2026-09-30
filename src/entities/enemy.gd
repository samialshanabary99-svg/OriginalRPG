class_name Enemy
extends CharacterBody2D

## Basic enemy entity.
## States: IDLE → PATROL → AGGRO → DEAD
## Uses CharacterStatsComponent for combat stats.
## On death: grants XP to player, removes self from scene.

signal enemy_died(enemy: Enemy)

enum State { IDLE, PATROL, AGGRO, DEAD }

@export var move_speed: float = 80.0
@export var patrol_radius: float = 100.0
@export var aggro_range: float = 150.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.2

@onready var stats: CharacterStatsComponent = $CharacterStatsComponent
@onready var aggro_area: Area2D = $AggroArea
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Sprite2D = $Sprite2D

var _state: State = State.PATROL
var _patrol_origin: Vector2 = Vector2.ZERO
var _patrol_target: Vector2 = Vector2.ZERO
var _target_player: CharacterBody2D = null
var _attack_timer: float = 0.0

func _ready() -> void:
	# Defensive: @onready may not resolve in all instantiation contexts
	if stats == null:
		stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if stats != null:
		stats.died.connect(_on_died)
	aggro_area.area_entered.connect(_on_aggro_area_entered)
	aggro_area.area_exited.connect(_on_aggro_area_exited)
	_patrol_origin = global_position
	_pick_patrol_target()


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)

	match _state:
		State.IDLE:
			_tick_idle(delta)
		State.PATROL:
			_tick_patrol(delta)
		State.AGGRO:
			_tick_aggro(delta)

# ── State ticks ───────────────────────────────────────────────────────────────

func _tick_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func _tick_patrol(delta: float) -> void:
	var direction: Vector2 = (_patrol_target - global_position)
	if direction.length() < 8.0:
		_pick_patrol_target()
		return
	velocity = direction.normalized() * move_speed * 0.5
	_flip_sprite(velocity.x)
	move_and_slide()

func _tick_aggro(_delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		_state = State.PATROL
		return

	var to_player: Vector2 = _target_player.global_position - global_position
	var dist: float = to_player.length()

	if dist <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		if _attack_timer <= 0.0:
			_perform_attack()
	else:
		velocity = to_player.normalized() * move_speed
		_flip_sprite(velocity.x)
		move_and_slide()

# ── Combat ────────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	if _target_player == null or not is_instance_valid(_target_player):
		return
	var player_stats: StatsComponent = _target_player.get_node_or_null("CharacterStatsComponent") as StatsComponent
	if player_stats == null:
		player_stats = _target_player.get_node_or_null("StatsComponent") as StatsComponent
	if player_stats != null:
		var dmg: int = DamageCalculator.calculate_damage(stats.attack, player_stats.defence if player_stats is CharacterStatsComponent else 0)
		player_stats.apply_damage(dmg)

## Called by Player when landing a hit on this enemy.
func receive_hit(attacker_attack: int) -> void:
	if _state == State.DEAD:
		return
	# Resolve stats defensively in case @onready hasn't fired yet
	var s: CharacterStatsComponent = stats
	if s == null:
		s = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if s == null:
		return
	var dmg: int = DamageCalculator.calculate_damage(attacker_attack, s.defence)
	s.apply_damage(dmg)


# ── Signals ───────────────────────────────────────────────────────────────────

func _on_died() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	enemy_died.emit(self)
	# Delay removal so animations / effects can play (none yet)
	await get_tree().create_timer(0.3).timeout
	queue_free()

func _on_aggro_area_entered(area: Area2D) -> void:
	# Detect player by checking parent node class
	var parent: Node = area.get_parent()
	if parent is CharacterBody2D and parent.get_script() != null:
		if parent.has_method("interact"):  # duck-type Player
			_target_player = parent as CharacterBody2D
			_state = State.AGGRO

func _on_aggro_area_exited(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if parent == _target_player:
		_target_player = null
		_state = State.PATROL

# ── Helpers ───────────────────────────────────────────────────────────────────

func _pick_patrol_target() -> void:
	var angle: float = randf() * TAU
	_patrol_target = _patrol_origin + Vector2(cos(angle), sin(angle)) * patrol_radius * randf()

func _flip_sprite(vx: float) -> void:
	if sprite != null and vx != 0.0:
		sprite.flip_h = vx < 0.0
