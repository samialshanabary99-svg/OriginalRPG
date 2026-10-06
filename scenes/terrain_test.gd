extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
var _frame_count: int = 0

func _ready() -> void:
	print("--- Running Terrain Test Scene (24 x 14) ---")
	if tile_map_layer == null:
		tile_map_layer = get_node_or_null("TileMapLayer") as TileMapLayer

	# 1. Fill 24 x 14 with dirt (terrain_set 0, terrain 1)
	var dirt_cells: Array[Vector2i] = []
	for x in range(24):
		for y in range(14):
			dirt_cells.append(Vector2i(x, y))
	
	tile_map_layer.set_cells_terrain_connect(dirt_cells, 0, 1)

	# 2. Prepare grass cells covering all required test cases:
	# - Large blob (at least 8 x 5): x in [2..11], y in [2..7] (10 x 6)
	# - 1-tile hole of dirt inside grass: omit (6, 4)
	# - 1-tile-wide strip, 6 tiles long: (14, 3) to (19, 3)
	# - Single isolated grass tile: (21, 3)
	# - Two grass tiles touching diagonally only: (17, 7) and (18, 8)
	var grass_cells: Array[Vector2i] = []

	# Case 1 & Case 4: Blob with 1-tile hole at (6, 4)
	for x in range(2, 12):
		for y in range(2, 8):
			if x == 6 and y == 4:
				continue
			grass_cells.append(Vector2i(x, y))

	# Case 2: 1-tile-wide strip, 6 tiles long
	for x in range(14, 20):
		grass_cells.append(Vector2i(x, 3))

	# Case 3: Single isolated grass tile
	grass_cells.append(Vector2i(21, 3))

	# Case 5: Two grass tiles touching diagonally only
	grass_cells.append(Vector2i(17, 7))
	grass_cells.append(Vector2i(18, 8))

	# Paint grass with terrain autotiling
	tile_map_layer.set_cells_terrain_connect(grass_cells, 0, 0)

	# Print chosen atlas coordinates for every cell
	print("\nGrid Atlas Coordinates (24 x 14):")
	for y in range(14):
		var row_str: String = "Row %02d: " % y
		for x in range(24):
			var coords: Vector2i = tile_map_layer.get_cell_atlas_coords(Vector2i(x, y))
			row_str += "(%d,%d) " % [coords.x, coords.y]
		print(row_str)

	print("\nGrid generation complete.")

func _process(_delta: float) -> void:
	_frame_count += 1
	if _frame_count == 10:
		var vp: Viewport = get_viewport()
		if vp != null:
			var tex: ViewportTexture = vp.get_texture()
			if tex != null:
				var img: Image = tex.get_image()
				if img != null:
					var out_path: String = "res://art_build/terrain_test_screenshot.png"
					img.save_png(ProjectSettings.globalize_path(out_path))
					print("Saved screenshot to ", out_path)
		# Exit after test capture
		get_tree().quit(0)
