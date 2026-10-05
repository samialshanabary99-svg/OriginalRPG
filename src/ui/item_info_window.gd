class_name ItemInfoWindow
extends Control

## Item Information window displaying detailed metadata, lore, stat bonuses,
## and action controls (Use/Equip, Drop, Favorite toggle).
##
## Styling matches Ragnarok Online wood/parchment theme of Basic Info Window.

signal window_closed()
signal window_minimized(is_minimized: bool)
signal item_used(item: ItemDefinition)
signal item_dropped(item: ItemDefinition)
signal favorite_toggled(item: ItemDefinition, is_fav: bool)

@onready var title_bar: PanelContainer = $WindowFrame/TitleBar if has_node("WindowFrame/TitleBar") else null
@onready var btn_minimize: Button = $WindowFrame/TitleBar/HBox/BtnMinimize if has_node("WindowFrame/TitleBar/HBox/BtnMinimize") else null
@onready var btn_close: Button = $WindowFrame/TitleBar/HBox/BtnClose if has_node("WindowFrame/TitleBar/HBox/BtnClose") else null

@onready var content_vbox: VBoxContainer = $WindowFrame/MainPanel/Margin/ContentVBox if has_node("WindowFrame/MainPanel/Margin/ContentVBox") else null

# Header controls
@onready var icon_rect: TextureRect = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/IconBox/IconTexture if has_node("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/IconBox/IconTexture") else null
@onready var label_name: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/LabelName if has_node("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/LabelName") else null
@onready var label_type: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/LabelType if has_node("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/LabelType") else null
@onready var label_weight: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/SubRow/LabelWeight if has_node("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/SubRow/LabelWeight") else null
@onready var label_quantity: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/SubRow/LabelQuantity if has_node("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/SubRow/LabelQuantity") else null

# Description & stats
@onready var label_desc: Label = $WindowFrame/MainPanel/Margin/ContentVBox/DetailsPanel/Margin/DetailsVBox/LabelDesc if has_node("WindowFrame/MainPanel/Margin/ContentVBox/DetailsPanel/Margin/DetailsVBox/LabelDesc") else null
@onready var label_stats: Label = $WindowFrame/MainPanel/Margin/ContentVBox/DetailsPanel/Margin/DetailsVBox/StatsBox/LabelStats if has_node("WindowFrame/MainPanel/Margin/ContentVBox/DetailsPanel/Margin/DetailsVBox/StatsBox/LabelStats") else null

# Action buttons
@onready var btn_fav: Button = $WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnFav if has_node("WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnFav") else null
@onready var btn_use: Button = $WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnUse if has_node("WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnUse") else null
@onready var btn_drop: Button = $WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnDrop if has_node("WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnDrop") else null

# Runtime state
var current_item: ItemDefinition = null
var current_quantity: int = 0
var is_favorite: bool = false
var is_drop_locked: bool = false

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _is_minimized: bool = false
var _bound_player: Node = null
var _bound_inventory: InventoryComponent = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resolve_nodes()

	if btn_minimize != null and not btn_minimize.pressed.is_connected(_on_minimize_pressed):
		btn_minimize.pressed.connect(_on_minimize_pressed)
	if btn_close != null and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	if title_bar != null and not title_bar.gui_input.is_connected(_on_title_bar_gui_input):
		title_bar.gui_input.connect(_on_title_bar_gui_input)

	if btn_fav != null and not btn_fav.pressed.is_connected(_on_fav_pressed):
		btn_fav.pressed.connect(_on_fav_pressed)
	if btn_use != null and not btn_use.pressed.is_connected(_on_use_pressed):
		btn_use.pressed.connect(_on_use_pressed)
	if btn_drop != null and not btn_drop.pressed.is_connected(_on_drop_pressed):
		btn_drop.pressed.connect(_on_drop_pressed)

	clear_display()

func _resolve_nodes() -> void:
	if title_bar == null: title_bar = get_node_or_null("WindowFrame/TitleBar") as PanelContainer
	if btn_minimize == null: btn_minimize = get_node_or_null("WindowFrame/TitleBar/HBox/BtnMinimize") as Button
	if btn_close == null: btn_close = get_node_or_null("WindowFrame/TitleBar/HBox/BtnClose") as Button
	if content_vbox == null: content_vbox = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox") as VBoxContainer
	if icon_rect == null: icon_rect = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/IconBox/IconTexture") as TextureRect
	if label_name == null: label_name = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/LabelName") as Label
	if label_type == null: label_type = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/LabelType") as Label
	if label_weight == null: label_weight = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/SubRow/LabelWeight") as Label
	if label_quantity == null: label_quantity = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/HeaderCard/HBox/InfoCol/SubRow/LabelQuantity") as Label
	if label_desc == null: label_desc = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/DetailsPanel/Margin/DetailsVBox/LabelDesc") as Label
	if label_stats == null: label_stats = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/DetailsPanel/Margin/DetailsVBox/StatsBox/LabelStats") as Label
	if btn_fav == null: btn_fav = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnFav") as Button
	if btn_use == null: btn_use = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnUse") as Button
	if btn_drop == null: btn_drop = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/ActionHBox/BtnDrop") as Button

