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

			# Triangle 1: (v00, v01, v10) in counter-clockwise order
			var n1: Vector3 = (v01 - v00).cross(v10 - v00).normalized()
			_add_terrain_vertex(surface_tool, v00, n1)
			_add_terrain_vertex(surface_tool, v01, n1)
			_add_terrain_vertex(surface_tool, v10, n1)

			# Triangle 2: (v01, v11, v10) in counter-clockwise order
			var n2: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			_add_terrain_vertex(surface_tool, v01, n2)
			_add_terrain_vertex(surface_tool, v11, n2)
			_add_terrain_vertex(surface_tool, v10, n2)

	surface_tool.generate_normals()
	var mesh: ArrayMesh = surface_tool.commit()

	# Create terrain material with vertex color support and pixel art grass texture
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var grass_tex: Texture2D = load("res://assets/tiles/ground/tile_grass_base.png")
	if grass_tex != null:
		mat.albedo_texture = grass_tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.metallic_specular = 0.1
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
	# Base rolling meadow waves (Tier 0: ~0.0m to 0.4m)
	var h: float = sin(x * 0.14) * cos(z * 0.14) * 0.35

	# Tier 1 Plateau (Northeast Hill: x in [4..18], z in [-18..-4])
	# Plateau rises to +2.2m with a smooth walkable ramp on the South face (x ≈ 10..12, z ≈ -4)
	var plateau_center: Vector2 = Vector2(11.0, -11.0)
	var p_dist: float = sqrt(pow((x - plateau_center.x) / 7.5, 2.0) + pow((z - plateau_center.y) / 6.0, 2.0))
	if p_dist < 1.0:
		var ramp_influence: float = 0.0
		# South ramp pathway at x ≈ 11, z from -6 to -3
		if abs(x - 11.0) < 2.0 and z > -7.0:
			ramp_influence = clampf((z + 7.0) / 3.5, 0.0, 1.0) # Smooth grade down to valley

		var hill_lift: float = (1.0 - smoothstep(0.65, 1.0, p_dist)) * 2.2
		h += lerpf(hill_lift, hill_lift * 0.3, ramp_influence)

	# Tier 2 Lookout Ridge (Northwest Elevation: x in [-18..-6], z in [-20..-10])
	var ridge_dist: float = sqrt(pow((x + 12.0) / 6.0, 2.0) + pow((z + 14.0) / 4.5, 2.0))
	if ridge_dist < 1.0:
		h += (1.0 - smoothstep(0.55, 1.0, ridge_dist)) * 3.8

	# Boundaries: gentle rising ridges at world edges
	var edge_dist: float = max(abs(x), abs(z)) / HALF_SIZE
	if edge_dist > 0.82:
		h += pow((edge_dist - 0.82) / 0.18, 2.0) * 4.0

	return h

func _add_terrain_vertex(st: SurfaceTool, pos: Vector3, normal: Vector3) -> void:
	# Color based on height and slope angle (normal.y):
	# Flat surfaces (normal.y > 0.88): Natural grass meadow & sunlit plateau
	# Slopes (0.72 < normal.y <= 0.88): Smooth blend from grass to warm earth
	# Cliffs (normal.y <= 0.72): Rich earth / rock cliff face
	var slope: float = clampf(normal.y, 0.0, 1.0)
	var col: Color

	if slope > 0.88:
		# Flat surfaces
		if pos.y > 1.5:
			col = Color(1.08, 1.06, 0.96) # Sunlit plateau golden highlight
		else:
			col = Color(1.0, 1.0, 1.0)    # Valley meadow natural vibrant pixel grass
	elif slope > 0.72:
		# Grassy slope transition into warm earth
		var t: float = (0.88 - slope) / 0.16
		col = Color(1.0, 1.0, 1.0).lerp(Color("8a6848"), t)
	else:
		# Earth / rock cliff face
		col = Color("684b34")

	st.set_color(col)
	st.set_normal(normal)
	st.set_uv(Vector2(pos.x, pos.z))
	st.add_vertex(pos)

func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
