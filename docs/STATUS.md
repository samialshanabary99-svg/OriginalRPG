# Project Status

## Current Milestone: Core RPG Progression & Stat Allocation UI

### Implemented Features
- **3D World & Terrain**: Procedural 50m x 50m hybrid 3D terrain with 2.5D billboard sprites and directional sun shadows.
- **Ragnarok Online Controls**: Click-to-move ground destination indicator, reticle aim hover/target, RMB camera rotation and pitch.
- **Combat System**: Melee collision radius edge-to-edge distance calculations, multi-hit continuous combat to death, dual apex + physics hit guarantees, overhead health and SP bars.
- **Basic Info Window**: Ragnarok Online style wood-trimmed window in upper-left corner showing portrait, character identity, base/job level EXP bars, HP/SP/Stamina/Power bars, weight, and money.
- **Character Stats Window (UI)**:
  - Tabbed RPG character window (`scenes/ui/character_stats_window.tscn`).
  - Read-only combat stats (HP, Stamina, Attack, Defense).
  - 6x reusable `AttributeRow` instances (`STR`, `AGI`, `VIT`, `INT`, `DEX`, `LUK`).
  - Dynamic cost scaling ($2 \to 3 \to 4 \to 5$ points).
  - Persistent global `GameState` tracking levels, resources, and stat points.
  - Floating toast confirmation on attribute increase (`Toast.show_toast`).
  - Hotkey toggle (`C` for Character Stats, `V` for Basic Info, `ESC` to close).

### Verification
- **Automated Tests**: 493 / 493 tests passing in `tests/test_runner.gd`.
- **In-Game Rendering**: Visual verification across resolutions and forward+ renderer.
