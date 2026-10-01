# 2026-10-02 — Milestone: Hybrid 3D Terrain + 2D Billboard Presentation (ADR-006)

## Summary
Transitioned OriginalRPG's world presentation to an authentic **Ragnarok Online / Octopath Traveler style Hybrid 3D architecture** under ADR-006. Replaced flat 2D tilemaps with genuine 3D multi-tier rolling terrain, true height elevations, dynamic sunlight with real-time shadow casting, and 2.5D animated character billboard sprites.

## Key Changes
1. **Architectural Decision Record (ADR-006)**:
   - Formally accepted and documented in `docs/decisions/ADR-006-hybrid-3d-world-presentation.md`.
   - Adopts Godot 4's 3D engine for terrain and world geometry while preserving 2D pixel-art character animations and 2D CanvasLayer UI.

2. **3D Multi-Tier Rolling Terrain (`scenes/maps/test_world_3d.tscn`, `src/entities/test_world_3d.gd`)**:
   - Generates a procedural 50m × 50m heightmapped landscape with:
     - **Tier 0**: Low rolling meadow valley.
     - **Tier 1**: Elevated grassy plateau (+2.2m) with a smooth walkable dirt ramp.
     - **Tier 2**: High lookout ridge (+3.8m) with rocky cliff faces.
   - Vertex coloring applies lush meadow green to flat planes, transition greens to gentle slopes, and warm earth/rock tones to cliffs.
   - Accurate trimesh collision (`ConcavePolygonShape3D`) ensures completely smooth CharacterBody3D navigation over slopes and ramps.

3. **Lighting & Environment**:
   - `DirectionalLight3D` providing angled sunlight (`-45° pitch, 45° yaw`) with real-time soft shadow casting.
   - `WorldEnvironment` with procedural blue sky and Filmic tonemapping.

4. **Player3D Controller (`src/entities/player_3d.gd`, `scenes/entities/player_3d.tscn`)**:
   - `CharacterBody3D` with 3D physics movement, gravity, and slope snapping.
   - `AnimatedSprite3D` in `BILLBOARD_FIXED_Y` mode driven by `player_sprite_frames.tres` with 8-directional idle animations.
   - Ground drop shadow disc under character feet.
   - Camera3D attached at a classic Ragnarok Online ~38° downward angle with narrow FOV for authentic depth.
   - Decoupled integration with `CharacterStatsComponent`, `InventoryComponent`, and `EquipmentComponent`.

5. **Universal 2D UI Compatibility**:
   - Updated `HUD` and `BasicInfoWindow` to bind to both 2D and 3D player nodes seamlessly.
   - Main menu now launches `test_world_3d.tscn`.

6. **Test Coverage & Verification**:
   - Added **Group U** to `tests/test_runner.gd`, expanding test suite from 296 to **323 automated tests** (0 failures).
   - Reimported assets and exported Windows desktop binary to `build/OriginalRPG.exe`.
   - Updated desktop shortcut `Play OriginalRPG.lnk`.

## Verification
- Automated tests: 323/323 PASS (`tests/test_runner.gd`)
- Asset validator: 70/70 files compliant (`scripts/validate_assets.gd`)
- Standalone EXE smoke test: exit code 0 (`build/OriginalRPG.exe --headless --quit`)
