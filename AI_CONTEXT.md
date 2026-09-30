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
**Player Character Foundation complete and stable. 123/123 automated tests pass.**
The player architecture has been expanded into a decoupled RPG character foundation:
- Player identity and progression parameters via data-driven `CharacterDefinition` resources (`data/characters/`).
- `CharacterStatsComponent` equipped with dual resource pools (Health + Mana), level progression, and dynamic additive stat modifiers.
- `EquipmentComponent` slot registry managing items and driving stat modifiers.
- `Player` controller managing character states (`ALIVE`, `DEAD`, `STUNNED`, `CASTING`), 4/8-direction movement facing tracking, and component aggregation.




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
4. Test.
5. Document additions/modifications/deletions.
6. Update project memory.
7. Leave a clear handoff.

## Source of Truth
Current repository state + documented ADRs + current project status.

If old documentation conflicts with verified code, correct the documentation.

