# Asset Manifest

Every important game asset must have a stable record here. Unmanifested assets are considered unverified drafts and will be flagged by `scripts/validate_assets.gd`.

---

## Manifest Record Schema

```yaml
asset_id: <unique_snake_case_id>
name: <human_readable_name>
type: <character | monster | boss | npc | map | tile | ui | icon | effect | environment>
path: <relative_path_under_assets_or_project>
source: <user_provided | ai_generated | human_authored | engine_default>
generator_or_tool: <dalle_3 | midjourney | imagen | stable_diffusion | antigravity_generate_image | manual | godot>
prompt_reference: <prompt_text_or_reference_key>
author: <author_name_or_agent>
created_date: <YYYY-MM-DD>
modified_date: <YYYY-MM-DD>
dimensions: <width x height, e.g. 128x128>
frame_size: <width x height per frame, e.g. 128x128>
animation_frames: <integer frame count, e.g. 4>
animation: <idle | walk | attack | hit | cast | none>
directions: <1 | 4 | 8 | none>
format: <png | svg | tres | res | ogg | wav>
transparency: <rgba_alpha | opaque>
intended_use: <gameplay description>
related_entity: <associated GDScript entity or scene>
status: <planned | generating | draft | approved | deprecated | replaced>
license_or_usage_notes: <license or provenance statement>
notes: <special considerations or rendering hints>
```

---

## Status Definitions

- **`planned`**: Asset entry reserved for planned game content (e.g. from `res://data/`).
- **`generating`**: Prompt prepared; generation or refinement in progress.
- **`draft`**: Generated/imported asset undergoing initial testing; not yet approved for release.
- **`approved`**: Verified against all dimension, transparency, and animation standards; active in game.
- **`deprecated`**: Still in repository for backward compatibility, but slated for replacement.
- **`replaced`**: Superseded by a newer asset.

---

## Active & Approved Assets

### 1. `icon_placeholder_godot`
```yaml
asset_id: icon_placeholder_godot
name: Godot Engine Default Icon
type: ui
path: icon.svg
source: engine_default
generator_or_tool: godot
prompt_reference: n/a
author: Godot Engine Contributors
created_date: 2026-09-30
modified_date: 2026-09-30
dimensions: 128x128
frame_size: 128x128
animation_frames: 1
animation: none
directions: none
format: svg
transparency: rgba_alpha
intended_use: Default application icon and fallback visual for test world entities (monument, enemy placeholder)
related_entity: scenes/test_main.tscn
status: approved
license_or_usage_notes: MIT License (Godot Engine)
notes: Temporary placeholder for non-player entities until dedicated art is authored.
```

### 2. `char_player_idle_breathing`
```yaml
asset_id: char_player_idle_breathing
name: Novice Adventurer 8-Directional Breathing Idle
type: character
path: assets/sprites/player/idle/animations/Breathing_Idle/
source: user_provided
generator_or_tool: ai_generated (Diffusion Pixel Art Pipeline)
prompt_reference: "Young male fantasy novice adventurer, inspired by classic 2D MMORPG beginner characters, full-body standing character, 3/4 view facing slightly left, youthful face, short messy dark brown hair, large expressive anime-style eyes, simple friendly appearance. Loose off-white tunic, brown leather utility belt with pouches, cloth/leather gloves, dark brown trousers, ankle boots. Low top-down view, crisp pixel clusters, 128x128, transparent background."
author: User / Diffusion Engine (metadata export 3.1)
created_date: 2026-09-25
modified_date: 2026-10-01
dimensions: 128x128
frame_size: 128x128
animation_frames: 4
animation: idle
directions: 8 (south, south-east, east, north-east, north, north-west, west, south-west)
format: png
transparency: rgba_alpha
intended_use: In-game animated visual presentation for player character when idle
related_entity: src/entities/player.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset provided for OriginalRPG
notes: 32 individual PNG frames (4 frames x 8 directions), rendered at 5.0 FPS loop.
```

