class_name EnemyDefinition
extends Resource

## Data-only Resource describing an enemy archetype.
## Loaded from res://data/enemies/. Never mutate at runtime.

@export var enemy_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

# ── Combat stats ─────────────────────────────────────────────────────────────
@export var max_health: int = 50
@export var attack: int = 8
@export var defence: int = 2
@export var xp_reward: int = 20

# ── Behavior & movement ──────────────────────────────────────────────────────
@export var move_speed: float = 80.0
@export var patrol_radius: float = 100.0
@export var aggro_range: float = 150.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.2

# ── Visual representation ────────────────────────────────────────────────────
@export var sprite_tint: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var sprite_scale: Vector2 = Vector2(0.15, 0.15)

func serialize() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"display_name": display_name,
		"description": description,
		"max_health": max_health,
		"attack": attack,
		"defence": defence,
		"xp_reward": xp_reward,
		"move_speed": move_speed,
		"patrol_radius": patrol_radius,
		"aggro_range": aggro_range,
		"attack_range": attack_range,
		"attack_cooldown": attack_cooldown,
		"sprite_tint": sprite_tint.to_html(true),
		"sprite_scale": [sprite_scale.x, sprite_scale.y]
	}

func deserialize(data: Dictionary) -> void:
	if data.has("enemy_id"):        enemy_id        = str(data["enemy_id"])
	if data.has("display_name"):    display_name    = str(data["display_name"])
	if data.has("description"):     description     = str(data["description"])
	if data.has("max_health"):      max_health      = int(data["max_health"])
	if data.has("attack"):          attack          = int(data["attack"])
	if data.has("defence"):         defence         = int(data["defence"])
	if data.has("xp_reward"):       xp_reward       = int(data["xp_reward"])
	if data.has("move_speed"):      move_speed      = float(data["move_speed"])
	if data.has("patrol_radius"):   patrol_radius   = float(data["patrol_radius"])
	if data.has("aggro_range"):     aggro_range     = float(data["aggro_range"])
	if data.has("attack_range"):    attack_range    = float(data["attack_range"])
	if data.has("attack_cooldown"): attack_cooldown = float(data["attack_cooldown"])
	if data.has("sprite_tint"):
		if data["sprite_tint"] is String:
			sprite_tint = Color.from_string(str(data["sprite_tint"]), Color(1.0, 0.3, 0.3, 1.0))
		elif data["sprite_tint"] is Color:
			sprite_tint = data["sprite_tint"]
	if data.has("sprite_scale") and data["sprite_scale"] is Array and data["sprite_scale"].size() >= 2:
		sprite_scale = Vector2(float(data["sprite_scale"][0]), float(data["sprite_scale"][1]))

func validate() -> Array[String]:
	var errors: Array[String] = []
	if enemy_id.strip_edges().is_empty():
		errors.append("Enemy 'enemy_id' cannot be empty.")
	if display_name.strip_edges().is_empty():
		errors.append("Enemy '%s': 'display_name' cannot be empty." % enemy_id)
	if max_health <= 0:
		errors.append("Enemy '%s': 'max_health' must be greater than 0." % enemy_id)
	if attack < 0:
		errors.append("Enemy '%s': 'attack' cannot be negative." % enemy_id)
	if defence < 0:
		errors.append("Enemy '%s': 'defence' cannot be negative." % enemy_id)
	if move_speed < 0.0:
		errors.append("Enemy '%s': 'move_speed' cannot be negative." % enemy_id)
	if aggro_range <= 0.0:
		errors.append("Enemy '%s': 'aggro_range' must be greater than 0." % enemy_id)
	if attack_range <= 0.0:
		errors.append("Enemy '%s': 'attack_range' must be greater than 0." % enemy_id)
	if attack_cooldown <= 0.0:
		errors.append("Enemy '%s': 'attack_cooldown' must be greater than 0." % enemy_id)
	if xp_reward < 0:
		errors.append("Enemy '%s': 'xp_reward' cannot be negative." % enemy_id)
	return errors
