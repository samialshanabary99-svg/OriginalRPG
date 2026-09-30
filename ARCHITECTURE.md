# Architecture

## Status
Early-stage and intentionally flexible.

## Confirmed Decisions
- Target Engine: Godot 4 (4.7.2 Forward+)
- Mode: Single-player initially
- Development Model: AI-first with human supervision
- Agent Concurrency: Exactly one active AI agent editing at a time
- Repository Memory: Documentation-driven persistence (ADRs, manifests, changelogs, task tracking)
- Scripting Language: Statically typed GDScript ([ADR-001](docs/decisions/ADR-001-scripting-language.md))
- Core Game & Data Architecture: Hybrid Composition + Resource-Driven Architecture ([ADR-002](docs/decisions/ADR-002-game-and-data-architecture.md))
- Save/Load Architecture: Versioned structured JSON with atomic file writing ([ADR-003](docs/decisions/ADR-003-save-load-architecture.md))
- Technical Conventions: Established in `docs/PROJECT_CONVENTIONS.md`

## Verified Existing Architecture
- **Governance & Documentation System:** Multi-agent coordination protocols, templates, and task tracking directories exist under `docs/`.
- **Engine Baseline:** Godot 4.7.2 Forward+ project initialized with `project.godot`, standard directory boundaries (`src/`, `scenes/`, `assets/`, `data/`, `tests/`), and startup scene `scenes/test_main.tscn`.
- **Core Models & Components:**
  - `ItemDefinition` (`src/core/item_definition.gd`): Custom `Resource` template for item definitions.
  - `DamageCalculator` (`src/services/damage_calculator.gd`): Pure static service for decoupled combat arithmetic.
  - `StatsComponent` (`src/components/stats_component.gd`): Reusable entity component for attributes, damage, healing, and JSON serialization.
- **Testing Framework:** Headless test runner script (`tests/test_runner.gd`) executing 123 automated unit tests across 14 groups.

## Player Character Architecture
The player architecture follows a modular composition pattern using a `CharacterBody2D` host node composed of independent, decoupled components:

### 1. Identity & Data Layer
- **`CharacterDefinition`** (`src/core/character_definition.gd`):
  - Data-only `Resource` template (never mutated at runtime).
  - Holds player identity (`character_id`, `display_name`, `character_class`), base attributes (`base_max_health`, `base_max_mana`, `base_attack`, `base_defence`, `base_speed_stat`), and per-level growth parameters (`health_per_level`, `mana_per_level`, `attack_per_level`, `defence_per_level`, `xp_per_level`).
  - Stored in `data/characters/` (e.g. `player_default.json`).

### 2. Attribute & Resource State
- **`StatsComponent`** (`src/components/stats_component.gd`):
  - Handles basic health (`current_health`, `max_health`), damage application, healing, clamping, and `health_changed`/`died` signals.
- **`CharacterStatsComponent`** (`src/components/character_stats_component.gd`):
  - Extends `StatsComponent`.
  - Initialized from `CharacterDefinition` archetype.
  - Adds mana resource pool (`current_mana`, `spend_mana()`, `restore_mana()`, `mana_changed` signal).
  - Progression logic: `level`, `experience`, `gain_experience()`, `level_up` event loop with stat growth scaling.
  - Additive Stat Modifier System: supports dynamic modifiers from equipment, buffs, and debuffs via `add_modifier(source_id, dict)` / `remove_modifier(source_id)`.
  - Separation of Concerns: computes and caches final stats (`final_attack`, `final_defence`, `final_speed`, `final_max_mana`) separate from base attributes.

### 3. Equipment & Items
- **`EquipmentComponent`** (`src/components/equipment_component.gd`):
  - Thin slot registry (`weapon`, `head`, `chest`, `offhand`, etc.).
  - Handles item equipping and un-equipping with `item_equipped`/`item_unequipped`/`equipment_changed` signals.
  - Serves as the bridge to `CharacterStatsComponent.add_modifier()`.
- **`InventoryComponent`** (`src/components/inventory_component.gd`):
  - Capacity-bounded collection of `ItemDefinition` resources.
  - Emits `item_added`, `item_removed`, `inventory_changed`.

