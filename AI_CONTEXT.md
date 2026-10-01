# AI Context

## Project
OriginalRPG

## Vision
An original RPG inspired by the broad design space of classic online RPGs, with its own world, characters, systems, art direction, and identity.

## Engine
Godot 4

## Development
AI-first with manual supervision and manual asset work where needed.

## Agent Model
Multiple AI tools may be used across the project's lifetime, but only one agent actively edits the project at a time.

## Current State
**Combat & Player Presentation complete and stable. 163/163 automated tests pass.**
- Player visuals integrated with 8-directional animated idle breathing sprites (`AnimatedSprite2D`, `player_sprite_frames.tres`).
- Mathematical 8-octant direction calculation dynamically drives directional animations on movement.
- Player targeting, deterministic combat calculations (`CombatResult`, `DamageCalculator`), and health/defeat/XP flow fully operational.
- Unified execution shared between Player and Enemy entities.
- All 163 automated tests pass across 16 groups.
- Standalone executable `build/OriginalRPG.exe` built and synchronized to `C:\Users\SAMI\Desktop\ProjectZero\OriginalRPG.exe`.





## Confirmed Technical Decisions
- Language: Statically typed GDScript (ADR-001)
- Architecture: Hybrid Composition + Resource-Driven Architecture (ADR-002)
- Persistence: Versioned structured JSON with atomic writes (ADR-003)
- Conventions: Documented in `docs/PROJECT_CONVENTIONS.md`

## Undecided Technical Areas (Deferred)
- Networking architecture (deferred until single-player prototype proves stable)
- Backend language (deferred; not required for single-player)
- Database (deferred; not required for single-player)


Do not invent permanent decisions. Use ADRs when a major decision becomes necessary.

## Agent Priority
1. Preserve existing functionality.
2. Understand before changing.
3. Make focused changes.
4. Test (run automated test suite tests/test_runner.gd).
5. Document additions/modifications/deletions.
6. Update project memory.
7. Rebuild standalone executable via scripts/build.ps1 after every code update and verify with headless smoke test.
8. Leave a clear handoff.

## Source of Truth
Current repository state + documented ADRs + current project status.

If old documentation conflicts with verified code, correct the documentation.

