class_name SkillDefinition
extends Resource

## Data-only Resource describing an active or passive skill.
## Loaded from res://data/skills/. Never mutate at runtime.

@export var skill_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: int = 10
@export var cooldown: float = 1.0
@export var power: int = 20
@export var skill_type: String = "damage"   ## "damage", "heal", "buff"
@export var target_type: String = "single_enemy" ## "single_enemy", "self", "area"

func serialize() -> Dictionary:
	return {
		"skill_id": skill_id,
		"display_name": display_name,
		"description": description,
		"mana_cost": mana_cost,
		"cooldown": cooldown,
		"power": power,
		"skill_type": skill_type,
		"target_type": target_type,
	}

func deserialize(data: Dictionary) -> void:
	if data.has("skill_id"):     skill_id     = str(data["skill_id"])
	if data.has("display_name"):  display_name  = str(data["display_name"])
	if data.has("description"):   description   = str(data["description"])
	if data.has("mana_cost"):    mana_cost    = int(data["mana_cost"])
	if data.has("cooldown"):     cooldown     = float(data["cooldown"])
	if data.has("power"):        power        = int(data["power"])
	if data.has("skill_type"):   skill_type   = str(data["skill_type"])
	if data.has("target_type"):  target_type  = str(data["target_type"])

func validate() -> Array[String]:
	var errors: Array[String] = []
	if skill_id.strip_edges().is_empty():
		errors.append("Skill 'skill_id' cannot be empty.")
	if display_name.strip_edges().is_empty():
		errors.append("Skill '%s': 'display_name' cannot be empty." % skill_id)
	if mana_cost < 0:
		errors.append("Skill '%s': 'mana_cost' cannot be negative." % skill_id)
	if cooldown < 0.0:
		errors.append("Skill '%s': 'cooldown' cannot be negative." % skill_id)
	if not skill_type in ["damage", "heal", "buff"]:
		errors.append("Skill '%s': Invalid 'skill_type' '%s'. Must be damage, heal, or buff." % [skill_id, skill_type])
	if not target_type in ["single_enemy", "self", "area"]:
		errors.append("Skill '%s': Invalid 'target_type' '%s'. Must be single_enemy, self, or area." % [skill_id, target_type])
	return errors
