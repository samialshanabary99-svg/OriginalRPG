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

const DirectionalProp3D = preload("res://src/entities/directional_prop_3d.gd")

@onready var player: Player3D = $Player3D if has_node("Player3D") else null
@onready var hud: HUD = $HUD if has_node("HUD") else null
@onready var terrain_mesh_instance: MeshInstance3D = $Terrain/TerrainMesh if has_node("Terrain/TerrainMesh") else null
@onready var terrain_collision: CollisionShape3D = $Terrain/StaticBody3D/CollisionShape3D if has_node("Terrain/StaticBody3D/CollisionShape3D") else null

# Terrain configuration: 100x100 quad grid at 0.5m cell size -> 50m x 50m world
# Provides 4x vertex density to support crisp, vertical Ragnarok Online rock cliffs
const GRID_SIZE: int = 100
const CELL_SIZE: float = 0.5
const HALF_SIZE: float = float(GRID_SIZE) * CELL_SIZE * 0.5

# Cliff elevation threshold: only hills taller than this get vertical stone cliff walls
const CLIFF_MIN_ELEVATION: float = 1.8

func _enter_tree() -> void:
	_resolve_nodes()

func _ready() -> void:
	_resolve_nodes()
	_generate_terrain()
	_spawn_field_decorations()
	_spawn_monsters()

	if player != null:
		var init_y: float = _calculate_height(player.position.x, player.position.z)
		player.position.y = init_y

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

	# 1. Generate height and vertex data (100x100 grid)
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

	# Create terrain splat ShaderMaterial supporting triplanar rock cliffs and organic ground blending
	var shader: Shader = load("res://shaders/terrain_splat.gdshader") as Shader
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader

	var grass_tex: Texture2D = load("res://assets/environment/ground/ground_grass_painterly.png")
	if grass_tex == null:
		grass_tex = load("res://assets/tiles/ground/tile_grass_base.png")
	var rock_tex: Texture2D = load("res://assets/environment/ground/rock_cliff_stone.png")
	var dry_tex: Texture2D = load("res://assets/environment/ground/ground_dry_grass.png")
	var dirt_tex: Texture2D = load("res://assets/environment/ground/ground_dirt_path.png")

	mat.set_shader_parameter("tex_grass", grass_tex)
	mat.set_shader_parameter("tex_rock", rock_tex)
	mat.set_shader_parameter("tex_dry_grass", dry_tex)
	mat.set_shader_parameter("tex_dirt_path", dirt_tex)

	mat.set_shader_parameter("uv_scale_grass", 0.65)
	mat.set_shader_parameter("uv_scale_rock", 0.32)
	mat.set_shader_parameter("uv_scale_dry", 0.65)
	mat.set_shader_parameter("uv_scale_dirt", 0.65)
	mat.set_shader_parameter("cliff_slope_threshold", 0.70)

	mesh.surface_set_material(0, mat)

	if terrain_mesh_instance != null:
		terrain_mesh_instance.mesh = mesh

	# Create 3D trimesh collision shape
	if terrain_collision != null:
		var trimesh_shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
		if trimesh_shape != null:
			trimesh_shape.backface_collision = true
			terrain_collision.shape = trimesh_shape

	# Generate invisible physical barriers along cliff rims and ramp flanks to prevent falling
	_create_cliff_barriers()

