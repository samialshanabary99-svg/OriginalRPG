# TODO

## Phase 2 — RPG Systems (Not yet started)

- **Task: Expand Player Stats Model**
  - Goal: Add `attack`, `defence`, `level`, `experience` to `StatsComponent` or create a dedicated `CharacterStatsComponent`.
  - Scope: `src/components/`, `src/core/`.
  - Acceptance Criteria: Stats are exported, serializable, and emit change signals.

- **Task: Basic Enemy Entity**
  - Goal: Create `scenes/entities/enemy.tscn` (`CharacterBody2D`) with idle/patrol state machine and aggro detection (Area2D).
  - Scope: `src/entities/enemy.gd`, `scenes/entities/`.
  - Dependencies: `StatsComponent`.

- **Task: Combat — Melee Attack**
  - Goal: Player can press Attack input; triggers hit detection on enemy; `DamageCalculator` resolves; enemy HP drops; enemy dies.
  - Scope: `src/entities/`, `src/services/damage_calculator.gd`.
  - Dependencies: Enemy Entity task.

- **Task: Item Pickup**
  - Goal: Create `ItemPickup` scene extending `Interactable`. On interact, adds `ItemDefinition` to player inventory slot.
  - Scope: `src/entities/item_pickup.gd`, `scenes/objects/`.
  - Dependencies: `InteractorComponent`, `ItemDefinition`.

- **Task: Inventory Component**
  - Goal: Create `InventoryComponent` (Node) with typed `Array[ItemDefinition]` storage, add/remove/has methods, serialization.
  - Scope: `src/components/inventory_component.gd`.

- **Task: Quest Log Stub (Data Only)**
  - Goal: Define `QuestDefinition` Resource with id, title, description, state enum. Load from `data/quests/`. No runtime UI yet.
  - Scope: `src/core/quest_definition.gd`, `data/quests/`.
