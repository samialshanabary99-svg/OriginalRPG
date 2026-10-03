class_name TestWorld3D
extends Node3D

## Hybrid 3D Game World for OriginalRPG (Ragnarok Online / Octopath Style).
##
## Features:
##   - Procedural 3D multi-tier rolling terrain with true elevation (Tier 0, 1, 2)
##   - Vertex-colored terrain: lush meadows on flats, warm earth/rock on slopes
##   - Accurate 3D trimesh collision for smooth CharacterBody3D navigation
##   - Directional sunlight with real-time shadow casting
##   - 2.5D Animated billboard player and props
##   - Seamless 2D HUD (Basic Info Window, status bars) on CanvasLayer

@onready var player: Player3D = $Player3D if has_node("Player3D") else null
@onready var hud: HUD = $HUD if has_node("HUD") else null
@onready var terrain_mesh_instance: MeshInstance3D = $Terrain/TerrainMesh if has_node("Terrain/TerrainMesh") else null
@onready var terrain_collision: CollisionShape3D = $Terrain/StaticBody3D/CollisionShape3D if has_node("Terrain/StaticBody3D/CollisionShape3D") else null

# Terrain configuration
const GRID_SIZE: int = 50       # 50x50 quad grid
const CELL_SIZE: float = 1.0     # 1 meter per cell -> 50m x 50m world
const HALF_SIZE: float = float(GRID_SIZE) * CELL_SIZE * 0.5

func _enter_tree() -> void:
	_resolve_nodes()

func _ready() -> void:
	_resolve_nodes()
	_generate_terrain()
	_spawn_field_decorations()

	if hud != null and player != null:
		hud.bind_player(player)
		if not hud.return_to_menu_requested.is_connected(_on_return_to_menu):
			hud.return_to_menu_requested.connect(_on_return_to_menu)

func _resolve_nodes() -> void:
	if player == null: player = get_node_or_null("Player3D") as Player3D
	if hud == null: hud = get_node_or_null("HUD") as HUD
	if terrain_mesh_instance == null: terrain_mesh_instance = get_node_or_null("Terrain/TerrainMesh") as MeshInstance3D
	if terrain_collision == null: terrain_collision = get_node_or_null("Terrain/StaticBody3D/CollisionShape3D") as CollisionShape3D

