# ADR-006 — Hybrid 3D Terrain with 2D Billboard Sprites (Ragnarok Online Style)

## Status
Accepted

## Date
2026-10-01

## Context
OriginalRPG's visual goal is an authentic retro-MMO aesthetic inspired by classic online RPGs, most notably *Ragnarok Online*. 
While pure 2D tilemaps provide rapid top-down prototyping, they struggle to convey genuine verticality, multi-tiered rolling hills, and depth without perspective distortion against ¾-view character sprites. 
*Ragnarok Online* achieved its iconic aesthetic by placing 2D animated pixel-art character billboards inside a true 3D polygonal world with heightmapped terrain, variable elevation, dynamic lighting, and cast shadows.

## Requirements
1. **Verticality & Multilayer Terrain**: Real 3D hills, plateaus, slopes, and cliffs with true geometric elevation.
2. **Preserve 2D Pixel-Art Assets**: Continue using the handcrafted 8-directional animated character frames and monster sprites.
3. **Decoupled Architecture (ADR-002 Compliance)**: Underlying RPG mechanics (`CharacterStatsComponent`, `InventoryComponent`, `EquipmentComponent`, `DamageCalculator`, `ContentRegistry`) must remain 100% agnostic to whether the visual node is 2D or 3D.
4. **2D UI Compatibility**: The `CanvasLayer`-based user interface (`BasicInfoWindow`, `HUD`, floating text, menus) must render seamlessly over the 3D viewport.
5. **No Regressions**: Existing automated test coverage must be preserved while adding 3D hybrid verification.

## Options Considered

### Option A: Pure 2D TileMap Elevation with Taller Cliffs
- **Description**: Stay in 2D and expand cliff tiles to 2–3 tiles high with manual drop-shadow layers.
- **Advantages**: Stays within 2D nodes.
- **Disadvantages**: Still visually flat; lacks real perspective depth; cannot do true slopes or dynamic camera angles; high asset burden for multi-tile cliff variations.

### Option B: Hybrid 3D Terrain + 2D Billboard Sprites (Accepted)
- **Description**: 
  - World rendered via Godot 4's 3D engine (`Node3D`, `Camera3D`, `DirectionalLight3D`, textured 3D terrain meshes).
  - Characters rendered using `CharacterBody3D` with `Sprite3D` set to `BILLBOARD_FIXED_Y` displaying 2D pixel-art animations.
  - Camera positioned at an isometric ~45° downward tilt with smooth follow.
  - Real dynamic shadows cast by terrain and character drop shadows onto rolling hills.
- **Advantages**: Perfectly captures the *Ragnarok Online* / *Octopath Traveler* visual style; natural multi-tier elevation; true slopes with standard 3D physics navigation; UI remains identical on `CanvasLayer`.
- **Disadvantages**: Requires 3D physics collision and 3D player controller alongside 2D mechanics.

### Option C: Isometric 2D Diamond TileMap
- **Description**: 2:1 isometric tilemap projection.
- **Advantages**: Classic isometric look.
- **Disadvantages**: High asset drawing complexity; doesn't match Ragnarok Online's true 3D rolling hills.

## Decision
Adopt **Option B: Hybrid 3D Terrain + 2D Billboard Sprites**.
- Create `scenes/maps/test_world_3d.tscn` as the primary game world.
- Create `Player3D` (`src/entities/player_3d.gd`) and `Enemy3D` (`src/entities/enemy_3d.gd`) featuring `Sprite3D` billboards driven by the existing `SpriteFrames` animations.
- Maintain existing 2D test fixtures for full regression safety while introducing Group U tests for 3D world verification.

## Consequences
- **Positive**: Rich dimensional depth; genuine rolling hills and cliff ledges; real-time lighting and shadows; authentic Ragnarok Online aesthetic.
- **Neutral**: Characters move in 3D space (`Vector3(x, y, z)`), where X and Z represent ground coordinates and Y represents height.
- **Negative**: Adds 3D node variants to manage alongside existing components.
