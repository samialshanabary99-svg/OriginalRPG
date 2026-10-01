@tool
extends SceneTree

## Generates pixel-art 32x32 tiles for OriginalRPG's green field terrain.
## Creates:
##   1. 20 distinct 32x32 RGBA8 PNG textures in res://assets/tiles/ground/
##   2. A complete Godot 4 TileSet resource at res://assets/tiles/tileset_green_field.tres
##   3. Configures custom data layers (terrain_type, elevation)

const TILES_DIR := "res://assets/tiles/ground"
const TILESET_PATH := "res://assets/tiles/tileset_green_field.tres"

# Palette Constants
const C_GRASS_BASE := Color("3d8b40")
const C_GRASS_DARK := Color("2d6930")
const C_GRASS_DARKER := Color("204d22")
const C_GRASS_LIGHT := Color("52a855")
const C_GRASS_LIGHTER := Color("67c26b")
const C_GRASS_HIGHLIGHT := Color("82dc86")

const C_ELEV_BASE := Color("48a64c")
const C_ELEV_LIGHT := Color("70cf74")
const C_ELEV_HIGHLIGHT := Color("92e896")
const C_ELEV_DARK := Color("367d39")

const C_EARTH_BASE := Color("6e5033")
const C_EARTH_DARK := Color("533b24")
const C_EARTH_SHADOW := Color("3a2818")
const C_EARTH_LIGHT := Color("8a6845")

const C_SHADOW_TINT := Color(0.1, 0.22, 0.12, 0.55)
const C_TRANSPARENT := Color(0, 0, 0, 0)

func _init() -> void:
	print("==========================================")
	print(" OriginalRPG — Field Tile Generator ")
	print("==========================================")

	var dir_global: String = ProjectSettings.globalize_path(TILES_DIR)
	DirAccess.make_dir_recursive_absolute(dir_global)

	_generate_all_tiles()
	print("[1/2] 20 tile textures generated in %s" % TILES_DIR)

	_build_tileset()
	print("[2/2] TileSet resource saved to %s" % TILESET_PATH)

	print("==========================================")
	print(" TILE GENERATION COMPLETE ")
	print("==========================================")
	quit(0)

# ── Tile Generation Logic ───────────────────────────────────────────────────

func _generate_all_tiles() -> void:
	# 1. Base grass
	_save_tile("tile_grass_base.png", _create_base_grass(0))
	# 2-4. Flower variations
	_save_tile("tile_grass_flower_red.png", _create_grass_with_flowers(Color("e74c3c"), Color("f1c40f"), 1))
	_save_tile("tile_grass_flower_yellow.png", _create_grass_with_flowers(Color("f1c40f"), Color("ffffff"), 2))
	_save_tile("tile_grass_flower_blue.png", _create_grass_with_flowers(Color("3498db"), Color("e0f7fa"), 3))
	# 5. Grass tuft
	_save_tile("tile_grass_tuft.png", _create_grass_tuft(4))
	# 6. Elevated grass (Tier 1 plateau)
	_save_tile("tile_elevated_grass.png", _create_elevated_grass(5))
	# 7-10. Directional Slopes
	_save_tile("tile_slope_north.png", _create_slope_north())
	_save_tile("tile_slope_south.png", _create_slope_south())
	_save_tile("tile_slope_east.png", _create_slope_east())
	_save_tile("tile_slope_west.png", _create_slope_west())
	# 11-14. Corner Slopes
	_save_tile("tile_slope_corner_ne.png", _create_slope_corner_ne())
	_save_tile("tile_slope_corner_nw.png", _create_slope_corner_nw())
	_save_tile("tile_slope_corner_se.png", _create_slope_corner_se())
	_save_tile("tile_slope_corner_sw.png", _create_slope_corner_sw())
	# 15. Slope Ramp
	_save_tile("tile_slope_ramp.png", _create_slope_ramp())
	# 16. Cliff edge south
	_save_tile("tile_cliff_edge_south.png", _create_cliff_edge_south())
	# 17-20. Decorations (transparent overlays)
	_save_tile("tile_deco_wildflowers.png", _create_deco_wildflowers())
	_save_tile("tile_deco_stepping_stones.png", _create_deco_stepping_stones())
	_save_tile("tile_deco_bush.png", _create_deco_bush())
	_save_tile("tile_deco_tall_grass.png", _create_deco_tall_grass())

func _save_tile(filename: String, img: Image) -> void:
	var path := "%s/%s" % [TILES_DIR, filename]
	var global_path: String = ProjectSettings.globalize_path(path)
	img.save_png(global_path)

# ── Procedural Tile Texture Builders ────────────────────────────────────────

