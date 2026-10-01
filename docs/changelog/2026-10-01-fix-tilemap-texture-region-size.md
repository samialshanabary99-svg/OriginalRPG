# 2026-10-01 — Fix: TileMapLayer Floor Rendering (texture_region_size)

## Summary
Fixed the broken multi-layer TileMapLayer floor rendering. The playable field was only showing
a thin column of tiles on the left and leaving the rest of the screen black. Root cause was a
missing `texture_region_size` property on all 20 `TileSetAtlasSource` entries in the TileSet resource.

## Root Cause
When `generate_field_tiles.gd` built the TileSet programmatically via `TileSetAtlasSource.new()`,
it did NOT set `src.texture_region_size = Vector2i(32, 32)`. Godot's default `texture_region_size`
for a new `TileSetAtlasSource` is `Vector2i(16, 16)`. This caused every 32×32 pixel tile to be
sampled using a 16×16 atlas region — rendering each tile as a quarter-sized (16×16 px) fragment
of the top-left corner of the PNG, making tiles appear as tiny 1-2 pixel coloured dots at the
game's display resolution.

The `TileSet` tile_size was correctly set to `Vector2i(32, 32)` — so each tile *cell* occupied
32 world pixels, but the texture *region sampled* was only 16×16. That's why the tiles looked
like scattered pixel fragments.

## Fix
Manually rewrote `assets/tiles/tileset_green_field.tres` to add:
```
texture_region_size = Vector2i(32, 32)
```
to all 20 `TileSetAtlasSource` sub-resources. Source ID ordering (0–19) and custom data layers
(`terrain_type`, `elevation`) were preserved exactly.

Also ran a headless editor import pass (`--headless --editor --quit`) to ensure all `.import`
metadata for the 20 tile PNGs was current before the final export build.

## Impact
- All 20 tile types now render at full 32×32 size filling the entire playable field
- No code changes — data fix only
- 296/296 automated tests continue to pass
- `build/OriginalRPG.exe` rebuilt (exit code 0)

## Files Changed
- MODIFIED: `assets/tiles/tileset_green_field.tres` — added `texture_region_size = Vector2i(32, 32)` to all 20 TileSetAtlasSource entries
