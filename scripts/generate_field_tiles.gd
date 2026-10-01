@tool
extends SceneTree

## Generates authentic 16-bit pixel-art 32x32 tiles for OriginalRPG.
## V4 — True Pixel Art & Seamless RPG Terrain:
##   - Seamless tileable base grass (wraps at all 4 borders)
##   - Seamless tileable sunlit elevated grass
##   - Seamless 1-tile South cliff bank (grass crest + textured rock/earth + shadow)
##   - Seamless 1-tile North, East, West slope transitions
##   - Matching 4 corner slopes
##   - Natural packed-dirt & cobblestone ramp
##   - Handcrafted pixel-art bushes, stepping stones, and wildflowers
##   - Strict Godot 4 GDScript typing throughout

const TILES_DIR: String = "res://assets/tiles/ground"
const TILESET_PATH: String = "res://assets/tiles/tileset_green_field.tres"

# ── Authentic 16-Bit RPG Palette ─────────────────────────────────────────────
# Base meadow grass
const C_G_DEEP: Color   = Color("1f4e18") # Deep shadow
const C_G_DARK: Color   = Color("2c6b22") # Shadow blade
const C_G_MID: Color    = Color("3d8b32") # Main grass tone
const C_G_LIGHT: Color  = Color("55a845") # Sunlit blade
const C_G_BRIGHT: Color = Color("70c45d") # Grass highlight tip

# Elevated meadow grass (slightly warmer, golden sunlit hue)
const C_E_DEEP: Color   = Color("285c1e")
const C_E_DARK: Color   = Color("3b7e2d")
const C_E_MID: Color    = Color("4ea03b")
const C_E_LIGHT: Color  = Color("69be53")
const C_E_BRIGHT: Color = Color("87d96f")

# Earth & Cliff rock
const C_R_DEEP: Color   = Color("302014") # Deep crevice / shadow
const C_R_DARK: Color   = Color("4a3321") # Shaded rock
const C_R_MID: Color    = Color("684a32") # Mid rock / earth
const C_R_LIGHT: Color  = Color("856346") # Sunlit rock ledge
const C_R_HIGHLIGHT: Color = Color("a6815e") # Bright ledge edge

# Stone & Accents
const C_STONE_DARK: Color  = Color("4e555e")
const C_STONE_MID: Color   = Color("7a828c")
const C_STONE_LIGHT: Color = Color("a8b0ba")
const C_TRANSPARENT: Color = Color(0.0, 0.0, 0.0, 0.0)

func _init() -> void:
	print("==========================================")
	print(" OriginalRPG — Field Tile Generator V4   ")
	print("==========================================")
	var dir_global: String = ProjectSettings.globalize_path(TILES_DIR)
	DirAccess.make_dir_recursive_absolute(dir_global)

	_generate_all_tiles()
	print("[1/2] 20 authentic pixel-art tile textures generated.")

	_build_tileset()
	print("[2/2] TileSet resource assembled & saved to %s." % TILESET_PATH)
	print("==========================================")
	quit(0)

# ── Pipeline ─────────────────────────────────────────────────────────────────

func _generate_all_tiles() -> void:
	# 0..4: Ground Base & Variations
	_save("tile_grass_base.png",           _make_grass_base(101))
	_save("tile_grass_flower_red.png",     _make_grass_flowers(Color("d93829"), Color("f1c40f"), 202))
	_save("tile_grass_flower_yellow.png",  _make_grass_flowers(Color("f4d03f"), Color("ffffff"), 303))
	_save("tile_grass_flower_blue.png",    _make_grass_flowers(Color("3498db"), Color("e8f8f5"), 404))
	_save("tile_grass_tuft.png",           _make_grass_tufts(505))

	# 5: Elevated Plateau Grass
	_save("tile_elevated_grass.png",       _make_elevated_grass(606))

	# 6..13: Directional 1-Tile Slopes / Cliffs
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

	# 16..19: Transparent Decoration Overlays
	_save("tile_deco_wildflowers.png",     _make_deco_wildflowers())
	_save("tile_deco_stepping_stones.png", _make_deco_stepping_stones())
	_save("tile_deco_bush.png",            _make_deco_bush())
	_save("tile_deco_tall_grass.png",      _make_deco_tall_grass())

func _save(filename: String, img: Image) -> void:
	var path: String = "%s/%s" % [TILES_DIR, filename]
	img.save_png(ProjectSettings.globalize_path(path))