func _create_base_grass(seed_val: int) -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_GRASS_BASE)

	# Add organic pixel dithering and blade clusters
	for y in range(32):
		for x in range(32):
			var n: float = _hash2d(x, y, seed_val)
			if n > 0.82:
				img.set_pixel(x, y, C_GRASS_LIGHT)
			elif n > 0.70:
				img.set_pixel(x, y, C_GRASS_LIGHTER)
			elif n < 0.20:
				img.set_pixel(x, y, C_GRASS_DARK)
			elif n < 0.08:
				img.set_pixel(x, y, C_GRASS_DARKER)

	# Tiny grass blade highlights
	for i in range(12):
		var bx: int = int(_hash2d(i * 3, i * 7, seed_val + 10) * 30) + 1
		var by: int = int(_hash2d(i * 5, i * 2, seed_val + 20) * 30) + 1
		img.set_pixel(bx, by, C_GRASS_HIGHLIGHT)
		img.set_pixel(bx, mini(by + 1, 31), C_GRASS_LIGHT)
	return img

func _create_grass_with_flowers(petal_color: Color, center_color: Color, seed_val: int) -> Image:
	var img := _create_base_grass(seed_val)
	# 3 flower clusters
	var coords: Array[Vector2i] = [
		Vector2i(8, 10),
		Vector2i(22, 14),
		Vector2i(14, 24)
	]
	for pos in coords:
		# Petals
		img.set_pixel(pos.x - 1, pos.y, petal_color)
		img.set_pixel(pos.x + 1, pos.y, petal_color)
		img.set_pixel(pos.x, pos.y - 1, petal_color)
		img.set_pixel(pos.x, pos.y + 1, petal_color)
		# Center
		img.set_pixel(pos.x, pos.y, center_color)
		# Stem/leaf
		img.set_pixel(pos.x, pos.y + 2, C_GRASS_DARKER)
	return img

func _create_grass_tuft(seed_val: int) -> Image:
	var img := _create_base_grass(seed_val)
	var coords: Array[Vector2i] = [Vector2i(10, 16), Vector2i(20, 12)]
	for pos in coords:
		img.set_pixel(pos.x, pos.y, C_GRASS_HIGHLIGHT)
		img.set_pixel(pos.x - 1, pos.y + 1, C_GRASS_LIGHTER)
		img.set_pixel(pos.x + 1, pos.y + 1, C_GRASS_LIGHTER)
		img.set_pixel(pos.x, pos.y + 2, C_GRASS_DARKER)
	return img

func _create_elevated_grass(seed_val: int) -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_ELEV_BASE)

	for y in range(32):
		for x in range(32):
			var n: float = _hash2d(x, y, seed_val + 50)
			if n > 0.80:
				img.set_pixel(x, y, C_ELEV_HIGHLIGHT)
			elif n > 0.65:
				img.set_pixel(x, y, C_ELEV_LIGHT)
			elif n < 0.20:
				img.set_pixel(x, y, C_ELEV_DARK)
			elif n < 0.08:
				img.set_pixel(x, y, C_GRASS_BASE)

	# Sunlit highlights
	for i in range(14):
		var bx: int = int(_hash2d(i * 4, i * 9, seed_val + 80) * 30) + 1
		var by: int = int(_hash2d(i * 6, i * 3, seed_val + 90) * 30) + 1
		img.set_pixel(bx, by, C_ELEV_HIGHLIGHT)
	return img

func _create_slope_north() -> Image:
	# Low ground at bottom, slopes UP toward North (top is elevated)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		var t: float = float(y) / 31.0 # 0 at top, 1 at bottom
		var base_col: Color = C_ELEV_BASE.lerp(C_GRASS_DARK, t * 0.85)
		for x in range(32):
			var n: float = (_hash2d(x, y, 101) - 0.5) * 0.12
			var col: Color = base_col
			col.r = clampf(col.r + n, 0.0, 1.0)
			col.g = clampf(col.g + n, 0.0, 1.0)
			col.b = clampf(col.b + n, 0.0, 1.0)
			img.set_pixel(x, y, col)

	# Crest highlight at top
	for x in range(32):
		img.set_pixel(x, 0, C_ELEV_HIGHLIGHT)
		if x % 2 == 0:
			img.set_pixel(x, 1, C_ELEV_LIGHT)
	# Gentle shaded bank at bottom
	for x in range(32):
		img.set_pixel(x, 31, C_GRASS_DARKER)
		if x % 3 == 0:
			img.set_pixel(x, 30, C_GRASS_DARK)
	return img