### 3. `char_player_rotations`
```yaml
asset_id: char_player_rotations
name: Novice Adventurer 8-Directional Still Rotations
type: character
path: assets/sprites/player/idle/rotations/
source: user_provided
generator_or_tool: ai_generated
prompt_reference: Same character model as char_player_idle_breathing
author: User
created_date: 2026-09-25
modified_date: 2026-10-01
dimensions: 128x128
frame_size: 128x128
animation_frames: 1
animation: none
directions: 8 (south, south-east, east, north-east, north, north-west, west, south-west)
format: png
transparency: rgba_alpha
intended_use: Static 8-direction posture previews and inventory/paperdoll character display
related_entity: src/entities/player.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset provided for OriginalRPG
notes: 8 directional single-frame PNG images.
```

### 4. `res_player_sprite_frames`
```yaml
asset_id: res_player_sprite_frames
name: Player AnimatedSprite2D SpriteFrames Resource
type: character
path: assets/sprites/player/player_sprite_frames.tres
source: human_authored (generated by scripts/generate_player_frames.gd)
generator_or_tool: godot
prompt_reference: n/a
author: Antigravity (Agent)
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 128x128
frame_size: 128x128
animation_frames: 32
animation: idle_south, idle_south-east, idle_east, idle_north-east, idle_north, idle_north-west, idle_west, idle_south-west
directions: 8
format: tres
transparency: rgba_alpha
intended_use: Runtime SpriteFrames resource driving player AnimatedSprite2D node
related_entity: scenes/entities/player.tscn
status: approved
license_or_usage_notes: Project-authored Godot resource
notes: Automatically maps 8 idle animations at 5.0 FPS with loop enabled.
```

### 5. `ui_portrait_valkyria`
```yaml
asset_id: ui_portrait_valkyria
name: Valkyria Novice Character Portrait
type: ui
path: assets/ui/portraits/portrait_valkyria.png
source: user_provided
generator_or_tool: ai_generated
prompt_reference: Classic Ragnarok Online inspired red-haired novice heroine portrait
author: User
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 128x128
frame_size: 128x128
animation_frames: 1
animation: none
directions: 1
format: png
transparency: rgba_alpha
intended_use: Character portrait displayed in the Basic Info Window
related_entity: scenes/ui/basic_info_window.tscn
status: approved
license_or_usage_notes: Custom user asset for OriginalRPG Basic Info Window
notes: 128x128 pixel portrait with decorative frame.
```

### 6. `ui_basic_info_icons`
```yaml
asset_id: ui_basic_info_icons
name: Basic Info Window Attribute & Currency Icons
type: ui
path: assets/ui/icons/
source: user_provided
generator_or_tool: manual_extraction
prompt_reference: Ragnarok Online Basic Info UI icons (HP, SP, Stamina, Power, Weight, Money)
author: Antigravity (Agent)
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 6
animation: none
directions: 1
format: png
transparency: rgba_alpha
intended_use: Attribute and resource row icons for Basic Info Window
related_entity: scenes/ui/basic_info_window.tscn
status: approved
license_or_usage_notes: Project UI icons (icon_hp.png, icon_sp.png, icon_stamina.png, icon_power.png, icon_weight.png, icon_money.png)
notes: Set of 6 standard 32x32 RGBA icons with transparent backgrounds.
```

### 7. `tiles_field_ground`
```yaml
asset_id: tiles_field_ground
name: Green Field Meadow, Slope & Decoration Tiles
type: tile
path: assets/tiles/ground/
source: human_authored (generated by scripts/generate_field_tiles.gd)
generator_or_tool: godot
prompt_reference: Classic 2D RPG green meadow field with rolling slopes, hill banks, ramps, wildflowers, stepping stones, and bushes
author: Antigravity (Agent)
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Terrain tiles for ground layers, elevated plateaus, gentle slopes, ramps, cliffs, and environmental doodads
related_entity: assets/tiles/tileset_green_field.tres
status: approved
license_or_usage_notes: Project-authored procedural pixel-art tiles (tile_grass_base.png, tile_grass_flower_red.png, tile_grass_flower_yellow.png, tile_grass_flower_blue.png, tile_grass_tuft.png, tile_elevated_grass.png, tile_slope_north.png, tile_slope_south.png, tile_slope_east.png, tile_slope_west.png, tile_slope_corner_ne.png, tile_slope_corner_nw.png, tile_slope_corner_se.png, tile_slope_corner_sw.png, tile_slope_ramp.png, tile_cliff_edge_south.png, tile_deco_wildflowers.png, tile_deco_stepping_stones.png, tile_deco_bush.png, tile_deco_tall_grass.png)
notes: Set of 20 32x32 RGBA8 terrain tiles with zero movement collision to preserve smooth character locomotion across slopes.
```