func _generate_terrain() -> void:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. Generate height and vertex data
	for z_idx: int in range(GRID_SIZE):
		for x_idx: int in range(GRID_SIZE):
			var x0: float = float(x_idx) * CELL_SIZE - HALF_SIZE
			var x1: float = float(x_idx + 1) * CELL_SIZE - HALF_SIZE
			var z0: float = float(z_idx) * CELL_SIZE - HALF_SIZE
			var z1: float = float(z_idx + 1) * CELL_SIZE - HALF_SIZE

			var y00: float = _calculate_height(x0, z0)
			var y10: float = _calculate_height(x1, z0)
			var y01: float = _calculate_height(x0, z1)
			var y11: float = _calculate_height(x1, z1)

			var v00: Vector3 = Vector3(x0, y00, z0)
			var v10: Vector3 = Vector3(x1, y10, z0)
			var v01: Vector3 = Vector3(x0, y01, z1)
			var v11: Vector3 = Vector3(x1, y11, z1)

			# Triangle 1: (v00, v10, v01) in CCW order (Normal points UP)
			_add_terrain_vertex(surface_tool, v00)
			_add_terrain_vertex(surface_tool, v10)
			_add_terrain_vertex(surface_tool, v01)

			# Triangle 2: (v10, v11, v01) in CCW order (Normal points UP)
			_add_terrain_vertex(surface_tool, v10)
			_add_terrain_vertex(surface_tool, v11)
			_add_terrain_vertex(surface_tool, v01)

	# 2. Generate vertical perimeter skirts (cliff walls) dropping down to Y = -6.0m
	var bottom_y: float = -6.0
	var norm_north: Vector3 = Vector3(0.0, 0.0, -1.0)
	var norm_south: Vector3 = Vector3(0.0, 0.0, 1.0)
	var norm_west: Vector3 = Vector3(-1.0, 0.0, 0.0)
	var norm_east: Vector3 = Vector3(1.0, 0.0, 0.0)

	for i: int in range(GRID_SIZE):
		var c0: float = float(i) * CELL_SIZE - HALF_SIZE
		var c1: float = float(i + 1) * CELL_SIZE - HALF_SIZE

		# North boundary (Z = -HALF_SIZE)
		var ny0: float = _calculate_height(c0, -HALF_SIZE)
		var ny1: float = _calculate_height(c1, -HALF_SIZE)
		_add_skirt_quad(surface_tool,
			Vector3(c1, ny1, -HALF_SIZE), Vector3(c0, ny0, -HALF_SIZE),
			Vector3(c1, bottom_y, -HALF_SIZE), Vector3(c0, bottom_y, -HALF_SIZE),
			norm_north)

		# South boundary (Z = +HALF_SIZE)
		var sy0: float = _calculate_height(c0, HALF_SIZE)
		var sy1: float = _calculate_height(c1, HALF_SIZE)
		_add_skirt_quad(surface_tool,
			Vector3(c0, sy0, HALF_SIZE), Vector3(c1, sy1, HALF_SIZE),
			Vector3(c0, bottom_y, HALF_SIZE), Vector3(c1, bottom_y, HALF_SIZE),
			norm_south)

		# West boundary (X = -HALF_SIZE)
		var wy0: float = _calculate_height(-HALF_SIZE, c0)
		var wy1: float = _calculate_height(-HALF_SIZE, c1)
		_add_skirt_quad(surface_tool,
			Vector3(-HALF_SIZE, wy0, c0), Vector3(-HALF_SIZE, wy1, c1),
			Vector3(-HALF_SIZE, bottom_y, c0), Vector3(-HALF_SIZE, bottom_y, c1),
			norm_west)

		# East boundary (X = +HALF_SIZE)
		var ey0: float = _calculate_height(HALF_SIZE, c0)
		var ey1: float = _calculate_height(HALF_SIZE, c1)
		_add_skirt_quad(surface_tool,
			Vector3(HALF_SIZE, ey1, c1), Vector3(HALF_SIZE, ey0, c0),
			Vector3(HALF_SIZE, bottom_y, c1), Vector3(HALF_SIZE, bottom_y, c0),
			norm_east)

	surface_tool.index()
	var mesh: ArrayMesh = surface_tool.commit()

	# Create terrain material with triplanar pixel-art projection and anisotropic mipmapping
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var grass_tex: Texture2D = load("res://assets/tiles/ground/tile_grass_base.png")
	if grass_tex != null:
		mat.albedo_texture = grass_tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	# Triplanar mapping projects seamlessly on both flats and vertical slopes without stretching/squishing
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 4.0
	mat.uv1_scale = Vector3(0.5, 0.5, 0.5)

	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.88
	mat.metallic_specular = 0.05
	mesh.surface_set_material(0, mat)

	if terrain_mesh_instance != null:
		terrain_mesh_instance.mesh = mesh

	# Create 3D trimesh collision shape
	if terrain_collision != null:
		var trimesh_shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
		if trimesh_shape != null:
			trimesh_shape.backface_collision = true
			terrain_collision.shape = trimesh_shape

