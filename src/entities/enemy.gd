class_name Enemy
extends CharacterBody2D

## Basic enemy entity.
## States: IDLE → PATROL → AGGRO → DEAD
## Uses CharacterStatsComponent for combat stats.
## On death: grants XP to player, removes self from scene.

signal enemy_died(enemy: Enemy)
signal targeted(enemy: Enemy)

enum State { IDLE, PATROL, AGGRO, DEAD }

@export var move_speed: float = 80.0
@export var patrol_radius: float = 100.0
@export var aggro_range: float = 150.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.2
@export var definition_id: String = ""
@export var definition: EnemyDefinition = null

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
	input_pickable = true
	# Defensive: @onready may not resolve in all instantiation contexts
	if stats == null:
		stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if stats != null:
		stats.died.connect(_on_died)
	if aggro_area != null:
		aggro_area.area_entered.connect(_on_aggro_area_entered)
		aggro_area.area_exited.connect(_on_aggro_area_exited)
	input_event.connect(_on_input_event)

	if definition != null:
		init_from_definition(definition)
	elif not definition_id.is_empty():
		init_from_id(definition_id)

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

func is_targetable() -> bool:
	var s: CharacterStatsComponent = stats if stats != null else get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	return _state != State.DEAD and s != null and s.current_health > 0

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			targeted.emit(self)

# ── Combat ────────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	if _target_player == null or not is_instance_valid(_target_player):
		return
	DamageCalculator.resolve_attack(self, _target_player)

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
	_spawn_item_drops()
	enemy_died.emit(self)
	# Delay removal so animations / effects can play (none yet)
	await get_tree().create_timer(0.3).timeout
	queue_free()

func _spawn_item_drops() -> void:
	if definition == null or definition.drops.is_empty():
		return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var drop_scene: PackedScene = load("res://scenes/objects/item_pickup.tscn") as PackedScene
	if drop_scene == null:
		return
	for drop_entry: Dictionary in definition.drops:
		var item_id: String = str(drop_entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		var chance: float = float(drop_entry.get("chance", 1.0))
		if randf() > chance:
			continue
		var drop: ItemPickup = drop_scene.instantiate() as ItemPickup
		if drop != null:
			var offset: Vector2 = Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))
			drop.position = position + offset
			drop.item_id = item_id
			parent_node.add_child(drop)

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

## Initializes this enemy's stats, behavior, and visuals from an EnemyDefinition ID.
func init_from_id(id: String) -> bool:
	var def: EnemyDefinition = ContentRegistry.get_enemy(id)
	if def == null:
		return false
	init_from_definition(def)
	return true

## Initializes this enemy's stats, behavior, and visuals directly from an EnemyDefinition.
func init_from_definition(def: EnemyDefinition) -> void:
	if def == null:
		return
	definition = def
	definition_id = def.enemy_id
	move_speed = def.move_speed
	patrol_radius = def.patrol_radius
	aggro_range = def.aggro_range
	attack_range = def.attack_range
	attack_cooldown = def.attack_cooldown

	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.modulate = def.sprite_tint
		sprite.scale = def.sprite_scale

	if stats == null:
		stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if stats != null:
		stats.max_health = def.max_health
		stats.set_health(def.max_health)
		stats.base_attack = def.attack
		stats.final_attack = def.attack
		stats.base_defence = def.defence
		stats.final_defence = def.defence
