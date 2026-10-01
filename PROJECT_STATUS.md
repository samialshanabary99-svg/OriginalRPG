# Project Status

## Current Phase
**Hybrid 3D Terrain + 2D Billboard Presentation Implemented (ADR-006) — 323/323 automated tests passing across 21 test groups.**

## Working Systems
- All Phase 1 systems (Main Menu, Test World, Player, Camera, Interaction, HUD, scene transitions).
- **`Multi-Layer TileMapLayer Field Terrain & Slope System`** (`scenes/maps/test_world.tscn`, `assets/tiles/`):
  - 3 dedicated layers: `GroundLayer` (z = -2), `ElevationLayer` (z = -1), `DecorationLayer` (z = 0, y_sort_enabled).
  - 20 custom 32×32 pixel-art RGBA8 tiles (`assets/tiles/ground/`): lush meadow grass, flower variants, elevated grass, directional slopes, corners, ramps, cliffs, stepping stones, and doodads.
  - Unified Godot 4 `TileSet` (`assets/tiles/tileset_green_field.tres`) with custom data layers for `terrain_type` (footstep/physics metadata) and `elevation`.
  - Zero physics collision geometry on slopes/plateaus ensuring completely free, smooth player movement across hills.
  - Manifest and dimension compliance (70 files checked, 0 errors).
- **`AI-Assisted Asset Pipeline & Validator`** (`src/services/asset_validator.gd`, `scripts/validate_assets.gd`, `docs/assets/`):
  - Strict naming, directory, dimension, format, and RGBA transparency enforcement.
  - Comprehensive asset manifest ([`docs/assets/ASSET_MANIFEST.md`](file:///c:/Users/SAMI/Desktop/ProjectZero/OriginalRPG/docs/assets/ASSET_MANIFEST.md)) with 100% disk coverage verification.
  - Automated CLI and test-suite validation detecting common asset errors.
- **`Data-Driven Content Pipeline & ContentRegistry`** (`src/services/content_registry.gd`, `res://data/`):
  - Centralized registry loading and caching definitions from `res://data/{characters,enemies,items,skills}/`.
  - Comprehensive validation detecting empty identifiers, invalid types, negative stats/mana/cooldowns.
  - Runtime instantiation of enemies and archetype initialization of players without code changes.
- **`CharacterDefinition`** (`src/core/character_definition.gd`): Data archetypes (`data/characters/`) with validation, base stats, mana, and level-up growth parameters.
- **`EnemyDefinition`** (`src/core/enemy_definition.gd`): Data-driven enemy archetypes (`data/enemies/`) defining combat attributes, patrol/aggro radii, speeds, visual tints, and XP awards.
- **`ItemDefinition`** (`src/core/item_definition.gd`): Data-driven items (`data/items/`) with categories, equipment slots, stat modifiers, and consumable heal/mana recovery.
- **`SkillDefinition`** (`src/core/skill_definition.gd`): Data-driven skills (`data/skills/`) with mana costs, cooldowns, powers, target types, and effect categories.
- **`CharacterStatsComponent`** (`src/components/character_stats_component.gd`): Dual resources (HP + Mana), progression (Level + XP), dynamic additive stat modifiers, separate computed final stats (`final_attack`, `final_defence`, `final_speed`, `final_max_mana`).
- **`EquipmentComponent`** (`src/components/equipment_component.gd`): Slot registry managing item equipping and driving `CharacterStatsComponent` stat modifiers via item `get_stat_bonuses()`.
- **`InventoryComponent`** (`src/components/inventory_component.gd`): Item container on Player and entities with serialization and `add_item_by_id()`.
- **`Combat Pipeline & CombatResult`** (`src/core/combat_result.gd`, `src/services/damage_calculator.gd`):
  - Deterministic attack resolution pipeline (`DamageCalculator.resolve_attack()`).
  - Player targeting (`set_target()`, `clear_target()`, `acquire_target()`, `current_target`).
  - Target defeat handling with automatic data-driven XP award (`target.definition.xp_reward`) and HUD combat reporting.
  - Guards for dead targets, invalid targets, cooldowns, and dead attackers.
- **`Player Visuals & Animations`** (`assets/sprites/player/`, `scenes/entities/player.tscn`):
  - 8-directional animated idle breathing states (`idle_south` through `idle_south-west`).
  - `AnimatedSprite2D` node driven by `player_sprite_frames.tres` (4 frames per direction at 5 FPS loop).
  - Mathematical 8-octant direction calculation updating animation state dynamically with movement.
- **`Player`** (`src/entities/player.gd`): Full character state machine, facing tracking, `attack_target()`, `try_use_skill()`, `init_from_character_id()`, delegating serialization.
- **`Enemy`** (`src/entities/enemy.gd`): AI patrol/aggro states, `init_from_id()` and `init_from_definition()`, dynamic stats and visual tint, click-targeting event, unified combat execution.
- **`Ragnarok-Style Basic Info Window`** (`src/ui/basic_info_window.gd`, `scenes/ui/basic_info_window.tscn`, `assets/ui/`):
  - Authentic RO aesthetic with wood title bar, parchment panel, inner recessed borders, character portrait, and 6 custom 32x32 RGBA8 status icons.
  - Dual EXP progression bars (Base LVL & Job LVL) with progress readouts.
  - 4 status bars (HP, SP, Stamina, Power) and footer stats (Weight, formatted Zeny).
  - Draggable window via title bar, minimize foldout toggle, close button `[X]`, and hotkey (`V`) / HUD button toggle.
  - Live signal binding to `CharacterStatsComponent` and `InventoryComponent`.

## In Progress
- None. Phase 2 & UI systems stable. Awaiting next user request.

## Planned (Phase 3 — Save/Load & Persistence)
- JSON save/load service (`SaveService`) for player stats + inventory
- Atomic file write to `user://save.json`
- Load-on-startup, save-on-quit hooks
- Save data versioning (ADR-003)

## Planned (Phase 4 — Content Expansion)
- More enemy types
- Multiple map rooms / dungeon area
- NPCs with dialogue
- Quest log runtime component (`QuestLog`)
- Sound effects and ambient audio

## Multiplayer
Not implemented. Architecture intentionally decoupled to support future headless server evaluation.

## Known Issues
- Godot 4 executable located at `C:\Users\SAMI\Desktop\ProjectZero\Godot_v4.7.2-stable_win64_console.exe` — not on system `PATH`.
- Non-player entities (Enemy, AncientMonument) still use placeholder `icon.svg` textures pending asset creation.
- Damaging skills do not award XP on defeat (addressed in proposed ADR-005).

## Last Updated
2026-10-01 (Antigravity — Multi-Layer TileMapLayer Field Complete & Verified)
