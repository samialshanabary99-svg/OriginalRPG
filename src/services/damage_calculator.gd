class_name DamageCalculator
extends RefCounted

## Pure stat and damage calculation helper for decoupled testing and simulation.

static func calculate_damage(attack: int, defense: int, min_damage: int = 1) -> int:
	var raw: int = attack - defense
	return maxi(raw, min_damage)

static func is_alive(current_hp: int) -> bool:
	return current_hp > 0