## Multi-tier height function creating authentic Ragnarok Online style mesas, cliffs, ramps, and micro-relief
func _calculate_height(x: float, z: float) -> float:
	# 1. Base rolling meadow waves
	var h: float = sin(x * 0.12) * 0.08 + cos(z * 0.12) * 0.08

	# 2. Purposeful micro-relief (Reference 2: natural bowls, hollows, and grove mounds)
	# Hollow A: Shallow dry basin / bowl in the meadow clearing
	var d_bowl_a: float = (Vector2(x, z) - Vector2(4.0, 3.5)).length()
	if d_bowl_a < 4.0:
		h -= (1.0 - smoothstep(0.0, 4.0, d_bowl_a)) * 0.30

	# Hollow B: Gentle depression in the south-west meadow
	var d_bowl_b: float = (Vector2(x, z) - Vector2(-9.0, 2.5)).length()
	if d_bowl_b < 3.5:
		h -= (1.0 - smoothstep(0.0, 3.5, d_bowl_b)) * 0.20

	# Sunken footpath trough along stepping stones from spawn towards plateau ramp
	var p_spawn: Vector2 = Vector2(0.5, 0.0)
	var p_ramp_foot: Vector2 = Vector2(11.0, -2.6)
	var d_path_trough: float = _distance_to_segment_2d(Vector2(x, z), p_spawn, p_ramp_foot)
	if d_path_trough < 1.8:
		h -= (1.0 - smoothstep(0.0, 1.8, d_path_trough)) * 0.09

	# Grove rises: gentle natural earth mounds under tree clusters (+0.22m)
	var d_grove1: float = (Vector2(x, z) - Vector2(-6.0, 7.0)).length()
	if d_grove1 < 4.0:
		h += (1.0 - smoothstep(0.0, 4.0, d_grove1)) * 0.22
	var d_grove2: float = (Vector2(x, z) - Vector2(14.0, 10.0)).length()
	if d_grove2 < 4.0:
		h += (1.0 - smoothstep(0.0, 4.0, d_grove2)) * 0.22

	# 3. Tier 1 Plateau (Northeast Hill: center (11.0, -11.0), height +2.4m)
	# Mesa shape with vertical rock cliff walls on all sides except the southern ramp
	var p_center: Vector2 = Vector2(11.0, -11.0)
	var p_dx: float = x - p_center.x
	var p_dz: float = z - p_center.y
	var p_angle: float = atan2(p_dz, p_dx)
	var p_pert: float = 1.0 + 0.08 * sin(5.0 * p_angle) + 0.04 * cos(9.0 * p_angle + 0.6)
	var p_rx: float = 8.4 * p_pert
	var p_rz: float = 7.0 * p_pert
	var p_dist: float = sqrt(pow(p_dx / p_rx, 2.0) + pow(p_dz / p_rz, 2.0))

	var mesa1: float = 0.0
	if p_dist < 1.0:
		if p_dist <= 0.85:
			mesa1 = 2.4 # Flat plateau top
		else:
			mesa1 = (1.0 - smoothstep(0.85, 1.0, p_dist)) * 2.4 # Sharp vertical cliff band (~70°)

	# South walkable green ramp with central footpath (x ≈ 11.0, z from -2.6 to -9.5)
	# Continuous non-truncated ramp function: blends seamlessly from meadow floor into plateau top
	var ramp1_x_dist: float = abs(x - 11.0)
	var lift1: float = mesa1
	if ramp1_x_dist < 2.4 and z >= -9.5 and z <= -2.6:
		var ramp1_z_prog: float = clampf((-2.6 - z) / 6.6, 0.0, 1.0)
		var ramp1_h: float = ramp1_z_prog * 2.4
		var ramp1_x_factor: float = (1.0 - smoothstep(1.0, 2.4, ramp1_x_dist)) * smoothstep(0.0, 0.10, ramp1_z_prog)
		lift1 = lerpf(mesa1, ramp1_h, ramp1_x_factor)

	h += lift1

	# 4. Tier 2 Lookout Ridge (Northwest Hill: center (-12.0, -14.0), height +3.8m)
	# Dramatic high mesa with layered stone cliff walls and south-east ramp
	var r_center: Vector2 = Vector2(-12.0, -14.0)
	var r_dx: float = x - r_center.x
	var r_dz: float = z - r_center.y
	var r_angle: float = atan2(r_dz, r_dx)
	var r_pert: float = 1.0 + 0.07 * sin(6.0 * r_angle) + 0.04 * cos(8.0 * r_angle - 0.4)
	var r_rx: float = 7.8 * r_pert
	var r_rz: float = 6.4 * r_pert
	var r_dist: float = sqrt(pow(r_dx / r_rx, 2.0) + pow(r_dz / r_rz, 2.0))

	var mesa2: float = 0.0
	if r_dist < 1.0:
		if r_dist <= 0.85:
			mesa2 = 3.8 # Flat ridge top
		else:
			mesa2 = (1.0 - smoothstep(0.85, 1.0, r_dist)) * 3.8 # Steep vertical cliff wall

	# South-East walkable green ramp (from (-5.2, -8.0) to (-9.8, -12.6))
	# Continuous non-truncated ramp function: smooth silky grade from meadow (h=0) to ridge summit
	var r_ramp_a: Vector2 = Vector2(-5.2, -8.0)
	var r_ramp_b: Vector2 = Vector2(-9.8, -12.6)
	var r_d_seg: float = _distance_to_segment_2d(Vector2(x, z), r_ramp_a, r_ramp_b)
	var r_prog: float = _segment_progress_2d(Vector2(x, z), r_ramp_a, r_ramp_b)
	var lift2: float = mesa2
	if r_d_seg < 2.4 and r_prog >= 0.0 and r_prog <= 1.0:
		var r_ramp_h: float = r_prog * 3.8
		var r_ramp_factor: float = (1.0 - smoothstep(1.0, 2.4, r_d_seg)) * smoothstep(0.0, 0.10, r_prog)
		lift2 = lerpf(mesa2, r_ramp_h, r_ramp_factor)

	h += lift2

	# 5. Boundaries: gentle rolling perimeter foothills that cradle the world
	var edge_dist: float = max(abs(x), abs(z)) / HALF_SIZE
	if edge_dist > 0.76:
		h += pow((edge_dist - 0.76) / 0.24, 2.0) * 4.5

	return h

