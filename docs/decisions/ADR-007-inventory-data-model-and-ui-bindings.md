# ADR-007 — Inventory Component Enhancements & UI Window Data Binding

## Status
Accepted

## Date
2026-10-05

## Agent
Antigravity

## Context
Implementing the Ragnarok Online-style Inventory Window and Item Information Window required expanding the capabilities of the item and inventory systems. The existing `InventoryComponent` held a simple `Array[ItemDefinition]` (`items`), provided basic `add_item()` / `remove_item()`, and calculated weight assuming 1 unit of weight per item. It lacked:
- Grouped stack querying for grid representation (quantity per distinct item).
- Stack-level "Favorite" tagging (allowing any item to be marked as favorite without changing item archetypes).
- Item-defined weight values (`ItemDefinition.weight`).
- Consumable item execution (`use_item()`) integrating with existing `StatsComponent` / `CharacterStatsComponent` recovery logic.
- Controlled item dropping (`drop_item()`) supporting "Lock Item Drop" safety.

## Requirements
1. **Single Source of Truth:** Do NOT build a secondary parallel inventory model; extend `InventoryComponent` directly.
2. **Backward Compatibility:** All existing tests, serialization schemas, and callers of `add_item()`, `remove_item()`, and `has_item()` must continue to work without breaking.
3. **Data Integrity:** Item definitions remain immutable templates (`Resource`), with instance state (favorites, quantities) managed by `InventoryComponent`.
4. **Input Isolation:** UI window interactions must never propagate into 3D gameplay input (preventing unintended click-to-move and combat targeting).

## Options Considered

### Option A: Separate Inventory UI Model / Wrapper Object
Create a dedicated `InventorySlotModel` class wrapping items with UI state.
- **Pros:** Completely isolates UI data structures from core logic.
- **Cons:** Introduces redundant duplication, synchronization overhead between UI model and `InventoryComponent`, and unnecessary abstraction layers.

### Option B: Extend InventoryComponent & ItemDefinition (Selected)
- Add `@export var weight: int = 10` and formatting helpers (`get_type_text()`, `get_stat_text()`) to `ItemDefinition`.
- Add `favorites: Dictionary` to `InventoryComponent` keyed by `item_id`.
- Add `get_stacks()` helper returning aggregated `Array[Dictionary]` (`item`, `quantity`, `is_favorite`) for grid display.
- Add `use_item(item, user)` and `drop_item(item, count)` methods directly to `InventoryComponent`.
- Preserve `items: Array[ItemDefinition]` and backward-compatible serialization.
- **Pros:** Clean, centralized, fully compatible with existing serialization, zero duplication.
- **Cons:** Adds minor UI-supporting query methods to the component.

## Decision
Selected **Option B**.
- `ItemDefinition` now declares `weight: int = 10` with default serialization and formatting helpers.
- `InventoryComponent` aggregates items into stacks via `get_stacks()`, computes total weight as `sum(item.weight * count)`, and stores favorite flags in a serializable dictionary.
- `InventoryWindow` and `ItemInfoWindow` bind to `InventoryComponent` via `HUD.bind_player()` and listen to `inventory_changed`.

## Consequences
- **Positive:** UI windows seamlessly reflect inventory changes in real time. Full test suite (646 tests) remains completely green with 0 regressions.
- **Negative:** None. Minimal footprint, strictly additive changes.
- **Trade-offs:** `favorites` is tracked by `item_id`, meaning favoriting an item marks stacks of that item ID as favorite in the current bag.

## Reversibility
Easy. Methods are additive; removing them or refactoring into specialized wrappers can be done cleanly if needed.

## Related Systems
- `src/components/inventory_component.gd`
- `src/core/item_definition.gd`
- `src/ui/inventory_window.gd`
- `src/ui/item_info_window.gd`
- `src/ui/item_slot.gd`
- `src/ui/hud.gd`
