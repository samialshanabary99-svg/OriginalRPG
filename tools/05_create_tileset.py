#!/usr/bin/env python3
"""
Step 5: Run Godot headless to build terrain_tileset.tres from atlas_layout.json.
"""

import os
import sys
import subprocess
import shutil

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GD_SCRIPT = os.path.join(PROJECT_ROOT, "tools", "build_tileset.gd")

def find_godot():
    godot_bin = shutil.which("godot")
    if godot_bin:
        return godot_bin
    candidate = os.path.abspath(os.path.join(PROJECT_ROOT, "..", "Godot_v4.7.2-stable_win64_console.exe"))
    if os.path.exists(candidate):
        return candidate
    env_bin = os.environ.get("GODOT_BIN")
    if env_bin and os.path.exists(env_bin):
        return env_bin
    return None

def create_tileset():
    godot_bin = find_godot()
    if not godot_bin:
        print("ERROR: Godot executable not found. Please provide path.", file=sys.stderr)
        sys.exit(1)

    print(f"Building TileSet via Godot: {godot_bin} --headless --path . --script {GD_SCRIPT}")
    res = subprocess.run([godot_bin, "--headless", "--path", PROJECT_ROOT, "--script", "tools/build_tileset.gd"], capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print(f"ERROR running build_tileset.gd:\n{res.stderr}", file=sys.stderr)
        sys.exit(1)

    tileset_path = os.path.join(PROJECT_ROOT, "assets", "terrain", "terrain_tileset.tres")
    if not os.path.exists(tileset_path):
        print(f"ERROR: Expected TileSet resource {tileset_path} was not created.", file=sys.stderr)
        sys.exit(1)

    print("TileSet creation completed successfully.")

if __name__ == "__main__":
    create_tileset()
