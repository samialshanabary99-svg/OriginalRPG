@tool
extends SceneTree

## Builds and saves the multi-layer TileMap field in scenes/maps/test_world.tscn.
## V3 — Organic Rolling Hills & Cohesive Field Environment:
##   - Smooth elliptical elevation mounds (natural rolling hills)
##   - Cohesive meadow grass scatter (subtle tufts & flowers)
##   - Strategic stepping stone trail from spawn to monument
##   - Scattered organic bushes, wildflowers, and foliage
##   - Preserves all architectural and test invariants (Group T)

const MAP_SCENE_PATH: String = "res://scenes/maps/test_world.tscn"
const TILESET_PATH: String   = "res://assets/tiles/tileset_green_field.tres"

# Source IDs matching tileset_green_field.tres sources/
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
	print("Building multi-layer TileMap field V3 for TestWorld...")

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

	# 2. Ensure Background ColorRect is behind all layers
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

	# ── Ground Layer: Smooth, Varied Meadow Grass ────────────────────────────
	# Playable area spans x = -26..25, y = -17..16 (approx 1600x1000 pixels)
	for y: int in range(-17, 17):
		for x: int in range(-26, 26):
			var r1: float = _hash2d(x, y, 777)
			var r2: float = _hash2d(x + 19, y + 23, 333)

			var src: int = S_GRASS_BASE
			# Organic scatter: mostly base grass, delicate accents
			if r1 > 0.94:
				src = S_GRASS_FLOWER_RED
			elif r1 > 0.88:
				src = S_GRASS_FLOWER_YELLOW
			elif r1 > 0.82:
				src = S_GRASS_FLOWER_BLUE
			elif r1 > 0.72 and r2 > 0.45:
				src = S_GRASS_TUFT

			# Test requirement: (0, 0) must be base grass (elevation 0)
			if x == 0 and y == 0:
				src = S_GRASS_BASE

			ground_layer.set_cell(Vector2i(x, y), src, Vector2i(0, 0))

	# ── Elevation Layer: Natural Rolling Hills (Mounds) ──────────────────────
	# Hill 1: Northeast Plateau
	# Contains test cells: (10, -8) [plateau, elev=1], (10, -3) [ramp], (10, -13) [north slope]
	_build_hill_mound(elev_layer, 11.0, -8.0, 8.0, 5.2, Vector2i(10, -3))

	# Hill 2: Southwest Rolling Meadow
	_build_hill_mound(elev_layer, -13.0, 8.0, 7.5, 4.5, Vector2i(-13, 12))

	# Guaranteed Test Cells for Group T compliance
	elev_layer.set_cell(Vector2i(10, -8), S_ELEVATED_GRASS, Vector2i(0, 0))
	elev_layer.set_cell(Vector2i(10, -3), S_SLOPE_RAMP, Vector2i(0, 0))
	elev_layer.set_cell(Vector2i(10, -13), S_SLOPE_NORTH, Vector2i(0, 0))

	# ── Decoration Layer: Stepping Stones, Bushes, Wildflowers ───────────────
	# Stepping stone path from player spawn (0, 0) towards monument (5, 0)
	var stones: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
		Vector2i(2, 1), Vector2i(3, 1)
	]
	for c: Vector2i in stones:
		deco_layer.set_cell(c, S_DECO_STEPPING_STONES, Vector2i(0, 0))

	# Wildflowers clustered near footpaths and meadow glades
	var flowers: Array[Vector2i] = [
		Vector2i(2, -2), # Test required cell!
		Vector2i(-4, -3), Vector2i(5, -2), Vector2i(-7, 2),
		Vector2i(1, 4), Vector2i(-12, -5), Vector2i(7, -12),
		Vector2i(-18, 9), Vector2i(16, 3), Vector2i(-5, 11),
		Vector2i(19, -4), Vector2i(-17, -11), Vector2i(6, 9)
	]
	for f: Vector2i in flowers:
		deco_layer.set_cell(f, S_DECO_WILDFLOWERS, Vector2i(0, 0))

	# Leafy bushes framing the open field naturally
	var bushes: Array[Vector2i] = [
		Vector2i(2, -14), Vector2i(20, -14), Vector2i(-21, 1),
		Vector2i(18, -4), Vector2i(-13, -13), Vector2i(-21, 11),
		Vector2i(17, 7),  Vector2i(-6, 13),  Vector2i(21, -11)
	]
	for b: Vector2i in bushes:
		deco_layer.set_cell(b, S_DECO_BUSH, Vector2i(0, 0))

	# Tall grass blades along forest edges & hill slopes
	var tall_grass: Array[Vector2i] = [
		Vector2i(-3, -2), Vector2i(8, -2), Vector2i(-14, 3),
		Vector2i(4, 6), Vector2i(-8, -7), Vector2i(13, 2),
		Vector2i(-2, 9), Vector2i(16, -9)
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

	print("V3: TestWorld field successfully assembled and saved!")
	quit(0)

# ── Organic Hill Builder ─────────────────────────────────────────────────────

func _build_hill_mound(layer: TileMapLayer, cx: float, cy: float, rx: float, ry: float, ramp_coord: Vector2i) -> void:
	var x_min: int = int(floor(cx - rx - 1.0))
	var x_max: int = int(ceil(cx + rx + 1.0))
	var y_min: int = int(floor(cy - ry - 1.0))
	var y_max: int = int(ceil(cy + ry + 1.0))

	for y: int in range(y_min, y_max + 1):
		for x: int in range(x_min, x_max + 1):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry))
			var coord: Vector2i = Vector2i(x, y)

			if dist < 0.65:
				# Sunlit elevated plateau interior
				layer.set_cell(coord, S_ELEVATED_GRASS, Vector2i(0, 0))
			elif dist <= 1.05:
				# Outer slope rim
				if coord == ramp_coord:
					layer.set_cell(coord, S_SLOPE_RAMP, Vector2i(0, 0))
				else:
					var angle: float = atan2(dy, dx)
					var deg: float = rad_to_deg(angle)

					# 8-Directional smooth slope assignment based on outward angle
					if deg >= -22.5 and deg < 22.5:
						layer.set_cell(coord, S_SLOPE_EAST, Vector2i(0, 0))
					elif deg >= 22.5 and deg < 67.5:
						layer.set_cell(coord, S_SLOPE_CORNER_SE, Vector2i(0, 0))
					elif deg >= 67.5 and deg < 112.5:
						layer.set_cell(coord, S_SLOPE_SOUTH, Vector2i(0, 0))
					elif deg >= 112.5 and deg < 157.5:
						layer.set_cell(coord, S_SLOPE_CORNER_SW, Vector2i(0, 0))
					elif deg >= -67.5 and deg < -22.5:
						layer.set_cell(coord, S_SLOPE_CORNER_NE, Vector2i(0, 0))
					elif deg >= -112.5 and deg < -67.5:
						layer.set_cell(coord, S_SLOPE_NORTH, Vector2i(0, 0))
					elif deg >= -157.5 and deg < -112.5:
						layer.set_cell(coord, S_SLOPE_CORNER_NW, Vector2i(0, 0))
					else:
						layer.set_cell(coord, S_SLOPE_WEST, Vector2i(0, 0))

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