func _create_slope_south() -> Image:
	# Elevated at top, slopes DOWN toward South (bottom is low ground)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		var t: float = float(y) / 31.0 # 0 at top, 1 at bottom
		var base_col: Color = C_ELEV_BASE.lerp(C_GRASS_BASE, t)
		for x in range(32):
			var n: float = (_hash2d(x, y, 102) - 0.5) * 0.12
			var col: Color = base_col
			col.r = clampf(col.r + n, 0.0, 1.0)
			col.g = clampf(col.g + n, 0.0, 1.0)
			col.b = clampf(col.b + n, 0.0, 1.0)
			img.set_pixel(x, y, col)

	# Sunlit ridge along top edge (y=0,1)
	for x in range(32):
		img.set_pixel(x, 0, C_ELEV_HIGHLIGHT)
		img.set_pixel(x, 1, C_ELEV_LIGHT)
	# Soft cast shadow along bottom edge (y=29,30,31)
	for x in range(32):
		img.set_pixel(x, 30, C_GRASS_DARK)
		img.set_pixel(x, 31, C_GRASS_DARKER)
	return img

func _create_slope_east() -> Image:
	# Slopes up toward East (left is low, right is elevated)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		var t: float = float(x) / 31.0
		var base_col: Color = C_GRASS_BASE.lerp(C_ELEV_BASE, t)
		for y in range(32):
			var n: float = (_hash2d(x, y, 103) - 0.5) * 0.12
			var col: Color = base_col
			col.r = clampf(col.r + n, 0.0, 1.0)
			col.g = clampf(col.g + n, 0.0, 1.0)
			col.b = clampf(col.b + n, 0.0, 1.0)
			img.set_pixel(x, y, col)
	# Ridge highlight on east edge
	for y in range(32):
		img.set_pixel(31, y, C_ELEV_HIGHLIGHT)
		img.set_pixel(30, y, C_ELEV_LIGHT)
	return img

func _create_slope_west() -> Image:
	# Slopes up toward West (right is low, left is elevated)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		var t: float = float(x) / 31.0
		var base_col: Color = C_ELEV_BASE.lerp(C_GRASS_BASE, t)
		for y in range(32):
			var n: float = (_hash2d(x, y, 104) - 0.5) * 0.12
			var col: Color = base_col
			col.r = clampf(col.r + n, 0.0, 1.0)
			col.g = clampf(col.g + n, 0.0, 1.0)
			col.b = clampf(col.b + n, 0.0, 1.0)
			img.set_pixel(x, y, col)
	# Ridge highlight on west edge
	for y in range(32):
		img.set_pixel(0, y, C_ELEV_HIGHLIGHT)
		img.set_pixel(1, y, C_ELEV_LIGHT)
	return img

func _create_slope_corner_ne() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var dist: float = (Vector2(x, 31 - y)).length() / 44.0
			var col: Color = C_GRASS_BASE.lerp(C_ELEV_BASE, clampf(dist, 0.0, 1.0))
			img.set_pixel(x, y, col)
	for i in range(16):
		img.set_pixel(16 + i, 0, C_ELEV_HIGHLIGHT)
		img.set_pixel(31, i, C_ELEV_HIGHLIGHT)
	return img

func _create_slope_corner_nw() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var dist: float = (Vector2(31 - x, 31 - y)).length() / 44.0
			var col: Color = C_GRASS_BASE.lerp(C_ELEV_BASE, clampf(dist, 0.0, 1.0))
			img.set_pixel(x, y, col)
	for i in range(16):
		img.set_pixel(i, 0, C_ELEV_HIGHLIGHT)
		img.set_pixel(0, i, C_ELEV_HIGHLIGHT)
	return img

func _create_slope_corner_se() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var dist: float = (Vector2(31 - x, 31 - y)).length() / 44.0
			var col: Color = C_ELEV_BASE.lerp(C_GRASS_DARK, clampf(dist, 0.0, 1.0))
			img.set_pixel(x, y, col)
	for x in range(32):
		img.set_pixel(x, 31, C_GRASS_DARKER)
		img.set_pixel(31, x, C_GRASS_DARKER)
	return img

func _create_slope_corner_sw() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var dist: float = (Vector2(x, 31 - y)).length() / 44.0
			var col: Color = C_ELEV_BASE.lerp(C_GRASS_DARK, clampf(dist, 0.0, 1.0))
			img.set_pixel(x, y, col)
	for x in range(32):
		img.set_pixel(x, 31, C_GRASS_DARKER)
		img.set_pixel(0, x, C_GRASS_DARKER)
	return img

