# Changelog — 2026-10-01 — Phase 2 RPG Systems

## Summary
Implemented the Phase 2 RPG systems layer: combat stats, leveling, enemy AI, inventory, item pickup, and quest data. 81 automated headless tests pass. Runtime smoke test clean.

---

## ADDED

### Scripts
| File | Description |
|------|-------------|
| `src/components/character_stats_component.gd` | Extends `StatsComponent` with `attack`, `defence`, `speed_stat`, `level`, `experience`. Level-up loop with stat scaling, `gain_experience()`, `xp_to_next_level()`. Full serialization. |
| `src/components/inventory_component.gd` | `Node` component: `Array[ItemDefinition]` storage, `add_item()`, `remove_item()`, `has_item()`, `count_item()`, `is_full()`, capacity limit, `item_added`/`item_removed`/`inventory_changed` signals, serialize/deserialize. |
| `src/entities/enemy.gd` | `CharacterBody2D` with `IDLE/PATROL/AGGRO/DEAD` state machine, `AggroArea` detection, melee `_perform_attack()`, `receive_hit()`, `enemy_died` signal, XP grant on death. |
| `src/entities/item_pickup.gd` | `Interactable` subclass that grants its `ItemDefinition` to the interactor's `InventoryComponent`. Optional respawn timer. |
| `src/core/quest_definition.gd` | `Resource` data stub: `quest_id`, `title`, `description`, `recommended_level`, `xp_reward`, `gold_reward`, `QuestState` enum, serialize/deserialize. |
| `data/items/herb_basic.json` | Sample item data file (JSON). |

### Scenes
| File | Description |
|------|-------------|
| `scenes/entities/enemy.tscn` | Enemy `CharacterBody2D` on collision layer 8, red-tinted sprite, `CharacterStatsComponent` (50HP, 8atk, 2def), `AggroArea` (150px), `AttackArea` (30px). |
| `scenes/objects/item_pickup.tscn` | `Area2D` on layer 4, gold-tinted sprite, pickup collision trigger. |

---

## MODIFIED

| File | Change |
|------|--------|
| `src/entities/player.gd` | `StatsComponent` → `CharacterStatsComponent`. Added `attack_cooldown`, `_attack_timer`, `_try_attack()` checking `AttackArea` overlaps, `player_attacked` signal, `attack` input action support. |
| `scenes/entities/player.tscn` | Replaced `StatsComponent` node with `CharacterStatsComponent`; added `AttackArea` (collision_mask=8). Fixed ext_resource declarations. |
| `src/ui/hud.gd` | Added `LevelLabel`, `XPLabel` binding to `CharacterStatsComponent.level_up` and `experience_changed` signals. Falls back gracefully to plain `StatsComponent`. |
| `scenes/ui/hud.tscn` | Added `LevelLabel` ("Lv 1") and `XPLabel` ("XP: 0 / 100") nodes to `VBoxContainer`. Updated controls hint. |
| `src/entities/test_world.gd` | Added `_register_enemies()`: wires all `Enemy` children's `enemy_died` signal → `_on_enemy_died()` → `player.stats.gain_experience(xp)` + HUD dialogue pop. |
| `src/entities/enemy.gd` | Added defensive `stats` lookup in `_ready()` and `receive_hit()` for headless test robustness. |
| `src/entities/ancient_monument.gd` | No change (already fixed in Phase 1 session). |
| `src/core/item_definition.gd` | Renamed `id` → `item_id`, `is_stackable` → `stackable`. Added `Category` enum. Added `serialize()`/`deserialize()`. |
| `src/services/damage_calculator.gd` | Added `xp_reward(enemy_level)` static helper. |
| `project.godot` | Added `attack` input action (J key + Left Mouse Button). |
| `tests/test_runner.gd` | Expanded from 31 to 81 tests across 12 groups (A–L). Added Phase 2 groups G–L. |

---

## DELETED
None.

---

## TESTS PERFORMED

### Automated Headless Tests
```
81 tests | 0 failures — ALL TESTS PASSED.

[A] DamageCalculator          6/6
[B] StatsComponent            7/7
[C] Scene loading             7/7
[D] Player composition        7/7
[E] Player movement           4/4
[F] Interaction system        3/3
[G] CharacterStatsComponent  10/10
[H] InventoryComponent       10/10
[I] ItemDefinition            5/5
[J] QuestDefinition           5/5
[K] Enemy entity              7/7
[L] XP and leveling          10/10
```

### Runtime Smoke Test
```
godot --headless --quit-after 60 → exit code 0 (clean)
```

---

## ARCHITECTURE NOTES
- `CharacterStatsComponent` cleanly extends `StatsComponent` via inheritance — existing code using `StatsComponent` references still works.
- Enemy AI is self-contained; adding new enemy types means extending `enemy.gd` or creating new scripts with the same interface.
- `InventoryComponent` is decoupled from UI — UI listens to signals.
- `ItemDefinition` is a `Resource` loaded from `data/items/`; runtime state (count, equipped) lives in `InventoryComponent`.
- `QuestDefinition` is data-only; runtime quest state will go into a future `QuestLog` component.

---

## NEXT RECOMMENDED TASK
**Phase 3 — Save/Load System:** implement JSON persistence for player `CharacterStatsComponent` and `InventoryComponent`, following ADR-003 (versioned JSON, atomic writes, `user://` path).
