@tool
extends SceneTree

## Builds and saves the multi-layer TileMap field in scenes/maps/test_world.tscn.
## Replaces the flat WorldGrid ColorRect with 3 dedicated TileMapLayer nodes:
##   1. GroundLayer (z_index = -2): Base meadow grass and flower variations
##   2. ElevationLayer (z_index = -1): Rolling hills, gentle slopes, ramps, and plateaus
##   3. DecorationLayer (z_index = 0, y_sort_enabled): Wildflowers, bushes, stepping stones

const MAP_SCENE_PATH := "res://scenes/maps/test_world.tscn"
const TILESET_PATH := "res://assets/tiles/tileset_green_field.tres"

# Tile Source IDs matching tileset_green_field.tres
const S_GRASS_BASE := 0
const S_GRASS_FLOWER_RED := 1
const S_GRASS_FLOWER_YELLOW := 2
const S_GRASS_FLOWER_BLUE := 3
const S_GRASS_TUFT := 4
const S_ELEVATED_GRASS := 5
const S_SLOPE_NORTH := 6
const S_SLOPE_SOUTH := 7
const S_SLOPE_EAST := 8
const S_SLOPE_WEST := 9
const S_SLOPE_CORNER_NE := 10
const S_SLOPE_CORNER_NW := 11
const S_SLOPE_CORNER_SE := 12
const S_SLOPE_CORNER_SW := 13
const S_SLOPE_RAMP := 14
const S_CLIFF_EDGE_SOUTH := 15
const S_DECO_WILDFLOWERS := 16
const S_DECO_STEPPING_STONES := 17
const S_DECO_BUSH := 18
const S_DECO_TALL_GRASS := 19

func _init() -> void:
	print("Building multi-layer TileMap field for TestWorld...")

	var tileset: TileSet = load(TILESET_PATH)
	if tileset == null:
		printerr("Failed to load TileSet at ", TILESET_PATH)
		quit(1)
		return

	# Load map scene
	var map_scene: PackedScene = load(MAP_SCENE_PATH)
	var world_node: Node2D = map_scene.instantiate() as Node2D

	# Remove legacy flat WorldGrid if present
	var legacy_grid: Node = world_node.get_node_or_null("WorldGrid")
	if legacy_grid != null:
		legacy_grid.queue_free()
		world_node.remove_child(legacy_grid)
		print("Removed legacy WorldGrid ColorRect.")

	# Prepare or fetch 3 TileMapLayers
	var ground_layer: TileMapLayer = _get_or_create_layer(world_node, "GroundLayer", -2, false, tileset)
	var elev_layer: TileMapLayer = _get_or_create_layer(world_node, "ElevationLayer", -1, false, tileset)
	var deco_layer: TileMapLayer = _get_or_create_layer(world_node, "DecorationLayer", 0, true, tileset)

	ground_layer.clear()
	elev_layer.clear()
	deco_layer.clear()

	# 1. Populate GroundLayer (Lush meadow grass across entire playable boundary: 50x32 tiles)
	# Spanning x = -26 to 25, y = -17 to 16
	for y in range(-17, 17):
		for x in range(-26, 26):
			var roll := _hash(x, y, 777)
			var src := S_GRASS_BASE
			if roll > 0.94:
				src = S_GRASS_FLOWER_RED
			elif roll > 0.88:
				src = S_GRASS_FLOWER_YELLOW
			elif roll > 0.82:
				src = S_GRASS_FLOWER_BLUE
			elif roll > 0.74:
				src = S_GRASS_TUFT
			ground_layer.set_cell(Vector2i(x, y), src, Vector2i(0, 0))

	# 2. Populate ElevationLayer: Gentle Hills, Slopes & Ramps (Ups & Downs)
	# Hill A (Northeast Plateau): x: 3..17, y: -13..-3
	_build_hill(elev_layer, 3, 17, -13, -3, 10, -3, true)

	# Hill B (Southwest Rolling Hill): x: -19..-6, y: 4..12
	_build_hill(elev_layer, -19, -6, 4, 12, -12, 4, false)

	# 3. Populate DecorationLayer: Stepping Stones, Bushes, Wildflowers
	# Path of stepping stones leading from spawn (0,0) toward Ancient Monument (around x=5, y=0)
	var stone_coords: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
		Vector2i(2, 1), Vector2i(3, 1)
	]
	for c in stone_coords:
		deco_layer.set_cell(c, S_DECO_STEPPING_STONES, Vector2i(0, 0))

	# Wildflower clusters along the foot of the hills
	var flower_spots: Array[Vector2i] = [
		Vector2i(2, -2), Vector2i(7, -2), Vector2i(14, -2),
		Vector2i(-5, 5), Vector2i(-5, 9), Vector2i(-12, 3),
		Vector2i(0, -6), Vector2i(-8, -8), Vector2i(12, 6)
	]
	for pos in flower_spots:
		deco_layer.set_cell(pos, S_DECO_WILDFLOWERS, Vector2i(0, 0))

	# Berry shrubs and tall grass clumps
	var bush_spots: Array[Vector2i] = [
		Vector2i(2, -14), Vector2i(18, -14), Vector2i(18, -2),
		Vector2i(-20, 3), Vector2i(-5, 13), Vector2i(-20, 13),
		Vector2i(19, 5), Vector2i(-10, -12)
	]
	for b in bush_spots:
		deco_layer.set_cell(b, S_DECO_BUSH, Vector2i(0, 0))

	var grass_spots: Array[Vector2i] = [
		Vector2i(3, -2), Vector2i(11, -2), Vector2i(16, -4),
		Vector2i(-14, 3), Vector2i(-6, 6), Vector2i(-18, 11),
		Vector2i(6, 4), Vector2i(-4, -4)
	]
	for g in grass_spots:
		deco_layer.set_cell(g, S_DECO_TALL_GRASS, Vector2i(0, 0))

	# Reparent order: keep layers near the back
	world_node.move_child(ground_layer, 1)
	world_node.move_child(elev_layer, 2)
	world_node.move_child(deco_layer, 3)

	# Pack and save scene
	var packed := PackedScene.new()
	var pack_err: Error = packed.pack(world_node)
	if pack_err != OK:
		printerr("Failed to pack TestWorld scene (Error %d)" % pack_err)
		quit(1)
		return

	var save_err: Error = ResourceSaver.save(packed, MAP_SCENE_PATH)
	if save_err != OK:
		printerr("Failed to save TestWorld scene to %s (Error %d)" % [MAP_SCENE_PATH, save_err])
		quit(1)
		return

	print("Successfully updated TestWorld with Multi-Layer TileMapLayer field!")
	quit(0)

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