### 4. Controller & State Management
- **`Player`** (`src/entities/player.gd`):
  - Character State enum: `CharacterState { ALIVE, DEAD, STUNNED, CASTING }`.
  - Movement State: velocity handling, `is_moving()`, 4/8-direction `facing_direction` tracking, `facing_changed` signal.
  - Input Handling: reads action mappings from `project.godot`.
  - Lifecycle & Signals: connects to `stats.died` to trigger state transition to `DEAD`.
  - Combat Hook: overlap checking via `AttackArea` passing `stats.final_attack` to enemies.
  - Serialization: delegating root that aggregates state from `stats`, `inventory`, and `equipment`.

### 5. Extension Points
- **Equipment:** Equip constraints, durability, multi-slot weapons via `EquipmentComponent`.
- **Skills:** Resource checks (`stats.spend_mana()`), state validation (`character_state == ALIVE`), casting state transitions (`CASTING`).
- **Combat & CC:** Stun/freeze/root effects transition player state to `STUNNED`, suspending input processing.

## Combat Architecture (Vertical Slice)
Combat follows a deterministic, decoupled interaction pipeline:

```
PLAYER / ATTACKER
  │
  ▼ (Acquire or select target)
TARGET ENEMY
  │
  ▼ (attack_target() checks cooldown & character_state)
ATTACK INITIATION
  │
  ▼ (DamageCalculator.resolve_attack)
DAMAGE CALCULATION (Deterministic: maxi(atk - def, min_damage))
  │
  ▼ (target_stats.apply_damage)
TARGET HEALTH REDUCTION & DEFEAT CHECK
  │
  ▼ (CombatResult object created)
ATTACKER RECEIVES RESULT (combat_resolved signal, XP reward if defeated)
```

### Key Principles:
1. **Clear Ownership of Combat State:**
   - Attacker owns its targeting state (`current_target`), attack timer (`_attack_timer`), and receives the `CombatResult`.
   - Target owns its health state via `CharacterStatsComponent` / `StatsComponent`.
   - `DamageCalculator` is stateless: purely functional calculations with no persistent combat state.
2. **Unified & Non-Duplicated Resolution:**
   - Both Player attacks on Enemies and Enemy attacks on Players execute via `DamageCalculator.resolve_attack()`.
   - Validates entity presence, life status, stats existence, calculates damage, applies health changes, and handles defeat XP calculation.
3. **Data Model (`CombatResult`):**
   - RefCounted object storing `attacker`, `target`, `is_valid`, `damage_dealt`, `target_defeated`, `target_remaining_health`, `xp_earned`, `error_reason`, and `damage_type`.
4. **Extension Points:**
   - **Different Weapons:** Weapon items provide base damage and damage type to `DamageCalculator`.
   - **Skills:** Skill execution provides custom attack power and mana costs, returning a `CombatResult`.
   - **Damage Types & Defenses:** `damage_type` field ready for elemental resistance/weakness calculations.
   - **Status Effects:** `CombatResult` can carry applied effect payloads (e.g. burn, poison, stun).
   - **Player Progression:** Defeat events automatically forward XP rewards into `CharacterStatsComponent.gain_experience()`.




### 4. Future Multiplayer & Networking (Exploratory / Deferred)
- **Status:** Deferred until single-player core mechanics prove stable.
- **Evaluated Options:** Authoritative Headless Godot Server (ENet/WebRTC/WebSocket) vs Custom External Game Server (Go/Rust/C#).
- **Guideline:** Keep game rules, damage math, and stat mutations decoupled from rendering/input nodes so logic can be shared or ported to an authoritative server in the future.

### 5. Backend & Database (Exploratory / Deferred)
- **Status:** Not required for single-player.
- **Evaluated Options:** PostgreSQL, SQLite, or Redis. Only evaluated in the context of persistent player accounts and world state if dedicated multiplayer services are formally introduced.

## Rule
Do not create a major architectural commitment without an ADR.

## Future
As decisions are approved, this document becomes the authoritative high-level map of the technical system.

