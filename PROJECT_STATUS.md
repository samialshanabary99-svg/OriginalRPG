# Project Status

## Current Phase
**Phase 2 Complete — RPG Systems Layer Stable. 81/81 automated tests passing.**

## Working Systems
- All Phase 1 systems (Main Menu, Test World, Player, Camera, Interaction, HUD, scene transitions).
- **`CharacterStatsComponent`**: attack, defence, speed_stat, level, experience, `gain_experience()`, level-up loop with stat scaling, full serialization.
- **`InventoryComponent`**: add/remove/has/count items, capacity enforcement, signals, serialize/deserialize.
- **`ItemDefinition`**: Resource with Category enum, serialize/deserialize.
- **`ItemPickup`**: `Interactable`-based world pickup → `InventoryComponent`.
- **`Enemy`**: `CharacterBody2D` with IDLE/PATROL/AGGRO/DEAD state machine, `receive_hit()`, `enemy_died` signal, XP grant integration.
- **`QuestDefinition`**: data Resource with xp/gold rewards, serialize/deserialize (no runtime quest log yet).
- **`DamageCalculator`**: `xp_reward(level)` helper added.
- **`HUD`**: now shows HP, Level, and XP (bound via signals to `CharacterStatsComponent`).
- **`TestWorld`**: wires enemy death → player XP gain + HUD notification.


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