func bind_player(player: Node) -> void:
	if player == null:
		return
	_bound_player = player
	var inv: InventoryComponent = null
	if "inventory" in player and player.inventory is InventoryComponent:
		inv = player.inventory
	elif player.get_node_or_null("InventoryComponent") != null:
		inv = player.get_node("InventoryComponent") as InventoryComponent
	else:
		for child in player.get_children():
			if child is InventoryComponent:
				inv = child
				break
	if inv != null:
		bind_inventory(inv)

func bind_inventory(inv: InventoryComponent) -> void:
	_bound_inventory = inv

func set_drop_locked(locked: bool) -> void:
	is_drop_locked = locked
	_update_drop_button_state()

func set_item(item: ItemDefinition, qty: int = 1, fav: bool = false) -> void:
	_resolve_nodes()
	current_item = item
	current_quantity = qty
	is_favorite = fav

	if item == null:
		clear_display()
		return

	if icon_rect != null:
		icon_rect.texture = ItemSlot.get_item_icon(item)
		icon_rect.visible = true

	if label_name != null:
		label_name.text = item.display_name

	if label_type != null:
		label_type.text = "Type: " + item.get_type_text()

	if label_weight != null:
		var w: int = item.weight if "weight" in item else 10
		label_weight.text = "Weight: %d" % w

	if label_quantity != null:
		label_quantity.text = "Qty: %d" % qty

	if label_desc != null:
		label_desc.text = item.description if not item.description.is_empty() else "No description."

	if label_stats != null:
		label_stats.text = item.get_stat_text()

	if btn_fav != null:
		btn_fav.disabled = false
		btn_fav.text = "★ Fav" if is_favorite else "☆ Fav"

	if btn_use != null:
		btn_use.disabled = false
		if item.category == ItemDefinition.Category.WEAPON or item.category == ItemDefinition.Category.ARMOUR:
			btn_use.text = "Equip"
		elif item.category == ItemDefinition.Category.CONSUMABLE:
			btn_use.text = "Use"
		else:
			btn_use.text = "Use"
			btn_use.disabled = true

	_update_drop_button_state()

func clear_display() -> void:
	_resolve_nodes()
	current_item = null
	current_quantity = 0
	is_favorite = false

	if icon_rect != null: icon_rect.texture = null
	if label_name != null: label_name.text = "Select an item"
	if label_type != null: label_type.text = "Type: —"
	if label_weight != null: label_weight.text = "Weight: —"
	if label_quantity != null: label_quantity.text = "Qty: 0"
	if label_desc != null: label_desc.text = "Click any item in the inventory to view its details, effects, and actions."
	if label_stats != null: label_stats.text = "No item selected"

	if btn_fav != null:
		btn_fav.disabled = true
		btn_fav.text = "☆ Fav"
	if btn_use != null:
		btn_use.disabled = true
		btn_use.text = "Use"
	if btn_drop != null:
		btn_drop.disabled = true

func _update_drop_button_state() -> void:
	if btn_drop != null:
		btn_drop.disabled = (current_item == null or is_drop_locked)
		if is_drop_locked:
			btn_drop.tooltip_text = "Item drop is locked by inventory security."
		else:
			btn_drop.tooltip_text = "Discard 1 item from inventory."

func _on_fav_pressed() -> void:
	if current_item == null:
		return
	is_favorite = not is_favorite
	if _bound_inventory != null:
		_bound_inventory.set_favorite(current_item.item_id, is_favorite)
	if btn_fav != null:
		btn_fav.text = "★ Fav" if is_favorite else "☆ Fav"
	favorite_toggled.emit(current_item, is_favorite)

func _on_use_pressed() -> void:
	if current_item == null:
		return
	if _bound_inventory != null:
		var ok: bool = _bound_inventory.use_item(current_item, _bound_player)
		if ok:
			item_used.emit(current_item)

func _on_drop_pressed() -> void:
	if current_item == null or is_drop_locked:
		return
	if _bound_inventory != null:
		var ok: bool = _bound_inventory.drop_item(current_item)
		if ok:
			item_dropped.emit(current_item)

func toggle_window() -> void:
	visible = not visible

func _on_minimize_pressed() -> void:
	_is_minimized = not _is_minimized
	if content_vbox != null:
		content_vbox.visible = not _is_minimized
	window_minimized.emit(_is_minimized)

func _on_close_pressed() -> void:
	visible = false
	window_closed.emit()

# ── Draggable Window Handling ────────────────────────────────────────────────
func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				if is_inside_tree() and get_viewport() != null:
					_drag_offset = get_global_mouse_position() - global_position
				else:
					_drag_offset = Vector2.ZERO
			else:
				_is_dragging = false

func _process(_delta: float) -> void:
	if _is_dragging:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if is_inside_tree() and get_viewport() != null:
				global_position = get_global_mouse_position() - _drag_offset
		else:
			_is_dragging = false
