@tool
extends SceneTree

## Generates high-quality pixel-art 32x32 tiles for OriginalRPG's green field terrain.
## V3 — Polished RPG Aesthetic:
##   - Smooth, seamless organic grass with natural color harmony
##   - Sunlit elevated plateau tiles (elevation 1)
##   - RPG-style directional cliff/slopes with top-left lighting
##   - Beaten-path gentle ramp tile
##   - Multi-cluster pixel-art leafy bushes with highlights & drop shadows
##   - Stepping stones, wildflowers, and tufts on transparent decoration layer
##   - Strict Godot 4 GDScript typing (clampf, lerpf, typed vars)

const TILES_DIR: String = "res://assets/tiles/ground"
const TILESET_PATH: String = "res://assets/tiles/tileset_green_field.tres"

# ── Palette ──────────────────────────────────────────────────────────────────
# Natural vibrant greens
const C_GRASS_BASE: Color      = Color("459c38") # Core meadow green
const C_GRASS_DARK: Color      = Color("37802b") # Mid shadow
const C_GRASS_DARKER: Color    = Color("29631f") # Deep shadow
const C_GRASS_LIGHT: Color     = Color("5cb84b") # Sunlit blade
const C_GRASS_LIGHTER: Color   = Color("72cc60") # Bright tip
const C_GRASS_HIGHLIGHT: Color = Color("8ee27c") # Sun glint

# Sunlit elevated grass (Higher plateau, warm sunlight)
const C_ELEV_BASE: Color       = Color("55b045")
const C_ELEV_DARK: Color       = Color("429434")
const C_ELEV_LIGHT: Color      = Color("6ec75c")
const C_ELEV_HIGHLIGHT: Color  = Color("8fe27c")

# Cliff / Earth bank tones (Warm RPG dirt & cliff)
const C_EARTH_BASE: Color      = Color("7c5b3c")
const C_EARTH_LIGHT: Color     = Color("99744f")
const C_EARTH_DARK: Color      = Color("5b3f27")
const C_EARTH_SHADOW: Color    = Color("3d2816")

# Cobblestone & utility
const C_STONE_LIGHT: Color     = Color("b8bec4")
const C_STONE_MID: Color       = Color("8c949d")
const C_STONE_DARK: Color      = Color("5e656d")
const C_TRANSPARENT: Color     = Color(0.0, 0.0, 0.0, 0.0)

func _init() -> void:
	print("==========================================")
	print(" OriginalRPG — Field Tile Generator V3   ")
	print("==========================================")
	var dir_global: String = ProjectSettings.globalize_path(TILES_DIR)
	DirAccess.make_dir_recursive_absolute(dir_global)

	_generate_all_tiles()
	print("[1/2] 20 high-quality tile textures generated.")

	_build_tileset()
	print("[2/2] TileSet resource assembled & saved to %s." % TILESET_PATH)
	print("==========================================")
	quit(0)

# ── Generation Pipeline ──────────────────────────────────────────────────────

func _generate_all_tiles() -> void:
	# 0..4: Ground layer base variants
	_save("tile_grass_base.png",           _make_grass_base(101))
	_save("tile_grass_flower_red.png",     _make_grass_flowers(Color("e74c3c"), Color("f1c40f"), 202))
	_save("tile_grass_flower_yellow.png",  _make_grass_flowers(Color("f1c40f"), Color("ffffff"), 303))
	_save("tile_grass_flower_blue.png",    _make_grass_flowers(Color("3498db"), Color("e0f7fa"), 404))
	_save("tile_grass_tuft.png",           _make_grass_tufts(505))

	# 5: Elevated plateau grass
	_save("tile_elevated_grass.png",       _make_elevated_grass(606))

	# 6..13: Directional slopes / cliff transitions
	_save("tile_slope_north.png",          _make_slope_north())
	_save("tile_slope_south.png",          _make_slope_south())
	_save("tile_slope_east.png",           _make_slope_east())
	_save("tile_slope_west.png",           _make_slope_west())
	_save("tile_slope_corner_ne.png",      _make_slope_corner_ne())
	_save("tile_slope_corner_nw.png",      _make_slope_corner_nw())
	_save("tile_slope_corner_se.png",      _make_slope_corner_se())
	_save("tile_slope_corner_sw.png",      _make_slope_corner_sw())

	# 14..15: Ramp and cliff
	_save("tile_slope_ramp.png",           _make_slope_ramp())
	_save("tile_cliff_edge_south.png",     _make_cliff_edge_south())

	# 16..19: Transparent decoration overlays
	_save("tile_deco_wildflowers.png",     _make_deco_wildflowers())
	_save("tile_deco_stepping_stones.png", _make_deco_stepping_stones())
	_save("tile_deco_bush.png",            _make_deco_bush())
	_save("tile_deco_tall_grass.png",      _make_deco_tall_grass())