func _build_hill(layer: TileMapLayer, x_min: int, x_max: int, y_min: int, y_max: int, ramp_x: int, ramp_y: int, cliff_bottom: bool) -> void:
	# Corners
	layer.set_cell(Vector2i(x_min, y_min), S_SLOPE_CORNER_NW, Vector2i(0, 0))
	layer.set_cell(Vector2i(x_max, y_min), S_SLOPE_CORNER_NE, Vector2i(0, 0))
	layer.set_cell(Vector2i(x_max, y_max), S_SLOPE_CORNER_SE, Vector2i(0, 0))
	layer.set_cell(Vector2i(x_min, y_max), S_SLOPE_CORNER_SW, Vector2i(0, 0))

	# North Edge
	for x in range(x_min + 1, x_max):
		if x == ramp_x and ramp_y == y_min:
			layer.set_cell(Vector2i(x, y_min), S_SLOPE_RAMP, Vector2i(0, 0))
		else:
			layer.set_cell(Vector2i(x, y_min), S_SLOPE_NORTH, Vector2i(0, 0))

	# South Edge
	for x in range(x_min + 1, x_max):
		if x == ramp_x and ramp_y == y_max:
			layer.set_cell(Vector2i(x, y_max), S_SLOPE_RAMP, Vector2i(0, 0))
		elif cliff_bottom and (x % 3 != 0):
			layer.set_cell(Vector2i(x, y_max), S_CLIFF_EDGE_SOUTH, Vector2i(0, 0))
		else:
			layer.set_cell(Vector2i(x, y_max), S_SLOPE_SOUTH, Vector2i(0, 0))

	# West Edge
	for y in range(y_min + 1, y_max):
		layer.set_cell(Vector2i(x_min, y), S_SLOPE_WEST, Vector2i(0, 0))

	# East Edge
	for y in range(y_min + 1, y_max):
		layer.set_cell(Vector2i(x_max, y), S_SLOPE_EAST, Vector2i(0, 0))

	# Elevated Plateau Interior
	for y in range(y_min + 1, y_max):
		for x in range(x_min + 1, x_max):
			layer.set_cell(Vector2i(x, y), S_ELEVATED_GRASS, Vector2i(0, 0))

func _hash(x: int, y: int, seed_val: int) -> float:
	var h: int = (x * 374761393 + y * 668265263 + seed_val * 912345671) ^ 0x5bf03635
	h = (h ^ (h >> 13)) * 1274126177
	return float(h & 0x7fffffff) / float(0x7fffffff)
