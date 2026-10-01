# Project Conventions — OriginalRPG

This document establishes the project's technical conventions for all development agents.

---

## 1. Language & Scripting Conventions

- **Language:** Statically typed GDScript (see [ADR-001](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/docs/decisions/ADR-001-scripting-language.md)).
- **Type Safety:** Always use explicit type annotations for variables, constants, parameters, and function return types:
  ```gdscript
  var speed: float = 120.0
  var current_hp: int = 100
  func take_damage(amount: int) -> int:
  ```
- **Inferred Typing:** Use `:=` only when the type is obvious from the right-hand side literal or constructor:
  ```gdscript
  var velocity := Vector2.ZERO
  ```
- **Class Names:** Use `PascalCase` for `class_name` definitions:
  ```gdscript
  class_name StatsComponent
  extends Node
  ```
- **Files & Directories:** Use `snake_case.gd` for all file and folder names:
  - `src/components/stats_component.gd`
  - `src/core/math_utils.gd`
- **Signals:** Use past-tense `snake_case` verbs or explicit event descriptors:
  ```gdscript
  signal health_changed(new_health: int, max_health: int)
  signal died()
  ```

---

## 2. Directory Layout Conventions

```text
OriginalRPG/
├── .godot/                  # Cache & import data (ignored in Git)
├── assets/                  # Media assets (sprites, audio, fonts)
│   ├── sprites/
│   ├── audio/
│   └── ui/
├── data/                    # Static game data (.tres Resources)
│   ├── items/
│   ├── monsters/
│   └── skills/
├── docs/                    # AI memory, ADRs, tasks, changelogs
├── scenes/                  # Godot scene files (.tscn)
│   ├── entities/
│   ├── maps/
│   └── ui/
├── src/                     # All source code (.gd)
│   ├── components/          # Reusable component nodes
│   ├── core/                # Data structures, definitions, base Resources
│   ├── entities/            # Controller scripts for character scenes
│   ├── services/            # Pure calculation or management singletons
│   └── ui/                  # UI view scripts
└── tests/                   # Automated tests
    ├── unit/                # Pure logic & math unit tests
    └── integration/         # Scene & interaction tests
```

---

## 3. Scene & Node Conventions

- **Root Nodes:** Every reusable scene must have an appropriately typed root node with a meaningful `PascalCase` name matching the scene filename:
  - `player.tscn` -> Root node `Player` (`CharacterBody2D`)
- **Composition over Inheritance:** Use child component nodes for capabilities:
  - Add `StatsComponent` node for entities that have HP/mana.
  - Add `HitboxComponent` node for collision handling.
  - Add `InteractionComponent` node for interactable objects.
- **Node Paths:** Never hardcode absolute node paths (`get_node("/root/...")`). Use `@onready @export var` or signal connections.
- **Decoupled UI:** UI scenes must never manipulate entity internals directly. UI elements listen to signals and emit user intentions.

---

## 4. Resource & Data Conventions

- **Static Definitions:** Inherit from custom `Resource` scripts defined in `src/core/`:
  - `item_definition.gd` extends `Resource`
  - `skill_definition.gd` extends `Resource`
- **Resource Placement:** Saved as `.tres` in `res://data/<category>/`.
- **Immutability at Runtime:** Treat static `Resource` definitions as read-only templates. Never mutate `.tres` fields during gameplay. Dynamic mutations belong in entity components.

---

## 5. Serialization & Save/Load Conventions

- Stateful components implement a standard serialization contract:
  ```gdscript
  func serialize() -> Dictionary:
      return {}

  func deserialize(data: Dictionary) -> void:
      pass
  ```
- Save files are written as versioned JSON to `user://saves/` via atomic file writing (see [ADR-003](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/docs/decisions/ADR-003-save-load-architecture.md)).

---

## 6. Testing Conventions

- **Unit Tests:** Placed under `tests/unit/` using the prefix `test_*.gd`.
- **Headless Execution:** All core calculation logic must run headlessly without requiring a display or window.
- **Runner:** Tested via headless Godot execution:
  ```powershell
- Before marking any gameplay task complete, run the test runner and verify zero failures.

---

## 7. Build & Executable Protocol

- **Automated Build Script:** Located at `scripts/build.ps1` (with `scripts/build.bat` for one-click rebuilds).
- **Mandate:** After every code update that alters gameplay, components, scenes, or assets, the agent MUST run `scripts/build.ps1`.
- **Target Deliverables:**
  - Primary executable: `build/OriginalRPG.exe` (embedded PCK, fully standalone).
  - Convenience copy: `C:\Users\SAMI\Desktop\ProjectZero\OriginalRPG.exe`.
  - Desktop shortcut: `Play OriginalRPG.lnk` on user desktop.
- **Verification Requirement:**
  - Always verify the newly built executable headlessly:
    ```powershell
    & "build/OriginalRPG.exe" --headless --quit-after 60
    ```
  - Exit code must be 0 with zero fatal errors.