# ── Math & Texture Helpers ───────────────────────────────────────────────────

# Toroidal (wrapping) noise helper for seamless tileable textures
func _torus_noise(x: int, y: int, seed_val: int) -> float:
	# Evaluate noise that repeats every 32 pixels seamlessly
	var nx: float = float(x % 32)
	var ny: float = float(y % 32)
	var h1: int = (int(nx) * 374761393 + int(ny) * 668265263 + seed_val * 912345671) ^ 0x5bf03635
	h1 = (h1 ^ (h1 >> 13)) * 1274126177
	return float(h1 & 0x7fffffff) / float(0x7fffffff)

func _create_image(transparent: bool = false) -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	if transparent:
		img.fill(C_TRANSPARENT)
	return img

# ── 1. Seamless Base Grass (Pixel-Art Dithering) ──────────────────────────────

func _make_grass_base(seed_val: int) -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			# Seamless 2-octave noise
			var n1: float = _torus_noise(x, y, seed_val)
			var n2: float = _torus_noise((x + 7) % 32, (y + 11) % 32, seed_val + 33)
			var v: float = n1 * 0.6 + n2 * 0.4

			# Discrete 4-tone pixel-art shading
			var col: Color = C_G_MID
			if v > 0.78:
				col = C_G_LIGHT
			elif v > 0.55:
				col = C_G_MID
			elif v > 0.30:
				col = C_G_DARK
			else:
				col = C_G_DEEP

			# Subtle blade tip
			if n1 > 0.92 and (x + y) % 2 == 0:
				col = C_G_BRIGHT

			img.set_pixel(x, y, col)
	return img

# ── 2. Seamless Elevated Grass (Sunlit Golden-Green) ─────────────────────────

func _make_elevated_grass(seed_val: int) -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n1: float = _torus_noise(x, y, seed_val)
			var n2: float = _torus_noise((x + 9) % 32, (y + 13) % 32, seed_val + 47)
			var v: float = n1 * 0.6 + n2 * 0.4

			var col: Color = C_E_MID
			if v > 0.76:
				col = C_E_LIGHT
			elif v > 0.52:
				col = C_E_MID
			elif v > 0.28:
				col = C_E_DARK
			else:
				col = C_E_DEEP

			if n1 > 0.91 and (x + y) % 2 == 0:
				col = C_E_BRIGHT

			img.set_pixel(x, y, col)
	return img

# ── 3. Base Grass with Flowers ───────────────────────────────────────────────

func _make_grass_flowers(petal_col: Color, center_col: Color, seed_val: int) -> Image:
	var img: Image = _make_grass_base(seed_val)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 65432

	for _i: int in range(5):
		var fx: int = rng.randi_range(3, 28)
		var fy: int = rng.randi_range(3, 28)
		# 5-pixel cross flower blossom
		img.set_pixel(fx - 1, fy, petal_col)
		img.set_pixel(fx + 1, fy, petal_col)
		img.set_pixel(fx, fy - 1, petal_col)
		img.set_pixel(fx, fy + 1, petal_col)
		img.set_pixel(fx, fy, center_col)
	return img

# ── 4. Base Grass with Tufts ─────────────────────────────────────────────────

func _make_grass_tufts(seed_val: int) -> Image:
	var img: Image = _make_grass_base(seed_val)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val * 88812

	for _i: int in range(4):
		var tx: int = rng.randi_range(4, 27)
		var ty: int = rng.randi_range(8, 28)
		img.set_pixel(tx, ty, C_G_DARK)
		img.set_pixel(tx, ty - 1, C_G_LIGHT)
		img.set_pixel(tx, ty - 2, C_G_LIGHT)
		img.set_pixel(tx, ty - 3, C_G_BRIGHT)
		img.set_pixel(tx - 1, ty - 1, C_G_LIGHT)
		img.set_pixel(tx - 1, ty - 2, C_G_BRIGHT)
		img.set_pixel(tx + 1, ty - 1, C_G_LIGHT)
	return img

