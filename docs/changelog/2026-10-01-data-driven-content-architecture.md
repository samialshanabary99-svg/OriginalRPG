# Changelog: Data-Driven Content Architecture & Validation

- **Date:** 2026-10-01
- **Author:** Antigravity (Agent)
- **Status:** Complete & Verified

## Overview
Designed and implemented OriginalRPG's first data-driven content architecture. Introducing new enemies, items, equipment, skills, and character archetypes now requires authoring structured JSON definitions under `res://data/` rather than duplicating scenes, scripts, or gameplay code.

The architecture was formalized and accepted under **ADR-004**, utilizing standard JSON source-of-truth definitions combined with typed Godot Resource models and strict schema validation.

## Changes Made

### 1. Architectural Decision
- Formalized and accepted [`docs/decisions/ADR-004-data-driven-content-architecture.md`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/docs/decisions/ADR-004-data-driven-content-architecture.md).
- Evaluated pure `.tres` Resources vs. loose JSON vs. Hybrid typed Resource-backed JSON models. Selected Hybrid architecture for safety, agent readability, static typing, and schema validation.

### 2. Core Typed Definition Resources (`src/core/`)
- **`CharacterDefinition`** (`src/core/character_definition.gd`): Added `validate() -> Array[String]` ensuring valid IDs, positive health and XP scaling, and non-negative attributes.
- **`EnemyDefinition`** (`src/core/enemy_definition.gd`): Created new Resource class defining enemy combat stats (`max_health`, `attack`, `defence`, `xp_reward`), behavior parameters (`move_speed`, `patrol_radius`, `aggro_range`, `attack_range`, `attack_cooldown`), visual parameters (`sprite_tint`, `sprite_scale`), serialization, and `validate()`.
- **`ItemDefinition`** (`src/core/item_definition.gd`): Expanded with `equip_slot`, `stat_modifiers`, `heal_amount`, `mana_amount`, `get_stat_bonuses()`, category parsing, and `validate()`.
- **`SkillDefinition`** (`src/core/skill_definition.gd`): Created new Resource class defining active/passive skills (`mana_cost`, `cooldown`, `power`, `skill_type`, `target_type`), serialization, and `validate()`.

### 3. Central Content Registry & Validator (`src/services/content_registry.gd`)
- Created `ContentRegistry` service:
  - Scans `res://data/characters/`, `res://data/enemies/`, `res://data/items/`, and `res://data/skills/`.
  - Parses JSON, instantiates typed definitions, executes `.validate()`, logs errors, and registers definitions for $O(1)$ lookup.
  - Exposes lookup methods (`get_enemy()`, `get_item()`, `get_skill()`, `get_character()`) and existence checks (`has_enemy()`, etc.).
  - Exposes `validate_json_string()` for validating raw data without registering.

### 4. Gameplay Entity Hooks
- **`Enemy`** (`src/entities/enemy.gd`):
  - Added `definition_id` and `definition` exports.
  - Added `init_from_id(id)` and `init_from_definition(def)` to dynamically configure enemy stats, movement speeds, ranges, and sprite tints without creating new scenes.
- **`Player`** (`src/entities/player.gd`):
  - Added `init_from_character_id(id)` to initialize stats from any defined archetype.
  - Added `try_use_skill(skill_id, target)` to execute skills with mana cost verification, healing, and damage calculation.
- **`InventoryComponent`** (`src/components/inventory_component.gd`):
  - Added `add_item_by_id(item_id)` convenience method.
- **`ItemPickup`** (`src/entities/item_pickup.gd`):
  - Added `item_id` export to auto-resolve from `ContentRegistry` on `_ready()`.
- **`DamageCalculator`** (`src/services/damage_calculator.gd`):
  - Supports data-driven `xp_reward` defined directly on the enemy's definition.

### 5. Content Definitions Created
- **Enemies:**
  - `data/enemies/goblin_scout.json` (fast, 35 HP, 7 ATK, 15 XP reward, green tint)
  - `data/enemies/orc_warrior.json` (tanky, 80 HP, 14 ATK, 4 DEF, 35 XP reward, red tint)
- **Items:**
  - `data/items/herb_basic.json` (consumable, heals 15 HP)
  - `data/items/potion_health.json` (consumable, heals 50 HP)
  - `data/items/potion_mana.json` (consumable, restores 30 MP)
  - `data/items/sword_iron.json` (weapon, +8 ATK, -1 SPD)
  - `data/items/shield_wooden.json` (armour, +5 DEF, +15 Max HP)
- **Skills:**
  - `data/skills/fireball.json` (damage, 15 MP cost, 35 power)
  - `data/skills/heal_minor.json` (heal self, 20 MP cost, 40 power)
- **Characters:**
  - `data/characters/player_default.json` (adventurer)
  - `data/characters/mage_apprentice.json` (mage with high mana pool and scaling)

### 6. Verification & Automated Testing
- Added **Group Q: Data-Driven Content Architecture & Validation** to [`tests/test_runner.gd`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/tests/test_runner.gd) (56 new assertions).
- Automated test count grew from **163 to 219 tests — 100% passing (0 failures)**.
- Rebuilt Windows Desktop standalone `.exe` using [`scripts/build.ps1`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/scripts/build.ps1).
- Executed headless smoke test (`OriginalRPG.exe --headless --quit-after 60`) with exit code 0.
