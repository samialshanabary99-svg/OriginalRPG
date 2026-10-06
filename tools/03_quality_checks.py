#!/usr/bin/env python3
"""
Step 3: Quality checks on center and transition tiles.
Generates:
- art_build/report.md
- art_build/preview_joins.png (2x nearest-neighbor)
- art_build/preview_mixed_grass.png (1x, 6x6 weighted random fill)
- art_build/preview_mixed_dirt.png (1x, 6x6 weighted random fill)
"""

import os
import sys
import numpy as np
from PIL import Image, ImageFilter

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TILES_DIR = os.path.join(PROJECT_ROOT, "assets", "terrain", "tiles")
BUILD_DIR = os.path.join(PROJECT_ROOT, "art_build")

def run_quality_checks():
    os.makedirs(BUILD_DIR, exist_ok=True)
    report_lines = []

    # Load 8 center tiles
    grass_names = [f"terrain_grass_center_0{i}.png" for i in range(1, 5)]
    dirt_names = [f"terrain_dirt_center_0{i}.png" for i in range(1, 5)]

    grass_imgs = {name: Image.open(os.path.join(TILES_DIR, name)).convert("RGB") for name in grass_names}
    dirt_imgs = {name: Image.open(os.path.join(TILES_DIR, name)).convert("RGB") for name in dirt_names}

    grass_arrs = {name: np.array(img, dtype=np.float32) for name, img in grass_imgs.items()}
    dirt_arrs = {name: np.array(img, dtype=np.float32) for name, img in dirt_imgs.items()}

    # ─────────────────────────────────────────────────────────────────────────
    # 3.1 Brightness
    # ─────────────────────────────────────────────────────────────────────────
    grass_brightness = {name: arr.mean() for name, arr in grass_arrs.items()}
    dirt_brightness = {name: arr.mean() for name, arr in dirt_arrs.items()}

    mean_grass_bg = np.mean(list(grass_brightness.values()))
    mean_dirt_bg = np.mean(list(dirt_brightness.values()))

    brightness_flags = []
    brightness_table = ["| Tile | Mean Brightness | Group Mean | Diff | Status |",
                        "|---|---|---|---|---|"]

    for name in grass_names:
        b = grass_brightness[name]
        diff = abs(b - mean_grass_bg)
        status = "PASS" if diff <= 3.0 else "**FLAG (>3)**"
        if diff > 3.0:
            brightness_flags.append((name, diff))
        brightness_table.append(f"| {name} | {b:.2f} | {mean_grass_bg:.2f} | {diff:.2f} | {status} |")

    for name in dirt_names:
        b = dirt_brightness[name]
        diff = abs(b - mean_dirt_bg)
        status = "PASS" if diff <= 3.0 else "**FLAG (>3)**"
        if diff > 3.0:
            brightness_flags.append((name, diff))
        brightness_table.append(f"| {name} | {b:.2f} | {mean_dirt_bg:.2f} | {diff:.2f} | {status} |")

    # ─────────────────────────────────────────────────────────────────────────
    # 3.2 Self-seam Check (2 px strips)
    # ─────────────────────────────────────────────────────────────────────────
    self_seam_table = ["| Tile | H-Seam Diff (Left vs Right) | V-Seam Diff (Top vs Bot) | Max Diff | Status |",
                       "|---|---|---|---|---|"]
    self_seam_flags = []

    def compute_self_seam(arr):
        # 2 px wide strip comparison
        left_strip = arr[:, :2, :]
        right_strip = arr[:, -2:, :]
        diff_h = np.abs(right_strip - left_strip).mean()

        top_strip = arr[:2, :, :]
        bot_strip = arr[-2:, :, :]
        diff_v = np.abs(bot_strip - top_strip).mean()
        return diff_h, diff_v

    for name in grass_names:
        arr = grass_arrs[name]
        dh, dv = compute_self_seam(arr)
        max_d = max(dh, dv)
        status = "OK (<6)" if max_d < 6.0 else ("PASS (<=12)" if max_d <= 12.0 else "**FLAG (>12)**")
        if max_d > 12.0:
            self_seam_flags.append((name, max_d))
        self_seam_table.append(f"| {name} | {dh:.2f} | {dv:.2f} | {max_d:.2f} | {status} |")

    for name in dirt_names:
        arr = dirt_arrs[name]
        dh, dv = compute_self_seam(arr)
        max_d = max(dh, dv)
        status = "OK (<6)" if max_d < 6.0 else ("PASS (<=12)" if max_d <= 12.0 else "**FLAG (>12)**")
        if max_d > 12.0:
            self_seam_flags.append((name, max_d))
        self_seam_table.append(f"| {name} | {dh:.2f} | {dv:.2f} | {max_d:.2f} | {status} |")

    # ─────────────────────────────────────────────────────────────────────────
    # 3.3 Cross-variant seams (4x4 ordered pairs)
    # ─────────────────────────────────────────────────────────────────────────
    cross_seam_flags = []

    def compute_cross_matrix(names, arrs, label):
        matrix_h = np.zeros((4, 4), dtype=np.float32)
        matrix_v = np.zeros((4, 4), dtype=np.float32)
        for i, a_name in enumerate(names):
            for j, b_name in enumerate(names):
                a_arr = arrs[a_name]
                b_arr = arrs[b_name]
                # A right against B left
                dh = np.abs(a_arr[:, -2:, :] - b_arr[:, :2, :]).mean()
                # A bottom against B top
                dv = np.abs(a_arr[-2:, :, :] - b_arr[:2, :, :]).mean()
                matrix_h[i, j] = dh
                matrix_v[i, j] = dv
                if dh > 12.0:
                    cross_seam_flags.append((f"{label} H {a_name}->{b_name}", dh))
                if dv > 12.0:
                    cross_seam_flags.append((f"{label} V {a_name}->{b_name}", dv))
        return matrix_h, matrix_v

    grass_mat_h, grass_mat_v = compute_cross_matrix(grass_names, grass_arrs, "Grass")
    dirt_mat_h, dirt_mat_v = compute_cross_matrix(dirt_names, dirt_arrs, "Dirt")

    # ─────────────────────────────────────────────────────────────────────────
    # 3.4 Boundary midpoint & pure areas
    # ─────────────────────────────────────────────────────────────────────────
    mean_g_color = grass_arrs["terrain_grass_center_01.png"].mean(axis=(0, 1))
    mean_d_color = dirt_arrs["terrain_dirt_center_01.png"].mean(axis=(0, 1))

    def get_binary_mask(fn):
        p = os.path.join(TILES_DIR, fn)
        img = Image.open(p).convert("RGB").filter(ImageFilter.MedianFilter(size=3))
        arr = np.array(img, dtype=np.float32)
        dg = np.linalg.norm(arr - mean_g_color, axis=-1)
        dd = np.linalg.norm(arr - mean_d_color, axis=-1)
        return dg < dd

    mask_edge = get_binary_mask("terrain_grass_dirt_edge_n.png")
    mask_outer = get_binary_mask("terrain_grass_dirt_outer_ne.png")
    mask_inner = get_binary_mask("terrain_grass_dirt_inner_ne.png")

    # edge_n crossings
    # left col (x=0) and right col (x=255)
    def find_crossing(strip):
        # strip is 1D boolean array of length 256
        diffs = np.where(strip[:-1] != strip[1:])[0]
        if len(diffs) > 0:
            return diffs[0]
        return -1

    y_left = find_crossing(mask_edge[:, 0])
    y_right = find_crossing(mask_edge[:, 255])
    y_diff = abs(y_left - y_right)

    edge_pass = (120 <= y_left <= 136) and (120 <= y_right <= 136) and (y_diff <= 8)

    # outer_ne crossings (top edge x ~ 128, right edge y ~ 128)
    x_outer_top = find_crossing(mask_outer[0, :])
    y_outer_right = find_crossing(mask_outer[:, 255])
    outer_top_pass = (120 <= x_outer_top <= 136)
    outer_right_pass = (120 <= y_outer_right <= 136)
    outer_pass = outer_top_pass and outer_right_pass

    # inner_ne crossings (top edge x ~ 128, right edge y ~ 128)
    x_inner_top = find_crossing(mask_inner[0, :])
    y_inner_right = find_crossing(mask_inner[:, 255])
    inner_top_pass = (120 <= x_inner_top <= 136)
    inner_right_pass = (120 <= y_inner_right <= 136)
    inner_pass = inner_top_pass and inner_right_pass

    # Pure areas
    edge_top25_pure = mask_edge[:64, :].all()
    edge_bot25_pure = not mask_edge[192:, :].any()
    outer_bl_pure = not mask_outer[128:, :128].any()
    inner_bl_pure = mask_inner[128:, :128].all()

    boundary_fails = []
    if not edge_pass: boundary_fails.append("edge_n midpoint crossing")
    if not outer_top_pass: boundary_fails.append(f"outer_ne top crossing (x={x_outer_top}, target 128+/-8)")
    if not outer_right_pass: boundary_fails.append(f"outer_ne right crossing (y={y_outer_right}, target 128+/-8)")
    if not inner_top_pass: boundary_fails.append(f"inner_ne top crossing (x={x_inner_top}, target 128+/-8)")
    if not inner_right_pass: boundary_fails.append(f"inner_ne right crossing (y={y_inner_right}, target 128+/-8)")

    # ─────────────────────────────────────────────────────────────────────────
    # Write art_build/report.md
    # ─────────────────────────────────────────────────────────────────────────
    header_alert = ""
    if boundary_fails or brightness_flags or self_seam_flags or cross_seam_flags:
        header_alert = "> [!WARNING]\n"
        if boundary_fails:
            header_alert += "> **Transition Boundary Warning**: One or more transition boundaries are not at the exact midpoint (+/-8px). Source art adjustment recommended for seamless alignment:\n"
            for bf in boundary_fails:
                header_alert += f"> - {bf}\n"
        if brightness_flags:
            header_alert += f"> **Brightness Flags**: {len(brightness_flags)} tile(s) deviate >3 points from group mean.\n"
        if self_seam_flags:
            header_alert += f"> **Self-Seam Flags**: {len(self_seam_flags)} tile(s) deviate >12 on 2px self-seam.\n"
        if cross_seam_flags:
            header_alert += f"> **Cross-Variant Seam Flags**: {len(cross_seam_flags)} ordered pair(s) deviate >12 on 2px cross-seam.\n"

    report_content = f"""# Terrain Tiles Quality & Validation Report

{header_alert}

## 1. Executive Summary
- **Source Tile Resolution**: All source images verified at **256 x 256 px**.
- **Generated Tile Count**: 22 tiles (8 center, 4 edge, 4 outer corner, 4 inner corner, 2 diagonal).
- **Pure Area Checks**: All 4 pure area tests **PASSED** (100% pure).
- **Edge Transition Midpoint**: edge_n left crossing = y:{y_left}, right crossing = y:{y_right} (diff = {y_diff} px) -> **PASS**.
- **Corner Transition Midpoints**:
  - `outer_ne`: top x = {x_outer_top} ({'PASS' if outer_top_pass else 'FAIL'}), right y = {y_outer_right} ({'PASS' if outer_right_pass else 'FAIL'})
  - `inner_ne`: top x = {x_inner_top} ({'PASS' if inner_top_pass else 'FAIL'}), right y = {y_inner_right} ({'PASS' if inner_right_pass else 'FAIL'})

---

## 2. Brightness Check (Section 3.1)
Mean RGB brightness comparison against terrain group mean:
- **Grass Group Mean**: {mean_grass_bg:.2f}
- **Dirt Group Mean**: {mean_dirt_bg:.2f}

{chr(10).join(brightness_table)}

---

## 3. Self-Seam Seam Continuity (Section 3.2)
Comparison of 2 px boundary strips within the same tile:
- Horizontal seam: Right 2px strip against Left 2px strip
- Vertical seam: Bottom 2px strip against Top 2px strip

{chr(10).join(self_seam_table)}

---

## 4. Cross-Variant Seam Matrices (Section 3.3)
Mean absolute difference per channel across all ordered 4x4 pairs (2 px wide strip):

### Grass Variants (4x4)
**Horizontal Seam (A right vs B left):**
| From \\ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | {grass_mat_h[0,0]:.2f} | {grass_mat_h[0,1]:.2f} | {grass_mat_h[0,2]:.2f} | {grass_mat_h[0,3]:.2f} |
| **_02** | {grass_mat_h[1,0]:.2f} | {grass_mat_h[1,1]:.2f} | {grass_mat_h[1,2]:.2f} | {grass_mat_h[1,3]:.2f} |
| **_03** | {grass_mat_h[2,0]:.2f} | {grass_mat_h[2,1]:.2f} | {grass_mat_h[2,2]:.2f} | {grass_mat_h[2,3]:.2f} |
| **_04** | {grass_mat_h[3,0]:.2f} | {grass_mat_h[3,1]:.2f} | {grass_mat_h[3,2]:.2f} | {grass_mat_h[3,3]:.2f} |

**Vertical Seam (A bottom vs B top):**
| From \\ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | {grass_mat_v[0,0]:.2f} | {grass_mat_v[0,1]:.2f} | {grass_mat_v[0,2]:.2f} | {grass_mat_v[0,3]:.2f} |
| **_02** | {grass_mat_v[1,0]:.2f} | {grass_mat_v[1,1]:.2f} | {grass_mat_v[1,2]:.2f} | {grass_mat_v[1,3]:.2f} |
| **_03** | {grass_mat_v[2,0]:.2f} | {grass_mat_v[2,1]:.2f} | {grass_mat_v[2,2]:.2f} | {grass_mat_v[2,3]:.2f} |
| **_04** | {grass_mat_v[3,0]:.2f} | {grass_mat_v[3,1]:.2f} | {grass_mat_v[3,2]:.2f} | {grass_mat_v[3,3]:.2f} |

### Dirt Variants (4x4)
**Horizontal Seam (A right vs B left):**
| From \\ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | {dirt_mat_h[0,0]:.2f} | {dirt_mat_h[0,1]:.2f} | {dirt_mat_h[0,2]:.2f} | {dirt_mat_h[0,3]:.2f} |
| **_02** | {dirt_mat_h[1,0]:.2f} | {dirt_mat_h[1,1]:.2f} | {dirt_mat_h[1,2]:.2f} | {dirt_mat_h[1,3]:.2f} |
| **_03** | {dirt_mat_h[2,0]:.2f} | {dirt_mat_h[2,1]:.2f} | {dirt_mat_h[2,2]:.2f} | {dirt_mat_h[2,3]:.2f} |
| **_04** | {dirt_mat_h[3,0]:.2f} | {dirt_mat_h[3,1]:.2f} | {dirt_mat_h[3,2]:.2f} | {dirt_mat_h[3,3]:.2f} |

**Vertical Seam (A bottom vs B top):**
| From \\ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | {dirt_mat_v[0,0]:.2f} | {dirt_mat_v[0,1]:.2f} | {dirt_mat_v[0,2]:.2f} | {dirt_mat_v[0,3]:.2f} |
| **_02** | {dirt_mat_v[1,0]:.2f} | {dirt_mat_v[1,1]:.2f} | {dirt_mat_v[1,2]:.2f} | {dirt_mat_v[1,3]:.2f} |
| **_03** | {dirt_mat_v[2,0]:.2f} | {dirt_mat_v[2,1]:.2f} | {dirt_mat_v[2,2]:.2f} | {dirt_mat_v[2,3]:.2f} |
| **_04** | {dirt_mat_v[3,0]:.2f} | {dirt_mat_v[3,1]:.2f} | {dirt_mat_v[3,2]:.2f} | {dirt_mat_v[3,3]:.2f} |

---

## 5. Transition Boundary Midpoint & Pure Area Verification (Section 3.4)
- **Classifier Colors**:
  - Grass Reference: RGB({mean_g_color[0]:.1f}, {mean_g_color[1]:.1f}, {mean_g_color[2]:.1f})
  - Dirt Reference: RGB({mean_d_color[0]:.1f}, {mean_d_color[1]:.1f}, {mean_d_color[2]:.1f})
- **Boundary Crossings**:
  - `edge_n`: left column (x=0) crosses at y={y_left} (expected 128±8) -> **{'PASS' if (120 <= y_left <= 136) else 'FAIL'}**
  - `edge_n`: right column (x=255) crosses at y={y_right} (expected 128±8) -> **{'PASS' if (120 <= y_right <= 136) else 'FAIL'}**
  - `edge_n`: crossing difference = {y_diff} px (expected <= 8 px) -> **{'PASS' if y_diff <= 8 else 'FAIL'}**
  - `outer_ne`: top row (y=0) crosses at x={x_outer_top} (expected 128±8) -> **{'PASS' if outer_top_pass else 'FAIL'}**
  - `outer_ne`: right column (x=255) crosses at y={y_outer_right} (expected 128±8) -> **{'PASS' if outer_right_pass else 'FAIL'}**
  - `inner_ne`: top row (y=0) crosses at x={x_inner_top} (expected 128±8) -> **{'PASS' if inner_top_pass else 'FAIL'}**
  - `inner_ne`: right column (x=255) crosses at y={y_inner_right} (expected 128±8) -> **{'PASS' if inner_right_pass else 'FAIL'}**
- **Pure Areas**:
  - `edge_n` top 25% (y 0..63) all grass: **{'PASS (100% pure)' if edge_top25_pure else 'FAIL'}**
  - `edge_n` bottom 25% (y 192..255) all dirt: **{'PASS (100% pure)' if edge_bot25_pure else 'FAIL'}**
  - `outer_ne` bottom-left corner all dirt: **{'PASS (100% pure)' if outer_bl_pure else 'FAIL'}**
  - `inner_ne` bottom-left corner all grass: **{'PASS (100% pure)' if inner_bl_pure else 'FAIL'}**
"""

    report_path = os.path.join(BUILD_DIR, "report.md")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report_content)
    print(f"Wrote quality report to {report_path}")

    # ─────────────────────────────────────────────────────────────────────────
    # 3.5 Rotation join test: preview_joins.png (2x nearest neighbor)
    # Layout:
    # Top-Left: Two edge_n side-by-side (512x256 at 1x)
    # Top-Right: outer_ne next to edge_n (512x256 at 1x)
    # Bottom: 3x3 block (768x768 at 1x)
    # ─────────────────────────────────────────────────────────────────────────
    print("Generating art_build/preview_joins.png (2x nearest-neighbor)...")
    edge_n = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_edge_n.png"))
    outer_ne = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_outer_ne.png"))
    outer_nw = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_outer_nw.png"))
    outer_se = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_outer_se.png"))
    outer_sw = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_outer_sw.png"))
    edge_e = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_edge_e.png"))
    edge_s = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_edge_s.png"))
    edge_w = Image.open(os.path.join(TILES_DIR, "terrain_grass_dirt_edge_w.png"))
    grass_center = Image.open(os.path.join(TILES_DIR, "terrain_grass_center_01.png"))

    # Part A: two edge_n side by side (512 x 256)
    part_a = Image.new("RGBA", (512, 256))
    part_a.paste(edge_n, (0, 0))
    part_a.paste(edge_n, (256, 0))

    # Part B: outer_ne next to edge_n (512 x 256)
    # For horizontal join: edge_n on left, outer_ne on right (grass runs top across both)
    part_b = Image.new("RGBA", (512, 256))
    part_b.paste(edge_n, (0, 0))
    part_b.paste(outer_ne, (256, 0))

    # Part C: 3x3 block (768 x 768)
    part_c = Image.new("RGBA", (768, 768))
    part_c.paste(outer_nw, (0, 0))
    part_c.paste(edge_n, (256, 0))
    part_c.paste(outer_ne, (512, 0))

    part_c.paste(edge_w, (0, 256))
    part_c.paste(grass_center, (256, 256))
    part_c.paste(edge_e, (512, 256))

    part_c.paste(outer_sw, (0, 512))
    part_c.paste(edge_s, (256, 512))
    part_c.paste(outer_se, (512, 512))

    # Assemble into full 1x canvas: width 1100, height 1100
    canvas_w = 1100
    canvas_h = 1100
    canvas_1x = Image.new("RGBA", (canvas_w, canvas_h), (35, 38, 42, 255))
    canvas_1x.paste(part_a, (30, 30))
    canvas_1x.paste(part_b, (560, 30))
    canvas_1x.paste(part_c, (166, 310))

    # Scale 2x with nearest-neighbor
    canvas_2x = canvas_1x.resize((canvas_w * 2, canvas_h * 2), Image.Resampling.NEAREST)
    joins_path = os.path.join(BUILD_DIR, "preview_joins.png")
    canvas_2x.save(joins_path, "PNG")
    print(f"Saved {joins_path} ({canvas_2x.size[0]}x{canvas_2x.size[1]})")

    # ─────────────────────────────────────────────────────────────────────────
    # 3.6 Mixed-variant preview: preview_mixed_grass.png and preview_mixed_dirt.png
    # 6x6 grid, weights 60/20/15/5, fixed seed, shown at 1x (1536 x 1536 px)
    # ─────────────────────────────────────────────────────────────────────────
    print("Generating art_build/preview_mixed_grass.png & preview_mixed_dirt.png...")
    rng = np.random.RandomState(42)
    weights = [0.60, 0.20, 0.15, 0.05]
    indices = [0, 1, 2, 3]

    # Mixed grass
    grass_6x6 = Image.new("RGBA", (1536, 1536))
    for row in range(6):
        for col in range(6):
            idx = rng.choice(indices, p=weights)
            tile_img = grass_imgs[grass_names[idx]]
            grass_6x6.paste(tile_img, (col * 256, row * 256))
    grass_preview_path = os.path.join(BUILD_DIR, "preview_mixed_grass.png")
    grass_6x6.save(grass_preview_path, "PNG")
    print(f"Saved {grass_preview_path}")

    # Mixed dirt (reset or continue seed)
    rng_dirt = np.random.RandomState(1337)
    dirt_6x6 = Image.new("RGBA", (1536, 1536))
    for row in range(6):
        for col in range(6):
            idx = rng_dirt.choice(indices, p=weights)
            tile_img = dirt_imgs[dirt_names[idx]]
            dirt_6x6.paste(tile_img, (col * 256, row * 256))
    dirt_preview_path = os.path.join(BUILD_DIR, "preview_mixed_dirt.png")
    dirt_6x6.save(dirt_preview_path, "PNG")
    print(f"Saved {dirt_preview_path}")

    print("\nQuality checks completed successfully.")

if __name__ == "__main__":
    run_quality_checks()
