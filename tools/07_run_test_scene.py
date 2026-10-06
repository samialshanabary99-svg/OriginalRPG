#!/usr/bin/env python3
"""
Step 7: Run test scene (scenes/terrain_test.tscn) with Godot.
Captures grid coordinates output and attempts screenshot generation.
"""

import os
import sys
import subprocess
import shutil

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

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

def run_test_scene():
    godot_bin = find_godot()
    if not godot_bin:
        print("ERROR: Godot executable not found. Please provide path.", file=sys.stderr)
        sys.exit(1)

    print(f"Running test scene: {godot_bin} scenes/terrain_test.tscn")
    # Run with windowed mode first to allow GPU viewport capture
    res = subprocess.run([godot_bin, "scenes/terrain_test.tscn"], cwd=PROJECT_ROOT, capture_output=True, text=True, timeout=30)
    print(res.stdout)
    if res.returncode != 0:
        print(f"Warning: Non-zero exit code: {res.returncode}. Trying headless fallback...", file=sys.stderr)
        res_headless = subprocess.run([godot_bin, "--headless", "scenes/terrain_test.tscn"], cwd=PROJECT_ROOT, capture_output=True, text=True, timeout=20)
        print(res_headless.stdout)

    screenshot_path = os.path.join(PROJECT_ROOT, "art_build", "terrain_test_screenshot.png")
    if os.path.exists(screenshot_path):
        print(f"Screenshot successfully captured: {screenshot_path}")
    else:
        print(f"Note: Display not available for screenshot, but coordinates were printed above.")

    print("Test scene execution completed.")

if __name__ == "__main__":
    run_test_scene()
