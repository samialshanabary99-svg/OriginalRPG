# TODO

## Phase 1 — Core Prototype Tasks
- **Task: Player Character Scene & Movement**
  - Goal: Create `scenes/entities/player.tscn` (`CharacterBody2D`) with basic 8-directional / click-to-move input and collision.
  - Scope: `src/entities/player.gd`, `scenes/entities/player.tscn`.
  - Dependencies: `StatsComponent`.
  - Acceptance Criteria: Player moves in 2D space, respects collisions, and runs headlessly in test runner.

- **Task: Camera Follower**
  - Goal: Add smoothed `Camera2D` following the player character with configurable zoom and drag margins.
  - Scope: `scenes/entities/player.tscn`.

- **Task: Prototype Environment / Map**
  - Goal: Create a basic testing map scene (`scenes/maps/test_world.tscn`) with boundaries and tilemap / placeholder background.
  - Scope: `scenes/maps/`.

- **Task: Health HUD Display**
  - Goal: Create lightweight HUD connecting to `StatsComponent` `health_changed` signal.
  - Scope: `scenes/ui/`, `src/ui/`.



