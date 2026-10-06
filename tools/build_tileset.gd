extends SceneTree

func _init() -> void:
	print("Starting TileSet build...")
	var json_file: FileAccess = FileAccess.open("res://assets/terrain/atlas_layout.json", FileAccess.READ)
	if json_file == null:
		print("ERROR: Cannot open atlas_layout.json")
		quit(1)
		return

	var json_text: String = json_file.get_as_text()
	json_file.close()

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(json_text)
	if parse_err != OK:
		print("ERROR: Failed to parse atlas_layout.json")
		quit(1)
		return

	var tiles_data: Array = json.data as Array
	print("Loaded ", tiles_data.size(), " tile definitions from JSON.")

	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(256, 256)

	# Terrain set 0 (Match Corners)
	tileset.add_terrain_set(0)
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)

	# Terrain 0 = grass
	tileset.add_terrain(0, 0)
	tileset.set_terrain_name(0, 0, "grass")
	tileset.set_terrain_color(0, 0, Color(0.2, 0.75, 0.25, 1.0))

	# Terrain 1 = dirt
	tileset.add_terrain(0, 1)
	tileset.set_terrain_name(0, 1, "dirt")
	tileset.set_terrain_color(0, 1, Color(0.55, 0.35, 0.15, 1.0))

	# Custom data layers
	tileset.add_custom_data_layer(0)
	tileset.set_custom_data_layer_name(0, "walkable")
	tileset.set_custom_data_layer_type(0, TYPE_BOOL)

	tileset.add_custom_data_layer(1)
	tileset.set_custom_data_layer_name(1, "footstep")
	tileset.set_custom_data_layer_type(1, TYPE_STRING)

	# Atlas source
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	var atlas_tex: Texture2D = load("res://assets/terrain/terrain_grass_dirt_atlas.png") as Texture2D
	if atlas_tex == null:
		print("ERROR: Could not load atlas texture!")
		quit(1)
		return

	source.texture = atlas_tex
	source.texture_region_size = Vector2i(256, 256)
	source.use_texture_padding = true

	tileset.add_source(source)

	# Create tiles
	for entry in tiles_data:
		var d: Dictionary = entry as Dictionary
		var coords: Vector2i = Vector2i(int(d["atlas_coords"][0]), int(d["atlas_coords"][1]))
		source.create_tile(coords)
		var td: TileData = source.get_tile_data(coords, 0)
		if td == null:
			print("ERROR: Failed to get TileData for coords ", coords)
			quit(1)
			return

		td.terrain_set = 0
		td.terrain = 0 if str(d["own_terrain"]) == "grass" else 1

		var tb: Dictionary = d["terrain_bits"] as Dictionary
		var tl: int = 0 if str(tb["top_left"]) == "G" else 1
		var tr: int = 0 if str(tb["top_right"]) == "G" else 1
		var br: int = 0 if str(tb["bottom_right"]) == "G" else 1
		var bl: int = 0 if str(tb["bottom_left"]) == "G" else 1

		td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, tl)
		td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, tr)
		td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, br)
		td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, bl)

		td.probability = float(d["probability"])
		td.set_custom_data("walkable", true)
		td.set_custom_data("footstep", str(d["custom_data"]["footstep"]))

	var save_err: Error = ResourceSaver.save(tileset, "res://assets/terrain/terrain_tileset.tres")
	if save_err != OK:
		print("ERROR: Failed to save terrain_tileset.tres (error code: ", save_err, ")")
		quit(1)
		return

	print("Successfully saved res://assets/terrain/terrain_tileset.tres with 22 configured cells.")
	quit(0)