func _save(filename: String, img: Image) -> void:
	var path: String = "%s/%s" % [TILES_DIR, filename]
	img.save_png(ProjectSettings.globalize_path(path))

# ── Math & Texture Helpers ───────────────────────────────────────────────────

func _h2d(x: int, y: int, seed_val: int) -> float:
	var h: int = (x * 374761393 + y * 668265263 + seed_val * 912345671) ^ 0x5bf03635
	h = (h ^ (h >> 13)) * 1274126177
	return float(h & 0x7fffffff) / float(0x7fffffff)

func _create_blank_image(transparent: bool = false) -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	if transparent:
		img.fill(C_TRANSPARENT)
	return img

# ── 1. Base Grass (Seamless, Soft Pixel Dithering) ───────────────────────────

func _make_grass_base(seed_val: int) -> Image:
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			# Multi-octave organic dithering
			var n1: float = _h2d(x, y, seed_val)
			var n2: float = _h2d(x + 17, y + 23, seed_val + 11)
			var n3: float = _h2d(x / 2, y / 2, seed_val + 37)
			var v: float = n1 * 0.45 + n2 * 0.35 + n3 * 0.20

			var col: Color
			if v > 0.76:
				col = C_GRASS_LIGHT
			elif v > 0.52:
				col = C_GRASS_BASE
			elif v > 0.28:
				col = C_GRASS_DARK
			else:
				col = C_GRASS_DARKER

			# Occasional tiny sun-fleck
			if n1 > 0.93 and n2 > 0.65:
				col = C_GRASS_HIGHLIGHT

			img.set_pixel(x, y, col)
	return img

# ── 2. Elevated Plateau Grass (Brighter, Sunlit Meadow) ──────────────────────

func _make_elevated_grass(seed_val: int) -> Image:
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var n1: float = _h2d(x, y, seed_val)
			var n2: float = _h2d(x + 29, y + 13, seed_val + 17)
			var v: float = n1 * 0.55 + n2 * 0.45

			var col: Color
			if v > 0.74:
				col = C_ELEV_LIGHT
			elif v > 0.45:
				col = C_ELEV_BASE
			else:
				col = C_ELEV_DARK

			if n1 > 0.92:
				col = C_ELEV_HIGHLIGHT

			img.set_pixel(x, y, col)
	return img

# ── 3. Grass Flower Variations ───────────────────────────────────────────────

func _make_grass_flowers(petal_col: Color, center_col: Color, seed_val: int) -> Image:
	var img: Image = _make_grass_base(seed_val)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 77771

	var count: int = rng.randi_range(5, 7)
	for _i: int in range(count):
		var fx: int = rng.randi_range(3, 28)
		var fy: int = rng.randi_range(3, 28)

		# 5-pixel cross flower blossom
		img.set_pixel(fx - 1, fy, petal_col)
		img.set_pixel(fx + 1, fy, petal_col)
		img.set_pixel(fx, fy - 1, petal_col)
		img.set_pixel(fx, fy + 1, petal_col)
		img.set_pixel(fx, fy, center_col)
	return img

# ── 4. Grass Tufts ───────────────────────────────────────────────────────────

func _make_grass_tufts(seed_val: int) -> Image:
	var img: Image = _make_grass_base(seed_val)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 91919

	for _i: int in range(5):
		var tx: int = rng.randi_range(3, 27)
		var ty: int = rng.randi_range(8, 28)
		# Draw 3 vertical grass blades of differing heights
		for h: int in range(4):
			img.set_pixel(tx, ty - h, C_GRASS_LIGHTER)
		for h: int in range(3):
			img.set_pixel(tx - 1, ty - h, C_GRASS_LIGHT)
		for h: int in range(3):
			img.set_pixel(tx + 1, ty - h, C_GRASS_LIGHT)
		img.set_pixel(tx, ty - 4, C_GRASS_HIGHLIGHT)
	return img

