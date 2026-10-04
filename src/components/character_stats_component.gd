class_name CharacterStatsComponent
extends StatsComponent

## RPG stat component for players and enemies.
##
## Design:
##   - "Base" stats come from level-1 CharacterDefinition values grown each level.
##   - "Modifiers" are additive bonuses from equipment, buffs, etc.
##   - "Final" stats = base + modifiers. Computed on demand; cached after recompute.
##   - Mana is a second resource pool managed identically to HP.
##   - All mutations go through explicit methods to guarantee signal emission.
##
## Extension points:
##   - EquipmentComponent calls add_modifier() / remove_modifier()
##   - SkillComponent reads final_attack, final_defence etc.
##   - CombatSystem uses final stats only (never raw base).

# ── Signals ───────────────────────────────────────────────────────────────────
signal level_up(new_level: int)
signal experience_changed(current_xp: int, xp_to_next: int)
signal mana_changed(current: int, maximum: int)
signal stats_recomputed()

# ── Identity / definition link ────────────────────────────────────────────────
## The archetype this character was built from. May be null for enemies without a definition.
@export var definition: CharacterDefinition = null

# ── Base stats (grow each level) ──────────────────────────────────────────────
@export_group("Base Stats")
@export var base_max_health: int = 100
@export var base_attack: int    = 10
@export var base_defence: int   = 5
@export var base_speed: int     = 10   ## Logical speed rating (not pixel move_speed)
@export var base_max_mana: int  = 50

# ── Current mana ──────────────────────────────────────────────────────────────
var current_mana: int = 50

# ── Progression ───────────────────────────────────────────────────────────────
@export_group("Progression")
@export var level: int      = 1
@export var experience: int = 0
@export var xp_per_level: int = 100   ## Overridden from CharacterDefinition when present

# ── Computed final stats (base + modifiers) ───────────────────────────────────
## Read these everywhere instead of raw base values.
var final_attack: int   = 10
var final_defence: int  = 5
var final_speed: int    = 10
var final_max_mana: int = 50

# ── Modifier system (equipment, buffs) ────────────────────────────────────────
## Key: modifier source ID (e.g. "sword_iron", "buff_rage")
## Value: Dictionary with optional keys: attack, defence, speed, max_health, max_mana
var _modifiers: Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Apply definition if provided
	if definition != null:
		_apply_definition()
	elif base_max_health == 100 and max_health != 100:
		base_max_health = max_health
	_recompute_final_stats()
	super._ready()             # StatsComponent sets current_health = max_health
	current_mana = final_max_mana


## Apply CharacterDefinition base values to this component.
## Called once at _ready if definition is set.
func _apply_definition() -> void:
	base_max_health   = definition.base_max_health
	max_health        = base_max_health
	base_max_mana     = definition.base_max_mana
	base_attack       = definition.base_attack
	base_defence      = definition.base_defence
	base_speed        = definition.base_speed_stat
	xp_per_level      = definition.xp_per_level

# ── Final stat computation ────────────────────────────────────────────────────
func _recompute_final_stats() -> void:
	var mod_attack: int    = 0
	var mod_defence: int   = 0
	var mod_speed: int     = 0
	var mod_max_health: int = 0
	var mod_max_mana: int  = 0
	for mod: Dictionary in _modifiers.values():
		mod_attack     += int(mod.get("attack", 0))
		mod_defence    += int(mod.get("defence", 0))
		mod_speed      += int(mod.get("speed", 0))
		mod_max_health += int(mod.get("max_health", 0))
		mod_max_mana   += int(mod.get("max_mana", 0))

	final_attack   = base_attack   + mod_attack
	final_defence  = base_defence  + mod_defence
	final_speed    = base_speed    + mod_speed
	final_max_mana = base_max_mana + mod_max_mana

	# HP max may grow from equipment — clamp current health to new max
	var prev_max: int = max_health
	max_health = base_max_health + mod_max_health
	if current_health > max_health:
		current_health = max_health
	if prev_max != max_health:
		health_changed.emit(current_health, max_health)

	# Clamp mana similarly
	if current_mana > final_max_mana:
		current_mana = final_max_mana

	stats_recomputed.emit()

