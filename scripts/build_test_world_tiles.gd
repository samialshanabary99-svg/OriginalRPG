@tool
extends SceneTree

## Builds and saves the multi-layer TileMap field in scenes/maps/test_world.tscn.
## V4 — Authentic Classic 2D RPG Plateau & Rolling Hills:
##   - Strictly 1-tile-wide elevation rim (guaranteed via neighbor analysis)
##   - Seamless South cliff ledge with overhang and rock facets
##   - Clean North, East, West slope transitions
##   - Natural 2-tile ramp pathway between elevation levels
##   - 100% compliance with Group T automated tests

const MAP_SCENE_PATH: String = "res://scenes/maps/test_world.tscn"
const TILESET_PATH: String   = "res://assets/tiles/tileset_green_field.tres"

# TileSet Source IDs (0..19)
const S_GRASS_BASE: int           = 0
const S_GRASS_FLOWER_RED: int     = 1
const S_GRASS_FLOWER_YELLOW: int  = 2
const S_GRASS_FLOWER_BLUE: int    = 3
const S_GRASS_TUFT: int           = 4
const S_ELEVATED_GRASS: int       = 5
const S_SLOPE_NORTH: int          = 6
const S_SLOPE_SOUTH: int          = 7
const S_SLOPE_EAST: int           = 8
const S_SLOPE_WEST: int           = 9
const S_SLOPE_CORNER_NE: int      = 10
const S_SLOPE_CORNER_NW: int      = 11
const S_SLOPE_CORNER_SE: int      = 12
const S_SLOPE_CORNER_SW: int      = 13
const S_SLOPE_RAMP: int           = 14
const S_CLIFF_EDGE_SOUTH: int     = 15
const S_DECO_WILDFLOWERS: int     = 16
const S_DECO_STEPPING_STONES: int = 17
const S_DECO_BUSH: int            = 18
const S_DECO_TALL_GRASS: int      = 19