# ── 5. Directional Slopes & Cliffs ───────────────────────────────────────────
# In RPGs with top-down camera (tilted ~45°):
#   - South slope is seen as a front-facing bank: lush grass on top with overhang,
#     warm shaded cliff/earth face in middle, soft shadow and transition at base.
#   - North slope is an upward receding bank: smooth transition from base grass to plateau.
#   - West slope is sunlit on its face.
#   - East slope has soft shadow on its face.

func _make_slope_south() -> Image:
	# Front-facing bank: Top has elevated grass with tuft fringe,
	# middle has smooth shaded bank, bottom has shadow onto base grass.
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _h2d(x, y, 71) * 0.12 - 0.06
			var col: Color

			if y < 8:
				# Elevated crest with wavy fringe
				var fringe: int = int((_h2d(x, 0, 81) - 0.5) * 4.0)
				if y + fringe < 7:
					col = C_ELEV_BASE.lerp(C_ELEV_LIGHT, _h2d(x, y, 82))
				else:
					col = C_ELEV_HIGHLIGHT
			elif y < 22:
				# Cliff / earth bank face with subtle vertical rock texture
				var bank_t: float = float(y - 8) / 14.0
				var rock_n: float = _h2d(x, y / 2, 83) * 0.15
				var bank_col: Color = C_EARTH_LIGHT.lerp(C_EARTH_DARK, clampf(bank_t + rock_n, 0.0, 1.0))
				# Occasional grass tuft hanging over edge
				if y < 11 and (x % 5 == 0 or x % 7 == 0):
					bank_col = C_GRASS_LIGHT
				col = bank_col
			elif y < 27:
				# Base shadow under bank
				var shadow_t: float = float(y - 22) / 5.0
				col = C_EARTH_SHADOW.lerp(C_GRASS_DARKER, shadow_t)
			else:
				# Base grass transition
				col = C_GRASS_BASE.lerp(C_GRASS_DARK, float(y - 27) / 5.0)

			img.set_pixel(x, y, col)
	return img

func _make_slope_north() -> Image:
	# Receding bank facing north: smooth upward green incline
	var img: Image = _create_blank_image()
	for y: int in range(32):
		var t: float = float(y) / 31.0
		for x: int in range(32):
			var n: float = _h2d(x, y, 72) * 0.10 - 0.05
			var blend: float = clampf(t + n, 0.0, 1.0)
			# Top is elevated grass, transitioning smoothly to base grass
			var col: Color = C_ELEV_BASE.lerp(C_GRASS_BASE, blend)
			if y < 4:
				col = C_ELEV_LIGHT
			img.set_pixel(x, y, col)
	return img

func _make_slope_west() -> Image:
	# West edge: sunlit side (light from top-left)
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var t: float = float(x) / 31.0
			var n: float = _h2d(x, y, 73) * 0.10 - 0.05
			var blend: float = clampf(t + n, 0.0, 1.0)
			var col: Color
			if x < 8:
				# Soft bank edge
				col = C_EARTH_BASE.lerp(C_GRASS_LIGHT, float(x) / 8.0)
			else:
				col = C_GRASS_LIGHT.lerp(C_ELEV_BASE, (float(x) - 8.0) / 23.0)
			img.set_pixel(x, y, col)
	return img

