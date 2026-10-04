class_name GameState
extends Node

## Global GameState tracking persistent RPG stats, levels, resources, and attribute point economy.
## Implements a unified static architecture so GameState.* is accessible everywhere in GDScript.

class _SignalEmitter extends RefCounted:
	signal stat_points_changed(new_points: int)
	signal leveled_up(new_level: int)
	signal job_leveled_up(new_job_level: int)
	signal stats_changed()
	signal health_changed(current: int, maximum: int)
	signal stamina_changed(current: int, maximum: int)

static var _emitter: _SignalEmitter = _SignalEmitter.new()

static var stat_points_changed: Signal:
	get:
		if _emitter == null: _emitter = _SignalEmitter.new()
		return _emitter.stat_points_changed

static var leveled_up: Signal:
	get:
		if _emitter == null: _emitter = _SignalEmitter.new()
		return _emitter.leveled_up

static var job_leveled_up: Signal:
	get:
		if _emitter == null: _emitter = _SignalEmitter.new()
		return _emitter.job_leveled_up

static var stats_changed: Signal:
	get:
		if _emitter == null: _emitter = _SignalEmitter.new()
		return _emitter.stats_changed

static var health_changed: Signal:
	get:
		if _emitter == null: _emitter = _SignalEmitter.new()
		return _emitter.health_changed

static var stamina_changed: Signal:
	get:
		if _emitter == null: _emitter = _SignalEmitter.new()
		return _emitter.stamina_changed

# ── Progression ───────────────────────────────────────────────────────────────
static var base_level: int = 1
static var job_level: int = 1
static var stat_points: int = 48

# ── Core Resources ────────────────────────────────────────────────────────────
static var hp: int = 100
static var max_hp: int = 100
static var stamina: int = 100
static var max_stamina: int = 100
static var mana: int = 50
static var max_mana: int = 50
static var attack: int = 10
static var defence: int = 5

# ── 6 Core RPG Attributes ─────────────────────────────────────────────────────
static var stats: Dictionary = {
	"STR": 1,
	"AGI": 1,
	"VIT": 1,
	"INT": 1,
	"DEX": 1,
	"LUK": 1
}

# Reference to active bound player node
static var _bound_player: Node = null

## Calculate cost to raise stat from its current value to current + 1.
## Formula: cost = max(1, floor((current - 1) / 10) + 2)
## 1-10: 2 pts, 11-20: 3 pts, 21-30: 4 pts, etc.
static func stat_increase_cost(current_stat_value: int) -> int:
	return maxi(1, int(floor(float(current_stat_value - 1) / 10.0)) + 2)

## Attempt to spend stat points to increase an attribute.
## Returns true if affordable and successfully increased.
static func try_increase_stat(stat_name: String) -> bool:
	if not stats.has(stat_name):
		return false

	var current: int = int(stats[stat_name])
	var cost: int = stat_increase_cost(current)

	if stat_points < cost:
		return false

	stat_points -= cost
	stats[stat_name] = current + 1
	_apply_stat_growth(stat_name)

	if _emitter != null:
		_emitter.stat_points_changed.emit(stat_points)
		_emitter.stats_changed.emit()
	return true

static func _apply_stat_growth(stat_name: String) -> void:
	match stat_name:
		"VIT":
			max_hp += 10
			hp += 10
			if _emitter != null:
				_emitter.health_changed.emit(hp, max_hp)
		"STR":
			attack += 1
		"AGI":
			max_stamina += 2
			stamina += 2
			if _emitter != null:
				_emitter.stamina_changed.emit(stamina, max_stamina)
		"INT":
			max_mana += 5
			mana += 5
		"DEX":
			attack += 1

	if _bound_player != null and is_instance_valid(_bound_player):
		_sync_to_player()

## Level up base level and reward stat points.
static func level_up_base(amount: int = 1) -> void:
	base_level += amount
	stat_points += 5 * amount
	max_hp += 15 * amount
	hp = max_hp
	if _emitter != null:
		_emitter.leveled_up.emit(base_level)
		_emitter.stat_points_changed.emit(stat_points)
		_emitter.health_changed.emit(hp, max_hp)

## Level up job level.
static func level_up_job(amount: int = 1) -> void:
	job_level += amount
	if _emitter != null:
		_emitter.job_leveled_up.emit(job_level)

## Synchronize GameState with an active in-game player instance.
static func bind_player(player: Node) -> void:
	if player == null:
		return
	_bound_player = player

	var p_stats: CharacterStatsComponent = player.get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if p_stats != null:
		base_level = p_stats.level
		hp = p_stats.current_health
		max_hp = p_stats.max_health
		attack = p_stats.final_attack
		defence = p_stats.final_defence
		mana = p_stats.current_mana
		max_mana = p_stats.final_max_mana

		var callable_lvl := Callable(GameState, "_on_player_level_up")
		if not p_stats.level_up.is_connected(callable_lvl):
			p_stats.level_up.connect(callable_lvl)

		var callable_hp := Callable(GameState, "_on_player_health_changed")
		if not p_stats.health_changed.is_connected(callable_hp):
			p_stats.health_changed.connect(callable_hp)

static func _on_player_level_up(new_lvl: int) -> void:
	base_level = new_lvl
	stat_points += 5
	if _emitter != null:
		_emitter.leveled_up.emit(base_level)
		_emitter.stat_points_changed.emit(stat_points)

static func _on_player_health_changed(cur: int, max_val: int) -> void:
	hp = cur
	max_hp = max_val
	if _emitter != null:
		_emitter.health_changed.emit(hp, max_hp)

static func _sync_to_player() -> void:
	if _bound_player == null or not is_instance_valid(_bound_player):
		return
	var p_stats: CharacterStatsComponent = _bound_player.get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	if p_stats != null:
		p_stats.base_attack = attack
		p_stats.base_max_health = max_hp
		p_stats.max_health = max_hp
		p_stats.current_health = hp
		p_stats._recompute_final_stats()

## Reset GameState to default baseline values (used for testing and resets).
static func reset_to_defaults() -> void:
	base_level = 1
	job_level = 1
	stat_points = 48
	hp = 100
	max_hp = 100
	stamina = 100
	max_stamina = 100
	mana = 50
	max_mana = 50
	attack = 10
	defence = 5
	stats = {
		"STR": 1,
		"AGI": 1,
		"VIT": 1,
		"INT": 1,
		"DEX": 1,
		"LUK": 1
	}
	_bound_player = null
