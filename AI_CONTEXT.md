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
**Multi-Layer TileMapLayer Field Terrain Complete. 296/296 automated tests pass.**
- Multi-layer 2D `TileMapLayer` field architecture (`GroundLayer`, `ElevationLayer`, `DecorationLayer`) in `scenes/maps/test_world.tscn`.
- 20 custom 32×32 RGBA8 pixel-art tiles (`assets/tiles/ground/`) with custom data layers for `terrain_type` and `elevation` in `assets/tiles/tileset_green_field.tres`.
- Zero physics collision geometry on slopes/plateaus ensuring completely smooth, free player movement across rolling hills and ramps.
- Authentic Ragnarok Online inspired Basic Info Window (`src/ui/basic_info_window.gd`, `scenes/ui/basic_info_window.tscn`, `assets/ui/`) with live signal binding.
- Formal AI-assisted asset pipeline documented in `docs/assets/ASSET_PIPELINE.md` with complete manifest in `docs/assets/ASSET_MANIFEST.md`.
- Automated asset validation via `AssetValidator`, `scripts/validate_assets.gd`, and `scripts/validate_assets.ps1`.
- Centralized `ContentRegistry` loads, validates, and serves definitions from `res://data/{characters,enemies,items,skills}/`.
- All 296 automated tests pass across 20 groups.
- Standalone executable `build/OriginalRPG.exe` built and synchronized to `C:\Users\SAMI\Desktop\ProjectZero\OriginalRPG.exe`.





## Confirmed Technical Decisions
- Language: Statically typed GDScript (ADR-001)
- Architecture: Hybrid Composition + Resource-Driven Architecture (ADR-002)
- Persistence: Versioned structured JSON with atomic writes (ADR-003)
- Content Architecture: Data-Driven Definitions with Strict Schema Validation (ADR-004)
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