func _make_slope_east() -> Image:
	# East edge: shaded side (in shadow from morning sun)
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var t: float = 1.0 - float(x) / 31.0
			var n: float = _h2d(x, y, 74) * 0.10 - 0.05
			var blend: float = clampf(t + n, 0.0, 1.0)
			var col: Color
			if x > 23:
				col = C_ELEV_BASE.lerp(C_EARTH_DARK, float(x - 23) / 8.0)
			else:
				col = C_ELEV_BASE.lerp(C_GRASS_DARK, float(x) / 23.0 * 0.4)
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_nw() -> Image:
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var dist: float = sqrt(pow(float(x), 2.0) + pow(float(y), 2.0)) / 32.0
			var n: float = _h2d(x, y, 75) * 0.08
			var blend: float = clampf(dist + n, 0.0, 1.0)
			var col: Color = C_EARTH_BASE.lerp(C_ELEV_BASE, blend)
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_ne() -> Image:
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var dist: float = sqrt(pow(31.0 - float(x), 2.0) + pow(float(y), 2.0)) / 32.0
			var n: float = _h2d(x, y, 76) * 0.08
			var blend: float = clampf(dist + n, 0.0, 1.0)
			var col: Color = C_EARTH_DARK.lerp(C_ELEV_BASE, blend)
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_sw() -> Image:
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var dist: float = sqrt(pow(float(x), 2.0) + pow(31.0 - float(y), 2.0)) / 32.0
			var n: float = _h2d(x, y, 77) * 0.08
			var blend: float = clampf(dist + n, 0.0, 1.0)
			var col: Color = C_EARTH_SHADOW.lerp(C_ELEV_BASE, blend)
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_se() -> Image:
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var dist: float = sqrt(pow(31.0 - float(x), 2.0) + pow(31.0 - float(y), 2.0)) / 32.0
			var n: float = _h2d(x, y, 78) * 0.08
			var blend: float = clampf(dist + n, 0.0, 1.0)
			var col: Color = C_EARTH_SHADOW.lerp(C_ELEV_BASE, blend)
			img.set_pixel(x, y, col)
	return img

# ── 6. Ramp & Cliff ──────────────────────────────────────────────────────────

func _make_slope_ramp() -> Image:
	# A natural, gentle walkable earth path winding up the slope
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			# Path center is x=16, path width ~18 pixels
			var path_dist: float = abs(float(x) - 16.0) / 9.0
			var n: float = _h2d(x, y, 91) * 0.2 - 0.1
			var blend: float = clampf(path_dist + n, 0.0, 1.0)

			var path_col: Color = C_EARTH_LIGHT.lerp(C_EARTH_BASE, float(y) / 31.0)
			# Small pebbles on path
			if _h2d(x, y, 92) > 0.88 and blend < 0.6:
				path_col = C_STONE_LIGHT

			var col: Color = path_col.lerp(C_GRASS_BASE, blend)
			img.set_pixel(x, y, col)
	return img

func _make_cliff_edge_south() -> Image:
	# More rugged cliff face for rocky hill sections
	var img: Image = _create_blank_image()
	for y: int in range(32):
		for x: int in range(32):
			var col: Color
			if y < 7:
				col = C_ELEV_BASE
			elif y < 24:
				# Rocky strata lines
				var strata: float = sin(float(y) * 1.2 + float(x) * 0.3) * 0.15
				var rock_t: float = float(y - 7) / 17.0
				col = C_EARTH_BASE.lerp(C_EARTH_DARK, clampf(rock_t + strata, 0.0, 1.0))
			else:
				col = C_EARTH_SHADOW.lerp(C_GRASS_BASE, float(y - 24) / 7.0)
			img.set_pixel(x, y, col)
	return img

# ── 7. Transparent Decoration Overlays ───────────────────────────────────────

