class_name CharacterStatsComponent
extends StatsComponent

## Extends StatsComponent with RPG combat stats, level, and experience.
## Attach alongside StatsComponent on a player or enemy CharacterBody2D.

signal level_up(new_level: int)
signal experience_changed(current_xp: int, xp_to_next: int)

@export var attack: int = 10
@export var defence: int = 5
@export var speed_stat: int = 10       # Logical speed stat (not move_speed pixels)

@export var level: int = 1
@export var experience: int = 0

## XP needed to reach the next level. Scales with current level.
func xp_to_next_level() -> int:
	return level * 100

## Grant experience; trigger level-up loop if threshold reached.
func gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	experience_changed.emit(experience, xp_to_next_level())
	while experience >= xp_to_next_level():
		experience -= xp_to_next_level()
		_level_up()

func _level_up() -> void:
	level += 1
	# Scale base stats on level-up
	max_health += 10
	attack += 2
	defence += 1
	# Fully restore HP on level-up (classic RPG feel)
	set_health(max_health)
	level_up.emit(level)

# ── Serialization ─────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var base: Dictionary = super.serialize()
	base.merge({
		"attack": attack,
		"defence": defence,
		"speed_stat": speed_stat,
		"level": level,
		"experience": experience,
	})
	return base

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("attack"):    attack    = int(data["attack"])
	if data.has("defence"):   defence   = int(data["defence"])
	if data.has("speed_stat"): speed_stat = int(data["speed_stat"])
	if data.has("level"):     level     = int(data["level"])
	if data.has("experience"): experience = int(data["experience"])