## Multi-tier height function creating authentic rolling hills, plateaus, and slopes
func _calculate_height(x: float, z: float) -> float:
	# Base rolling meadow waves (Tier 0: ~0.0m to 0.25m)
	var h: float = (sin(x * 0.12) * 0.12 + cos(z * 0.12) * 0.12)

	# Tier 1 Plateau (Northeast Hill: x in [3..19], z in [-19..-3])
	# Plateau rises to +2.2m with a smooth walkable ramp on the South face
	var plateau_center: Vector2 = Vector2(11.0, -11.0)
	var p_dist: float = sqrt(pow((x - plateau_center.x) / 8.5, 2.0) + pow((z - plateau_center.y) / 7.0, 2.0))
	if p_dist < 1.0:
		var ramp_influence: float = 0.0
		# South ramp pathway at x ≈ 11, z from -6 to -3
		if abs(x - 11.0) < 2.4 and z > -7.5:
			ramp_influence = clampf((z + 7.5) / 4.0, 0.0, 1.0)

		# Smooth, natural stepped slope with flat plateau top and soft foothill blend
		var t: float = 1.0 - smoothstep(0.42, 1.0, p_dist)
		var hill_lift: float = t * 2.2
		h += lerpf(hill_lift, hill_lift * 0.35, ramp_influence)

	# Tier 2 Lookout Ridge (Northwest Elevation: x in [-19..-5], z in [-21..-9])
	var ridge_dist: float = sqrt(pow((x + 12.0) / 7.5, 2.0) + pow((z + 14.0) / 6.0, 2.0))
	if ridge_dist < 1.0:
		var t2: float = 1.0 - smoothstep(0.42, 1.0, ridge_dist)
		h += t2 * 3.6

	# Boundaries: gentle rolling perimeter foothills that cradle the world
	var edge_dist: float = max(abs(x), abs(z)) / HALF_SIZE
	if edge_dist > 0.76:
		h += pow((edge_dist - 0.76) / 0.24, 2.0) * 4.2

	return h

func _add_skirt_quad(st: SurfaceTool, top_left: Vector3, top_right: Vector3, bot_left: Vector3, bot_right: Vector3, norm: Vector3) -> void:
	# Triangle 1 (top_right, top_left, bot_right) in CCW order
	_add_skirt_vertex(st, top_right, norm)
	_add_skirt_vertex(st, top_left, norm)
	_add_skirt_vertex(st, bot_right, norm)

	# Triangle 2 (top_left, bot_left, bot_right) in CCW order
	_add_skirt_vertex(st, top_left, norm)
	_add_skirt_vertex(st, bot_left, norm)
	_add_skirt_vertex(st, bot_right, norm)

func _add_skirt_vertex(st: SurfaceTool, pos: Vector3, norm: Vector3) -> void:
	var col: Color = Color(0.85, 0.76, 0.62) # Warm earthy cliff tone
	st.set_color(col)
	st.set_normal(norm)
	st.set_uv(Vector2(pos.x, pos.z))
	st.add_vertex(pos)

## Calculates smooth continuous analytical surface normal using finite differences
func _calculate_normal(x: float, z: float) -> Vector3:
	var eps: float = 0.08
	var h_left: float = _calculate_height(x - eps, z)
	var h_right: float = _calculate_height(x + eps, z)
	var h_down: float = _calculate_height(x, z - eps)
	var h_up: float = _calculate_height(x, z + eps)
	var tangent_x: Vector3 = Vector3(2.0 * eps, h_right - h_left, 0.0)
	var tangent_z: Vector3 = Vector3(0.0, h_up - h_down, 2.0 * eps)
	return tangent_z.cross(tangent_x).normalized()

func _add_terrain_vertex(st: SurfaceTool, pos: Vector3) -> void:
	var norm: Vector3 = _calculate_normal(pos.x, pos.z)
	var slope: float = clampf(norm.y, 0.0, 1.0)
	var col: Color

	if slope > 0.82:
		# Flat surfaces & gentle rolling meadows
		if pos.y > 1.8:
			col = Color(1.04, 1.03, 0.96) # Sunlit plateau meadow
		else:
			col = Color(1.0, 1.0, 1.0)    # Vibrant lush green meadow
	elif slope > 0.65:
		# Grassy slope transition into warm sun-baked soil
		var t: float = (0.82 - slope) / 0.17
		col = Color(1.0, 1.0, 1.0).lerp(Color(0.94, 0.89, 0.78), t)
	else:
		# Warm earthy cliff face (golden sandstone / rocky soil)
		var cliff_t: float = clampf((0.65 - slope) / 0.35, 0.0, 1.0)
		col = Color(0.94, 0.89, 0.78).lerp(Color(0.86, 0.76, 0.62), cliff_t)

	st.set_color(col)
	st.set_normal(norm)
	st.set_uv(Vector2(pos.x, pos.z))
	st.add_vertex(pos)