func _distance_to_segment_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq < 0.0001:
		return (p - a).length()
	var t: float = clampf((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var proj: Vector2 = a + ab * t
	return (p - proj).length()

func _segment_progress_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq < 0.0001:
		return 0.0
	return clampf((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)

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
	# Skirts are vertical boundary cliff walls: R=0 (no dry grass), G=0 (no ramp), B=0.85 (subtle shadow), A=0
	var col: Color = Color(0.0, 0.0, 0.85, 0.0)
	st.set_color(col)
	st.set_normal(norm)
	st.set_uv(Vector2(pos.x, pos.z))
	st.add_vertex(pos)

## Calculates continuous analytical surface normal using finite differences
func _calculate_normal(x: float, z: float) -> Vector3:
	var eps: float = 0.04
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

	# 1. Ramp & Path weight (COLOR.g) and Ramp center dirt path (COLOR.a)
	var ramp_weight: float = 0.0
	var path_dirt_weight: float = 0.0

	# Plateau south ramp (x ≈ 11.0, z from -2.6 to -9.5)
	var p_ramp_dx: float = abs(pos.x - 11.0)
	var is_p_ramp: bool = (p_ramp_dx < 2.2 and pos.z >= -9.5 and pos.z <= -2.6)
	if is_p_ramp:
		ramp_weight = 0.85
		# Footpath down the middle of the ramp
		path_dirt_weight = clampf(1.0 - p_ramp_dx / 0.8, 0.0, 1.0)

	# Ridge south-east ramp (from (-5.2, -8.0) to (-9.8, -12.6))
	var r_ramp_a: Vector2 = Vector2(-5.2, -8.0)
	var r_ramp_b: Vector2 = Vector2(-9.8, -12.6)
	var r_d_seg: float = _distance_to_segment_2d(Vector2(pos.x, pos.z), r_ramp_a, r_ramp_b)
	var r_prog: float = _segment_progress_2d(Vector2(pos.x, pos.z), r_ramp_a, r_ramp_b)
	var is_r_ramp: bool = (r_d_seg < 2.0 and r_prog >= 0.0 and r_prog <= 1.0)
	if is_r_ramp:
		ramp_weight = 0.85
		path_dirt_weight = clampf(1.0 - r_d_seg / 0.7, 0.0, 1.0)

	# Stepping stone trail from spawn to plateau ramp foot
	var p_spawn: Vector2 = Vector2(0.5, 0.0)
	var p_ramp_foot: Vector2 = Vector2(11.0, -2.6)
	var d_trail: float = _distance_to_segment_2d(Vector2(pos.x, pos.z), p_spawn, p_ramp_foot)
	if not is_p_ramp and not is_r_ramp and d_trail < 1.6:
		ramp_weight = 0.40 * (1.0 - d_trail / 1.6)
		path_dirt_weight = clampf(1.0 - d_trail / 0.9, 0.0, 1.0)

	# 2. Dry grass weight (COLOR.r) - subtle ~15% coverage in hollows, clearings, and plateau corner
	var dry_weight: float = 0.0

	# Hollow A basin
	var d_bowl_a: float = (Vector2(pos.x, pos.z) - Vector2(4.0, 3.5)).length()
	if d_bowl_a < 3.8:
		dry_weight = max(dry_weight, (1.0 - d_bowl_a / 3.8) * 0.92)

	# Hollow B depression
	var d_bowl_b: float = (Vector2(pos.x, pos.z) - Vector2(-9.0, 2.5)).length()
	if d_bowl_b < 3.2:
		dry_weight = max(dry_weight, (1.0 - d_bowl_b / 3.2) * 0.70)

	# Plateau back-corner dry patch (as seen in Reference 1 top-left)
	var d_plateau_dry: float = (Vector2(pos.x, pos.z) - Vector2(14.5, -13.5)).length()
	if d_plateau_dry < 3.0:
		dry_weight = max(dry_weight, (1.0 - d_plateau_dry / 3.0) * 0.80)

	# Path shoulder dry flecks
	if d_trail >= 0.8 and d_trail < 2.0:
		dry_weight = max(dry_weight, 0.35 * (1.0 - abs(d_trail - 1.4) / 0.6))

	# 3. Cavity AO / Shading (COLOR.b)
	var ao: float = 1.0
	# Shadow in hollow basins
	if d_bowl_a < 3.8:
		ao -= (1.0 - d_bowl_a / 3.8) * 0.12
	# Shadow at cliff foot where slope is steep and height is low
	if slope < 0.72 and pos.y < 1.5:
		ao = 0.75

	var col: Color = Color(dry_weight, ramp_weight, ao, path_dirt_weight)
	st.set_color(col)
	st.set_normal(norm)
	st.set_uv(Vector2(pos.x, pos.z))
	st.add_vertex(pos)

## Spawns fantasy monsters (e.g. Desert Wolf) across open meadow grounds
func _spawn_monsters() -> void:
	var monsters_node: Node3D = Node3D.new()
	monsters_node.name = "Monsters"
	add_child(monsters_node)

	var wolf_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn") as PackedScene
	if wolf_scene == null:
		return

	# Carefully placed on flat meadow areas (height ~ 0.0, slope normal.y >= 0.98)
	var spawn_coords: Array[Vector2] = [
		Vector2(-6.0, 3.5),
		Vector2(7.5, -3.0),
		Vector2(-3.0, 8.5)
	]

	for pos2d: Vector2 in spawn_coords:
		var wolf: CharacterBody3D = wolf_scene.instantiate() as CharacterBody3D
		var y: float = _calculate_height(pos2d.x, pos2d.y)
		var spawn_pos: Vector3 = Vector3(pos2d.x, y + 0.1, pos2d.y)
		wolf.position = spawn_pos
		if "spawn_position" in wolf:
			wolf.spawn_position = spawn_pos
		monsters_node.add_child(wolf)

## Spawns authentic Ragnarok Online style 2.5D billboard vegetation and props
func _spawn_field_decorations() -> void:
	var props_node: Node3D = Node3D.new()
	props_node.name = "Props"
	add_child(props_node)

	# Load ground blending decals (contact shadows and tree soil/root rings)
	var shadow_tex: Texture2D = load("res://assets/environment/shadows/shadow_oval_soft.png")
	var root_soil_tex: Texture2D = load("res://assets/environment/ground/ground_tree_roots_soil.png")

	# 1. Authentic animated green bushes (Ragnarok Online style) along meadow contours and hilltops
	var bush_coords: Array[Vector2] = [
		Vector2(2.0, -7.0), Vector2(14.5, -10.5), Vector2(1.5, -15.0),
		Vector2(-3.5, -10.5), Vector2(-14.5, -14.5), Vector2(-11.5, -12.5),
		Vector2(-4.0, 4.0), Vector2(8.0, 5.0), Vector2(-12.0, 10.0), Vector2(14.0, 9.0),
		Vector2(1.0, -9.0), Vector2(-8.0, 3.0), Vector2(12.0, 3.0)
	]
	var bush_frames: SpriteFrames = load("res://assets/sprites/environment/bush/bush_sprite_frames.tres") as SpriteFrames
	var bush_tex_fallback: Texture2D = load("res://assets/sprites/environment/bush/rotations/south.png") as Texture2D
	for coord: Vector2 in bush_coords:
		_create_animated_bush_prop(props_node, bush_frames, bush_tex_fallback, coord, 0.009, shadow_tex)

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
		_create_flat_prop(props_node, flower_tex, coord, 0.035, 0.025)

	# 3. Animated green stalks (Ragnarok Online style fluid swaying blades)
	var stalks_frames: SpriteFrames = load("res://green stalks/green_stalks_sprite_frames.tres") as SpriteFrames
	var grass_tex_fallback: Texture2D = load("res://assets/tiles/ground/tile_deco_tall_grass.png")
	var grass_coords: Array[Vector2] = [
		Vector2(-1.5, -1.0), Vector2(3.0, 1.5), Vector2(-4.5, 2.0),
		Vector2(5.0, -6.0), Vector2(-6.5, -6.5), Vector2(13.5, -8.0),
		Vector2(6.0, 8.0), Vector2(-7.0, 12.0), Vector2(-2.5, -8.0),
		Vector2(11.0, -14.0), Vector2(-9.0, -15.0),
		Vector2(1.0, 3.5), Vector2(-3.5, 4.0), Vector2(4.5, -2.5)
	]
	for coord: Vector2 in grass_coords:
		_create_animated_stalks_prop(props_node, stalks_frames, grass_tex_fallback, coord, 0.014)

	# 4. Stepping stones along the path leading towards the plateau ramp (flat decals hugging terrain)
	var stone_tex: Texture2D = load("res://assets/tiles/ground/tile_deco_stepping_stones.png")
	var stone_coords: Array[Vector2] = [
		Vector2(2.0, -0.6), Vector2(4.5, -1.1), Vector2(7.0, -1.6),
		Vector2(9.0, -2.1), Vector2(11.0, -2.6)
	]
	for coord: Vector2 in stone_coords:
		_create_flat_prop(props_node, stone_tex, coord, 0.032, 0.022)

	# 5. Authentic animated forest trees (Ragnarok Online style) across meadows, hilltops, and horizons
	var tree_coords: Array[Vector2] = [
		Vector2(-6.0, 7.0), Vector2(6.0, 9.0), Vector2(-14.0, 5.0),
		Vector2(16.0, -4.0), Vector2(-8.0, -6.0), Vector2(6.5, -1.5),
		Vector2(15.0, -15.0), Vector2(8.5, -11.5), Vector2(-13.0, -13.0),
		Vector2(-2.5, -15.5), Vector2(-12.0, 14.0), Vector2(14.0, 12.0)
	]
	var tree_frames: SpriteFrames = load("res://assets/sprites/environment/tree/tree_sprite_frames.tres") as SpriteFrames
	var tree_tex_fallback: Texture2D = load("res://assets/sprites/environment/tree/rotations/normal_tree.png") as Texture2D
	for coord: Vector2 in tree_coords:
		_create_animated_tree_prop(props_node, tree_frames, tree_tex_fallback, coord, 0.015, shadow_tex, root_soil_tex)


func _create_animated_bush_prop(parent: Node3D, frames: SpriteFrames, fallback_tex: Texture2D, pos2d: Vector2, pixel_scale: float, shadow_tex: Texture2D = null) -> void:
	# 1. Soft contact shadow decal hugging the terrain directly under the bush
	if shadow_tex != null:
		_create_flat_prop(parent, shadow_tex, pos2d, 0.016, 0.010, true)

	var y: float = _calculate_height(pos2d.x, pos2d.y)
	# The bush frame is 170x170 with center at y=85. Bottom-most foliage pixel is at y=130 (+45 px below center).
	# Anchoring at y + 45.0 * pixel_scale touches the base of the bush foliage directly to the terrain surface.
	var anchor_y: float = y + 45.0 * pixel_scale
	if frames != null and (frames.has_animation("default") or frames.has_animation("sway_south")):
		var anim_sprite: DirectionalProp3D = DirectionalProp3D.new()
		anim_sprite.sprite_frames = frames
		anim_sprite.anim_prefix = "sway"
		anim_sprite.world_facing_yaw = fmod(absf(pos2d.x * 17.13 + pos2d.y * 31.37), TAU)
		anim_sprite.pixel_size = pixel_scale
		anim_sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		parent.add_child(anim_sprite)
		var fc: int = frames.get_frame_count("sway_south") if frames.has_animation("sway_south") else frames.get_frame_count("default")
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

	# 2. Solid bush physical collision (CylinderShape3D preventing player overlap)
	var bush_body: StaticBody3D = StaticBody3D.new()
	bush_body.name = "BushCollision_%d_%d" % [int(pos2d.x * 10), int(pos2d.y * 10)]
	bush_body.collision_layer = 2
	bush_body.collision_mask = 0
	var bush_col: CollisionShape3D = CollisionShape3D.new()
	var bush_cyl: CylinderShape3D = CylinderShape3D.new()
	bush_cyl.radius = 0.40
	bush_cyl.height = 0.90
	bush_col.shape = bush_cyl
	bush_col.position = Vector3(pos2d.x, y + 0.45, pos2d.y)
	bush_body.add_child(bush_col)
	parent.add_child(bush_body)

func _create_animated_tree_prop(parent: Node3D, frames: SpriteFrames, fallback_tex: Texture2D, pos2d: Vector2, pixel_scale: float, shadow_tex: Texture2D = null, root_soil_tex: Texture2D = null) -> void:
	# 1. Warm earthy soil & root flare transition decal
	if root_soil_tex != null:
		_create_flat_prop(parent, root_soil_tex, pos2d, 0.036, 0.012, true)

	# 2. Deep soft canopy contact shadow decal
	if shadow_tex != null:
		_create_flat_prop(parent, shadow_tex, pos2d, 0.044, 0.016, true)

	var y: float = _calculate_height(pos2d.x, pos2d.y)
	# The tree frame is 256x256 with center at y=128. Bottom-most trunk pixel is at y=248 (+120 px below center).
	# Anchoring at y + 118.0 * pixel_scale embeds root base slightly into the ground surface.
	var anchor_y: float = y + 118.0 * pixel_scale
	if frames != null and (frames.has_animation("default") or frames.has_animation("sway_south")):
		var anim_sprite: DirectionalProp3D = DirectionalProp3D.new()
		anim_sprite.sprite_frames = frames
		anim_sprite.anim_prefix = "sway"
		anim_sprite.world_facing_yaw = fmod(absf(pos2d.x * 23.41 + pos2d.y * 19.87), TAU)
		anim_sprite.pixel_size = pixel_scale
		anim_sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		parent.add_child(anim_sprite)
		var fc: int = frames.get_frame_count("sway_south") if frames.has_animation("sway_south") else frames.get_frame_count("default")
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

	# 3. Solid tree trunk physical collision (CylinderShape3D preventing player overlap)
	var tree_body: StaticBody3D = StaticBody3D.new()
	tree_body.name = "TreeCollision_%d_%d" % [int(pos2d.x * 10), int(pos2d.y * 10)]
	tree_body.collision_layer = 2
	tree_body.collision_mask = 0
	var tree_col: CollisionShape3D = CollisionShape3D.new()
	var tree_cyl: CylinderShape3D = CylinderShape3D.new()
	tree_cyl.radius = 0.55
	tree_cyl.height = 2.40
	tree_col.shape = tree_cyl
	tree_col.position = Vector3(pos2d.x, y + 1.20, pos2d.y)
	tree_body.add_child(tree_col)
	parent.add_child(tree_body)

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

func _create_animated_stalks_prop(parent: Node3D, frames: SpriteFrames, fallback_tex: Texture2D, pos2d: Vector2, pixel_scale: float) -> void:
	var y: float = _calculate_height(pos2d.x, pos2d.y)
	# The stalks frame is 68x68 with center at y=34. The base of the stalks touches y=64 (+30 px below center).
	# Anchoring at y + 30.0 * pixel_scale touches stalks base directly to the terrain surface.
	var anchor_y: float = y + 30.0 * pixel_scale
	if frames != null and (frames.has_animation("default") or frames.has_animation("sway") or frames.has_animation("sway_south")):
		var anim_sprite: DirectionalProp3D = DirectionalProp3D.new()
		anim_sprite.sprite_frames = frames
		anim_sprite.anim_prefix = "sway"
		anim_sprite.world_facing_yaw = fmod(absf(pos2d.x * 11.19 + pos2d.y * 29.43), TAU)
		anim_sprite.pixel_size = pixel_scale
		anim_sprite.position = Vector3(pos2d.x, anchor_y, pos2d.y)
		parent.add_child(anim_sprite)
		var fc: int = frames.get_frame_count("sway_south") if frames.has_animation("sway_south") else frames.get_frame_count("default")
		if fc > 0:
			anim_sprite.frame = randi() % fc
	elif fallback_tex != null:
		var sprite: Sprite3D = Sprite3D.new()
		sprite.texture = fallback_tex
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = pixel_scale
		var sprite_height: float = float(fallback_tex.get_height()) * pixel_scale
		sprite.position = Vector3(pos2d.x, y + sprite_height * 0.5, pos2d.y)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(sprite)

func _create_flat_prop(parent: Node3D, tex: Texture2D, pos2d: Vector2, pixel_scale: float, height_offset: float = 0.025, use_alpha_blend: bool = false) -> void:
	if tex == null:
		return
	var y: float = _calculate_height(pos2d.x, pos2d.y)
	var norm: Vector3 = _calculate_normal(pos2d.x, pos2d.y)
	var sprite: Sprite3D = Sprite3D.new()
	sprite.texture = tex
	sprite.axis = Vector3.AXIS_Y
	if use_alpha_blend:
		sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = pixel_scale
	sprite.position = Vector3(pos2d.x, y + height_offset, pos2d.y)

	# Align sprite normal with the terrain slope normal so it hugs the ground
	if not norm.is_equal_approx(Vector3.UP):
		var rot_axis: Vector3 = Vector3.UP.cross(norm).normalized()
		var rot_angle: float = Vector3.UP.angle_to(norm)
		if rot_axis.length_squared() > 0.001:
			sprite.transform.basis = Basis(rot_axis, rot_angle)

	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sprite)

## Generates invisible vertical physical collision barriers along cliff rims and ramp flanks
func _create_cliff_barriers() -> void:
	var terrain_node: Node3D = get_node_or_null("Terrain")
	if terrain_node == null:
		terrain_node = self

	var barrier_body: StaticBody3D = StaticBody3D.new()
	barrier_body.name = "CliffBarriers"
	barrier_body.collision_layer = 2
	barrier_body.collision_mask = 0
	terrain_node.add_child(barrier_body)

	# 1. Tier 1 Plateau (Northeast Hill) Cliff Rim & Ramp Flank Barriers
	var p_center: Vector2 = Vector2(11.0, -11.0)
	var p_steps: int = 24
	var p_a_start: float = 0.64 * PI
	var p_a_end: float = 2.36 * PI
	var p_pts: Array[Vector2] = []
	for i: int in range(p_steps + 1):
		var t: float = float(i) / float(p_steps)
		var angle: float = lerpf(p_a_start, p_a_end, t)
		var pert: float = 1.0 + 0.08 * sin(5.0 * angle) + 0.04 * cos(9.0 * angle + 0.6)
		var rx: float = 8.4 * pert * 0.85
		var rz: float = 7.0 * pert * 0.85
		p_pts.append(p_center + Vector2(rx * cos(angle), rz * sin(angle)))

	for i: int in range(p_steps):
		_add_barrier_wall(barrier_body, p_pts[i], p_pts[i + 1], 2.1, 2.8)

	# Plateau ramp side flanks (corridor guides player safely up ramp without falling off sides)
	# West flank: from p_pts[0] down to (8.6, -2.6)
	var p_west_foot: Vector2 = Vector2(8.6, -2.6)
	var p_west_rim: Vector2 = p_pts[0]
	var p_flank_steps: int = 4
	for k: int in range(p_flank_steps):
		var pt_a: Vector2 = p_west_foot.lerp(p_west_rim, float(k) / float(p_flank_steps))
		var pt_b: Vector2 = p_west_foot.lerp(p_west_rim, float(k + 1) / float(p_flank_steps))
		var y_mid: float = (_calculate_height(pt_a.x, pt_a.y) + _calculate_height(pt_b.x, pt_b.y)) * 0.5
		_add_barrier_wall(barrier_body, pt_a, pt_b, y_mid - 0.2, 2.6)

	# East flank: from p_pts[p_steps] down to (13.4, -2.6)
	var p_east_foot: Vector2 = Vector2(13.4, -2.6)
	var p_east_rim: Vector2 = p_pts[p_steps]
	for k: int in range(p_flank_steps):
		var pt_a: Vector2 = p_east_foot.lerp(p_east_rim, float(k) / float(p_flank_steps))
		var pt_b: Vector2 = p_east_foot.lerp(p_east_rim, float(k + 1) / float(p_flank_steps))
		var y_mid: float = (_calculate_height(pt_a.x, pt_a.y) + _calculate_height(pt_b.x, pt_b.y)) * 0.5
		_add_barrier_wall(barrier_body, pt_a, pt_b, y_mid - 0.2, 2.6)

	# 2. Tier 2 Lookout Ridge (Northwest Hill) Cliff Rim & Ramp Flank Barriers
	var r_center: Vector2 = Vector2(-12.0, -14.0)
	var r_steps: int = 24
	var r_a_start: float = 1.05
	var r_a_end: float = 2.0 * PI + 0.12
	var r_pts: Array[Vector2] = []
	for i: int in range(r_steps + 1):
		var t: float = float(i) / float(r_steps)
		var angle: float = lerpf(r_a_start, r_a_end, t)
		var pert: float = 1.0 + 0.07 * sin(6.0 * angle) + 0.04 * cos(8.0 * angle - 0.4)
		var rx: float = 7.8 * pert * 0.85
		var rz: float = 6.4 * pert * 0.85
		r_pts.append(r_center + Vector2(rx * cos(angle), rz * sin(angle)))

	for i: int in range(r_steps):
		_add_barrier_wall(barrier_body, r_pts[i], r_pts[i + 1], 3.5, 3.0)

	# Lookout ridge ramp side flanks (from meadow ramp foot to summit gateway)
	var r_ramp_foot: Vector2 = Vector2(-5.2, -8.0)
	var r_perp: Vector2 = Vector2(-0.707, 0.707) * 1.8
	var r_flank1_foot: Vector2 = r_ramp_foot + r_perp
	var r_flank1_rim: Vector2 = r_pts[0]
	var r_flank2_foot: Vector2 = r_ramp_foot - r_perp
	var r_flank2_rim: Vector2 = r_pts[r_steps]
	var r_flank_steps: int = 4
	for k: int in range(r_flank_steps):
		var pt_a: Vector2 = r_flank1_foot.lerp(r_flank1_rim, float(k) / float(r_flank_steps))
		var pt_b: Vector2 = r_flank1_foot.lerp(r_flank1_rim, float(k + 1) / float(r_flank_steps))
		var y_mid: float = (_calculate_height(pt_a.x, pt_a.y) + _calculate_height(pt_b.x, pt_b.y)) * 0.5
		_add_barrier_wall(barrier_body, pt_a, pt_b, y_mid - 0.2, 2.6)

		var pt_c: Vector2 = r_flank2_foot.lerp(r_flank2_rim, float(k) / float(r_flank_steps))
		var pt_d: Vector2 = r_flank2_foot.lerp(r_flank2_rim, float(k + 1) / float(r_flank_steps))
		var y_mid2: float = (_calculate_height(pt_c.x, pt_c.y) + _calculate_height(pt_d.x, pt_d.y)) * 0.5
		_add_barrier_wall(barrier_body, pt_c, pt_d, y_mid2 - 0.2, 2.6)

func _add_barrier_wall(body: StaticBody3D, p1: Vector2, p2: Vector2, y_bottom: float, wall_height: float, thickness: float = 0.6) -> void:
	var seg: Vector2 = p2 - p1
	var seg_len: float = seg.length()
	if seg_len < 0.05:
		return
	var mid: Vector2 = (p1 + p2) * 0.5
	var angle: float = atan2(seg.y, seg.x)

	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(seg_len + 0.15, wall_height, thickness)
	col.shape = box
	col.position = Vector3(mid.x, y_bottom + wall_height * 0.5, mid.y)
	col.rotation.y = -angle
	body.add_child(col)

func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
