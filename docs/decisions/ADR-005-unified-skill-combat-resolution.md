# ADR-005 — Unified Combat & Skill Resolution Architecture

## Status
Proposed

## Date
2026-10-01

## Agent
Antigravity (Senior QA & Architecture Review)

## Context
During the comprehensive repository audit, an architectural discrepancy was identified between basic melee combat resolution and offensive skill execution:
- Basic attacks (`Player.attack_target()`) route through `DamageCalculator.resolve_attack()`, returning a structured `CombatResult`, triggering `combat_resolved` signals, and automatically awarding data-driven experience (`result.xp_earned`) upon defeat.
- In contrast, damaging skills (`Player.try_use_skill()`) currently calculate damage inline (`stats.final_attack + skill.power - def`), apply damage directly to target health without emitting `combat_resolved`, and do not award experience points when an enemy is defeated by spell damage.
- Furthermore, `DamageCalculator.resolve_attack()` already supports an optional `override_attack: int = -1` parameter specifically designed to accommodate skills, but it was bypassed during the initial Phase 2 skill prototype.

## Requirements
1. **DRY (Don't Repeat Yourself):** A single, canonical pipeline for calculating and applying combat damage, health reduction, defeat status, and XP rewards.
2. **Deterministic & Extensible:** Support skill power, elemental affinities, damage types (`physical`, `magical`, `true`), and status effects without branching separate resolution pipelines in entity controllers.
3. **Event Transparency:** UI, audio, and achievement systems must receive uniform combat events regardless of whether damage originated from a basic weapon swing or a spell.
4. **Target Handling:** Unify target validity, death checking, and auto-clearing across both attacks and skills.

## Options Considered

### Option A — Direct Unified Resolution via `DamageCalculator.resolve_attack()`
Route offensive skills directly through `DamageCalculator.resolve_attack(attacker, target, effective_power, damage_type)`:
- **Pros:** Reuses 100% of existing combat logic, fixes the missing XP reward and HUD feedback bug immediately, keeps `DamageCalculator` as the pure functional calculation authority.
- **Cons:** Spells with complex non-target mechanics (e.g. AoE ground circles, bouncing projectiles) will need additional orchestration beyond a 1-to-1 attacker/target pair.

### Option B — Dedicated `SkillExecutionService`
Create a separate service class `SkillExecutionService` responsible for casting validation, resource deduction, targeting patterns (single target, self, circle AoE, cone), which internally calls `DamageCalculator` for damage steps.
- **Pros:** Scalable to complex spell patterns and status effects.
- **Cons:** Over-engineering for current single-player vertical slice.

## Proposed Decision
Adopt **Option A** as the immediate architecture baseline, evolving toward **Option B** when area-of-effect spells or projectile systems are implemented in Phase 4.

Under this decision:
1. `DamageCalculator.resolve_attack()` remains the single point of combat damage application.
2. `Player.try_use_skill()` delegates damage resolution to `DamageCalculator.resolve_attack(self, chosen, stats.final_attack + skill.power)`.
3. Defeating an enemy via a skill will consistently emit `combat_resolved` and award `result.xp_earned` to `CharacterStatsComponent`.

## Consequences
- **Positive:** Eliminates duplicated combat calculations in `player.gd`, fixes spell-kill XP rewards, ensures HUD combat messages display spell damage.
- **Negative:** None; completely backwards compatible.
- **Trade-offs:** `DamageCalculator` takes on optional damage type/source metadata in `CombatResult`.

## Reversibility
Easy. Can be refactored into a full spell dispatcher service when AoE spells are introduced.

## Related Systems
- `src/services/damage_calculator.gd`
- `src/entities/player.gd`
- `src/core/combat_result.gd`
- `src/core/skill_definition.gd`
- `src/ui/hud.gd`

## Follow-up
Implement unification when Phase 3/4 skill expansions begin.