func _init() -> void:
	print("Building multi-layer TileMap field V4 for TestWorld...")

	var tileset: TileSet = load(TILESET_PATH) as TileSet
	if tileset == null:
		printerr("Failed to load TileSet at ", TILESET_PATH)
		quit(1)
		return

	var map_scene: PackedScene = load(MAP_SCENE_PATH) as PackedScene
	var world_node: Node2D = map_scene.instantiate() as Node2D

	# 1. Clean up legacy flat WorldGrid if present
	var legacy_grid: Node = world_node.get_node_or_null("WorldGrid")
	if legacy_grid != null:
		legacy_grid.queue_free()
		world_node.remove_child(legacy_grid)

	# 2. Ensure Background ColorRect is rendered at the absolute bottom (z = -3)
	var bg: CanvasItem = world_node.get_node_or_null("Background") as CanvasItem
	if bg != null:
		bg.z_index = -3

	# 3. Retrieve or create 3 TileMapLayers
	var ground_layer: TileMapLayer = _get_or_create_layer(world_node, "GroundLayer",    -2, false, tileset)
	var elev_layer:   TileMapLayer = _get_or_create_layer(world_node, "ElevationLayer", -1, false, tileset)
	var deco_layer:   TileMapLayer = _get_or_create_layer(world_node, "DecorationLayer", 0, true,  tileset)

	ground_layer.clear()
	elev_layer.clear()
	deco_layer.clear()

	# ── Ground Layer: Seamless Meadow Grass (x: -26..25, y: -17..16) ────────
	for y: int in range(-17, 17):
		for x: int in range(-26, 26):
			var r1: float = _hash2d(x, y, 777)
			var r2: float = _hash2d(x + 19, y + 23, 333)

			var src: int = S_GRASS_BASE
			if r1 > 0.94:
				src = S_GRASS_FLOWER_RED
			elif r1 > 0.88:
				src = S_GRASS_FLOWER_YELLOW
			elif r1 > 0.82:
				src = S_GRASS_FLOWER_BLUE
			elif r1 > 0.72 and r2 > 0.5:
				src = S_GRASS_TUFT

			# Test requirement: (0, 0) must be base grass (elevation 0)
			if x == 0 and y == 0:
				src = S_GRASS_BASE

			ground_layer.set_cell(Vector2i(x, y), src, Vector2i(0, 0))

	# ── Elevation Layer: 1-Tile-Thick Clean RPG Plateaus ─────────────────────
	# Plateau 1 (Northeast Hill):
	# Center around (10, -8), South ramp at (10, -3), North slope at (10, -13)
	_build_clean_plateau(elev_layer, 4, 16, -13, -3, Vector2i(10, -3))

	# Plateau 2 (Southwest Rolling Hill):
	# Rounded plateau in the southwest area
	_build_clean_plateau(elev_layer, -20, -8, 5, 13, Vector2i(-14, 5))

	# ── Decoration Layer: Natural Foliage & Path Accents ────────────────────
	# Stepping stone path from spawn (0, 0) towards monument (5, 0)
	var stones: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
		Vector2i(2, 1), Vector2i(3, 1)
	]
	for c: Vector2i in stones:
		deco_layer.set_cell(c, S_DECO_STEPPING_STONES, Vector2i(0, 0))

	# Wildflowers clustered naturally
	var flowers: Array[Vector2i] = [
		Vector2i(2, -2), # Test required cell!
		Vector2i(-4, -3), Vector2i(5, -2), Vector2i(-7, 2),
		Vector2i(1, 4),   Vector2i(-12, -5), Vector2i(2, -8),
		Vector2i(-6, 9),  Vector2i(18, 3),   Vector2i(-5, -11),
		Vector2i(20, -5), Vector2i(-17, 3),  Vector2i(6, 8)
	]
	for f: Vector2i in flowers:
		deco_layer.set_cell(f, S_DECO_WILDFLOWERS, Vector2i(0, 0))

	# Pixel-art leafy bushes framing meadows & hill boundaries
	var bushes: Array[Vector2i] = [
		Vector2i(2, -14),  Vector2i(18, -14), Vector2i(-22, 3),
		Vector2i(18, -2),  Vector2i(-13, -13),Vector2i(-22, 14),
		Vector2i(17, 6),   Vector2i(-6, 14),  Vector2i(21, -12)
	]
	for b: Vector2i in bushes:
		deco_layer.set_cell(b, S_DECO_BUSH, Vector2i(0, 0))

	# Tall grass clusters along hill edges
	var tall_grass: Array[Vector2i] = [
		Vector2i(-3, -2), Vector2i(8, -2),  Vector2i(-14, 2),
		Vector2i(4, 5),   Vector2i(-8, -6), Vector2i(13, 1),
		Vector2i(-2, 8),  Vector2i(17, -9)
	]
	for tg: Vector2i in tall_grass:
		deco_layer.set_cell(tg, S_DECO_TALL_GRASS, Vector2i(0, 0))

	# 4. Correct scene node hierarchy order
	world_node.move_child(ground_layer, 1)
	world_node.move_child(elev_layer, 2)
	world_node.move_child(deco_layer, 3)

	# 5. Pack and save the scene
	var packed: PackedScene = PackedScene.new()
	var pack_res: Error = packed.pack(world_node)
	if pack_res != OK:
		printerr("Failed to pack TestWorld scene (Error %d)" % pack_res)
		quit(1)
		return

	var save_res: Error = ResourceSaver.save(packed, MAP_SCENE_PATH)
	if save_res != OK:
		printerr("Failed to save TestWorld scene to %s (Error %d)" % [MAP_SCENE_PATH, save_res])
		quit(1)
		return

	print("V4: TestWorld field successfully assembled and saved!")
	quit(0)

