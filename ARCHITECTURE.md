# Architecture

## Status
Early-stage and intentionally flexible.

## Confirmed Decisions
- Target Engine: Godot 4 (4.7.2 Forward+)
- Mode: Single-player initially
- Development Model: AI-first with human supervision
- Agent Concurrency: Exactly one active AI agent editing at a time
- Repository Memory: Documentation-driven persistence (ADRs, manifests, changelogs, task tracking)
- Scripting Language: Statically typed GDScript ([ADR-001](docs/decisions/ADR-001-scripting-language.md))
- Core Game & Data Architecture: Hybrid Composition + Resource-Driven Architecture ([ADR-002](docs/decisions/ADR-002-game-and-data-architecture.md))
- Save/Load Architecture: Versioned structured JSON with atomic file writing ([ADR-003](docs/decisions/ADR-003-save-load-architecture.md))
- Technical Conventions: Established in `docs/PROJECT_CONVENTIONS.md`

## Verified Existing Architecture
- **Governance & Documentation System:** Multi-agent coordination protocols, templates, and task tracking directories exist under `docs/`.
- **Engine Baseline:** Godot 4.7.2 Forward+ project initialized with `project.godot`, standard directory boundaries (`src/`, `scenes/`, `assets/`, `data/`, `tests/`), and startup scene `scenes/test_main.tscn`.
- **Core Models & Components:**
  - `ItemDefinition` (`src/core/item_definition.gd`): Custom `Resource` template for item definitions.
  - `DamageCalculator` (`src/services/damage_calculator.gd`): Pure static service for decoupled combat arithmetic.
  - `StatsComponent` (`src/components/stats_component.gd`): Reusable entity component for attributes, damage, healing, and JSON serialization.
- **Testing Framework:** Headless test runner script (`tests/test_runner.gd`) executing automated unit tests.


### 4. Future Multiplayer & Networking (Exploratory / Deferred)
- **Status:** Deferred until single-player core mechanics prove stable.
- **Evaluated Options:** Authoritative Headless Godot Server (ENet/WebRTC/WebSocket) vs Custom External Game Server (Go/Rust/C#).
- **Guideline:** Keep game rules, damage math, and stat mutations decoupled from rendering/input nodes so logic can be shared or ported to an authoritative server in the future.

### 5. Backend & Database (Exploratory / Deferred)
- **Status:** Not required for single-player.
- **Evaluated Options:** PostgreSQL, SQLite, or Redis. Only evaluated in the context of persistent player accounts and world state if dedicated multiplayer services are formally introduced.

## Rule
Do not create a major architectural commitment without an ADR.

## Future
As decisions are approved, this document becomes the authoritative high-level map of the technical system.