# ── 5. South Ledge / Bank (Classic Top-Down RPG Cliff) ────────────────────────
# Seamless horizontally (x=0 matches x=31 pattern logic)
# Top 0..9:   Sunlit elevated grass with natural overhang fringe
# Mid 10..22: Rock/earth cliff bank with pixel-art ledges
# Bot 23..31: Deep drop-shadow transitioning into base grass
func _make_slope_south() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 711)
			var col: Color

			if y < 8:
				# Elevated sunlit grass surface
				col = C_E_MID if n > 0.4 else C_E_LIGHT
				if y == 7:
					col = C_E_BRIGHT # Sunlit highlight edge of the drop-off
			elif y < 11:
				# Overhanging grass fringe (jagged blades peeking down)
				var fringe_down: bool = (x % 3 == 0) or (x % 5 == 0)
				if fringe_down and y < 10:
					col = C_E_LIGHT if n > 0.5 else C_E_MID
				else:
					col = C_R_LIGHT # First exposed rock shelf
			elif y < 22:
				# Rock & Earth cliff face (discrete pixel-art rock facets)
				var rock_layer: int = (y - 11) / 3
				if rock_layer == 0:
					col = C_R_MID if n > 0.45 else C_R_LIGHT
				elif rock_layer == 1:
					col = C_R_DARK if n > 0.50 else C_R_MID
				elif rock_layer == 2:
					col = C_R_DARK if n > 0.40 else C_R_DEEP
				else:
					col = C_R_DEEP
				# Occasional vertical rock crevice
				if (x % 7 == 2 or x % 11 == 5) and y > 12:
					col = C_R_DEEP
			elif y < 26:
				# Drop shadow cast onto the lower ground
				col = C_G_DEEP
			else:
				# Lower meadow grass base
				col = C_G_DARK if n > 0.45 else C_G_MID

			img.set_pixel(x, y, col)
	return img

# ── 6. North Slope (Gentle Upward Green Incline) ──────────────────────────────
# Top 0..10:   Elevated grass
# Mid 11..21:  Shaded grassy incline transition
# Bot 22..31:  Base grass
func _make_slope_north() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 722)
			var col: Color

			if y < 10:
				# Elevated plateau
				col = C_E_MID if n > 0.4 else C_E_LIGHT
			elif y < 20:
				# Incline slope with upward grass fringe
				if (y == 10 or y == 11) and (x % 4 == 0 or x % 6 == 0):
					col = C_E_BRIGHT
				else:
					col = C_G_MID if n > 0.45 else C_G_LIGHT
			else:
				# Lower base grass
				col = C_G_MID if n > 0.5 else C_G_DARK

			img.set_pixel(x, y, col)
	return img

# ── 7. West Slope (Left Bank, Sunlit Side) ───────────────────────────────────
# Left 0..12: Base grass
# Mid 13..18: Sunlit grassy bank ridge
# Right 19..31: Elevated grass
func _make_slope_west() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 733)
			var col: Color

			if x < 10:
				col = C_G_MID if n > 0.45 else C_G_DARK
			elif x < 15:
				# Bank transition (sunlit from top-left)
				col = C_G_LIGHT if n > 0.4 else C_E_LIGHT
				if x == 14 and (y % 4 == 0):
					col = C_E_BRIGHT
			else:
				col = C_E_MID if n > 0.4 else C_E_LIGHT

			img.set_pixel(x, y, col)
	return img

# ── 8. East Slope (Right Bank, Shaded Side) ──────────────────────────────────
# Left 0..12: Elevated grass
# Mid 13..18: Shaded bank edge
# Right 19..31: Base grass
func _make_slope_east() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 744)
			var col: Color

			if x < 13:
				col = C_E_MID if n > 0.4 else C_E_LIGHT
			elif x < 19:
				# Shaded slope ridge
				col = C_G_DARK if n > 0.4 else C_R_DARK
			else:
				col = C_G_MID if n > 0.45 else C_G_DARK

			img.set_pixel(x, y, col)
	return img

# ── 9. Corner Slopes ─────────────────────────────────────────────────────────

