#!/usr/bin/env python3
"""
Step 4: Build 1024x1536 PNG Atlas (4 cols x 6 rows) and atlas_layout.json.
"""

import os
import sys
import json
from PIL import Image

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TILES_DIR = os.path.join(PROJECT_ROOT, "assets", "terrain", "tiles")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets", "terrain")

ATLAS_LAYOUT = [
    # Row 0
    {"col": 0, "row": 0, "file": "terrain_grass_center_01.png", "tile": "grass_center_01", "own": "grass", "TL": "G", "TR": "G", "BR": "G", "BL": "G", "prob": 1.0, "footstep": "grass"},
    {"col": 1, "row": 0, "file": "terrain_grass_center_02.png", "tile": "grass_center_02", "own": "grass", "TL": "G", "TR": "G", "BR": "G", "BL": "G", "prob": 0.33, "footstep": "grass"},
    {"col": 2, "row": 0, "file": "terrain_grass_center_03.png", "tile": "grass_center_03", "own": "grass", "TL": "G", "TR": "G", "BR": "G", "BL": "G", "prob": 0.25, "footstep": "grass"},
    {"col": 3, "row": 0, "file": "terrain_grass_center_04.png", "tile": "grass_center_04", "own": "grass", "TL": "G", "TR": "G", "BR": "G", "BL": "G", "prob": 0.08, "footstep": "grass"},

    # Row 1
    {"col": 0, "row": 1, "file": "terrain_dirt_center_01.png", "tile": "dirt_center_01", "own": "dirt", "TL": "D", "TR": "D", "BR": "D", "BL": "D", "prob": 1.0, "footstep": "dirt"},
    {"col": 1, "row": 1, "file": "terrain_dirt_center_02.png", "tile": "dirt_center_02", "own": "dirt", "TL": "D", "TR": "D", "BR": "D", "BL": "D", "prob": 0.33, "footstep": "dirt"},
    {"col": 2, "row": 1, "file": "terrain_dirt_center_03.png", "tile": "dirt_center_03", "own": "dirt", "TL": "D", "TR": "D", "BR": "D", "BL": "D", "prob": 0.25, "footstep": "dirt"},
    {"col": 3, "row": 1, "file": "terrain_dirt_center_04.png", "tile": "dirt_center_04", "own": "dirt", "TL": "D", "TR": "D", "BR": "D", "BL": "D", "prob": 0.08, "footstep": "dirt"},

    # Row 2
    {"col": 0, "row": 2, "file": "terrain_grass_dirt_outer_nw.png", "tile": "outer_nw", "own": "grass", "TL": "G", "TR": "D", "BR": "D", "BL": "D", "prob": 1.0, "footstep": "grass"},
    {"col": 1, "row": 2, "file": "terrain_grass_dirt_edge_n.png", "tile": "edge_n", "own": "grass", "TL": "G", "TR": "G", "BR": "D", "BL": "D", "prob": 1.0, "footstep": "grass"},
    {"col": 2, "row": 2, "file": "terrain_grass_dirt_outer_ne.png", "tile": "outer_ne", "own": "grass", "TL": "D", "TR": "G", "BR": "D", "BL": "D", "prob": 1.0, "footstep": "grass"},
    {"col": 3, "row": 2, "file": "terrain_grass_dirt_inner_nw.png", "tile": "inner_nw", "own": "grass", "TL": "D", "TR": "G", "BR": "G", "BL": "G", "prob": 1.0, "footstep": "grass"},

    # Row 3
    {"col": 0, "row": 3, "file": "terrain_grass_dirt_edge_w.png", "tile": "edge_w", "own": "grass", "TL": "G", "TR": "D", "BR": "D", "BL": "G", "prob": 1.0, "footstep": "grass"},
    # (col 1, row 3 is empty)
    {"col": 2, "row": 3, "file": "terrain_grass_dirt_edge_e.png", "tile": "edge_e", "own": "grass", "TL": "D", "TR": "G", "BR": "G", "BL": "D", "prob": 1.0, "footstep": "grass"},
    {"col": 3, "row": 3, "file": "terrain_grass_dirt_inner_ne.png", "tile": "inner_ne", "own": "grass", "TL": "G", "TR": "D", "BR": "G", "BL": "G", "prob": 1.0, "footstep": "grass"},

    # Row 4
    {"col": 0, "row": 4, "file": "terrain_grass_dirt_outer_sw.png", "tile": "outer_sw", "own": "grass", "TL": "D", "TR": "D", "BR": "D", "BL": "G", "prob": 1.0, "footstep": "grass"},
    {"col": 1, "row": 4, "file": "terrain_grass_dirt_edge_s.png", "tile": "edge_s", "own": "grass", "TL": "D", "TR": "D", "BR": "G", "BL": "G", "prob": 1.0, "footstep": "grass"},
    {"col": 2, "row": 4, "file": "terrain_grass_dirt_outer_se.png", "tile": "outer_se", "own": "grass", "TL": "D", "TR": "D", "BR": "G", "BL": "D", "prob": 1.0, "footstep": "grass"},
    {"col": 3, "row": 4, "file": "terrain_grass_dirt_inner_sw.png", "tile": "inner_sw", "own": "grass", "TL": "G", "TR": "G", "BR": "G", "BL": "D", "prob": 1.0, "footstep": "grass"},

    # Row 5
    {"col": 0, "row": 5, "file": "terrain_grass_dirt_inner_se.png", "tile": "inner_se", "own": "grass", "TL": "G", "TR": "G", "BR": "D", "BL": "G", "prob": 1.0, "footstep": "grass"},
    {"col": 1, "row": 5, "file": "terrain_grass_dirt_diag_ne_sw.png", "tile": "diag_ne_sw", "own": "grass", "TL": "D", "TR": "G", "BR": "D", "BL": "G", "prob": 1.0, "footstep": "grass"},
    {"col": 2, "row": 5, "file": "terrain_grass_dirt_diag_nw_se.png", "tile": "diag_nw_se", "own": "grass", "TL": "G", "TR": "D", "BR": "G", "BL": "D", "prob": 1.0, "footstep": "grass"},
    # (col 3, row 5 is empty)
]

