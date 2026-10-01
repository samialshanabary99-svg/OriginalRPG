# Agent Change Record

```yaml
agent: Antigravity (Senior QA & Architecture Review)
date: 2026-10-01
task: Exhaustive Repository Audit, Bug Fixes & Project Memory Alignment
status: completed

summary:
  Conducted an exhaustive repository audit covering Code, Scenes, Architecture, Documentation, and Change History.
  Identified and safely resolved a HIGH-severity mathematical accumulation bug in CharacterStatsComponent where max_health
  compounded unbounded on modifier additions/removals. Cleaned up signal declaration placement in Enemy. Proposed ADR-005
  for unified skill combat resolution. Completely eliminated documentation drift across ARCHITECTURE.md, README.md,
  ROADMAP.md, PROJECT_STATUS.md, AI_CONTEXT.md, and TODO.md. Added regression tests bringing suite to 239/239 passing.
  Rebuilt standalone Windows executable and validated headless execution.

added:
  - docs/decisions/ADR-005-unified-skill-combat-resolution.md
  - docs/reports/2026-10-01-repository-audit.md
  - docs/changelog/2026-10-01-repository-audit-and-doc-alignment.md

modified:
  - src/components/character_stats_component.gd
  - src/entities/enemy.gd
  - tests/test_runner.gd
  - ARCHITECTURE.md
  - README.md
  - ROADMAP.md
  - PROJECT_STATUS.md
  - AI_CONTEXT.md
  - docs/tasks/TODO.md
  - docs/tasks/COMPLETED.md

deleted:
  - none

renamed:
  - none

architecture_changes:
  - Formulated ADR-005 (Proposed) to unify offensive skill damage calculations and experience awards via DamageCalculator.resolve_attack().
  - Decoupled base_max_health in CharacterStatsComponent to maintain pure additive modifier symmetry across all attributes (health, mana, attack, defence, speed).

dependencies:
  - none

tests:
  - Automated headless test suite (tests/test_runner.gd) expanded with max_health modifier removal regression assertions (239 tests, 0 failures).
  - Standalone Windows build rebuilt (scripts/build.ps1) and verified via 60-frame headless smoke test.

known_issues:
  - Damaging skills do not award XP on defeat (documented in proposed ADR-005).
  - Non-player entities (Enemy, AncientMonument) use placeholder icon.svg pending asset pipeline generation.

next_agent:
  Proceed to Phase 3 — Save/Load & Persistence (SaveService JSON persistence adhering to ADR-003, and UI save/load button integration).
```

## Detailed Notes

### 1. High-Severity Logic Bug Fix: `CharacterStatsComponent.max_health` Accumulation
- **Root Cause:** In `CharacterStatsComponent._recompute_final_stats()`, health modifiers were applied directly to `max_health` via `max_health = max_health + mod_max_health`. Unlike `base_attack` or `base_max_mana`, there was no `base_max_health` variable to anchor the calculation. Consequently, every time any modifier was added or removed (e.g., equipping a weapon, un-equipping a ring), `mod_max_health` was repeatedly added to the accumulated `max_health`, causing maximum health to climb indefinitely and never return to baseline upon un-equipping.
- **Fix:** Added `@export var base_max_health: int = 100`, updated `_ready()` and `_apply_definition()` to set `base_max_health`, updated `_recompute_final_stats()` to compute `max_health = base_max_health + mod_max_health`, updated `_level_up()` to scale `base_max_health`, and preserved `base_max_health` across serialization/deserialization. Added 2 regression tests in Group N.

### 2. Code Convention Cleanups
- **`Enemy.targeted` Signal:** Moved `signal targeted(enemy: Enemy)` from line 100 in the middle of state machine code up to line 10 at the top of `src/entities/enemy.gd` adhering to `docs/PROJECT_CONVENTIONS.md`.

### 3. Documentation Drift Alignment
- **`ARCHITECTURE.md`:** Documented ADR-004, proposed ADR-005, updated test metrics (239 tests), and added comprehensive architectural sections for `ContentRegistry`, 8-directional player animations, and the AI asset pipeline.
- **`README.md`:** Updated Section 3 technology decisions table: transitioned Programming language (GDScript), Game architecture (Hybrid Composition + Resource-Driven), Version control strategy (Git on main), and Content architecture (Data-Driven JSON) from Undecided/To be formalized to Confirmed.
- **`ROADMAP.md`:** Updated Phase 2 with all completed systems and accurate test metrics; refined Phase 3 and Phase 4 objectives.
- **`PROJECT_STATUS.md` & `AI_CONTEXT.md`:** Corrected outdated "no sprite art" notice, aligned test counts, and noted proposed ADR-005.
- **`docs/tasks/TODO.md`:** Removed already-completed Phase 2 tasks (equipment stat binding, skills system) and aligned future backlog with Phase 3 persistence and Phase 4 content.
