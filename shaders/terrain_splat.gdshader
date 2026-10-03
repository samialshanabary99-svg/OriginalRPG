shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
// Multi-material terrain splat shader for OriginalRPG (Ragnarok Online / Octopath Style).
// Features:
//   - Seamless Triplanar projection for vertical rock cliffs (no texture stretching)
//   - Slope-based rock cliff generation on high elevations (height > cliff_min_height)
//   - Walkable ramp override (forces grass and central dirt footpath on hill access ramps)
//   - Organic dual-ground blending (lush green meadow grass + dry straw/tan earth in hollows)
//   - Footpath blending along stepping stones and trail corridors
//   - Ambient cavity & shadow shading

uniform sampler2D tex_grass : source_color, filter_nearest_mipmap;
uniform sampler2D tex_rock : source_color, filter_nearest_mipmap;
uniform sampler2D tex_dry_grass : source_color, filter_nearest_mipmap;
uniform sampler2D tex_dirt_path : source_color, filter_nearest_mipmap;

uniform float uv_scale_grass : hint_range(0.1, 4.0) = 0.65;
uniform float uv_scale_rock : hint_range(0.1, 4.0) = 0.45;
uniform float uv_scale_dry : hint_range(0.1, 4.0) = 0.65;
uniform float uv_scale_dirt : hint_range(0.1, 4.0) = 0.65;

uniform float cliff_slope_threshold : hint_range(0.3, 0.9) = 0.68;
uniform float cliff_min_height : hint_range(0.5, 3.0) = 1.35;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec4 v_vertex_color;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_vertex_color = COLOR;
}

void fragment() {
	// 1. Triplanar mapping weights for uniform, unstretched texturing on flats, slopes, and cliffs
	vec3 n_abs = abs(v_world_normal);
	vec3 tri_weights = pow(n_abs, vec3(4.0));
	float w_sum = tri_weights.x + tri_weights.y + tri_weights.z + 0.0001;
	tri_weights /= w_sum;

	// Triplanar rock cliff texture
	vec4 rock_x = texture(tex_rock, v_world_pos.zy * uv_scale_rock);
	vec4 rock_y = texture(tex_rock, v_world_pos.xz * uv_scale_rock);
	vec4 rock_z = texture(tex_rock, v_world_pos.xy * uv_scale_rock);
	vec4 col_rock = rock_x * tri_weights.x + rock_y * tri_weights.y + rock_z * tri_weights.z;

	// Triplanar painterly grass (prevents diagonal texture stretching on ramps and hill slopes)
	vec4 grass_x = texture(tex_grass, v_world_pos.zy * uv_scale_grass);
	vec4 grass_y = texture(tex_grass, v_world_pos.xz * uv_scale_grass);
	vec4 grass_z = texture(tex_grass, v_world_pos.xy * uv_scale_grass);
	vec4 col_grass = grass_x * tri_weights.x + grass_y * tri_weights.y + grass_z * tri_weights.z;

	// Triplanar dry meadow grass
	vec4 dry_x = texture(tex_dry_grass, v_world_pos.zy * uv_scale_dry);
	vec4 dry_y = texture(tex_dry_grass, v_world_pos.xz * uv_scale_dry);
	vec4 dry_z = texture(tex_dry_grass, v_world_pos.xy * uv_scale_dry);
	vec4 col_dry = dry_x * tri_weights.x + dry_y * tri_weights.y + dry_z * tri_weights.z;

	// Triplanar packed dirt footpath
	vec4 dirt_x = texture(tex_dirt_path, v_world_pos.zy * uv_scale_dirt);
	vec4 dirt_y = texture(tex_dirt_path, v_world_pos.xz * uv_scale_dirt);
	vec4 dirt_z = texture(tex_dirt_path, v_world_pos.xy * uv_scale_dirt);
	vec4 col_dirt = dirt_x * tri_weights.x + dirt_y * tri_weights.y + dirt_z * tri_weights.z;

	// 2. Slope & Cliff Determination
	float slope_y = clamp(v_world_normal.y, 0.0, 1.0);


	// Organic noise edge for cliff lip
	float edge_noise = sin(v_world_pos.x * 2.8 + v_world_pos.z * 1.9) * 0.04 + cos(v_world_pos.x * 5.7 - v_world_pos.z * 4.3) * 0.03;
	float threshold = cliff_slope_threshold + edge_noise;

	// Cliff steepness: 1.0 on steep walls, 0.0 on flat ground
	// No halfway height cutoff: rock extends from the top lip all the way down to the meadow floor!
	float cliff_steepness = 1.0 - smoothstep(threshold - 0.10, threshold + 0.04, slope_y);

	// Ramp & Path masks from vertex colors:
	// COLOR.g >= 0.7: Walkable ramp (suppresses rock, forces grass)
	// COLOR.g between 0.2 and 0.6: Trail / footpath corridor
	float is_ramp = step(0.65, v_vertex_color.g);
	float is_path = smoothstep(0.20, 0.55, v_vertex_color.g) * (1.0 - is_ramp);

	float rock_factor = cliff_steepness * (1.0 - is_ramp);

	// 4. Ground Multi-Material Blending
	// Dry grass in hollows and subtle sun-baked patches
	float dry_weight = clamp(v_vertex_color.r, 0.0, 1.0);
	float dry_noise = sin(v_world_pos.x * 2.2 + v_world_pos.z * 1.7) * 0.08 + cos(v_world_pos.z * 3.8) * 0.05;
	float dry_factor = smoothstep(0.32, 0.62, dry_weight + dry_noise);

	// Base ground: lush green grass blended with dry straw/earth
	vec4 ground_col = mix(col_grass, col_dry, dry_factor);

	// Trail & Ramp center dirt path (v_vertex_color.a provides path center weight)
	float path_dirt = max(is_path * 0.75, is_ramp * v_vertex_color.a * 0.85);
	ground_col = mix(ground_col, col_dirt, path_dirt);

	// 5. Final Composite (Rock Cliff vs Ground)
	vec4 final_albedo = mix(ground_col, col_rock, rock_factor);

	// Cavity / Ambient Occlusion shading from v_vertex_color.b
	float ao = clamp(v_vertex_color.b, 0.45, 1.05);
	final_albedo.rgb *= ao;

	ALBEDO = final_albedo.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.01;
	METALLIC = 0.0;
}