### 8. `res_tileset_green_field`
```yaml
asset_id: res_tileset_green_field
name: Green Field Godot TileSet Resource
type: tile
path: assets/tiles/tileset_green_field.tres
source: human_authored (generated by scripts/generate_field_tiles.gd)
generator_or_tool: godot
prompt_reference: n/a
author: Antigravity (Agent)
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 20
animation: none
directions: none
format: tres
transparency: rgba_alpha
intended_use: Runtime TileSet resource driving TileMapLayers (GroundLayer, ElevationLayer, DecorationLayer) in scenes/maps/test_world.tscn
related_entity: scenes/maps/test_world.tscn
status: approved
license_or_usage_notes: Project-authored Godot TileSet resource
notes: Contains 20 TileSetAtlasSources configured with custom data layers for terrain_type and elevation.
```

---

## Planned Content Assets (Data Stubs)

These entries correspond to registered definitions in `res://data/` awaiting asset generation:

### 5. `monster_goblin_scout`
```yaml
asset_id: monster_goblin_scout
name: Goblin Scout Animated Sprite
type: monster
path: assets/monsters/goblin/goblin_scout_idle/
source: ai_generated
generator_or_tool: planned
prompt_reference: "Small agile fantasy goblin scout, green skin, holding crude daggers, classic 2D MMORPG style, low top-down perspective, crisp pixel art, 128x128, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 128x128
frame_size: 128x128
animation_frames: 4
animation: idle
directions: 4 or 8
format: png
transparency: rgba_alpha
intended_use: Visual representation for data/enemies/goblin_scout.json
related_entity: src/entities/enemy.gd
status: planned
license_or_usage_notes: To be generated
notes: Will replace tinted icon fallback in scenes/entities/enemy.tscn.
```

### 6. `monster_orc_warrior`
```yaml
asset_id: monster_orc_warrior
name: Orc Warrior Animated Sprite
type: monster
path: assets/monsters/orc/orc_warrior_idle/
source: ai_generated
generator_or_tool: planned
prompt_reference: "Brutish bulky orc warrior in crude iron scrap armor, holding heavy iron cleaver, classic 2D MMORPG style, low top-down perspective, crisp pixel art, 128x128, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 128x128
frame_size: 128x128
animation_frames: 4
animation: idle
directions: 4 or 8
format: png
transparency: rgba_alpha
intended_use: Visual representation for data/enemies/orc_warrior.json
related_entity: src/entities/enemy.gd
status: planned
license_or_usage_notes: To be generated
notes: High-health melee archetype.
```

### 7. `icon_item_herb_basic`
```yaml
asset_id: icon_item_herb_basic
name: Wild Herb Item Icon
type: icon
path: assets/icons/items/herb_basic.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Small bundle of green wild medicinal herbs tied with twine, classic RPG icon, pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Inventory icon for data/items/herb_basic.json
related_entity: src/core/item_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Consumable item icon.
```

### 8. `icon_item_potion_health`
```yaml
asset_id: icon_item_potion_health
name: Health Potion Item Icon
type: icon
path: assets/icons/items/potion_health.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Glass round-bottom potion flask filled with glowing crimson red liquid, cork stopper, classic 2D RPG inventory icon, crisp pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Inventory icon for data/items/potion_health.json
related_entity: src/core/item_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Consumable healing potion.
```

