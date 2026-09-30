class_name EquipmentComponent
extends Node

## Manages equipment slots and applies stat modifiers to CharacterStatsComponent.
##
## Design:
##   - Each slot holds at most one ItemDefinition.
##   - Equipping an item calls stats.add_modifier(slot, item.stat_bonuses).
##   - Unequipping calls stats.remove_modifier(slot).
##   - Slot names are open strings so future content can define new slots freely.
##
## Standard slot names (not enforced; use consistently):
##   "weapon", "offhand", "head", "chest", "legs", "feet", "ring_1", "ring_2"
##
## Extension points:
##   - Add two-hand weapon logic (occupies "weapon" + "offhand")
##   - Add durability tracking per slot
##   - Add level requirement checks before equip

signal item_equipped(slot: String, item: ItemDefinition)
signal item_unequipped(slot: String, item: ItemDefinition)
signal equipment_changed()

## Reference to sibling CharacterStatsComponent. Set automatically in _ready.
@onready var _stats: CharacterStatsComponent = _find_stats()

## Map of slot_name → ItemDefinition (null = empty)
var slots: Dictionary = {}

func _ready() -> void:
	_stats = _find_stats()

func _find_stats() -> CharacterStatsComponent:
	var s: CharacterStatsComponent = get_parent().get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	return s

# ── Equip / Unequip ───────────────────────────────────────────────────────────

func equip(slot: String, item: ItemDefinition) -> bool:
	if item == null:
		return false
	# Remove whatever was in the slot first
	if slots.get(slot) != null:
		unequip(slot)
	slots[slot] = item
	# Apply stat bonuses if item carries any
	if _stats != null and item.has_method("get_stat_bonuses"):
		_stats.add_modifier(slot, item.get_stat_bonuses())
	item_equipped.emit(slot, item)
	equipment_changed.emit()
	return true

func unequip(slot: String) -> ItemDefinition:
	var item: ItemDefinition = slots.get(slot) as ItemDefinition
	if item == null:
		return null
	slots.erase(slot)
	if _stats != null:
		_stats.remove_modifier(slot)
	item_unequipped.emit(slot, item)
	equipment_changed.emit()
	return item

func get_equipped(slot: String) -> ItemDefinition:
	return slots.get(slot) as ItemDefinition

func is_slot_occupied(slot: String) -> bool:
	return slots.get(slot) != null

# ── Serialization ─────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var out: Dictionary = {}
	for slot: String in slots:
		var item: ItemDefinition = slots[slot] as ItemDefinition
		if item != null:
			out[slot] = item.serialize()
	return {"slots": out}

func deserialize(data: Dictionary) -> void:
	slots.clear()
	if not data.has("slots"):
		return
	for slot: String in data["slots"]:
		var item := ItemDefinition.new()
		item.deserialize(data["slots"][slot])
		# Re-equip silently (bypasses signals — called before scene is ready)
		slots[slot] = item
