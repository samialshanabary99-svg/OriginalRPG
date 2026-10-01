class_name ItemDefinition
extends Resource

## Data-only Resource representing a single item type.
## Loaded from res://data/items/. Instances are shared; never mutate at runtime.

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var stackable: bool = true
@export var max_stack_size: int = 99

## Item categories for future filtering / equipment slots.
enum Category { MISC, WEAPON, ARMOUR, CONSUMABLE, QUEST }
@export var category: Category = Category.MISC

## Equipment & combat modifiers
@export var equip_slot: String = ""       ## e.g. "weapon", "offhand", "head", "chest", "legs", "feet"
@export var stat_modifiers: Dictionary = {} ## e.g. {"attack": 5, "defence": 2, "max_health": 10}

## Consumable recovery values
@export var heal_amount: int = 0
@export var mana_amount: int = 0

## Helper returning stat bonuses for EquipmentComponent integration.
func get_stat_bonuses() -> Dictionary:
	return stat_modifiers

# ── Serialization (for InventoryComponent save/load) ─────────────────────────

func serialize() -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"description": description,
		"stackable": stackable,
		"max_stack_size": max_stack_size,
		"category": int(category),
		"equip_slot": equip_slot,
		"stat_modifiers": stat_modifiers,
		"heal_amount": heal_amount,
		"mana_amount": mana_amount,
	}

func deserialize(data: Dictionary) -> void:
	if data.has("item_id"):        item_id        = str(data["item_id"])
	if data.has("display_name"):   display_name   = str(data["display_name"])
	if data.has("description"):    description    = str(data["description"])
	if data.has("stackable"):      stackable      = bool(data["stackable"])
	if data.has("max_stack_size"): max_stack_size = int(data["max_stack_size"])
	if data.has("category"):
		if typeof(data["category"]) == TYPE_STRING:
			category = _category_from_string(str(data["category"]))
		else:
			category = int(data["category"]) as Category
	if data.has("equip_slot"):     equip_slot     = str(data["equip_slot"])
	if data.has("stat_modifiers") and data["stat_modifiers"] is Dictionary:
		stat_modifiers = (data["stat_modifiers"] as Dictionary).duplicate()
	if data.has("heal_amount"):    heal_amount    = int(data["heal_amount"])
	if data.has("mana_amount"):    mana_amount    = int(data["mana_amount"])

func validate() -> Array[String]:
	var errors: Array[String] = []
	if item_id.strip_edges().is_empty():
		errors.append("Item 'item_id' cannot be empty.")
	if display_name.strip_edges().is_empty():
		errors.append("Item '%s': 'display_name' cannot be empty." % item_id)
	if max_stack_size < 1:
		errors.append("Item '%s': 'max_stack_size' must be at least 1." % item_id)
	if heal_amount < 0:
		errors.append("Item '%s': 'heal_amount' cannot be negative." % item_id)
	if mana_amount < 0:
		errors.append("Item '%s': 'mana_amount' cannot be negative." % item_id)
	if category == Category.WEAPON or category == Category.ARMOUR:
		if equip_slot.strip_edges().is_empty():
			errors.append("Item '%s': Weapon/armour requires non-empty 'equip_slot'." % item_id)
	return errors

static func _category_from_string(val: String) -> Category:
	match val.to_lower():
		"weapon": return Category.WEAPON
		"armour", "armor": return Category.ARMOUR
		"consumable": return Category.CONSUMABLE
		"quest": return Category.QUEST
		_: return Category.MISC
