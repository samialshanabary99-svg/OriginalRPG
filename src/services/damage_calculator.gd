class_name DamageCalculator
extends RefCounted

## Pure stat, damage calculation, and combat resolution service.
## Single source of truth for deterministic combat calculations.

## Deterministic damage formula: raw attack minus defense, clamped to minimum damage.
static func calculate_damage(attack: int, defense: int, min_damage: int = 1) -> int:
	var raw: int = attack - defense
	return maxi(raw, min_damage)

static func is_alive(current_hp: int) -> bool:
	return current_hp > 0

## Calculate XP reward for defeating an enemy of a given level.
static func xp_reward(enemy_level: int) -> int:
	return maxi(enemy_level * 20, 10)

## Helper to retrieve the stats component from an entity.
static func get_entity_stats(entity: Node) -> StatsComponent:
	if entity == null or not is_instance_valid(entity):
		return null
	var stats: StatsComponent = entity.get_node_or_null("CharacterStatsComponent") as StatsComponent
	if stats == null:
		stats = entity.get_node_or_null("StatsComponent") as StatsComponent
	return stats

## Helper to retrieve attack rating from an entity.
static func get_attack_power(entity: Node, override_attack: int = -1) -> int:
	if override_attack >= 0:
		return override_attack
	if entity == null or not is_instance_valid(entity):
		return 1
	var s: StatsComponent = get_entity_stats(entity)
	if s is CharacterStatsComponent:
		return (s as CharacterStatsComponent).final_attack
	elif s != null and "attack" in s:
		return int(s.attack)
	return 1

## Helper to retrieve defense rating from an entity.
static func get_defense_power(entity: Node) -> int:
	if entity == null or not is_instance_valid(entity):
		return 0
	var s: StatsComponent = get_entity_stats(entity)
	if s is CharacterStatsComponent:
		return (s as CharacterStatsComponent).final_defence
	elif s != null and "defence" in s:
		return int(s.defence)
	return 0

## Executes and resolves a complete combat attack between attacker and target.
## Validates both entities, calculates deterministic damage, applies health changes,
## and returns an extensible CombatResult.
static func resolve_attack(attacker: Node, target: Node, override_attack: int = -1) -> CombatResult:
	if target == null or not is_instance_valid(target):
		return CombatResult.failure("invalid_target", attacker, target)

	if attacker != null and is_instance_valid(attacker) and attacker.has_method("is_alive") and not attacker.is_alive():
		return CombatResult.failure("attacker_invalid_state", attacker, target)

	var target_stats: StatsComponent = get_entity_stats(target)
	if target_stats == null:
		return CombatResult.failure("target_has_no_stats", attacker, target)

	if not is_alive(target_stats.current_health):
		return CombatResult.failure("target_dead", attacker, target)

	if target is Enemy and (target as Enemy)._state == Enemy.State.DEAD:
		return CombatResult.failure("target_dead", attacker, target)

	var atk: int = get_attack_power(attacker, override_attack)
	var def: int = get_defense_power(target)
	var damage: int = calculate_damage(atk, def)

	target_stats.apply_damage(damage)
	var defeated: bool = (target_stats.current_health == 0)

	var xp: int = 0
	if defeated:
		if target_stats is CharacterStatsComponent:
			xp = xp_reward((target_stats as CharacterStatsComponent).level)
		else:
			xp = xp_reward(1)

	return CombatResult.success(attacker, target, damage, defeated, target_stats.current_health, xp)