func _make_slope_corner_nw() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 755)
			# Top-left is lower base, bottom-right is elevated
			var dist: float = sqrt(pow(float(x), 2.0) + pow(float(y), 2.0))
			var col: Color
			if dist < 12.0:
				col = C_G_MID if n > 0.5 else C_G_DARK
			elif dist < 18.0:
				col = C_G_LIGHT if n > 0.4 else C_E_BRIGHT
			else:
				col = C_E_MID if n > 0.4 else C_E_LIGHT
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_ne() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 766)
			# Top-right is lower base, bottom-left is elevated
			var dist: float = sqrt(pow(31.0 - float(x), 2.0) + pow(float(y), 2.0))
			var col: Color
			if dist < 12.0:
				col = C_G_MID if n > 0.5 else C_G_DARK
			elif dist < 18.0:
				col = C_G_DARK if n > 0.4 else C_R_DARK
			else:
				col = C_E_MID if n > 0.4 else C_E_LIGHT
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_sw() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 777)
			# Bottom-left is lower base with cliff drop-off
			var dist: float = sqrt(pow(float(x), 2.0) + pow(31.0 - float(y), 2.0))
			var col: Color
			if dist < 10.0:
				col = C_G_MID if n > 0.5 else C_G_DARK
			elif dist < 18.0:
				col = C_R_DARK if n > 0.4 else C_R_DEEP
			elif dist < 22.0:
				col = C_E_BRIGHT if n > 0.5 else C_E_LIGHT
			else:
				col = C_E_MID if n > 0.4 else C_E_LIGHT
			img.set_pixel(x, y, col)
	return img

func _make_slope_corner_se() -> Image:
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 788)
			# Bottom-right is lower base with shadow cliff
			var dist: float = sqrt(pow(31.0 - float(x), 2.0) + pow(31.0 - float(y), 2.0))
			var col: Color
			if dist < 10.0:
				col = C_G_MID if n > 0.5 else C_G_DARK
			elif dist < 18.0:
				col = C_R_DARK if n > 0.4 else C_R_DEEP
			elif dist < 22.0:
				col = C_E_LIGHT if n > 0.5 else C_E_MID
			else:
				col = C_E_MID if n > 0.4 else C_E_LIGHT
			img.set_pixel(x, y, col)
	return img

# ── 10. Ramp & Cliff ─────────────────────────────────────────────────────────

func _make_slope_ramp() -> Image:
	# A natural cobblestone and packed dirt ramp connecting levels
	var img: Image = _create_image()
	for y: int in range(32):
		for x: int in range(32):
			var n: float = _torus_noise(x, y, 911)
			# Center path is x = 6..25
			var is_path: bool = x >= 6 and x <= 25
			var col: Color

			if is_path:
				# Beaten dirt path with cobblestone steps
				var step_row: bool = (y % 7 == 0 or y % 7 == 1)
				if step_row and x >= 8 and x <= 23:
					col = C_STONE_LIGHT if y % 7 == 0 else C_STONE_DARK
				else:
					col = C_R_LIGHT if n > 0.5 else C_R_MID
				# Tiny pebbles
				if n > 0.85 and (x + y) % 3 == 0:
					col = C_STONE_LIGHT
			else:
				# Grassy banks flanking the path
				if y < 14:
					col = C_E_MID if n > 0.4 else C_E_LIGHT
				else:
					col = C_G_MID if n > 0.45 else C_G_DARK

			img.set_pixel(x, y, col)
	return img

func _make_cliff_edge_south() -> Image:
	# Rugged variant of south ledge
	return _make_slope_south()

# ── 11. Transparent Decorations ──────────────────────────────────────────────

func _make_deco_bush() -> Image:
	var img: Image = _create_image(true)
	# 5 round leaf lobes: Vector3(cx, cy, radius)
	var lobes: Array[Vector3] = [
		Vector3(16.0, 19.0, 9.5), # Base central lobe
		Vector3(10.0, 18.0, 7.5), # Left lobe
		Vector3(22.0, 18.0, 7.5), # Right lobe
		Vector3(13.0, 13.0, 7.0), # Upper left lobe
		Vector3(19.0, 13.0, 7.0), # Upper right lobe
	]

	# 1. Soft drop shadow on ground beneath bush
	for y: int in range(25, 30):
		for x: int in range(6, 26):
			var d: float = sqrt(pow((float(x) - 16.0) / 8.5, 2.0) + pow((float(y) - 27.0) / 2.5, 2.0))
			if d < 1.0:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, (1.0 - d) * 0.45))

	# 2. Render pixel-art leaf lobes with top-left lighting
	for y: int in range(32):
		for x: int in range(32):
			var inside: bool = false
			var min_edge_ratio: float = 999.0
			var lobe_center: Vector3

			for lb: Vector3 in lobes:
				var dist: float = sqrt(pow(float(x) - lb.x, 2.0) + pow(float(y) - lb.y, 2.0))
				if dist < lb.z:
					inside = true
					var r: float = dist / lb.z
					if r < min_edge_ratio:
						min_edge_ratio = r
						lobe_center = lb

			if inside:
				# Discrete 4-step shading
				var col: Color
				if min_edge_ratio > 0.82:
					col = C_G_DEEP # Dark leaf outline
				elif (float(x) - lobe_center.x) + (float(y) - lobe_center.y) < -2.0:
					col = C_G_BRIGHT # Sun glint on top-left of lobe
				elif y < 17:
					col = C_G_LIGHT
				elif y < 23:
					col = C_G_MID
				else:
					col = C_G_DARK

				# Red flower berries
				if (x == 12 and y == 16) or (x == 20 and y == 15) or (x == 15 and y == 11):
					col = Color("e74c3c")
				elif (x == 13 and y == 16) or (x == 21 and y == 15):
					col = Color("f39c12")

				img.set_pixel(x, y, col)
	return img

