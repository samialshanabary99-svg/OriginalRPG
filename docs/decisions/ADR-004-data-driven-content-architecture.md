# ADR-004 — Data-Driven Content Architecture & Validation

## Status
Accepted

## Date
2026-10-01

## Agent
Antigravity (Data & Content Architecture)

## Context
OriginalRPG requires a scalable, data-driven content pipeline for defining characters, enemies, items, and skills. The design goal is that introducing new enemies, equipment, consumables, or player abilities should primarily require authoring structured data rather than duplicating scenes, scripts, or gameplay code.

We needed to evaluate whether pure Godot Resources (`.tres`), pure JSON files, custom resource scripts, or a hybrid architecture is appropriate for the project.

## Requirements
1. **Decoupled Definitions:** Stats, attributes, visual hints, and behavior parameters live outside scene trees.
2. **Zero Code Duplication for Content:** New enemies, items, and skills use existing components (`CharacterStatsComponent`, `InventoryComponent`, `EquipmentComponent`, `Enemy`, `Player`) configured by data.
3. **Robust Schema Validation:** Malformed definitions (empty identifiers, negative health/mana/cooldowns, missing required equipment slots) must be caught and reported early with actionable error diagnostics.
4. **Agent & Human Friendliness:** Formats should be easy for autonomous AI agents and designers to create, diff, inspect, and maintain without editor crashes or `.tres` syntax corruption.
5. **Godot 4 Native Idioms:** High runtime performance, type safety in GDScript, and seamless compatibility with standalone desktop exports.

## Options Considered

### Option A: Pure Godot Resources (`.tres` / `.res`)
- **Description:** Content authored directly as Godot `.tres` text resources in the filesystem.
- **Pros:** Native Inspector support inside Godot Editor.
- **Cons:** Fragile for external text editors and AI agents; manual edits often corrupt UIDs or engine internal syntax; Godot's `ResourceLoader` does not validate schema rules (e.g. positive bounds, non-empty IDs) and silently accepts broken data; diffs contain engine metadata.

### Option B: Pure Loose JSON with Generic Dictionaries
- **Description:** All data stored in `.json` files and passed around as untyped `Dictionary` objects at runtime.
- **Pros:** Trivial to author and validate.
- **Cons:** Loses all GDScript static type safety (`def.max_health` vs `def["max_health"]`); prone to runtime typos; no IDE autocomplete; awkward for resource references.

### Option C: Hybrid Architecture — Standard JSON Source of Truth with Strongly Typed Resource Models and Validation (Selected)
- **Description:**
  1. **Source of Truth:** Clean, human-readable, schema-strict JSON files organized under `res://data/{characters,enemies,items,skills}/`.
  2. **Typed Definition Models:** Statically typed GDScript classes extending `Resource` (`CharacterDefinition`, `EnemyDefinition`, `ItemDefinition`, `SkillDefinition`) equipped with `serialize()`, `deserialize()`, and `validate() -> Array[String]`.
  3. **Central Registry & Validation Service:** `ContentRegistry` (`src/services/content_registry.gd`) scans directories, parses JSON, validates bounds and constraints, logs diagnostic errors, and caches definitions for $O(1)$ lookups.
  4. **Entity Initialization API:** Game entities provide standard initialization hooks (`Enemy.init_from_id()`, `Enemy.init_from_definition()`, `Player.init_from_character_id()`, `InventoryComponent.add_item_by_id()`).
- **Pros:** 
  - Perfect type safety and autocomplete throughout gameplay systems.
  - Zero syntax corruption risk for AI agents and designers.
  - Explicit error reporting on startup for invalid or missing fields.
  - Fully compatible with Godot 4 standalone builds via export preset include filters (`*.json`).
- **Cons:** Requires maintaining `serialize()`, `deserialize()`, and `validate()` methods on definition classes.

## Decision
Adopt **Option C: Hybrid Architecture**.
- Definitions live in `res://data/<category>/<id>.json`.
- Typed representations live in `src/core/*_definition.gd`.
- Access and validation orchestrated by `ContentRegistry` (`src/services/content_registry.gd`).

## Directory Organization
```
data/
├── characters/     # Player and NPC archetypes (e.g. player_default.json, mage_apprentice.json)
├── enemies/        # Enemy archetypes (e.g. goblin_scout.json, orc_warrior.json)
├── items/          # Items, weapons, armour, consumables (e.g. potion_health.json, sword_iron.json)
└── skills/         # Active/passive skills (e.g. fireball.json, heal_minor.json)
```

## How to Add New Content
1. To add an **Enemy**: Create `res://data/enemies/<id>.json`.
2. To add an **Item**: Create `res://data/items/<id>.json`.
3. To add a **Skill**: Create `res://data/skills/<id>.json`.
4. To add a **Character**: Create `res://data/characters/<id>.json`.
5. Call `ContentRegistry.load_all()` (or let `ContentRegistry.ensure_initialized()` load it).
6. Verify with `tests/test_runner.gd`.
