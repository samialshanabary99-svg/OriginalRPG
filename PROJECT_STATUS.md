# Project Status

## Current Phase
**Combat Vertical Slice Complete — 149/149 automated tests passing.**

## Working Systems
- All Phase 1 systems (Main Menu, Test World, Player, Camera, Interaction, HUD, scene transitions).
- **`CharacterDefinition`** (`src/core/character_definition.gd`): Data-only archetypes (`data/characters/`) defining base stats, mana, and level-up growth parameters.
- **`CharacterStatsComponent`** (`src/components/character_stats_component.gd`): Dual resources (HP + Mana), progression (Level + XP), dynamic additive stat modifiers, separate computed final stats (`final_attack`, `final_defence`, `final_speed`, `final_max_mana`).
- **`EquipmentComponent`** (`src/components/equipment_component.gd`): Slot registry managing item equipping and driving `CharacterStatsComponent` stat modifiers.
- **`InventoryComponent`** (`src/components/inventory_component.gd`): Item container on Player and entities with serialization.
- **`Combat Pipeline & CombatResult`** (`src/core/combat_result.gd`, `src/services/damage_calculator.gd`):
  - Deterministic attack resolution pipeline (`DamageCalculator.resolve_attack()`).
  - Player targeting (`set_target()`, `clear_target()`, `acquire_target()`, `current_target`).
  - Target defeat handling with automatic XP award (`result.xp_earned`) and HUD combat event reporting.
  - Invalid target and dead target validation guards.
  - Symmetrical execution for both player attacks on enemies and enemy attacks on player.
- **`Player`** (`src/entities/player.gd`): Full character state machine (`ALIVE`, `DEAD`, `STUNNED`, `CASTING`), 4/8-direction `facing_direction` tracking, `is_moving()` and `is_alive()` helpers, `attack_target()` returning `CombatResult`, delegating serialization.
- **`Enemy`** (`src/entities/enemy.gd`): AI patrol/aggro states, `is_targetable()` check, click-targeting event, unified combat execution, XP reward on defeat.
- **`TestWorld`** (`scenes/maps/test_world.tscn`): Playable slice containing Player, AncientMonument, and Enemy instance with signal-bound HUD feedback.




## In Progress
- None. Phase 2 is stable. Awaiting Phase 3 task selection.

## Planned (Phase 3 — Save/Load & Persistence)
- JSON save/load service (`SaveService`) for player stats + inventory
- Atomic file write to `user://save.json`
- Load-on-startup, save-on-quit hooks
- Save data versioning (ADR-003)

## Planned (Phase 4 — Content Expansion)
- More enemy types
- Multiple map rooms / dungeon area
- NPCs with dialogue
- Quest log runtime component (`QuestLog`)
- Sound effects and ambient audio


## Multiplayer
Not implemented. Architecture intentionally decoupled to support future headless server evaluation.

## Known Issues
- Godot 4 executable located at `C:\Users\SAMI\Desktop\ProjectZero\Godot_v4.7.2-stable_win64_console.exe` — not on system `PATH`.
- No sprite art yet; player and objects use the default Godot icon as a placeholder.

## Last Updated
2026-10-01 (Agent-1 — Phase 1 Core Prototype Complete)
