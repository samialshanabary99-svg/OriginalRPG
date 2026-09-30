class_name CharacterDefinition
extends Resource

## Data-only Resource describing a player or NPC character archetype.
## Loaded from res://data/characters/.
## At runtime, CharacterStatsComponent is populated from this definition.
## Do NOT mutate this resource at runtime.

## Unique identifier used in save data and database lookups.
@export var character_id: String = ""

## Display name shown in UI.
@export var display_name: String = "Unnamed Hero"

## Class tag for future class-based skill unlocks.
## Examples: "warrior", "ranger", "mage"
@export var character_class: String = "adventurer"

## ── Base stat block ──────────────────────────────────────────────────────────
## These are level-1 base values before any equipment or modifier is applied.
@export_group("Base Stats")
@export var base_max_health: int = 100
@export var base_max_mana: int   = 50
@export var base_attack: int     = 10
@export var base_defence: int    = 5
@export var base_speed_stat: int = 10

## ── Per-level scaling ────────────────────────────────────────────────────────
## Added to the relevant stat each time a level-up occurs.
@export_group("Level Scaling")
@export var health_per_level: int  = 10
@export var mana_per_level: int    = 5
@export var attack_per_level: int  = 2
@export var defence_per_level: int = 1

## ── Progression ──────────────────────────────────────────────────────────────
@export_group("Progression")
## Formula multiplier for XP required at each level. xp_needed = level * xp_per_level.
@export var xp_per_level: int = 100

func serialize() -> Dictionary:
	return {
		"character_id": character_id,
		"display_name": display_name,
		"character_class": character_class,
		"base_max_health": base_max_health,
		"base_max_mana": base_max_mana,
		"base_attack": base_attack,
		"base_defence": base_defence,
		"base_speed_stat": base_speed_stat,
		"health_per_level": health_per_level,
		"mana_per_level": mana_per_level,
		"attack_per_level": attack_per_level,
		"defence_per_level": defence_per_level,
		"xp_per_level": xp_per_level,
	}

func deserialize(data: Dictionary) -> void:
	if data.has("character_id"):     character_id     = str(data["character_id"])
	if data.has("display_name"):     display_name     = str(data["display_name"])
	if data.has("character_class"):  character_class  = str(data["character_class"])
	if data.has("base_max_health"):  base_max_health  = int(data["base_max_health"])
	if data.has("base_max_mana"):    base_max_mana    = int(data["base_max_mana"])
	if data.has("base_attack"):      base_attack      = int(data["base_attack"])
	if data.has("base_defence"):     base_defence     = int(data["base_defence"])
	if data.has("base_speed_stat"):  base_speed_stat  = int(data["base_speed_stat"])
	if data.has("health_per_level"): health_per_level = int(data["health_per_level"])
	if data.has("mana_per_level"):   mana_per_level   = int(data["mana_per_level"])
	if data.has("attack_per_level"): attack_per_level = int(data["attack_per_level"])
	if data.has("defence_per_level"):defence_per_level= int(data["defence_per_level"])
	if data.has("xp_per_level"):     xp_per_level     = int(data["xp_per_level"])