## Spawns authentic Ragnarok Online style 2.5D billboard vegetation and props
func _spawn_field_decorations() -> void:
	var props_node: Node3D = Node3D.new()
	props_node.name = "Props"
	add_child(props_node)

	# 1. Authentic animated green bushes (Ragnarok Online style) along hill bases and meadow contours
	var bush_coords: Array[Vector2] = [
		Vector2(3.5, -8.0), Vector2(18.0, -11.0), Vector2(10.0, -17.5),
		Vector2(-5.0, -12.5), Vector2(-18.0, -13.0), Vector2(-11.0, -20.0),
		Vector2(-4.0, 4.0), Vector2(8.0, 5.0), Vector2(-12.0, 10.0), Vector2(14.0, 9.0),
		Vector2(1.0, -9.0), Vector2(-8.0, 3.0), Vector2(12.0, 3.0)
	]
	var bush_frames: SpriteFrames = load("res://assets/sprites/environment/bush/bush_sprite_frames.tres") as SpriteFrames
	var bush_tex_fallback: Texture2D = load("res://assets/sprites/environment/bush/rotations/south.png") as Texture2D
	for coord: Vector2 in bush_coords:
		_create_animated_bush_prop(props_node, bush_frames, bush_tex_fallback, coord, 0.009)

	# 2. Wildflowers scattered across meadows and plateau surfaces (flat decals hugging terrain)
	var flower_tex: Texture2D = load("res://assets/tiles/ground/tile_deco_wildflowers.png")
	var flower_coords: Array[Vector2] = [
		Vector2(2.0, -2.0), Vector2(-3.0, -3.5), Vector2(5.0, -4.0),
		Vector2(11.0, -11.0), Vector2(13.0, -9.5), Vector2(9.5, -12.5),
		Vector2(-2.0, 3.0), Vector2(3.5, 4.5), Vector2(-5.0, 6.0),
		Vector2(-10.0, -12.5), Vector2(-9.0, -15.0),
		Vector2(6.5, -10.0), Vector2(-1.0, -6.0), Vector2(4.0, 2.0),
		Vector2(1.5, -1.0), Vector2(-4.0, 1.0)
	]
	for coord: Vector2 in flower_coords:
		_create_flat_prop(props_node, flower_tex, coord, 0.035)

	# 3. Tall grass tufts (upright billboards)
	var grass_tex: Texture2D = load("res://assets/tiles/ground/tile_deco_tall_grass.png")
	var grass_coords: Array[Vector2] = [
		Vector2(-1.5, -1.0), Vector2(3.0, 1.5), Vector2(-4.5, 2.0),
		Vector2(7.0, -7.0), Vector2(-8.0, -8.0), Vector2(15.0, -6.0),
		Vector2(6.0, 8.0), Vector2(-7.0, 12.0), Vector2(-2.5, -8.0),
		Vector2(11.0, -14.0), Vector2(-9.0, -15.0)
	]
	for coord: Vector2 in grass_coords:
		_create_billboard_prop(props_node, grass_tex, coord, 0.030)

	# 4. Stepping stones along the path leading towards the plateau ramp (flat decals hugging terrain)
	var stone_tex: Texture2D = load("res://assets/tiles/ground/tile_deco_stepping_stones.png")
	var stone_coords: Array[Vector2] = [
		Vector2(2.0, -1.0), Vector2(4.5, -2.0), Vector2(7.0, -3.0),
		Vector2(9.0, -4.0), Vector2(10.5, -5.5)
	]
	for coord: Vector2 in stone_coords:
		_create_flat_prop(props_node, stone_tex, coord, 0.032)

	# 5. Authentic animated forest trees (Ragnarok Online style) across meadows, hilltops, and horizons
	var tree_coords: Array[Vector2] = [
		Vector2(-6.0, 7.0), Vector2(6.0, 9.0), Vector2(-14.0, 5.0),
		Vector2(16.0, -4.0), Vector2(-8.0, -6.0), Vector2(6.5, -1.5),
		Vector2(15.0, -15.0), Vector2(6.0, -16.0), Vector2(-16.0, -10.0),
		Vector2(-5.0, -16.0), Vector2(-12.0, 14.0), Vector2(14.0, 12.0)
	]
	var tree_frames: SpriteFrames = load("res://assets/sprites/environment/tree/tree_sprite_frames.tres") as SpriteFrames
	var tree_tex_fallback: Texture2D = load("res://assets/sprites/environment/tree/rotations/normal_tree.png") as Texture2D
	for coord: Vector2 in tree_coords:
		_create_animated_tree_prop(props_node, tree_frames, tree_tex_fallback, coord, 0.015)