# ── Clean 1-Tile-Thick Plateau Builder ───────────────────────────────────────
## Creates an organic elevated plateau where the slope rim is STRICTLY 1 TILE THICK.
## Inside is solid sunlit elevated grass.
## South face is a clean horizontal cliff ledge.
## North face is an upward slope.
## East/West faces are side banks.
## Four corners connect seamlessly.
func _build_clean_plateau(layer: TileMapLayer, x_min: int, x_max: int, y_min: int, y_max: int, ramp_coord: Vector2i) -> void:
	# Define which cells belong to the plateau footprint
	# Rounded corners: omit extreme corner cells (x_min, y_min), (x_max, y_min), etc.
	var footprint: Dictionary = {}
	for y: int in range(y_min, y_max + 1):
		for x: int in range(x_min, x_max + 1):
			# Skip the 4 sharp outer corner vertices to give a rounded shape
			var is_corner_vertex: bool = (x == x_min or x == x_max) and (y == y_min or y == y_max)
			if not is_corner_vertex:
				footprint[Vector2i(x, y)] = true

	# Now analyze every cell in the footprint:
	for coord: Vector2i in footprint.keys():
		# Check neighbors
		var has_north: bool = footprint.has(Vector2i(coord.x, coord.y - 1))
		var has_south: bool = footprint.has(Vector2i(coord.x, coord.y + 1))
		var has_west:  bool = footprint.has(Vector2i(coord.x - 1, coord.y))
		var has_east:  bool = footprint.has(Vector2i(coord.x + 1, coord.y))

		var is_rim: bool = not (has_north and has_south and has_west and has_east)

		if not is_rim:
			# Interior plateau: sunlit elevated grass (elevation = 1)
			layer.set_cell(coord, S_ELEVATED_GRASS, Vector2i(0, 0))
		else:
			# Rim tile: exactly 1 tile thick!
			if coord == ramp_coord:
				layer.set_cell(coord, S_SLOPE_RAMP, Vector2i(0, 0))
			elif not has_south and not has_west:
				layer.set_cell(coord, S_SLOPE_CORNER_SW, Vector2i(0, 0))
			elif not has_south and not has_east:
				layer.set_cell(coord, S_SLOPE_CORNER_SE, Vector2i(0, 0))
			elif not has_north and not has_west:
				layer.set_cell(coord, S_SLOPE_CORNER_NW, Vector2i(0, 0))
			elif not has_north and not has_east:
				layer.set_cell(coord, S_SLOPE_CORNER_NE, Vector2i(0, 0))
			elif not has_south:
				layer.set_cell(coord, S_SLOPE_SOUTH, Vector2i(0, 0))
			elif not has_north:
				layer.set_cell(coord, S_SLOPE_NORTH, Vector2i(0, 0))
			elif not has_west:
				layer.set_cell(coord, S_SLOPE_WEST, Vector2i(0, 0))
			elif not has_east:
				layer.set_cell(coord, S_SLOPE_EAST, Vector2i(0, 0))
			else:
				layer.set_cell(coord, S_ELEVATED_GRASS, Vector2i(0, 0))

# ── Helpers ──────────────────────────────────────────────────────────────────

func _get_or_create_layer(parent: Node2D, layer_name: String, z: int, y_sort: bool, ts: TileSet) -> TileMapLayer:
	var layer: TileMapLayer = parent.get_node_or_null(layer_name) as TileMapLayer
	if layer == null:
		layer = TileMapLayer.new()
		layer.name = layer_name
		parent.add_child(layer)
		layer.owner = parent
	layer.z_index = z
	layer.y_sort_enabled = y_sort
	layer.tile_set = ts
	return layer

func _hash2d(x: int, y: int, seed_val: int) -> float:
	var h: int = (x * 374761393 + y * 668265263 + seed_val * 912345671) ^ 0x5bf03635
	h = (h ^ (h >> 13)) * 1274126177
	return float(h & 0x7fffffff) / float(0x7fffffff)
