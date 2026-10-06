#!/usr/bin/env python3
"""
Step 6: Import and project settings.
1. Sets mipmaps/generate=true in assets/terrain/terrain_grass_dirt_atlas.png.import and reimports via Godot.
2. Sets rendering/textures/canvas_textures/default_texture_filter=3 in project.godot.
"""

import os
import sys
import subprocess
import shutil

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
IMPORT_FILE = os.path.join(PROJECT_ROOT, "assets", "terrain", "terrain_grass_dirt_atlas.png.import")
PROJECT_GODOT = os.path.join(PROJECT_ROOT, "project.godot")

def find_godot():
    # 1. On PATH
    godot_bin = shutil.which("godot")
    if godot_bin:
        return godot_bin
    
    # 2. Sibling executable in parent folder
    candidate = os.path.abspath(os.path.join(PROJECT_ROOT, "..", "Godot_v4.7.2-stable_win64_console.exe"))
    if os.path.exists(candidate):
        return candidate
    
    # 3. Environment variable
    env_bin = os.environ.get("GODOT_BIN")
    if env_bin and os.path.exists(env_bin):
        return env_bin

    return None

def configure_project():
    godot_bin = find_godot()
    if not godot_bin:
        print("ERROR: Godot executable not found. Please provide path.", file=sys.stderr)
        sys.exit(1)

    # 1. Set mipmaps/generate=true in atlas .import file
    if os.path.exists(IMPORT_FILE):
        with open(IMPORT_FILE, "r", encoding="utf-8") as f:
            content = f.read()

        if "mipmaps/generate=false" in content:
            content = content.replace("mipmaps/generate=false", "mipmaps/generate=true")
            with open(IMPORT_FILE, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Updated {IMPORT_FILE}: mipmaps/generate = true")
        elif "mipmaps/generate=true" in content:
            print(f"{IMPORT_FILE} already has mipmaps/generate = true")

    # 2. Update project.godot for default_texture_filter=3 (Linear Mipmap)
    if os.path.exists(PROJECT_GODOT):
        with open(PROJECT_GODOT, "r", encoding="utf-8") as f:
            p_content = f.read()

        setting_line = "textures/canvas_textures/default_texture_filter=3"
        if setting_line not in p_content:
            if "[rendering]" in p_content:
                p_content = p_content.replace("[rendering]", f"[rendering]\n\n{setting_line}")
            else:
                p_content += f"\n[rendering]\n\n{setting_line}\n"
            
            with open(PROJECT_GODOT, "w", encoding="utf-8") as f:
                f.write(p_content)
            print(f"Updated project.godot: {setting_line} (Linear Mipmap)")
        else:
            print(f"project.godot already has {setting_line}")

    # 3. Reimport with Godot
    print(f"Reimporting assets with Godot: {godot_bin} --headless --path . --import")
    res = subprocess.run([godot_bin, "--headless", "--path", PROJECT_ROOT, "--import"], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"ERROR reimporting assets:\n{res.stderr}", file=sys.stderr)
        sys.exit(1)

    print("Reimport completed successfully.")

if __name__ == "__main__":
    configure_project()