func _create_slope_ramp() -> Image:
	# Gentle dirt-grass pathway ramp leading up
	var img := _create_slope_south()
	for y in range(32):
		for x in range(10, 22):
			var n: float = _hash2d(x, y, 105)
			var col: Color = C_EARTH_BASE.lerp(C_GRASS_BASE, 0.4)
			if n > 0.6:
				col = C_EARTH_LIGHT
			elif n < 0.25:
				col = C_EARTH_DARK
			img.set_pixel(x, y, col)
		# Track edges
		img.set_pixel(9, y, C_GRASS_DARK)
		img.set_pixel(22, y, C_GRASS_DARK)
	return img

func _create_cliff_edge_south() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	# Upper half (0..13): Overhanging grass
	for y in range(14):
		for x in range(32):
			var n: float = _hash2d(x, y, 106)
			var col: Color = C_ELEV_BASE if n > 0.3 else C_ELEV_LIGHT
			img.set_pixel(x, y, col)
	# Scalloped grassy lip (y=13, 14)
	for x in range(32):
		img.set_pixel(x, 13, C_ELEV_HIGHLIGHT)
		if (x + int(_hash2d(x, 0, 107) * 4)) % 3 == 0:
			img.set_pixel(x, 14, C_ELEV_BASE)
			img.set_pixel(x, 15, C_GRASS_LIGHT)
	# Lower half (14..31): Earthy rock bank
	for y in range(14, 32):
		for x in range(32):
			if img.get_pixel(x, y).a == 0.0 or y > 15:
				var t: float = float(y - 14) / 17.0
				var col: Color = C_EARTH_BASE.lerp(C_EARTH_SHADOW, t)
				var n: float = _hash2d(x, y, 108)
				if n > 0.75:
					col = C_EARTH_LIGHT
				elif n < 0.2:
					col = C_EARTH_DARK
				img.set_pixel(x, y, col)
	# Soft cast shadow at bottom
	for x in range(32):
		img.set_pixel(x, 30, C_GRASS_DARK)
		img.set_pixel(x, 31, C_GRASS_DARKER)
	return img

# ── Transparent Overlays (DecorationLayer) ──────────────────────────────────

func _create_deco_wildflowers() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	var flowers: Array[Dictionary] = [
		{"pos": Vector2i(8, 12), "col": Color("e74c3c")},
		{"pos": Vector2i(14, 18), "col": Color("f1c40f")},
		{"pos": Vector2i(20, 10), "col": Color("ffffff")},
		{"pos": Vector2i(24, 20), "col": Color("3498db")},
		{"pos": Vector2i(10, 24), "col": Color("e67e22")},
	]
	for f in flowers:
		var p: Vector2i = f["pos"]
		var c: Color = f["col"]
		img.set_pixel(p.x, p.y, c)
		img.set_pixel(p.x - 1, p.y, c)
		img.set_pixel(p.x + 1, p.y, c)
		img.set_pixel(p.x, p.y - 1, c)
		img.set_pixel(p.x, p.y + 1, c)
		img.set_pixel(p.x, p.y, Color("ffffaa")) # center
		img.set_pixel(p.x, p.y + 2, C_GRASS_DARKER) # stem
	return img

func _create_deco_stepping_stones() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	var stones: Array[Dictionary] = [
		{"center": Vector2i(10, 10), "rx": 5, "ry": 3},
		{"center": Vector2i(21, 16), "rx": 6, "ry": 4},
		{"center": Vector2i(12, 24), "rx": 5, "ry": 3},
	]
	for s in stones:
		var c: Vector2i = s["center"]
		var rx: int = s["rx"]
		var ry: int = s["ry"]
		for dy in range(-ry - 1, ry + 2):
			for dx in range(-rx - 1, rx + 2):
				var px: int = c.x + dx
				var py: int = c.y + dy
				if px < 0 or px >= 32 or py < 0 or py >= 32:
					continue
				var norm: float = (float(dx * dx) / float(rx * rx)) + (float(dy * dy) / float(ry * ry))
				if norm <= 1.0:
					var col: Color = Color("7f8c8d")
					if dy < 0:
						col = Color("95a5a6") # light top
					elif dy > 0:
						col = Color("596263") # shadow bottom
					if dx == 0 and dy == 0:
						col = Color("529e57") # moss specks
					img.set_pixel(px, py, col)
				elif norm <= 1.35 and dy > 0:
					# Drop shadow
					img.set_pixel(px, py, Color(0.1, 0.15, 0.1, 0.5))
	return img

