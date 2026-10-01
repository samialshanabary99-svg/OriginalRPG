# Changelog: Ragnarok Online-Style Basic Info Window

- **Date:** 2026-10-01
- **Author:** Antigravity (Agent)
- **Status:** Complete & Verified

## Overview
Implemented an authentic *Ragnarok Online* inspired "Basic Info Window" matching the UI reference layout and aesthetic. The window features a classic wood/parchment frame, character portrait, identity tags, dual EXP progression bars, 4 attribute/resource bars with custom status icons, weight & Zeny financial statistics, full title-bar drag-and-drop support, compact minimize toggle, hotkey (`V`) / HUD button visibility toggling, and live data binding to player stats and inventory components.

## Changes Made

### 1. UI Assets (`assets/ui/`)
- Created character portrait: `assets/ui/portraits/portrait_valkyria.png` (128x128 RGBA8 PNG) matching reference character artwork.
- Extracted and created 6 pixel-clean 32x32 transparent UI status icons in `assets/ui/icons/`:
  - `icon_hp.png`: Heart icon for Health Points.
  - `icon_sp.png`: Orb icon for Spell Points / Mana.
  - `icon_stamina.png`: Lightning bolt icon for Stamina.
  - `icon_power.png`: Flame icon for Power / Attack Energy.
  - `icon_weight.png`: Storage crate icon for Inventory Weight.
  - `icon_money.png`: Gold coin icon for Currency / Zeny.
- Added Godot `.import` files and registered all 7 new assets in [`docs/assets/ASSET_MANIFEST.md`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/docs/assets/ASSET_MANIFEST.md).
- Verified with [`scripts/validate_assets.ps1`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/scripts/validate_assets.ps1) — 100% manifest and dimension compliance.

### 2. Basic Info Window Implementation
- **Controller (`src/ui/basic_info_window.gd`):**
  - Title bar dragging: Computes mouse delta on `gui_input` and updates window position with viewport boundary clamping.
  - Minimize foldout: Toggles content container visibility, reducing window height while preserving title bar visibility.
  - Close button `[X]`: Hides window.
  - Live signal binding: Connects to `CharacterStatsComponent` (`hp_changed`, `sp_changed`, `exp_gained`, `level_up`) and `InventoryComponent` (`inventory_changed`, `gold_changed`, `weight_changed`) to reactively update progress bars and text labels without polling.
  - Helper functions: `_format_number` for formatted currency/XP values with thousands separators (e.g. `80,000,000`).
- **Scene (`scenes/ui/basic_info_window.tscn`):**
  - Styled with custom `StyleBoxFlat` matching reference palette: dark wood title bar (`#3a2818`), warm parchment content frame (`#fad5ab`), inner recessed panels (`#eed09e`).
  - Dual EXP bars: Base Level (emerald green `#2ecc71`, "LVL", "1500 / 2800") and Job Level (amber gold `#f39c12`, "JOB", "900 / 1800").
  - 4 Resource rows: HP (crimson `#e74c3c`), SP (azure blue `#2980b9`), Stamina (vibrant orange `#e67e22`), Power (deep red `#c0392b`).
  - Footer stats: Weight indicator and Money readout with custom icons.

### 3. HUD Integration & Keybindings
- Configured new input action `toggle_character_info` mapped to `KEY_V` in [`project.godot`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/project.godot).
- Integrated `BasicInfoWindow` into [`scenes/ui/hud.tscn`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/scenes/ui/hud.tscn) positioned neatly on the right side of the screen.
- Added on-screen `ToggleInfoButton` labeled `"Basic Info (V)"` to the HUD top action bar in [`src/ui/hud.gd`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/src/ui/hud.gd).

### 4. Automated Testing
- Added **Group S: Ragnarok-Style Basic Info Window** to [`tests/test_runner.gd`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/tests/test_runner.gd) (26 assertions covering asset paths, scene instantiation, node hierarchy, number formatting, dragging logic, minimize toggle, and live player data updates).
- Total automated test suite grew to **265 tests (19 groups) — 100% passing (0 failures)**.

### 5. Packaging & Verification
- Rebuilt Windows standalone executable via [`scripts/build.ps1`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/scripts/build.ps1) (104.57 MB).
- Updated Desktop shortcut `Play OriginalRPG.lnk`.
- Verified clean startup and shutdown via 60-frame headless smoke test.
