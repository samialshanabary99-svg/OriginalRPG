class_name InventoryComponent
extends Node

## Stores a collection of ItemDefinition resources.
## Signals drive UI updates. Serializes for save/load.

signal item_added(item: ItemDefinition)
signal item_removed(item: ItemDefinition)
signal item_used(item: ItemDefinition)
signal inventory_changed()

@export var capacity: int = 20
@export var base_weight: int = 1200
@export var max_weight: int = 2900

var items: Array[ItemDefinition] = []
var favorites: Dictionary = {} ## Map of item_id -> bool

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
func add_item_by_id(item_id: String, quantity: int = 1) -> bool:
	var def: ItemDefinition = ContentRegistry.get_item(item_id)
	if def == null:
		return false
	var all_added: bool = true
	for _i: int in range(maxi(1, quantity)):
		if not add_item(def):
			all_added = false
			break
	return all_added

func remove_item(item: ItemDefinition) -> bool:
	var idx: int = items.find(item)
	if idx == -1:
		return false
	items.remove_at(idx)
	item_removed.emit(item)
	inventory_changed.emit()
	return true

func remove_one_by_id(item_id: String) -> bool:
	for it: ItemDefinition in items:
		if it.item_id == item_id:
			return remove_item(it)
	return false

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

# ── Favorites System ─────────────────────────────────────────────────────────

func set_favorite(item_id: String, fav: bool) -> void:
	favorites[item_id] = fav
	inventory_changed.emit()

func is_favorite(item_id: String) -> bool:
	return favorites.get(item_id, false)

func toggle_favorite(item_id: String) -> bool:
	var new_state: bool = not is_favorite(item_id)
	set_favorite(item_id, new_state)
	return new_state

# ── Stacks & UI Representation ───────────────────────────────────────────────

## Groups items into stacks: stackable items collapse by item_id with quantity;
## non-stackable items produce separate 1-item entries.
func get_stacks() -> Array[Dictionary]:
	var stacks: Array[Dictionary] = []
	var stackable_indices: Dictionary = {} # item_id -> index in stacks

	for it: ItemDefinition in items:
		if it.stackable:
			if stackable_indices.has(it.item_id):
				var idx: int = int(stackable_indices[it.item_id])
				stacks[idx]["quantity"] += 1
			else:
				var s_idx: int = stacks.size()
				stackable_indices[it.item_id] = s_idx
				stacks.append({
					"item": it,
					"quantity": 1,
					"is_favorite": is_favorite(it.item_id)
				})
		else:
			stacks.append({
				"item": it,
				"quantity": 1,
				"is_favorite": is_favorite(it.item_id)
			})

	return stacks

# ── Use & Drop Actions ───────────────────────────────────────────────────────

## Uses an item: applies consumable heal/mana recovery to user and consumes 1 item.
func use_item(item: ItemDefinition, user: Node = null) -> bool:
	if item == null or not has_item(item.item_id):
		return false

	var target_node: Node = user
	if target_node == null:
		target_node = get_parent()

	var used_effect: bool = false
	if target_node != null:
		var stats_comp: Node = target_node.get_node_or_null("CharacterStatsComponent")
		if stats_comp == null:
			stats_comp = target_node.get_node_or_null("StatsComponent")
		if stats_comp == null and "stats" in target_node and target_node.stats != null:
			stats_comp = target_node.stats
		if stats_comp == null:
			for child in target_node.get_children():
				if child is StatsComponent:
					stats_comp = child
					break

		if stats_comp != null:
			if item.heal_amount > 0 and stats_comp.has_method("heal"):
				stats_comp.heal(item.heal_amount)
				used_effect = true
			if item.mana_amount > 0 and stats_comp.has_method("restore_mana"):
				stats_comp.restore_mana(item.mana_amount)
				used_effect = true

	# Remove one instance of the item
	remove_item(item)
	item_used.emit(item)
	return true

## Drops / discards one instance of the item from the inventory.
func drop_item(item: ItemDefinition) -> bool:
	if item == null:
		return false
	return remove_item(item)

## Total current weight calculation.
func get_total_weight() -> int:
	var total: int = base_weight
	for it: ItemDefinition in items:
		var w: int = it.weight if "weight" in it else 10
		total += w
	return total

# ── Serialization ──────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var item_list: Array = []
	for item: ItemDefinition in items:
		item_list.append(item.serialize())
	return {
		"capacity": capacity,
		"base_weight": base_weight,
		"max_weight": max_weight,
		"items": item_list,
		"favorites": favorites.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	items.clear()
	favorites.clear()
	if data.has("capacity"):
		capacity = int(data["capacity"])
	if data.has("base_weight"):
		base_weight = int(data["base_weight"])
	if data.has("max_weight"):
		max_weight = int(data["max_weight"])
	if data.has("favorites") and data["favorites"] is Dictionary:
		favorites = (data["favorites"] as Dictionary).duplicate()
	if data.has("items"):
		for raw in data["items"]:
			var item := ItemDefinition.new()
			item.deserialize(raw)
			items.append(item)
