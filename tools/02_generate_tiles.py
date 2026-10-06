#!/usr/bin/env python3
"""
Step 2: Generate missing tiles via lossless 90-degree rotations (Image.transpose)
and diagonal composition. Verify grass placement using pixel classifier.
Save all 22 tiles to assets/terrain/tiles/.
"""

import os
import sys
import shutil
import numpy as np
from PIL import Image, ImageFilter

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NAMED_DIR = os.path.join(PROJECT_ROOT, "art_build", "01_named")
TILES_DIR = os.path.join(PROJECT_ROOT, "assets", "terrain", "tiles")

def get_mean_colors():
    grass_p = os.path.join(NAMED_DIR, "terrain_grass_center_01.png")
    dirt_p = os.path.join(NAMED_DIR, "terrain_dirt_center_01.png")
    
    with Image.open(grass_p) as g_img:
        g_arr = np.array(g_img.convert("RGB"), dtype=np.float32)
        mean_grass = g_arr.mean(axis=(0, 1))

    with Image.open(dirt_p) as d_img:
        d_arr = np.array(d_img.convert("RGB"), dtype=np.float32)
        mean_dirt = d_arr.mean(axis=(0, 1))

    return mean_grass, mean_dirt

def classify_mask(img: Image.Image, mean_grass: np.ndarray, mean_dirt: np.ndarray) -> np.ndarray:
    """Returns boolean array (256, 256): True for Grass, False for Dirt."""
    smoothed = img.convert("RGB").filter(ImageFilter.MedianFilter(size=3))
    arr = np.array(smoothed, dtype=np.float32)
    dist_grass = np.linalg.norm(arr - mean_grass, axis=-1)
    dist_dirt = np.linalg.norm(arr - mean_dirt, axis=-1)
    return dist_grass < dist_dirt

