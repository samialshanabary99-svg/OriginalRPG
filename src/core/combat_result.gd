class_name CombatResult
extends RefCounted

## Encapsulates the complete outcome of a single combat attack.
## Designed to be extensible for future weapons, skills, damage types, and status effects.

var attacker: Node = null
var target: Node = null
var is_valid: bool = false
var damage_dealt: int = 0
var target_defeated: bool = false
var target_remaining_health: int = 0
var xp_earned: int = 0
var error_reason: String = ""

## Future extension point: damage category (e.g. physical, fire, magic)
var damage_type: String = "physical"

static func success(
	p_attacker: Node,
	p_target: Node,
	p_damage: int,
	p_defeated: bool,
	p_remaining_hp: int,
	p_xp: int = 0,
	p_damage_type: String = "physical"
) -> CombatResult:
	var res := CombatResult.new()
	res.attacker = p_attacker
	res.target = p_target
	res.is_valid = true
	res.damage_dealt = p_damage
	res.target_defeated = p_defeated
	res.target_remaining_health = p_remaining_hp
	res.xp_earned = p_xp
	res.damage_type = p_damage_type
	return res

static func failure(p_reason: String, p_attacker: Node = null, p_target: Node = null) -> CombatResult:
	var res := CombatResult.new()
	res.attacker = p_attacker
	res.target = p_target
	res.is_valid = false
	res.error_reason = p_reason
	return res