### 9. `icon_item_potion_mana`
```yaml
asset_id: icon_item_potion_mana
name: Mana Potion Item Icon
type: icon
path: assets/icons/items/potion_mana.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Tall slender glass potion vial filled with shimmering azure blue mana elixir, silver stopper, classic 2D RPG inventory icon, crisp pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Inventory icon for data/items/potion_mana.json
related_entity: src/core/item_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Consumable mana potion.
```

### 10. `icon_item_sword_iron`
```yaml
asset_id: icon_item_sword_iron
name: Iron Sword Item Icon
type: icon
path: assets/icons/items/sword_iron.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Straight iron arming sword with crossguard and leather-wrapped grip, diagonal alignment, classic 2D RPG icon, crisp pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Inventory & equipment icon for data/items/sword_iron.json
related_entity: src/core/item_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Weapon slot item.
```

### 11. `icon_item_shield_wooden`
```yaml
asset_id: icon_item_shield_wooden
name: Wooden Shield Item Icon
type: icon
path: assets/icons/items/shield_wooden.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Round wooden buckler shield with iron rim and central iron boss, classic 2D RPG icon, crisp pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Inventory & equipment icon for data/items/shield_wooden.json
related_entity: src/core/item_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Offhand slot armour.
```

### 12. `icon_skill_fireball`
```yaml
asset_id: icon_skill_fireball
name: Fireball Skill Icon
type: icon
path: assets/icons/skills/fireball.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Blazing sphere of orange and yellow fire swirling with sparks, glowing aura, classic 2D MMORPG skill icon, crisp pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Skill bar and spellbook icon for data/skills/fireball.json
related_entity: src/core/skill_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Damage spell icon.
```

### 13. `icon_skill_heal_minor`
```yaml
asset_id: icon_skill_heal_minor
name: Minor Heal Skill Icon
type: icon
path: assets/icons/skills/heal_minor.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Gentle cupped hands glowing with warm emerald-green healing energy and soft light motes, classic 2D RPG spell icon, crisp pixel art, 32x32, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 32x32
frame_size: 32x32
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Skill bar and spellbook icon for data/skills/heal_minor.json
related_entity: src/core/skill_definition.gd
status: planned
license_or_usage_notes: To be generated
notes: Healing spell icon.
```

### 14. `env_ancient_monument`
```yaml
asset_id: env_ancient_monument
name: Ancient Rune Pillar Prop
type: environment
path: assets/environment/monuments/ancient_monument.png
source: ai_generated
generator_or_tool: planned
prompt_reference: "Weathered gray stone obelisk engraved with faint glowing cyan magical runes, mossy base, low top-down perspective, classic fantasy RPG, crisp pixel art, 128x256, transparent background."
author: planned
created_date: 2026-10-01
modified_date: 2026-10-01
dimensions: 128x256
frame_size: 128x256
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: In-game sprite for AncientMonument interactive world object
related_entity: src/entities/ancient_monument.gd
status: planned
license_or_usage_notes: To be generated
notes: Interactive monument in test_world.tscn.
```

### 15. `env_green_bush_sway`
```yaml
asset_id: env_green_bush_sway
name: Small Green Bush 8-Directional Sway
type: environment
path: assets/sprites/environment/bush/
source: user_provided
generator_or_tool: ai_generated (Diffusion Pixel Art Pipeline)
prompt_reference: "A normal small green bush for a classic 2D MMORPG map, inspired by the charming pixel-art aesthetic of early 2000s Korean MMORPGs. Compact natural shape, dense cluster of many detailed green leaves, multiple layers of foliage, small overlapping leaves with varied sizes and directions, fresh medium-green and dark-green tones, subtle lighter green highlights, soft pixel-art shading, natural uneven silhouette, transparent background."
author: User / Diffusion Engine (metadata export 1.1)
created_date: 2026-10-03
modified_date: 2026-10-03
dimensions: 170x170
frame_size: 170x170
animation_frames: 9
animation: sway
directions: 8 (south, south-east, south-west, east, west, north-east, north-west, north)
format: png, tres
transparency: rgba_alpha
intended_use: In-game animated foliage decoration billboard prop across 3D meadows and hills
related_entity: src/entities/test_world_3d.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset provided for OriginalRPG
notes: 72 animated frames (9 frames x 8 directions) plus 8 static rotations and SpriteFrames resource.
```