func _create_animated_bush_prop(parent: Node3D, frames: SpriteFrames, fallback_tex: Texture2D, pos2d: Vector2, pixel_scale: float) -> void:
	var y: float = _calculate_height(pos2d.x, pos2d.y)
	# The bush frame is 170x170 with center at y=85. Bottom-most foliage pixel is at y=130 (+45 px below center).
	# Anchoring at y + 45.0 * pixel_scale touches the base of the bush foliage directly to the terrain surface.
	var anchor_y: float = y + 45.0 * pixel_scale
	if frames != null and frames.has_animation("default"):
		var anim_sprite: AnimatedSprite3D = AnimatedSprite3D.new()
		anim_sprite.sprite_frames = frames
		anim_sprite.animation = "default"
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
		anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_sprite.pixel_size = pixel_scale
		anim_sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		anim_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(anim_sprite)
		anim_sprite.play("default")
		var fc: int = frames.get_frame_count("default")
		if fc > 0:
			anim_sprite.frame = randi() % fc
	elif fallback_tex != null:
		var sprite: Sprite3D = Sprite3D.new()
		sprite.texture = fallback_tex
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = pixel_scale
		sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(sprite)

func _create_animated_tree_prop(parent: Node3D, frames: SpriteFrames, fallback_tex: Texture2D, pos2d: Vector2, pixel_scale: float) -> void:
	var y: float = _calculate_height(pos2d.x, pos2d.y)
	# The tree frame is 256x256 with center at y=128. Bottom-most trunk pixel is at y=248 (+120 px below center).
	# Anchoring at y + 118.0 * pixel_scale embeds root base slightly into the ground surface.
	var anchor_y: float = y + 118.0 * pixel_scale
	if frames != null and frames.has_animation("default"):
		var anim_sprite: AnimatedSprite3D = AnimatedSprite3D.new()
		anim_sprite.sprite_frames = frames
		anim_sprite.animation = "default"
		anim_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		anim_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
		anim_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_sprite.pixel_size = pixel_scale
		anim_sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		anim_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(anim_sprite)
		anim_sprite.play("default")
		var fc: int = frames.get_frame_count("default")
		if fc > 0:
			anim_sprite.frame = randi() % fc
	elif fallback_tex != null:
		var sprite: Sprite3D = Sprite3D.new()
		sprite.texture = fallback_tex
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = pixel_scale
		sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(sprite)

func _create_billboard_prop(parent: Node3D, tex: Texture2D, pos2d: Vector2, pixel_scale: float) -> void:
	if tex == null:
		return
	var y: float = _calculate_height(pos2d.x, pos2d.y)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = pixel_scale
	var sprite_height: float = float(tex.get_height()) * pixel_scale
	sprite.position = Vector3(pos2d.x, y + sprite_height * 0.5, pos2d.y)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sprite)

func _create_flat_prop(parent: Node3D, tex: Texture2D, pos2d: Vector2, pixel_scale: float) -> void:
	if tex == null:
		return
	var y: float = _calculate_height(pos2d.x, pos2d.y)
	var norm: Vector3 = _calculate_normal(pos2d.x, pos2d.y)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = tex
	sprite.axis = Vector3.AXIS_Y
	sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = pixel_scale
	sprite.position = Vector3(pos2d.x, y + 0.025, pos2d.y)

	# Align sprite normal with the terrain slope normal so it hugs the ground
	if not norm.is_equal_approx(Vector3.UP):
		var rot_axis: Vector3 = Vector3.UP.cross(norm).normalized()
		var rot_angle: float = Vector3.UP.angle_to(norm)
		if rot_axis.length_squared() > 0.001:
			sprite.transform.basis = Basis(rot_axis, rot_angle)

	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sprite)

func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
