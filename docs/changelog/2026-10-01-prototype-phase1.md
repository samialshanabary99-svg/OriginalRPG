# Changelog — 2026-10-01 — Phase 1 Core Prototype

## Summary
Implemented the first minimal playable prototype of OriginalRPG — the core gameplay loop from Main Menu → Load World → Control Player → Interact with Object → Return to Menu. All 31 automated headless tests pass. Runtime smoke test exits cleanly.

---

## ADDED

### Scenes
| File | Description |
|------|-------------|
| `scenes/ui/main_menu.tscn` | Title screen with Start Game and Exit buttons. |
| `scenes/maps/test_world.tscn` | Bounded play area: coloured background, StaticBody2D boundary walls, AncientMonument, Player instance, HUD. |
| `scenes/entities/player.tscn` | Player scene: `CharacterBody2D` + `Sprite2D` + `CollisionShape2D` + `Camera2D` + `StatsComponent` + `InteractorComponent`. |
| `scenes/objects/ancient_monument.tscn` | Interactive world object: `Area2D` + `StaticBody2D` body + `CollisionShape2D` + `PromptLabel` + `Sprite2D`. |
| `scenes/ui/hud.tscn` | In-game HUD: `CanvasLayer` with HP label, dialogue panel (hidden by default), Return to Menu button. |

### Scripts
| File | Description |
|------|-------------|
| `src/ui/main_menu.gd` | `Control` script: Start → `change_scene_to_file(test_world.tscn)`; Quit → `get_tree().quit()`. |
| `src/entities/player.gd` | `CharacterBody2D` script: WASD/Arrow input, `_apply_movement()`, `interact()`, `player_moved` signal. Guarded `move_and_slide()` with `is_inside_tree()` check. |
| `src/entities/ancient_monument.gd` | `Interactable` subclass: lore text, interaction counter, `inspection_triggered` signal. Core signal wired in `_init()` for testability. |
| `src/entities/test_world.gd` | `Node2D` coordinator: wires monument → HUD dialogue; ESC → scene change to main menu. |
| `src/ui/hud.gd` | `CanvasLayer` script: `bind_player()` connects `StatsComponent.health_changed`; `show_dialogue()` / `hide_dialogue()`. |
| `src/components/interactable.gd` | Base `Area2D` for interactive objects: `interact()`, `can_interact()`, `set_focused()`. |
| `src/components/interactor_component.gd` | `Area2D` player component: proximity detection, closest-target selection, `try_interact()`. |

---

## MODIFIED

| File | Change |
|------|--------|
| `src/components/stats_component.gd` | Removed GDScript property setter (unreliable in headless test context). Added explicit `apply_damage()`, `heal()`, and `set_health()` methods. Signals now emit reliably. |
| `src/entities/ancient_monument.gd` | Moved `interacted.connect(_on_interacted)` from `_ready()` to `_init()` so signal fires during headless instantiation tests. Added `has_node()` guards in `_on_focused`/`_on_unfocused` to prevent null-ref when child nodes absent. |
| `tests/test_runner.gd` | Fully replaced 4-test foundation runner with 31-test comprehensive suite covering 6 groups: DamageCalculator, StatsComponent, Scene Loading, Player Composition, Movement, Interaction. Uses `get_root().add_child()` for tree-dependent tests. |
| `project.godot` | Updated main scene to `scenes/ui/main_menu.tscn`; added input actions (`move_left`, `move_right`, `move_up`, `move_down`, `interact`, `pause_menu`); set viewport to 1280×720. |
| `AI_CONTEXT.md` | Updated Current State to Phase 1 complete. |
| `PROJECT_STATUS.md` | Updated Phase, Working Systems, Known Issues. Added Phase 2 planning notes. |
| `ROADMAP.md` | Marked all Phase 1 items complete with [x]. |
| `docs/tasks/TODO.md` | Replaced Phase 1 tasks with Phase 2 backlog. |
| `docs/tasks/COMPLETED.md` | Added Phase 1 prototype completion entry. |

---

## DELETED
None.

---

## TESTS PERFORMED

### Automated Headless Tests (`tests/test_runner.gd`)
```
31 tests | 0 failures — ALL TESTS PASSED.

[Group A] DamageCalculator          — 4/4
[Group B] StatsComponent            — 7/7
[Group C] Scene loading             — 5/5
[Group D] Player composition        — 5/5
[Group E] Player movement           — 4/4
[Group F] Interaction system        — 6/6
```

### Runtime Smoke Test
```
godot --headless --quit-after 60
Exit code: 0 (clean)
```

---

## KNOWN ISSUES / LIMITATIONS

- No real sprite art; player, monument, and world objects use Godot placeholder icon.
- No audio system yet.
- Camera zoom not tuned (default).
- No save/load yet.
- Godot executable not on system PATH — must use absolute path for all commands.

---

## NEXT RECOMMENDED TASK
**Begin Phase 2 — RPG Systems.** Suggested entry point: *Expand Player Stats Model* (attack, defence, level, experience) as the foundation for combat and progression systems.
