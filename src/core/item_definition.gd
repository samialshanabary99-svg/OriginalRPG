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

# ── Serialization (for InventoryComponent save/load) ─────────────────────────

func serialize() -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"description": description,
		"stackable": stackable,
		"max_stack_size": max_stack_size,
		"category": int(category),
	}

func deserialize(data: Dictionary) -> void:
	if data.has("item_id"):       item_id       = str(data["item_id"])
	if data.has("display_name"):  display_name  = str(data["display_name"])
	if data.has("description"):   description   = str(data["description"])
	if data.has("stackable"):     stackable     = bool(data["stackable"])
	if data.has("max_stack_size"): max_stack_size = int(data["max_stack_size"])
	if data.has("category"):      category      = int(data["category"]) as Category
