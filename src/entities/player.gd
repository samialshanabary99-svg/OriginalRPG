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

# ── Combat ────────────────────────────────────────────────────────────────────
func _try_attack() -> void:
	if _attack_timer > 0.0 or stats == null:
		return
	_attack_timer = attack_cooldown
	player_attacked.emit()

	if attack_area == null:
		return
	for body: Node in attack_area.get_overlapping_bodies():
		if body is Enemy:
			# Use final_attack so equipment bonuses are included
			(body as Enemy).receive_hit(stats.final_attack)

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
