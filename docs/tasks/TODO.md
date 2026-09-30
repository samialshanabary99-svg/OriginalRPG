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

- **Task: Equipment Stat Calculation Binding**
  - Goal: Extend `ItemDefinition` with `stat_bonuses` dictionary so equipped weapons/armour automatically pass bonuses to `EquipmentComponent` and `CharacterStatsComponent`.
  - Scope: `src/core/item_definition.gd`, `data/items/`.

- **Task: Skills & Spellcasting System**
  - Goal: Implement skill execution consuming Mana via `CharacterStatsComponent.spend_mana()` with casting state (`CharacterState.CASTING`).
  - Scope: `src/core/skill_definition.gd`, `src/components/skills_component.gd`.