def verify_tile_orientation(name: str, img: Image.Image, mean_grass: np.ndarray, mean_dirt: np.ndarray) -> bool:
    """Verifies that grass and dirt are located where the tile name specifies."""
    mask = classify_mask(img, mean_grass, mean_dirt)
    h, w = mask.shape
    
    # Quadrants
    tl = mask[:h//2, :w//2].mean()
    tr = mask[:h//2, w//2:].mean()
    bl = mask[h//2:, :w//2].mean()
    br = mask[h//2:, w//2:].mean()
    
    # Halves
    top = mask[:h//2, :].mean()
    bot = mask[h//2:, :].mean()
    left = mask[:, :w//2].mean()
    right = mask[:, w//2:].mean()

    # Thresholds: dominant area > 0.60, non-dominant < 0.40
    if name == "edge_n":
        ok = top > bot and top > 0.70 and bot < 0.30
    elif name == "edge_e":
        ok = right > left and right > 0.70 and left < 0.30
    elif name == "edge_s":
        ok = bot > top and bot > 0.70 and top < 0.30
    elif name == "edge_w":
        ok = left > right and left > 0.70 and right < 0.30
    elif name == "outer_ne":
        ok = tr > 0.60 and bl < 0.20 and tl < 0.40 and br < 0.40
    elif name == "outer_se":
        ok = br > 0.60 and tl < 0.20 and tr < 0.40 and bl < 0.40
    elif name == "outer_sw":
        ok = bl > 0.60 and tr < 0.20 and tl < 0.40 and br < 0.40
    elif name == "outer_nw":
        ok = tl > 0.60 and br < 0.20 and tr < 0.40 and bl < 0.40
    elif name == "inner_ne":
        # Dirt in TR (concave), rest grass
        ok = tr < 0.40 and bl > 0.80 and tl > 0.60 and br > 0.60
    elif name == "inner_se":
        ok = br < 0.40 and tl > 0.80 and tr > 0.60 and bl > 0.60
    elif name == "inner_sw":
        ok = bl < 0.40 and tr > 0.80 and tl > 0.60 and br > 0.60
    elif name == "inner_nw":
        ok = tl < 0.40 and br > 0.80 and tr > 0.60 and bl > 0.60
    elif name == "diag_ne_sw":
        ok = tr > 0.60 and bl > 0.60 and tl < 0.30 and br < 0.30
    elif name == "diag_nw_se":
        ok = tl > 0.60 and br > 0.60 and tr < 0.30 and bl < 0.30
    else:
        ok = True
    return ok

def generate_tiles():
    os.makedirs(TILES_DIR, exist_ok=True)
    mean_grass, mean_dirt = get_mean_colors()

    # Load 11 base tiles
    tiles = {}
    for fn in os.listdir(NAMED_DIR):
        if fn.endswith(".png"):
            p = os.path.join(NAMED_DIR, fn)
            tiles[fn] = Image.open(p)

    # 1. Rotations
    # Pillow Image.Transpose.ROTATE_270 is 90 deg clockwise
    # Pillow Image.Transpose.ROTATE_180 is 180 deg
    # Pillow Image.Transpose.ROTATE_90 is 270 deg clockwise (90 deg CCW)
    rot_map = {
        # (source_key, angle_label): (transpose_method, target_key)
        ("terrain_grass_dirt_edge_n.png", "90_cw"): (Image.Transpose.ROTATE_270, "terrain_grass_dirt_edge_e.png"),
        ("terrain_grass_dirt_edge_n.png", "180"): (Image.Transpose.ROTATE_180, "terrain_grass_dirt_edge_s.png"),
        ("terrain_grass_dirt_edge_n.png", "270_cw"): (Image.Transpose.ROTATE_90, "terrain_grass_dirt_edge_w.png"),
        
        ("terrain_grass_dirt_outer_ne.png", "90_cw"): (Image.Transpose.ROTATE_270, "terrain_grass_dirt_outer_se.png"),
        ("terrain_grass_dirt_outer_ne.png", "180"): (Image.Transpose.ROTATE_180, "terrain_grass_dirt_outer_sw.png"),
        ("terrain_grass_dirt_outer_ne.png", "270_cw"): (Image.Transpose.ROTATE_90, "terrain_grass_dirt_outer_nw.png"),
        
        ("terrain_grass_dirt_inner_ne.png", "90_cw"): (Image.Transpose.ROTATE_270, "terrain_grass_dirt_inner_se.png"),
        ("terrain_grass_dirt_inner_ne.png", "180"): (Image.Transpose.ROTATE_180, "terrain_grass_dirt_inner_sw.png"),
        ("terrain_grass_dirt_inner_ne.png", "270_cw"): (Image.Transpose.ROTATE_90, "terrain_grass_dirt_inner_nw.png"),
    }

    generated = {}
    for (src_key, angle_name), (trans_op, tgt_key) in rot_map.items():
        src_img = tiles[src_key]
        rot_img = src_img.transpose(trans_op)
        generated[tgt_key] = rot_img

    # 2. Diagonal tiles
    # diag_ne_sw: start from outer_ne; paste bottom-left quarter (x 0-127, y 128-255) of outer_sw
    outer_ne = tiles["terrain_grass_dirt_outer_ne.png"].copy()
    outer_sw = generated["terrain_grass_dirt_outer_sw.png"]
    bl_crop = outer_sw.crop((0, 128, 128, 256))
    outer_ne.paste(bl_crop, (0, 128))
    generated["terrain_grass_dirt_diag_ne_sw.png"] = outer_ne

    # diag_nw_se: start from outer_nw; paste bottom-right quarter (x 128-255, y 128-255) of outer_se
    outer_nw = generated["terrain_grass_dirt_outer_nw.png"].copy()
    outer_se = generated["terrain_grass_dirt_outer_se.png"]
    br_crop = outer_se.crop((128, 128, 256, 256))
    outer_nw.paste(br_crop, (128, 128))
    generated["terrain_grass_dirt_diag_nw_se.png"] = outer_nw

    # Combine all 22 tiles
    all_22 = {}
    all_22.update(tiles)
    all_22.update(generated)

    if len(all_22) != 22:
        print(f"ERROR: Expected 22 tiles, found {len(all_22)}", file=sys.stderr)
        sys.exit(1)

    # Verification of orientation
    print("Verifying orientation of all 22 tiles...")
    all_passed = True
    for name, img in sorted(all_22.items()):
        short_name = name.replace("terrain_grass_dirt_", "").replace(".png", "")
        is_ok = verify_tile_orientation(short_name, img, mean_grass, mean_dirt)
        status = "PASS" if is_ok else "FAIL"
        if not is_ok:
            all_passed = False
            print(f"  [{status}] {name} orientation check FAILED!", file=sys.stderr)
        else:
            print(f"  [{status}] {name}")

        # Save to assets/terrain/tiles/
        out_path = os.path.join(TILES_DIR, name)
        img.save(out_path, "PNG")

    if not all_passed:
        print("ERROR: Some tile orientations failed verification!", file=sys.stderr)
        sys.exit(1)

    print(f"\nSuccessfully generated and saved all 22 tiles to {TILES_DIR}")
    return all_22

if __name__ == "__main__":
    generate_tiles()