func _make_deco_stepping_stones() -> Image:
	var img: Image = _create_image(true)
	var stones: Array[Dictionary] = [
		{"cx": 9.0, "cy": 16.0, "rx": 6.5, "ry": 4.5},
		{"cx": 22.0, "cy": 15.0, "rx": 5.5, "ry": 4.0},
	]

	for s: Dictionary in stones:
		var cx: float = float(s["cx"])
		var cy: float = float(s["cy"])
		var rx: float = float(s["rx"])
		var ry: float = float(s["ry"])

		# Drop shadow
		for y: int in range(int(cy), int(cy + ry + 3.0)):
			for x: int in range(int(cx - rx - 1.0), int(cx + rx + 2.0)):
				var d: float = sqrt(pow((float(x) - cx - 1.0) / (rx + 0.5), 2.0) + pow((float(y) - cy - 1.5) / ry, 2.0))
				if d < 1.0:
					img.set_pixel(x, y, Color(0.0, 0.0, 0.0, (1.0 - d) * 0.40))

		# Stone slab
		for y: int in range(int(cy - ry - 1.0), int(cy + ry + 1.0)):
			for x: int in range(int(cx - rx - 1.0), int(cx + rx + 1.0)):
				var d: float = sqrt(pow((float(x) - cx) / rx, 2.0) + pow((float(y) - cy) / ry, 2.0))
				if d < 1.0:
					var col: Color = C_STONE_MID
					if (float(x) - cx) + (float(y) - cy) < -1.5:
						col = C_STONE_LIGHT
					elif (float(x) - cx) + (float(y) - cy) > 2.0:
						col = C_STONE_DARK
					img.set_pixel(x, y, col)
	return img

func _make_deco_wildflowers() -> Image:
	var img: Image = _create_image(true)
	var colors: Array[Color] = [
		Color("e74c3c"), # Poppy
		Color("f1c40f"), # Buttercup
		Color("3498db"), # Bluebell
		Color("9b59b6"), # Violet
		Color("ffffff"), # Daisy
	]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 44433

	for _i: int in range(8):
		var fx: int = rng.randi_range(3, 27)
		var fy: int = rng.randi_range(4, 27)
		var c: Color = colors[rng.randi() % colors.size()]

		img.set_pixel(fx, fy + 1, C_G_DEEP) # Stem
		img.set_pixel(fx, fy, c)
		img.set_pixel(fx - 1, fy, c.lightened(0.2))
		img.set_pixel(fx + 1, fy, c.lightened(0.2))
		img.set_pixel(fx, fy - 1, c.lightened(0.3))
		if c != Color("f1c40f"):
			img.set_pixel(fx, fy, Color("f39c12"))
	return img

func _make_deco_tall_grass() -> Image:
	var img: Image = _create_image(true)
	var stalks: Array[int] = [6, 11, 16, 22, 27]

	for sx: int in stalks:
		var n: float = _torus_noise(sx, 0, 99)
		var sway: int = int((n - 0.5) * 5.0)
		var height: int = 8 + int(n * 8.0)

		for dy: int in range(height):
			var py: int = 31 - dy
			var curve: float = float(dy) / float(height)
			var px: int = sx + int(float(sway) * curve * curve)
			px = clampi(px, 0, 31)
			py = clampi(py, 0, 31)
			var col: Color = C_G_DARK.lerp(C_G_BRIGHT, curve)
			img.set_pixel(px, py, col)
	return img

# ── TileSet Resource Assembly ────────────────────────────────────────────────

func _build_tileset() -> void:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "terrain_type")
	ts.set_custom_data_layer_type(0, TYPE_STRING)

	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(1, "elevation")
	ts.set_custom_data_layer_type(1, TYPE_INT)

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
