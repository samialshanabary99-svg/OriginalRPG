# Roadmap

This roadmap is intentionally high level. Agents should create concrete tasks before implementation.

## Phase 0 — Foundation
- [x] Repository structure & documentation hierarchy
- [x] AI memory protocol & governance files
- [x] Godot 4 project foundation (`project.godot` initialization)
- [x] Core directory structure (`src/`, `scenes/`, `assets/`, `data/`, `tests/`)
- [x] Git repository initialization & `.gitignore`
- [x] Scripting language decision (ADR-001: Typed GDScript)
- [x] Architecture & persistence decisions (ADR-002, ADR-003)
- [x] Development & testing conventions (`docs/PROJECT_CONVENTIONS.md`)
- [x] Baseline automated test runner (`tests/test_runner.gd`)





## Phase 1 — Core Prototype
- [x] Player character scene (`CharacterBody2D`, component-based)
- [x] WASD / Arrow key movement with velocity-based locomotion
- [x] Camera2D follower with position smoothing
- [x] Bounded test world map (`scenes/maps/test_world.tscn`)
- [x] Interactive object system (`Interactable`, `InteractorComponent`, `AncientMonument`)
- [x] HUD with signal-bound HP display and dialogue panel
- [x] Main Menu with scene transition to game and exit
- [x] Return to Menu (ESC or HUD button)
- [x] 31 automated headless tests covering all Phase 1 systems


## Phase 2 — RPG Systems
- [x] `CharacterStatsComponent` (attack, defence, level, experience, level-up, serialization)
- [x] `DamageCalculator.xp_reward()` helper
- [x] `Enemy` entity (CharacterBody2D, IDLE/PATROL/AGGRO/DEAD state machine, melee combat)
- [x] `InventoryComponent` (add/remove/has/count, capacity, signals, serialization)
- [x] `ItemDefinition` expanded (Category enum, serialize/deserialize)
- [x] `ItemPickup` scene (Interactable → InventoryComponent)
- [x] `QuestDefinition` resource stub (data only, no runtime log yet)
- [x] HUD expanded (Level + XP labels, signal-bound to CharacterStatsComponent)
- [x] TestWorld wires enemy death → XP grant → HUD notification
- [x] 81 automated headless tests across 12 groups

## Phase 3 — Content
- Maps
- Towns
- Dungeons
- Monsters
- Bosses
- Characters
- Story
- Audio
- Effects

## Phase 4 — Persistence
- Save/load
- Character persistence
- Configuration
- Data validation

## Phase 5 — Multiplayer Research
Only after the single-player architecture provides enough evidence to choose an appropriate multiplayer architecture.

Every major transition should be documented through ADRs.