func _make_deco_bush() -> Image:
	# A classic 16-bit RPG bush: rich leaf cluster with highlight & shadow
	var img: Image = _create_blank_image(true)

	# Overlapping foliage circles: Vector3(cx, cy, radius)
	var clusters: Array[Vector3] = [
		Vector3(16.0, 19.0, 10.0), # Main base body
		Vector3(11.0, 17.0, 8.0),  # Left cluster
		Vector3(21.0, 17.0, 8.0),  # Right cluster
		Vector3(16.0, 13.0, 8.5),  # Top central dome
		Vector3(12.0, 13.0, 6.5),  # Top-left highlight dome
		Vector3(20.0, 14.0, 6.5),  # Top-right dome
	]

	# 1. Soft drop shadow on ground beneath bush
	for y: int in range(25, 31):
		for x: int in range(6, 26):
			var s_dist: float = sqrt(pow((float(x) - 16.0) / 9.0, 2.0) + pow((float(y) - 27.0) / 3.0, 2.0))
			if s_dist < 1.0:
				var s_alpha: float = (1.0 - s_dist) * 0.45
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, s_alpha))

	# 2. Render organic leaf clusters
	for y: int in range(32):
		for x: int in range(32):
			var inside: bool = false
			var min_dist_ratio: float = 999.0
			var closest_cy: float = 16.0

			for c: Vector3 in clusters:
				var d: float = sqrt(pow(float(x) - c.x, 2.0) + pow(float(y) - c.y, 2.0))
				if d < c.z:
					inside = true
					var r: float = d / c.z
					if r < min_dist_ratio:
						min_dist_ratio = r
						closest_cy = c.y

			if inside:
				# Height factor: 0.0 at top of bush, 1.0 at bottom
				var h_factor: float = clampf((float(y) - 6.0) / 20.0, 0.0, 1.0)
				# Light from top-left: calculate sun direction
				var sun_dot: float = clampf(((16.0 - float(x)) * 0.4 + (24.0 - float(y)) * 0.6) / 16.0, 0.0, 1.0)

				var leaf_col: Color
				if sun_dot > 0.65 and h_factor < 0.45:
					leaf_col = C_GRASS_HIGHLIGHT # Sun glint on top leaves
				elif h_factor < 0.40:
					leaf_col = C_GRASS_LIGHTER
				elif h_factor < 0.70:
					leaf_col = C_GRASS_LIGHT
				elif h_factor < 0.88:
					leaf_col = C_GRASS_BASE
				else:
					leaf_col = C_GRASS_DARKER

				# Dark leaf-edge outline
				if min_dist_ratio > 0.82:
					leaf_col = leaf_col.darkened(0.35)

				# Red flower berries in bush
				if (x == 12 and y == 16) or (x == 20 and y == 15) or (x == 16 and y == 20) or (x == 15 and y == 11):
					leaf_col = Color("e74c3c")
				elif (x == 13 and y == 16) or (x == 21 and y == 15):
					leaf_col = Color("f39c12")

				img.set_pixel(x, y, leaf_col)
	return img

func _make_deco_stepping_stones() -> Image:
	var img: Image = _create_blank_image(true)

	# Two distinct stone slabs
	var stones: Array[Dictionary] = [
		{"cx": 9.0, "cy": 16.0, "rx": 6.5, "ry": 4.5},
		{"cx": 22.0, "cy": 15.0, "rx": 5.5, "ry": 4.0},
	]

	for s: Dictionary in stones:
		var cx: float = float(s["cx"])
		var cy: float = float(s["cy"])
		var rx: float = float(s["rx"])
		var ry: float = float(s["ry"])

		# Drop shadow under stone
		for y: int in range(int(cy), int(cy + ry + 3.0)):
			for x: int in range(int(cx - rx - 1.0), int(cx + rx + 2.0)):
				var d: float = sqrt(pow((float(x) - cx - 1.0) / (rx + 0.5), 2.0) + pow((float(y) - cy - 1.5) / ry, 2.0))
				if d < 1.0:
					img.set_pixel(x, y, Color(0.0, 0.0, 0.0, (1.0 - d) * 0.35))

		# Stone body with beveled edge
		for y: int in range(int(cy - ry - 1.0), int(cy + ry + 1.0)):
			for x: int in range(int(cx - rx - 1.0), int(cx + rx + 1.0)):
				var d: float = sqrt(pow((float(x) - cx) / rx, 2.0) + pow((float(y) - cy) / ry, 2.0))
				if d < 1.0:
					var col: Color = C_STONE_MID
					# Top-left bevel highlight
					if (float(x) - cx) + (float(y) - cy) < -1.5:
						col = C_STONE_LIGHT
					# Bottom-right bevel shadow
					elif (float(x) - cx) + (float(y) - cy) > 2.0:
						col = C_STONE_DARK
					img.set_pixel(x, y, col)
	return img

