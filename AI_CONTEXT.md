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
Governance, project memory, and the core Godot 4 project foundation are initialized and verified. The repository contains `project.godot` (configured for Godot 4.7.2 Forward+), core directories (`src/`, `scenes/`, `assets/`, `tests/`), and a verified minimal test scene (`scenes/test_main.tscn`). Git repository initialization is pending.


## Undecided Technical Areas
- Programming language (GDScript vs C#)
- Game architecture (Node-based, component, data-driven, state machines)
- Networking architecture
- Backend language
- Database
- Long-term version-control workflow (Git repository initialization pending)

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

