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
- [x] `CharacterStatsComponent` (progression, dual HP/Mana pools, additive modifiers, base_max_health decoupling)
- [x] `EquipmentComponent` slot registry & stat modifier binding
- [x] `DamageCalculator` & deterministic combat vertical slice (`CombatResult`, targeting, XP awards)
- [x] `Enemy` entity (CharacterBody2D, IDLE/PATROL/AGGRO/DEAD state machine, data-driven archetypes)
- [x] `InventoryComponent` (add/remove/has/count, capacity, signals, serialization, `add_item_by_id`)
- [x] `ItemDefinition`, `SkillDefinition`, `EnemyDefinition`, `CharacterDefinition` typed models
- [x] `Player` 8-directional animated idle presentation (`AnimatedSprite2D`, `player_sprite_frames.tres`, octant math)
- [x] Data-driven content architecture & registry (`ContentRegistry`, `res://data/`, schema validation — ADR-004)
- [x] AI-assisted asset pipeline & manifest system (`AssetValidator`, `docs/assets/`)
- [x] 239 automated headless tests across 18 groups

## Phase 3 — Save/Load & Persistence
- [ ] Save/load service (`SaveService`) adhering to ADR-003
- [ ] Atomic file write to `user://save.json`
- [ ] Save data versioning and schema validation
- [ ] Main menu & pause menu UI save/load integration
- [ ] Character sheet UI (attributes, equipment display)

## Phase 4 — Content Expansion & Advanced Systems
- [ ] Additional maps, dungeons, and environment assets
- [ ] Monsters, bosses, and unique enemy abilities
- [ ] NPCs with interactive dialogue
- [ ] QuestLog runtime component
- [ ] Sound effects and audio pipeline
- [ ] Unified skill combat execution (ADR-005)

## Phase 5 — Multiplayer Research
Only after the single-player architecture provides enough evidence to choose an appropriate multiplayer architecture.

Every major transition should be documented through ADRs.