func _make_deco_wildflowers() -> Image:
	var img: Image = _create_blank_image(true)
	var colors: Array[Color] = [
		Color("e74c3c"), # Red Poppy
		Color("f1c40f"), # Yellow Buttercup
		Color("3498db"), # Bluebell
		Color("9b59b6"), # Lavender
		Color("ffffff"), # White Daisy
	]

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 44433
	for _i: int in range(8):
		var fx: int = rng.randi_range(3, 27)
		var fy: int = rng.randi_range(4, 27)
		var c: Color = colors[rng.randi() % colors.size()]

		# Stalk
		img.set_pixel(fx, fy + 1, C_GRASS_DARKER)
		# Petals
		img.set_pixel(fx, fy, c)
		img.set_pixel(fx - 1, fy, c.lightened(0.2))
		img.set_pixel(fx + 1, fy, c.lightened(0.2))
		img.set_pixel(fx, fy - 1, c.lightened(0.3))
		# Yellow center dot for non-yellow flowers
		if c != Color("f1c40f"):
			img.set_pixel(fx, fy, Color("f39c12"))
	return img

func _make_deco_tall_grass() -> Image:
	var img: Image = _create_blank_image(true)
	var stalks: Array[int] = [6, 11, 16, 22, 27]

	for sx: int in stalks:
		var n: float = _h2d(sx, 0, 99)
		var sway: int = int((n - 0.5) * 6.0)
		var height: int = 8 + int(n * 9.0)

		for dy: int in range(height):
			var py: int = 31 - dy
			var curve: float = float(dy) / float(height)
			var px: int = sx + int(float(sway) * curve * curve)
			px = clampi(px, 0, 31)
			py = clampi(py, 0, 31)

			var col: Color = C_GRASS_DARK.lerp(C_GRASS_HIGHLIGHT, curve)
			img.set_pixel(px, py, col)
	return img

# ── TileSet Resource Assembly ────────────────────────────────────────────────

func _build_tileset() -> void:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	# 1. Custom data layers
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "terrain_type")
	ts.set_custom_data_layer_type(0, TYPE_STRING) # 4

	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(1, "elevation")
	ts.set_custom_data_layer_type(1, TYPE_INT) # 2

	# 2. Config list matching source IDs 0..19
	var configs: Array[Dictionary] = [
		{"file": "tile_grass_base.png",          "terrain": "grass",   "elev": 0},
		{"file": "tile_grass_flower_red.png",     "terrain": "grass",   "elev": 0},
		{"file": "tile_grass_flower_yellow.png",  "terrain": "grass",   "elev": 0},
		{"file": "tile_grass_flower_blue.png",    "terrain": "grass",   "elev": 0},
		{"file": "tile_grass_tuft.png",           "terrain": "grass",   "elev": 0},
		{"file": "tile_elevated_grass.png",       "terrain": "grass",   "elev": 1},
		{"file": "tile_slope_north.png",          "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_south.png",          "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_east.png",           "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_west.png",           "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_corner_ne.png",      "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_corner_nw.png",      "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_corner_se.png",      "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_corner_sw.png",      "terrain": "slope",   "elev": 0},
		{"file": "tile_slope_ramp.png",           "terrain": "ramp",    "elev": 0},
		{"file": "tile_cliff_edge_south.png",     "terrain": "cliff",   "elev": 0},
		{"file": "tile_deco_wildflowers.png",     "terrain": "flower",  "elev": 0},
		{"file": "tile_deco_stepping_stones.png", "terrain": "stone",   "elev": 0},
		{"file": "tile_deco_bush.png",            "terrain": "foliage", "elev": 0},
		{"file": "tile_deco_tall_grass.png",      "terrain": "foliage", "elev": 0},
	]

	for cfg: Dictionary in configs:
		var rel_path: String = "%s/%s" % [TILES_DIR, String(cfg["file"])]
		var tex: Texture2D = load(rel_path) as Texture2D
		if tex == null:
			var img: Image = Image.load_from_file(ProjectSettings.globalize_path(rel_path))
			tex = ImageTexture.create_from_image(img)

		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(32, 32)
		src.create_tile(Vector2i(0, 0))

		var source_id: int = ts.add_source(src)
		var tile_data: TileData = (ts.get_source(source_id) as TileSetAtlasSource).get_tile_data(Vector2i(0, 0), 0)
		tile_data.set_custom_data("terrain_type", String(cfg["terrain"]))
		tile_data.set_custom_data("elevation", int(cfg["elev"]))

	var save_err: Error = ResourceSaver.save(ts, TILESET_PATH)
	if save_err != OK:
		printerr("Failed to save TileSet to %s (Error %d)" % [TILESET_PATH, save_err])