# ── Modifier API (called by EquipmentComponent / buffs) ──────────────────────
func add_modifier(source_id: String, modifiers: Dictionary) -> void:
	_modifiers[source_id] = modifiers
	_recompute_final_stats()

func remove_modifier(source_id: String) -> void:
	if _modifiers.erase(source_id):
		_recompute_final_stats()

func has_modifier(source_id: String) -> bool:
	return _modifiers.has(source_id)

# ── Mana API ──────────────────────────────────────────────────────────────────
func set_mana(value: int) -> void:
	var clamped: int = clampi(value, 0, final_max_mana)
	if clamped != current_mana:
		current_mana = clamped
		mana_changed.emit(current_mana, final_max_mana)

func spend_mana(amount: int) -> bool:
	if amount <= 0 or current_mana < amount:
		return false
	current_mana -= amount
	mana_changed.emit(current_mana, final_max_mana)
	return true

func restore_mana(amount: int) -> void:
	if amount <= 0:
		return
	current_mana = mini(current_mana + amount, final_max_mana)
	mana_changed.emit(current_mana, final_max_mana)

# ── Progression ───────────────────────────────────────────────────────────────
func xp_to_next_level() -> int:
	return level * xp_per_level

func gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	experience_changed.emit(experience, xp_to_next_level())
	while experience >= xp_to_next_level():
		experience -= xp_to_next_level()
		_level_up()

func gain_xp(amount: int) -> void:
	gain_experience(amount)

func _level_up() -> void:
	level += 1
	# Grow base stats from definition if available, else use fixed increments
	if definition != null:
		base_max_health += definition.health_per_level
		base_max_mana   += definition.mana_per_level
		base_attack     += definition.attack_per_level
		base_defence    += definition.defence_per_level
	else:
		base_max_health += 10
		base_max_mana   += 5
		base_attack     += 2
		base_defence    += 1
	_recompute_final_stats()
	# Full restore on level-up (classic RPG feel)
	set_health(max_health)
	current_mana = final_max_mana
	level_up.emit(level)

# ── Serialization ─────────────────────────────────────────────────────────────
func serialize() -> Dictionary:
	var base: Dictionary = super.serialize()
	base.merge({
		"base_max_health": base_max_health,
		"base_attack":     base_attack,
		"base_defence":    base_defence,
		"base_speed":      base_speed,
		"base_max_mana":   base_max_mana,
		"current_mana":    current_mana,
		"level":           level,
		"experience":      experience,
		"xp_per_level":    xp_per_level,
	})
	return base

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	if data.has("base_max_health"): base_max_health = int(data["base_max_health"])
	elif data.has("max_health"):    base_max_health = int(data["max_health"])
	if data.has("base_attack"):     base_attack     = int(data["base_attack"])
	if data.has("base_defence"):    base_defence    = int(data["base_defence"])
	if data.has("base_speed"):      base_speed      = int(data["base_speed"])
	if data.has("base_max_mana"):   base_max_mana   = int(data["base_max_mana"])
	if data.has("current_mana"):    current_mana    = int(data["current_mana"])
	if data.has("level"):           level           = int(data["level"])
	if data.has("experience"):      experience      = int(data["experience"])
	if data.has("xp_per_level"):    xp_per_level    = int(data["xp_per_level"])
	_recompute_final_stats()

# ── Backwards compatibility shims ────────────────────────────────────────────
## Previous code referenced .attack and .defence directly.
## These computed properties forward to the final values so old code still compiles,
## while setters adjust the base values and trigger recomputation.
var attack: int:
	get: return final_attack
	set(val):
		base_attack = val
		_recompute_final_stats()
var defence: int:
	get: return final_defence
	set(val):
		base_defence = val
		_recompute_final_stats()
var speed_stat: int:
	get: return final_speed
	set(val):
		base_speed = val
		_recompute_final_stats()

