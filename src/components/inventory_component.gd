class_name InventoryComponent
extends Node

## Stores a collection of ItemDefinition resources.
## Signals drive UI updates. Serializes for save/load.

signal item_added(item: ItemDefinition)
signal item_removed(item: ItemDefinition)
signal inventory_changed()

@export var capacity: int = 20

var items: Array[ItemDefinition] = []

func add_item(item: ItemDefinition) -> bool:
	if item == null:
		return false
	if not item.stackable and items.size() >= capacity:
		return false
	items.append(item)
	item_added.emit(item)
	inventory_changed.emit()
	return true

## Convenience method to add an item by its registry ID.
func add_item_by_id(item_id: String) -> bool:
	var def: ItemDefinition = ContentRegistry.get_item(item_id)
	if def == null:
		return false
	return add_item(def)

func remove_item(item: ItemDefinition) -> bool:
	var idx: int = items.find(item)
	if idx == -1:
		return false
	items.remove_at(idx)
	item_removed.emit(item)
	inventory_changed.emit()
	return true

func has_item(item_id: String) -> bool:
	for it: ItemDefinition in items:
		if it.item_id == item_id:
			return true
	return false

func count_item(item_id: String) -> int:
	var total: int = 0
	for it: ItemDefinition in items:
		if it.item_id == item_id:
			total += 1
	return total

func is_full() -> bool:
	return items.size() >= capacity

# ── Serialization ──────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var item_list: Array = []
	for item: ItemDefinition in items:
		item_list.append(item.serialize())
	return {
		"capacity": capacity,
		"items": item_list
	}

func deserialize(data: Dictionary) -> void:
	items.clear()
	if data.has("capacity"):
		capacity = int(data["capacity"])
	if data.has("items"):
		for raw in data["items"]:
			var item := ItemDefinition.new()
			item.deserialize(raw)
			items.append(item)
