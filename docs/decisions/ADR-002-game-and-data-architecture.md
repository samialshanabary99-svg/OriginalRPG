# ADR-002 — Core Game & RPG Data Architecture

## Status
Accepted


## Date
2026-10-01

## Agent
Agent-1 (Architecture & Evaluation)

## Context
OriginalRPG requires a clean architecture for managing entities (player, enemies, NPCs), systems (combat, stats, inventory, quests, progression), and data definitions. We must choose an architecture that avoids monolithic node coupling while fitting Godot 4 idioms without unnecessary complexity.

## Requirements
1. Decoupled data models: Stats, items, skills, and quests must not be hardcoded inside UI or scene nodes.
2. High inspectability and data reuse: Designers/agents should define items and monster stats cleanly.
3. Compatibility with future persistence (save/load) and potential headless/multiplayer extraction.
4. Clean separation of concerns between visual representation and underlying RPG mechanics.

## Options Considered

### Option A: Pure Godot Node Inheritance (Monolithic Scene Approach)
- **Description:** CharacterBase node -> Player node / Enemy node with scripts attached directly, handling movement, stats, inventory, and rendering in a single hierarchy.
- **Advantages:** Simple to set up initially in the editor.
- **Disadvantages:** High coupling; hard to test headlessly; stat calculations become tangled with animations and physics.
- **Complexity:** Low initially, exponential later.
- **Scalability:** Poor.
- **Godot 4 Compatibility:** High.
- **Reversibility:** Difficult.

### Option B: Pure ECS (Entity Component System via third-party library)
- **Description:** Entities are pure IDs; components are raw data structs; systems iterate over component queries.
- **Advantages:** Excellent cache locality; strict separation of logic and data.
- **Disadvantages:** Fights Godot's built-in scene tree design; adds third-party dependencies; high boilerplate for event handling, UI binding, and animation.
- **Complexity:** High.
- **Scalability:** Very high for thousands of identical entities (e.g., bullet hell), unnecessary for classic RPG scope.
- **Godot 4 Compatibility:** Low / Awkward.
- **Reversibility:** Very difficult.

### Option C: Hybrid Composition + Resource-Driven Architecture (Recommended)
- **Description:** 
  - **Data Definitions:** Godot 4 custom `Resource` scripts (e.g., `ItemData`, `SkillData`, `MonsterData`, `ProgressionTable`).
  - **Component Nodes:** Composable child nodes on entities (e.g., `StatsComponent`, `InventoryComponent`, `HitboxComponent`, `CombatComponent`).
  - **Signals & Events:** Systems communicate via Godot signals (e.g., `health_changed`, `item_used`, `level_up`).
  - **Decoupled Logic:** Stat math and damage calculation live in pure data/helper classes (`DamageCalculator`, `StatContainer`) separate from physics and visuals.
- **Advantages:** Leverages Godot's native strengths (Resources, Nodes, Signals) while keeping business logic decoupled; fully serializable; inspectable in the editor; straightforward to test headlessly.
- **Disadvantages:** Requires discipline in maintaining clear component boundaries and signal conventions.
- **Complexity:** Moderate.
- **Scalability:** High.
- **Godot 4 Compatibility:** 100% native.
- **Reversibility:** Moderate.

## Recommendation
**Option C: Hybrid Composition + Resource-Driven Architecture.**
Static definitions (items, skills, enemy base stats, quest templates) live in custom `Resource` files (`.tres` / `.res`). Runtime state (current HP, equipped items, active buffs, quest state) lives in dedicated component nodes (`StatsComponent`, `InventoryComponent`) attached to character scenes.

## Consequences
- Positive: Clear separation of visual scenes from data rules; rapid creation of items and enemies by making new Resource files; clean unit testing of stat logic.
- Negative: Requires defining custom Resource classes for data types before building gameplay features.

## Reversibility
Moderate.

## Related Systems
Stats, Combat, Inventory, Items, Enemies, NPCs, Quests, Save/Load.
