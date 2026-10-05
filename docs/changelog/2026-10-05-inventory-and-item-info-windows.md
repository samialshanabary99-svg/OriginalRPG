# Agent Change Record

```yaml
agent: Antigravity
date: 2026-10-05
task: Add Inventory window and Item Information window to OriginalRPG (UI only, wood/parchment style matching Basic Info window)
status: Completed

summary: Implemented Ragnarok Online-style 35-slot Inventory Window and Item Information Window with reusable ItemSlot component, vertical category tabs (Item, Gear, Etc., Fav.), rarity borders, stacked quantities, favorite toggling, weight capacity monitoring, drop lock protection, consumable item usage (healing/mana), item dropping, draggable title bars, hotkey I and HUD toggle button, and complete input isolation guarding 3D click-to-move and combat.

added:
  - assets/ui/icons/icon_item_consumable.png
  - assets/ui/icons/icon_item_gear.png
  - assets/ui/icons/icon_item_etc.png
  - assets/ui/icons/icon_item_fav.png
  - scenes/ui/item_slot.tscn
  - src/ui/item_slot.gd
  - scenes/ui/inventory_window.tscn
  - src/ui/inventory_window.gd
  - scenes/ui/item_info_window.tscn
  - src/ui/item_info_window.gd
  - docs/decisions/ADR-007-inventory-data-model-and-ui-bindings.md

modified:
  - docs/assets/ASSET_MANIFEST.md
  - src/core/item_definition.gd
  - src/components/inventory_component.gd
  - scenes/ui/hud.tscn
  - src/ui/hud.gd
  - tests/test_runner.gd
  - docs/tasks/IN_PROGRESS.md
  - docs/tasks/COMPLETED.md
  - PROJECT_STATUS.md
  - ARCHITECTURE.md

deleted:
  - none

renamed:
  - none

architecture_changes:
  - ADR-007: Enhanced InventoryComponent with stack aggregation (get_stacks), favorites tracking, total weight calculation, consumable execution (use_item), and item dropping (drop_item). Added weight property and text formatters to ItemDefinition.

dependencies:
  - none

tests:
  - Group CC (Tests 582-646, 65 new assertions): ItemSlot initialization, slot mouse filter isolation, quantity badge visibility, favorite star display, selection outline, slot click signal emission, clear_item reset, InventoryWindow 35-slot 7x5 grid layout, vertical tabs filtering (Item, Gear, Etc., Fav.), weight calculation and label/bar binding, ItemInfoWindow metadata rendering, consumable item use and HP healing on player, drop lock protection checkbox, item dropping when unlocked, window drag input isolation verifying Player3D movement target is unaffected, and HUD integration with hotkey I and toggle button.
  - Full automated suite: 646 / 646 tests pass (0 failures).
  - Asset validator: 257 files checked, 563 assets validated, 0 errors.

known_issues:
  - none

next_agent:
  - Standalone build compiled and verified at build/OriginalRPG.exe and root OriginalRPG.exe.
  - All inventory data bindings and UI input isolation are thoroughly covered by automated regression tests in Group CC.
```

## Detailed Notes

### 1. Aesthetic & UI Architecture
- The Inventory and Item Information windows reuse the wood title bar (`#5C3A21` border, `#8B5A2B` wood fill), parchment panel (`#F4E8D0` parchment fill, `#D8C29D` border), recessed inset panels (`#E8D8BA`), and pixel styling established by `BasicInfoWindow`.
- 4 category placeholder icons (32x32 RGBA8) were created using Pillow and registered in `docs/assets/ASSET_MANIFEST.md`:
  - `icon_item_consumable.png`
  - `icon_item_gear.png`
  - `icon_item_etc.png`
  - `icon_item_fav.png`

### 2. Reusable ItemSlot (`scenes/ui/item_slot.tscn`, `src/ui/item_slot.gd`)
- Fixed 42x42 size with `mouse_filter = MOUSE_FILTER_STOP` to block clicks from leaking to the 3D world.
- Rarity border color based on item rarity (Common: gray-brown, Rare: blue, Epic: purple, Legendary: gold).
- Gold selection frame with glowing corners.
- Dynamic quantity badge displayed in bottom-right corner when `quantity > 1`.
- Gold star badge displayed in top-right corner when flagged as favorite.
- Draws an inset empty box when no item is present.

### 3. Inventory Window (`scenes/ui/inventory_window.tscn`, `src/ui/inventory_window.gd`)
- Vertical category tabs: `Item` (consumables), `Gear` (weapons/armor), `Etc.` (misc/quest items), and `Fav.` (favorite items).
- 7x5 grid accommodating 35 slots.
- Real-time weight tracking: progress bar and text (e.g. `Weight: 1,390 / 2,900`).
- "Lock Item Drop" safety checkbox.
- Draggable title bar with viewport-safety guards, minimize button `[-]`, and close button `[X]`.

### 4. Item Information Window (`scenes/ui/item_info_window.tscn`, `src/ui/item_info_window.gd`)
- Populated when clicking any non-empty slot in the inventory.
- Displays 32x32 icon, name, category/slot type text, item weight, stacked quantity, multi-line lore description, and stat modifiers / effect descriptions.
- `Use` button: dynamically labels "Equip" for equipment or "Use" for consumables. Invoking calls `InventoryComponent.use_item()` to heal HP or restore Mana on the player.
- `Drop` button: disabled when "Lock Item Drop" is checked; removes item from inventory when unlocked.
- `Fav` button: toggles favorite flag for the item stack.

### 5. Input Isolation Verification
- All UI panels enforce `mouse_filter = Control.MOUSE_FILTER_STOP`.
- Dragging windows consumes input events and explicitly verifies that `Player3D.has_move_target` remains `false` and player position does not change.