### 16. `env_normal_tree_sway`
```yaml
asset_id: env_normal_tree_sway
name: Normal Forest Tree Animated Sway
type: environment
path: assets/sprites/environment/tree/
source: user_provided
generator_or_tool: ai_generated (Diffusion Pixel Art Pipeline)
prompt_reference: "normal tree for a classic 2D/3D MMORPG map, inspired by the charming pixel-art aesthetic of early 2000s Korean MMORPGs. Massive sturdy trunk firmly anchored to the ground with natural root flares, broad lush leafy canopy with rich green tones, gentle foliage breeze sway, crisp hand-crafted pixel art, 256x256, transparent background."
author: User / Diffusion Engine (metadata export 1.1)
created_date: 2026-10-03
modified_date: 2026-10-03
dimensions: 256x256
frame_size: 256x256
animation_frames: 9
animation: sway
directions: 1 (billboard facing)
format: png, tres
transparency: rgba_alpha
intended_use: In-game animated tree decoration billboard prop across meadows, hills, and ridgelines
related_entity: src/entities/test_world_3d.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset provided for OriginalRPG
notes: 9 animated breeze sway frames plus static rotation and SpriteFrames resource.
```

### 17. `env_ground_grass_painterly`
```yaml
asset_id: env_ground_grass_painterly
name: Harmonized Painterly Meadow Grass Surface
type: environment
path: assets/environment/ground/ground_grass_painterly.png
source: human_authored
generator_or_tool: manual
prompt_reference: "128x128 seamless tileable RPG meadow grass texture, warm olive-green and moss tones, hand-painted pixel art aesthetic of early 2000s Korean MMORPG (Ragnarok Online style), soft clumpy grass blades, subtle shaded crevices, palette harmonized with bush and tree."
author: Antigravity
created_date: 2026-10-03
modified_date: 2026-10-03
dimensions: 64x64
frame_size: 64x64
animation_frames: 1
animation: none
directions: none
format: png
transparency: opaque
intended_use: Seamless primary terrain ground albedo texture across 3D meadows and hills
related_entity: src/entities/test_world_3d.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset for OriginalRPG
notes: Seamless toroidal harmonic generation matching #3d4729 and #47512d palette.
```

### 18. `env_shadow_oval_soft`
```yaml
asset_id: env_shadow_oval_soft
name: Soft Oval Contact Shadow Decal
type: environment
path: assets/environment/shadows/shadow_oval_soft.png
source: human_authored
generator_or_tool: manual
prompt_reference: "128x128 soft feathered elliptical contact shadow decal for classic MMORPG props, cubic ease-out alpha falloff, tinted towards deep ambient moss."
author: Antigravity
created_date: 2026-10-03
modified_date: 2026-10-03
dimensions: 128x128
frame_size: 128x128
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Contact shadow decal hugging terrain directly under trees, bushes, and props
related_entity: src/entities/test_world_3d.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset for OriginalRPG
notes: 3/4 perspective elliptical ratio with feathered ambient dropoff.
```

### 19. `env_ground_tree_roots_soil`
```yaml
asset_id: env_ground_tree_roots_soil
name: Tree Roots and Soil Transition Decal
type: environment
path: assets/environment/ground/ground_tree_roots_soil.png
source: human_authored
generator_or_tool: manual
prompt_reference: "128x128 organic soil and root transition decal for tree bases, earthy walnut browns with root lobe flares fading softly into surrounding turf."
author: Antigravity
created_date: 2026-10-03
modified_date: 2026-10-03
dimensions: 128x128
frame_size: 128x128
animation_frames: 1
animation: none
directions: none
format: png
transparency: rgba_alpha
intended_use: Ground contact soil patch beneath tree trunks to blend wood roots with turf
related_entity: src/entities/test_world_3d.gd
status: approved
license_or_usage_notes: Project-exclusive custom asset for OriginalRPG
notes: Multi-lobe radial root flares blending bark into grass.
```


