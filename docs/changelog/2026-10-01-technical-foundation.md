# Agent Change Record

```yaml
agent: Agent-1 (Architecture & Foundation)
date: 2026-10-01
task: Technical Foundation, Conventions & Architecture Baseline
status: completed

summary: Formalized and accepted ADR-001, ADR-002, and ADR-003. Created docs/PROJECT_CONVENTIONS.md. Scaffolded the approved folder structure (src/core, src/components, src/services, src/entities, src/ui, data/items, data/skills, data/monsters, tests/unit, tests/integration). Implemented core baseline scripts (ItemDefinition, DamageCalculator, StatsComponent) and an automated headless test runner passing all 4 unit tests. Synchronized all memory files.

added:
  - docs/decisions/ADR-001-scripting-language.md
  - docs/decisions/ADR-002-game-and-data-architecture.md
  - docs/decisions/ADR-003-save-load-architecture.md
  - docs/PROJECT_CONVENTIONS.md
  - src/core/item_definition.gd
  - src/services/damage_calculator.gd
  - src/components/stats_component.gd
  - tests/test_runner.gd
  - docs/changelog/2026-10-01-technical-foundation.md

modified:
  - AI_CONTEXT.md
  - PROJECT_STATUS.md
  - ARCHITECTURE.md
  - ROADMAP.md
  - docs/tasks/TODO.md
  - docs/tasks/COMPLETED.md

deleted:
  - none

renamed:
  - none

architecture_changes:
  - Approved ADR-001: Statically Typed GDScript as primary scripting language.
  - Approved ADR-002: Hybrid Composition + Resource-Driven Architecture for entities and data.
  - Approved ADR-003: Versioned structured JSON serialization for persistence.
  - Established project conventions covering naming, typing, signals, scene root composition, and headless test runners.

dependencies:
  - Godot Engine 4.7.2 stable

tests:
  - Headless test runner (tests/test_runner.gd): 4/4 tests passed (DamageCalculator math, min damage clamp, StatsComponent damage & signal emission, StatsComponent serialize/deserialize roundtrip).
  - Headless runtime test: godot --headless --quit-after 30 exited with code 0.

known_issues:
  - Godot executable is not in system PATH (accessed via absolute binary path).

next_agent: Proceed with Phase 1: Create player scene (CharacterBody2D) with 2D movement and camera follower.
```

## Detailed Notes
1. **ADR Formalization:**
   - ADR-001 (GDScript): Chosen to eliminate toolchain friction (.NET SDK is not installed), leverage native engine serialization, and optimize AI iteration speed.
   - ADR-002 (Hybrid Composition): Entities use modular component nodes (`StatsComponent`), while definitions (items, skills) use custom `Resource` scripts. Calculations are decoupled into pure static services (`DamageCalculator`).
   - ADR-003 (JSON Persistence): Saves will use versioned JSON dictionaries with atomic writes rather than direct `.tres` binary execution.
2. **Conventions Established:**
   - Created `docs/PROJECT_CONVENTIONS.md` providing clear rules for naming, strict type hints, folder layout, and component boundaries.
3. **Automated Testing:**
   - Created `tests/test_runner.gd` runnable via `godot --headless --script tests/test_runner.gd`. All tests execute headlessly and report pass/fail codes.
