# TODO

## Phase 3 — Save/Load & Persistence (Next)

- **Task: Save/Load Service (SaveService)**
  - Goal: Implement JSON save/load service adhering to ADR-003 with versioning, checksum/validation, and atomic file replacement (`user://save.json`).
  - Scope: `src/services/save_service.gd`.
  - Dependencies: `Player.serialize()`, `CharacterStatsComponent.serialize()`, `InventoryComponent.serialize()`, `EquipmentComponent.serialize()`.
  - Acceptance Criteria: Roundtrip persistence test in test runner; handles missing or corrupt files safely with default fallback.

- **Task: UI Integration for Save/Load & Character Details**
  - Goal: Add Save/Load buttons to Main Menu and Pause Menu; add Character Sheet window to display Player attributes, Mana, and equipped gear.
  - Scope: `scenes/ui/`, `src/ui/`.
  - Acceptance Criteria: Player can trigger save from pause menu; loading game restores character position, stats, inventory, and equipment.

## Phase 4 — Content Expansion & Advanced Systems

- **Task: Unified Skill Combat Resolution (ADR-005)**
  - Goal: Route damaging skills through `DamageCalculator.resolve_attack()`, ensuring uniform combat events and XP awards upon defeat.
  - Scope: `src/entities/player.gd`, `src/services/damage_calculator.gd`.
  - Acceptance Criteria: Defeating an enemy with `fireball` awards XP to player and emits `combat_resolved`.

- **Task: Additional Maps & Dungeons**
  - Goal: Create multi-room or tiled dungeon map with collision boundaries and environment tiles adhering to `docs/assets/ASSET_PIPELINE.md`.
  - Scope: `scenes/maps/`, `assets/tiles/`.

- **Task: NPCs & Interactive Dialogue System**
  - Goal: Create NPC entities using `Interactable` component with branching dialogue data.
  - Scope: `src/entities/npc.gd`, `data/dialogues/`.

- **Task: QuestLog Runtime Component**
  - Goal: Implement runtime tracker for `QuestDefinition` resources with objective completion and reward distribution.
  - Scope: `src/components/quest_log_component.gd`.
