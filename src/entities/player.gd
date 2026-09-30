class_name Player
extends CharacterBody2D

## RPG Player controller.
##
## Responsibilities:
##   - Read input and translate to movement / actions
##   - Maintain CharacterState (alive, dead, stunned, etc.)
##   - Delegate all stat logic to CharacterStatsComponent
##   - Delegate all inventory logic to InventoryComponent
##   - Delegate all equipment logic to EquipmentComponent
##   - Emit signals for decoupled UI / system communication
##
## Extension points:
##   - Skills: call _try_use_skill(skill_id) and check stats.spend_mana()
##   - Combat: read stats.final_attack; write to enemy.receive_hit()
##   - Animation: connect to player_state_changed and facing_changed signals

# ── Character state ───────────────────────────────────────────────────────────
enum CharacterState {
	ALIVE,    ## Normal gameplay — can move, act, interact
	DEAD,     ## HP == 0. No input accepted.
	STUNNED,  ## Extension point: future CC/combat
	CASTING,  ## Extension point: skill charge-up
}

# ── Signals ───────────────────────────────────────────────────────────────────
signal player_moved(position: Vector2)
signal player_attacked()
signal player_state_changed(new_state: CharacterState)
signal facing_changed(direction: Vector2)
signal target_changed(new_target: Node)
signal combat_resolved(result: CombatResult)

# ── Exports ───────────────────────────────────────────────────────────────────
## Pixel movement speed. Separate from the logical speed_stat on CharacterStatsComponent.
## Future: drive this from stats.final_speed via a conversion formula.
@export var move_speed: float = 200.0
@export var attack_cooldown: float = 0.6

# ── Component references ──────────────────────────────────────────────────────
@onready var stats: CharacterStatsComponent   = $CharacterStatsComponent
@onready var inventory: InventoryComponent    = $InventoryComponent
@onready var equipment: EquipmentComponent    = $EquipmentComponent
@onready var interactor_component: InteractorComponent = $InteractorComponent
@onready var attack_area: Area2D              = $AttackArea
@onready var sprite: Sprite2D                 = $Sprite2D
@onready var camera: Camera2D                 = $Camera2D

# ── Runtime state ─────────────────────────────────────────────────────────────
var input_direction: Vector2      = Vector2.ZERO
var facing_direction: Vector2     = Vector2.RIGHT   ## Last non-zero movement direction
var character_state: CharacterState = CharacterState.ALIVE
var current_target: Node          = null
var last_combat_result: CombatResult = null


var _attack_timer: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	if stats == null:
		stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if stats != null:
		stats.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if character_state != CharacterState.ALIVE:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_handle_input()
	_apply_movement()

# ── Input ─────────────────────────────────────────────────────────────────────
func _handle_input() -> void:
	var raw_x: float = Input.get_axis("move_left", "move_right")
	var raw_y: float = Input.get_axis("move_up", "move_down")
	input_direction = Vector2(raw_x, raw_y).normalized()

	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_just_pressed("attack"):
		_try_attack()

# ── Movement ──────────────────────────────────────────────────────────────────
func _apply_movement() -> void:
	velocity = input_direction * move_speed

	if is_inside_tree():
		move_and_slide()
	else:
		global_position += velocity * (1.0 / 60.0)

	if velocity.length_squared() > 0.0:
		# Update facing only when actually moving
		if input_direction != Vector2.ZERO:
			var new_facing: Vector2 = input_direction
			if new_facing != facing_direction:
				facing_direction = new_facing
				facing_changed.emit(facing_direction)

		player_moved.emit(global_position)

		# Sprite flip for horizontal movement
		if sprite != null and input_direction.x != 0.0:
			sprite.flip_h = input_direction.x < 0.0

func is_moving() -> bool:
	return velocity.length_squared() > 0.0

# ── Interaction ───────────────────────────────────────────────────────────────
func interact() -> void:
	if interactor_component != null:
		interactor_component.try_interact()

# ── Targeting ─────────────────────────────────────────────────────────────────
func set_target(new_target: Node) -> void:
	if current_target == new_target:
		return
	current_target = new_target
	target_changed.emit(current_target)

func clear_target() -> void:
	set_target(null)

func acquire_target() -> Node:
	if attack_area == null:
		return null
	var candidates: Array[Enemy] = []
	for body: Node in attack_area.get_overlapping_bodies():
		if body is Enemy and is_instance_valid(body):
			var enemy: Enemy = body as Enemy
			if enemy.has_method("is_targetable"):
				if enemy.is_targetable():
					candidates.append(enemy)
			else:
				var s: StatsComponent = DamageCalculator.get_entity_stats(enemy)
				if s != null and s.current_health > 0:
					candidates.append(enemy)

	if candidates.is_empty():
		return null

	var my_pos: Vector2 = global_position
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return my_pos.distance_squared_to(a.global_position) < my_pos.distance_squared_to(b.global_position)
	)
	var chosen: Enemy = candidates[0]
	set_target(chosen)
	return chosen

# ── Combat ────────────────────────────────────────────────────────────────────
func attack_target(target: Node = null) -> CombatResult:
	if character_state != CharacterState.ALIVE:
		var fail_res := CombatResult.failure("attacker_invalid_state", self, target)
		last_combat_result = fail_res
		combat_resolved.emit(fail_res)
		return fail_res

	if _attack_timer > 0.0:
		var cd_res := CombatResult.failure("on_cooldown", self, target)
		last_combat_result = cd_res
		combat_resolved.emit(cd_res)
		return cd_res

	var chosen: Node = target
	if chosen == null:
		chosen = current_target
	if chosen == null:
		chosen = acquire_target()

	if chosen == null:
		var no_target_res := CombatResult.failure("no_target", self, null)
		last_combat_result = no_target_res
		combat_resolved.emit(no_target_res)
		return no_target_res

	if stats == null:
		stats = get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent

	_attack_timer = attack_cooldown
	player_attacked.emit()

	var result: CombatResult = DamageCalculator.resolve_attack(self, chosen)
	last_combat_result = result
	combat_resolved.emit(result)

	if result.is_valid and result.target_defeated:
		if result.xp_earned > 0 and stats != null:
			stats.gain_experience(result.xp_earned)
		if current_target == chosen:
			clear_target()

	return result


func _try_attack() -> void:
	attack_target()


# ── Character state management ────────────────────────────────────────────────
func _set_state(new_state: CharacterState) -> void:
	if character_state == new_state:
		return
	character_state = new_state
	player_state_changed.emit(character_state)

func _on_died() -> void:
	_set_state(CharacterState.DEAD)
	velocity = Vector2.ZERO

func is_alive() -> bool:
	return character_state == CharacterState.ALIVE

# ── Serialization (delegates to components) ───────────────────────────────────
func serialize() -> Dictionary:
	var data: Dictionary = {}
	if stats != null:     data["stats"]     = stats.serialize()
	if inventory != null: data["inventory"] = inventory.serialize()
	if equipment != null: data["equipment"] = equipment.serialize()
	return data

func deserialize(data: Dictionary) -> void:
	if data.has("stats")     and stats != null:     stats.deserialize(data["stats"])
	if data.has("inventory") and inventory != null:  inventory.deserialize(data["inventory"])
	if data.has("equipment") and equipment != null:  equipment.deserialize(data["equipment"])
