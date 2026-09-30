class_name ItemPickup
extends Interactable

## World item pickup. On interact, adds the item to the interactor's inventory.
## Disappears after pickup unless respawn_time is set.

signal picked_up(item: ItemDefinition, by: Node)

@export var item: ItemDefinition = null
@export var respawn_time: float = 0.0   # 0 = no respawn

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if item != null:
		prompt_message = "Press E to pick up [%s]" % item.display_name
	interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if item == null:
		return

	# Try to get InventoryComponent from interactor or its parent
	var inv: InventoryComponent = interactor.get_node_or_null("InventoryComponent") as InventoryComponent
	if inv == null:
		return

	if inv.add_item(item):
		picked_up.emit(item, interactor)
		if respawn_time > 0.0:
			_hide_and_respawn()
		else:
			queue_free()

func _hide_and_respawn() -> void:
	is_interactable = false
	if sprite != null:
		sprite.visible = false
	await get_tree().create_timer(respawn_time).timeout
	is_interactable = true
	if sprite != null:
		sprite.visible = true
