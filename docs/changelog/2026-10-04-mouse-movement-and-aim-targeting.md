# Changelog: Mouse Click-to-Move, Cell Target Preview & Aim Reticle Combat

**Date:** 2026-10-04  
**Author:** AI Agent (Antigravity)  
**Status:** Completed & Verified  

---

## 1. Overview
In accordance with user requirements, keyboard WASD movement was completely removed from the 3D player controller, and replaced with authentic Ragnarok Online style mouse click-to-move navigation and mouse click-to-attack targeting with floating aim reticles.

## 2. Key Changes & Architecture

### A. Removal of WASD Movement
- In `Player3D` (`src/entities/player_3d.gd`), keyboard axis polling (`move_left`, `move_right`, `move_up`, `move_down`, `ui_left`, `ui_right`, etc.) was removed from `_physics_process`.
- Character locomotion is now strictly driven by mouse clicks/drags or combat pursuit targets.

### B. Ragnarok Online Style Mouse Click-to-Move
- **Left-Click Navigation**: Clicking on the 3D terrain performs a camera raycast against collision layer 2 (terrain), setting the player's destination vector.
- **Drag Walking**: Holding down the Left Mouse Button and dragging across the ground continuously streams destination updates, providing smooth mouse-steering navigation.
- **Cell Target Preview (`CellCursor3D`)**:
  - Instantiates `res://scenes/entities/cell_cursor_3d.tscn` with a dedicated pixel art cursor `res://assets/ui/cursors/cell_target_cursor.png`.
  - Snaps to the clicked coordinate, conforms flat along the terrain normal, pulses dynamically on placement, and smoothly fades out upon destination arrival.
- **UI Guard**: Mouse raycasting is guarded by `_is_mouse_over_ui()` to prevent movement triggers when interacting with the Basic Info Window or HUD buttons.

### C. Mouse Aim Reticle & Monster Targeting
- **Hover Preview**: Moving the mouse over an enemy highlights the monster with an aim indicator preview (`aim_indicator` at 65% opacity).
- **Target Locking**: Left-clicking a monster (`Enemy3D`) targets it and locks the RO-style crimson & gold downward aim reticle (`res://assets/ui/cursors/target_aim_reticle.png`) floating above the monster's head.
- **Combat Auto-Attack Loop**:
  - The player paths towards the monster.
  - When within melee attack reach (`attack_reach = 2.0`), the player immediately stops moving, faces the enemy (updating billboard orientation), and auto-attacks with sword slash animations whenever `attack_cooldown` expires.
  - If the monster moves, the player pursues it back into melee range.
  - When the monster dies, the player clears the target, the aim reticle turns off, and the player returns to idle.
  - Left-clicking ground deselects the monster and paths to the new ground point.

### D. Asset Pipeline & Tests
- New cursor textures created and registered in `docs/assets/ASSET_MANIFEST.md`.
- Automated test runner extended with **Group W** (14 new assertions covering cell cursor behavior, aim indicator visibility/opacities, player pursuit, immediate melee range halt, and death auto-cleanup).
- Total tests expanded to **406 passing tests with 0 failures**.
- Standalone release binary built: `build/OriginalRPG.exe` (108.95 MB) and `ProjectZero/OriginalRPG.exe`.
