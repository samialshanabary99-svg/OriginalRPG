#!/usr/bin/env python3
"""
Master Entry Point: python tools/run_all.py
Executes the entire end-to-end pipeline:
1. Source preparation & verification (256x256)
2. Tile rotations (lossless) & diagonal composition (22 tiles)
3. Quality checks, report generation, join preview, and mixed previews
4. Atlas generation (1024x1536) & atlas_layout.json
5. Godot TileSet construction (terrain_tileset.tres)
6. Project & import configuration (mipmaps + linear mipmap filter)
7. Test scene execution & verification
"""

import os
import sys
import subprocess
import time

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(TOOLS_DIR, ".."))

STEPS = [
    ("01_prepare_source.py", "Step 1: Inspect & Prepare Source Images (256x256)"),
    ("02_generate_tiles.py", "Step 2: Generate Rotations & Diagonals (22 Tiles)"),
    ("03_quality_checks.py", "Step 3: Quality Checks & Previews (report.md)"),
    ("04_build_atlas.py", "Step 4: Build Atlas PNG & Layout JSON"),
    ("05_create_tileset.py", "Step 5: Build Godot TileSet (terrain_tileset.tres)"),
    ("06_configure_project.py", "Step 6: Configure Import Mipmaps & Project Filter"),
    ("07_run_test_scene.py", "Step 7: Run Test Scene (scenes/terrain_test.tscn)")
]

def run_pipeline():
    start_time = time.time()
    print("=" * 70)
    print("  Terrain Autotiling Pipeline Runner (Godot 4, 256x256)")
    print("=" * 70)

    for script_name, description in STEPS:
        script_path = os.path.join(TOOLS_DIR, script_name)
        print(f"\n>>> Running {description}...")
        res = subprocess.run([sys.executable, script_path], cwd=PROJECT_ROOT)
        if res.returncode != 0:
            print(f"\n[PIPELINE FAILED] Error in {script_name} (code: {res.returncode})", file=sys.stderr)
            sys.exit(res.returncode)

    elapsed = time.time() - start_time
    print("\n" + "=" * 70)
    print(f"  PIPELINE COMPLETE in {elapsed:.2f} seconds.")
    print("=" * 70)

if __name__ == "__main__":
    run_pipeline()
