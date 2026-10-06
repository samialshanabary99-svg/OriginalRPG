#!/usr/bin/env python3
"""
Step 1: Inspect source images, verify dimensions (256x256), establish mapping,
and copy to art_build/01_named/.
"""

import os
import sys
import shutil
from PIL import Image

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_DIR = os.path.join(PROJECT_ROOT, "art_src", "terrain")
FALLBACK_SRC = os.path.join(PROJECT_ROOT, "11 tiiles")
DEST_DIR = os.path.join(PROJECT_ROOT, "art_build", "01_named")

# Explicit mapping between source filenames and expected target names
# Note: Visual inspection confirms:
# - source "inner_ne.png" has grass only in the top-right corner (convex) -> role "outer_ne"
# - source "outer_ne.png" has dirt only in the top-right corner (concave) -> role "inner_ne"
MAPPING = {
    "grass_center_01.png": "terrain_grass_center_01.png",
    "grass_center_02.png": "terrain_grass_center_02.png",
    "grass_center_03.png": "terrain_grass_center_03.png",
    "grass_center_04.png": "terrain_grass_center_04.png",
    "dirt_center_01.png": "terrain_dirt_center_01.png",
    "dirt_center_02.png": "terrain_dirt_center_02.png",
    "dirt_center_03.png": "terrain_dirt_center_03.png",
    "dirt_center_04.png": "terrain_dirt_center_04.png",
    "edge_n.png": "terrain_grass_dirt_edge_n.png",
    "inner_ne.png": "terrain_grass_dirt_outer_ne.png",
    "outer_ne.png": "terrain_grass_dirt_inner_ne.png",
}

def prepare_source_images():
    os.makedirs(SRC_DIR, exist_ok=True)
    os.makedirs(DEST_DIR, exist_ok=True)

    # If art_src/terrain is empty, copy from '11 tiiles' without touching originals
    existing_src = [f for f in os.listdir(SRC_DIR) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    if len(existing_src) < 11:
        if not os.path.exists(FALLBACK_SRC):
            print(f"ERROR: Neither {SRC_DIR} nor {FALLBACK_SRC} contains source images.", file=sys.stderr)
            sys.exit(1)
        print(f"Populating {SRC_DIR} with pristine copies from {FALLBACK_SRC}...")
        for src_file in os.listdir(FALLBACK_SRC):
            if src_file.lower().endswith(('.png', '.jpg', '.jpeg')):
                shutil.copy2(os.path.join(FALLBACK_SRC, src_file), os.path.join(SRC_DIR, src_file))

    # Verify each expected source file
    results = {}
    for src_name, target_name in MAPPING.items():
        src_path = os.path.join(SRC_DIR, src_name)
        if not os.path.exists(src_path):
            print(f"ERROR: Expected source file {src_name} not found in {SRC_DIR}", file=sys.stderr)
            sys.exit(1)

        with Image.open(src_path) as img:
            w, h = img.size
            mode = img.mode
            if w != 256 or h != 256:
                print(f"ERROR: Image {src_name} has invalid dimension {w}x{h} (expected 256x256). Stopping without resizing.", file=sys.stderr)
                sys.exit(1)
            
            # Convert to RGBA only if needed without changing pixel values
            if mode != "RGBA":
                converted = img.convert("RGBA")
            else:
                converted = img.copy()

            target_path = os.path.join(DEST_DIR, target_name)
            converted.save(target_path, "PNG")
            results[src_name] = {
                "target": target_name,
                "size": (w, h),
                "orig_mode": mode,
                "final_mode": "RGBA"
            }
            print(f"Mapped {src_name} ({w}x{h}, {mode}) -> {target_name}")

    print("\nStep 1.1 & 1.2 completed successfully. All 11 images verified at 256x256 RGBA.")
    return results

if __name__ == "__main__":
    prepare_source_images()
