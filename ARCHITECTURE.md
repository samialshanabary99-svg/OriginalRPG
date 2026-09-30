# Architecture

## Status
Early-stage and intentionally flexible.

## Confirmed Decisions
- Target Engine: Godot 4
- Mode: Single-player initially
- Development Model: AI-first with human supervision
- Agent Concurrency: Exactly one active AI agent editing at a time
- Repository Memory: Documentation-driven persistence (ADRs, manifests, changelogs, task tracking)

## Verified Existing Architecture
- **Governance & Documentation System:** Multi-agent coordination protocols, templates, and task tracking directories exist under `docs/`.
- **Engine Baseline:** Godot 4.7.2 Forward+ project initialized with `project.godot`, standard directory boundaries (`src/`, `scenes/`, `assets/`, `tests/`), and a clean test root scene (`scenes/test_main.tscn`).
- **Gameplay Architecture:** Not yet implemented (pending language and node design decisions).



## Not Yet Decided
- GDScript vs C#
- Scene/node architecture conventions
- Data-driven architecture
- ECS usage or non-ECS design
- Networking model
- Backend
- Database
- Persistence architecture
- Multiplayer synchronization
- Deployment architecture

## Rule
Do not create a major architectural commitment without an ADR.

## Future
As the architecture stabilizes, this document becomes the authoritative high-level map of the technical system.