func _create_deco_bush() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	var cx := 16
	var cy := 16
	var r := 11
	for dy in range(-r - 2, r + 4):
		for dx in range(-r - 2, r + 2):
			var px := cx + dx
			var py := cy + dy
			if px < 0 or px >= 32 or py < 0 or py >= 32:
				continue
			var d := sqrt(float(dx * dx + dy * dy))
			if d <= float(r):
				var col := Color("27ae60")
				if dy < -3:
					col = Color("2ecc71") # sunlit top
				elif dy > 4:
					col = Color("1e8449") # dark underbelly
				# Berries
				if (dx == -2 and dy == -1) or (dx == 4 and dy == 2) or (dx == -4 and dy == 4):
					col = Color("e74c3c")
				img.set_pixel(px, py, col)
			elif d <= float(r + 2) and dy > 4:
				img.set_pixel(px, py, Color(0.08, 0.15, 0.08, 0.5))
	return img

func _create_deco_tall_grass() -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(C_TRANSPARENT)
	var blades: Array[Array] = [
		[Vector2i(10, 28), Vector2i(9, 22), Vector2i(8, 16), Vector2i(6, 10)],
		[Vector2i(14, 28), Vector2i(14, 20), Vector2i(13, 14), Vector2i(12, 8)],
		[Vector2i(18, 28), Vector2i(19, 21), Vector2i(20, 15), Vector2i(22, 10)],
		[Vector2i(22, 28), Vector2i(23, 23), Vector2i(24, 18), Vector2i(25, 14)]
	]
	for b in blades:
		for i in range(b.size()):
			var p: Vector2i = b[i]
			var col: Color = C_GRASS_DARKER if i == 0 else (C_GRASS_LIGHT if i == b.size() - 1 else C_GRASS_LIGHTER)
			img.set_pixel(p.x, p.y, col)
			img.set_pixel(p.x + 1, p.y, col.darkened(0.15))
	return img

# ── Pseudo-Random Hash Helper ───────────────────────────────────────────────

func _hash2d(x: int, y: int, seed_val: int) -> float:
	var h: int = (x * 374761393 + y * 668265263 + seed_val * 912345671) ^ 0x5bf03635
	h = (h ^ (h >> 13)) * 1274126177
	return float(h & 0x7fffffff) / float(0x7fffffff)

# ── TileSet Resource Assembly ───────────────────────────────────────────────

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	# 1. Custom Data Layers
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "terrain_type")
	ts.set_custom_data_layer_type(0, TYPE_STRING)

	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(1, "elevation")
	ts.set_custom_data_layer_type(1, TYPE_INT)

	var tile_configs: Array[Dictionary] = [
		{"file": "tile_grass_base.png", "terrain": "grass", "elev": 0},
		{"file": "tile_grass_flower_red.png", "terrain": "grass", "elev": 0},
		{"file": "tile_grass_flower_yellow.png", "terrain": "grass", "elev": 0},
		{"file": "tile_grass_flower_blue.png", "terrain": "grass", "elev": 0},
		{"file": "tile_grass_tuft.png", "terrain": "grass", "elev": 0},
		{"file": "tile_elevated_grass.png", "terrain": "grass", "elev": 1},
		{"file": "tile_slope_north.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_south.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_east.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_west.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_corner_ne.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_corner_nw.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_corner_se.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_corner_sw.png", "terrain": "slope", "elev": 0},
		{"file": "tile_slope_ramp.png", "terrain": "ramp", "elev": 0},
		{"file": "tile_cliff_edge_south.png", "terrain": "cliff", "elev": 0},
		{"file": "tile_deco_wildflowers.png", "terrain": "flower", "elev": 0},
		{"file": "tile_deco_stepping_stones.png", "terrain": "stone", "elev": 0},
		{"file": "tile_deco_bush.png", "terrain": "foliage", "elev": 0},
		{"file": "tile_deco_tall_grass.png", "terrain": "foliage", "elev": 0},
	]

	for cfg in tile_configs:
		var rel_path: String = "%s/%s" % [TILES_DIR, cfg["file"]]
		var tex: Texture2D = load(rel_path)
		if tex == null:
			var img: Image = Image.load_from_file(ProjectSettings.globalize_path(rel_path))
			tex = ImageTexture.create_from_image(img)

		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.create_tile(Vector2i(0, 0))
		var source_id: int = ts.add_source(src)

		var tile_data: TileData = (ts.get_source(source_id) as TileSetAtlasSource).get_tile_data(Vector2i(0, 0), 0)
		tile_data.set_custom_data("terrain_type", cfg["terrain"])
		tile_data.set_custom_data("elevation", cfg["elev"])

	var save_err: Error = ResourceSaver.save(ts, TILESET_PATH)
	if save_err != OK:
		printerr("Failed to save TileSet to %s (Error %d)" % [TILESET_PATH, save_err])