def build_atlas():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    atlas_w = 4 * 256  # 1024
    atlas_h = 6 * 256  # 1536
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))

    json_records = []

    for entry in ATLAS_LAYOUT:
        col = entry["col"]
        row = entry["row"]
        fn = entry["file"]
        tile_path = os.path.join(TILES_DIR, fn)
        if not os.path.exists(tile_path):
            print(f"ERROR: Tile file {tile_path} does not exist!", file=sys.stderr)
            sys.exit(1)

        tile_img = Image.open(tile_path).convert("RGBA")
        x = col * 256
        y = row * 256
        atlas.paste(tile_img, (x, y))

        json_records.append({
            "name": fn,
            "role": entry["tile"],
            "atlas_coords": [col, row],
            "own_terrain": entry["own"],
            "terrain_bits": {
                "top_left": entry["TL"],
                "top_right": entry["TR"],
                "bottom_right": entry["BR"],
                "bottom_left": entry["BL"]
            },
            "probability": entry["prob"],
            "custom_data": {
                "walkable": True,
                "footstep": entry["footstep"]
            }
        })

    # Save atlas PNG
    atlas_out = os.path.join(OUTPUT_DIR, "terrain_grass_dirt_atlas.png")
    atlas.save(atlas_out, "PNG")
    print(f"Saved atlas PNG ({atlas.size[0]}x{atlas.size[1]}) -> {atlas_out}")

    # Save atlas layout JSON
    json_out = os.path.join(OUTPUT_DIR, "atlas_layout.json")
    with open(json_out, "w", encoding="utf-8") as f:
        json.dump(json_records, f, indent=2)
    print(f"Saved atlas layout JSON ({len(json_records)} tiles) -> {json_out}")

if __name__ == "__main__":
    build_atlas()
