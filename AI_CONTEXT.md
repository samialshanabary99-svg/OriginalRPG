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
**Phase 2 — RPG Systems complete and stable. 81/81 automated tests pass.**
Built on the Phase 1 prototype: `CharacterStatsComponent` (attack, defence, level, XP, level-up loop), `Enemy` entity (patrol/aggro AI, melee combat, `receive_hit()`, XP reward on death), `InventoryComponent`, `ItemPickup`, `ItemDefinition` (Category enum, serialize/deserialize), `QuestDefinition` (data stub), expanded HUD (HP + Level + XP), and `DamageCalculator.xp_reward()`.



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

