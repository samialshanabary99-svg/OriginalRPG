class_name ItemSlot
extends PanelContainer

## Reusable 42x42 item slot for inventory grid.
## Displays item icon (or category placeholder), stacked quantity,
## rarity-colored border, favorite star badge, and selection outline.

signal slot_clicked(slot: ItemSlot)

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const COLOR_EMPTY := Color(0.42, 0.28, 0.18, 0.6)
const COLOR_COMMON := Color(0.55, 0.55, 0.60, 0.95)
const COLOR_RARE := Color(0.22, 0.74, 0.97, 1.0)
const COLOR_EPIC := Color(0.75, 0.52, 0.98, 1.0)
const COLOR_LEGENDARY := Color(0.98, 0.75, 0.14, 1.0)
const COLOR_SELECTED := Color(1.0, 0.84, 0.15, 1.0)

const ICON_CONSUMABLE = preload("res://assets/ui/icons/icon_item_consumable.png")
const ICON_GEAR = preload("res://assets/ui/icons/icon_item_gear.png")
const ICON_ETC = preload("res://assets/ui/icons/icon_item_etc.png")
const ICON_FAV = preload("res://assets/ui/icons/icon_item_fav.png")

@export var item_data: ItemDefinition = null
@export var quantity: int = 0
@export var is_favorite: bool = false
@export var is_selected: bool = false

@onready var icon_rect: TextureRect = $Icon if has_node("Icon") else null
@onready var qty_badge: PanelContainer = $QtyBadge if has_node("QtyBadge") else null
@onready var qty_label: Label = $QtyBadge/Label if has_node("QtyBadge/Label") else null
@onready var fav_icon: TextureRect = $FavIcon if has_node("FavIcon") else null

func _ready() -> void:
	custom_minimum_size = Vector2(42, 42)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resolve_nodes()
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	update_display()

func _resolve_nodes() -> void:
	if icon_rect == null: icon_rect = get_node_or_null("Icon") as TextureRect
	if qty_badge == null: qty_badge = get_node_or_null("QtyBadge") as PanelContainer
	if qty_label == null: qty_label = get_node_or_null("QtyBadge/Label") as Label
	if fav_icon == null: fav_icon = get_node_or_null("FavIcon") as TextureRect

func set_item(item: ItemDefinition, qty: int = 1, fav: bool = false) -> void:
	item_data = item
	quantity = qty
	is_favorite = fav
	update_display()

func clear_item() -> void:
	item_data = null
	quantity = 0
	is_favorite = false
	is_selected = false
	update_display()

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_style()

func update_display() -> void:
	_resolve_nodes()
	if item_data == null or quantity <= 0:
		if icon_rect != null: icon_rect.visible = false
		if qty_badge != null: qty_badge.visible = false
		if fav_icon != null: fav_icon.visible = false
	else:
		if icon_rect != null:
			icon_rect.visible = true
			icon_rect.texture = get_item_icon(item_data)
		if qty_badge != null:
			qty_badge.visible = quantity > 1
			if qty_label != null:
				qty_label.text = str(quantity)
		if fav_icon != null:
			fav_icon.visible = is_favorite
	_update_style()

static func get_item_icon(item: ItemDefinition) -> Texture2D:
	if item == null:
		return null
	if item.icon != null:
		return item.icon
	match item.category:
		ItemDefinition.Category.CONSUMABLE:
			return ICON_CONSUMABLE
		ItemDefinition.Category.WEAPON, ItemDefinition.Category.ARMOUR:
			return ICON_GEAR
		ItemDefinition.Category.QUEST, ItemDefinition.Category.MISC:
			return ICON_ETC
		_:
			return ICON_ETC

func get_item_rarity(item: ItemDefinition) -> Rarity:
	if item == null:
		return Rarity.COMMON
	var id: String = item.item_id.to_lower()
	if id.contains("legendary") or id.contains("god"):
		return Rarity.LEGENDARY
	if id.contains("epic") or id.contains("crystal"):
		return Rarity.EPIC
	if item.category == ItemDefinition.Category.WEAPON or item.category == ItemDefinition.Category.ARMOUR:
		return Rarity.RARE
	if item.category == ItemDefinition.Category.CONSUMABLE and item.heal_amount >= 50:
		return Rarity.RARE
	return Rarity.COMMON

func _update_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2

	if is_selected:
		sb.bg_color = Color(0.98, 0.90, 0.75, 1.0)
		sb.border_color = COLOR_SELECTED
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
	elif item_data == null or quantity <= 0:
		sb.bg_color = Color(0.85, 0.69, 0.52, 0.5)
		sb.border_color = COLOR_EMPTY
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
	else:
		sb.bg_color = Color(0.96, 0.86, 0.72, 1.0)
		match get_item_rarity(item_data):
			Rarity.RARE:
				sb.border_color = COLOR_RARE
			Rarity.EPIC:
				sb.border_color = COLOR_EPIC
			Rarity.LEGENDARY:
				sb.border_color = COLOR_LEGENDARY
			_:
				sb.border_color = COLOR_COMMON

	add_theme_stylebox_override("panel", sb)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			slot_clicked.emit(self)
