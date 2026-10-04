shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;

// Ratios (0.0 to 1.0)
uniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float sp_ratio : hint_range(0.0, 1.0) = 1.0;
uniform bool show_sp = false;

// Theme Colors
uniform vec4 bg_color : source_color = vec4(0.12, 0.12, 0.16, 0.88);
uniform vec4 border_color : source_color = vec4(0.03, 0.03, 0.05, 0.95);
uniform vec4 hp_color : source_color = vec4(0.22, 0.82, 0.35, 1.0);
uniform vec4 hp_low_color : source_color = vec4(0.92, 0.22, 0.22, 1.0);
uniform vec4 sp_color : source_color = vec4(0.18, 0.56, 0.96, 1.0);

void vertex() {
	// Full spherical billboard: quad always faces active camera orientation
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV;

	// Border margin: 0.03 on horizontal edges, 0.10/0.15 on vertical edges
	float bx = 0.03;
	float by = show_sp ? 0.10 : 0.15;
	if (uv.x < bx || uv.x > 1.0 - bx || uv.y < by || uv.y > 1.0 - by) {
		ALBEDO = border_color.rgb;
		ALPHA = border_color.a;
	} else if (!show_sp) {
		// ── Single Monster HP Bar ──────────────────────────────────────────────
		// Color transitions from healthy green to critical red when below 30%
		vec4 fill_col = mix(hp_low_color, hp_color, smoothstep(0.20, 0.55, hp_ratio));
		if (uv.x <= hp_ratio) {
			// Subtle gradient highlight on upper half of bar
			float highlight = (uv.y < 0.45) ? 0.12 : 0.0;
			ALBEDO = clamp(fill_col.rgb + highlight, 0.0, 1.0);
			ALPHA = fill_col.a;
		} else {
			ALBEDO = bg_color.rgb;
			ALPHA = bg_color.a;
		}
	} else {
		// ── Dual Player Character HP & SP Bar ──────────────────────────────────
		// Top ~52%: HP Bar (Green -> Red)
		// Middle 52% - 58%: Divider border line
		// Bottom ~42%: SP Bar (Mana Blue)
		if (uv.y < 0.52) {
			vec4 fill_col = mix(hp_low_color, hp_color, smoothstep(0.20, 0.55, hp_ratio));
			if (uv.x <= hp_ratio) {
				float highlight = (uv.y < 0.30) ? 0.12 : 0.0;
				ALBEDO = clamp(fill_col.rgb + highlight, 0.0, 1.0);
				ALPHA = fill_col.a;
			} else {
				ALBEDO = bg_color.rgb;
				ALPHA = bg_color.a;
			}
		} else if (uv.y > 0.58) {
			if (uv.x <= sp_ratio) {
				float highlight = (uv.y < 0.75) ? 0.12 : 0.0;
				ALBEDO = clamp(sp_color.rgb + highlight, 0.0, 1.0);
				ALPHA = sp_color.a;
			} else {
				ALBEDO = bg_color.rgb;
				ALPHA = bg_color.a;
			}
		} else {
			// Center horizontal divider
			ALBEDO = border_color.rgb;
			ALPHA = border_color.a;
		}
	}
}
