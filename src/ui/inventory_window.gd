class_name InventoryWindow
extends Control

## Ragnarok Online style Inventory Window.
## Features:
##   - Vertical tabs: Item, Gear, Etc., Fav.
##   - 7x5 grid (35 slots) using ItemSlot scene
##   - Weight encumbrance bar & label
##   - "Lock Item Drop" toggle
##   - Draggable title bar, minimize [-], close [X]
##   - Fully signal-bound to InventoryComponent & CharacterStatsComponent

signal window_closed()
signal window_minimized(is_minimized: bool)
signal item_selected(item: ItemDefinition, quantity: int, is_favorite: bool)
signal lock_drop_toggled(is_locked: bool)

const ITEM_SLOT_SCENE: PackedScene = preload("res://scenes/ui/item_slot.tscn")

@onready var title_bar: PanelContainer = $WindowFrame/TitleBar if has_node("WindowFrame/TitleBar") else null
@onready var btn_minimize: Button = $WindowFrame/TitleBar/HBox/BtnMinimize if has_node("WindowFrame/TitleBar/HBox/BtnMinimize") else null
@onready var btn_close: Button = $WindowFrame/TitleBar/HBox/BtnClose if has_node("WindowFrame/TitleBar/HBox/BtnClose") else null

@onready var main_panel: PanelContainer = $WindowFrame/MainPanel if has_node("WindowFrame/MainPanel") else null
@onready var content_vbox: VBoxContainer = $WindowFrame/MainPanel/Margin/ContentVBox if has_node("WindowFrame/MainPanel/Margin/ContentVBox") else null
@onready var grid_container: GridContainer = $WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/GridPanel/Margin/GridContainer if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/GridPanel/Margin/GridContainer") else null

@onready var tab_item: Button = $WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabItem if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabItem") else null
@onready var tab_gear: Button = $WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabGear if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabGear") else null
@onready var tab_etc: Button = $WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabEtc if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabEtc") else null
@onready var tab_fav: Button = $WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabFav if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabFav") else null

@onready var lock_drop_checkbox: CheckBox = $WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/StatusHBox/LockDropCheckBox if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/StatusHBox/LockDropCheckBox") else null
@onready var label_weight: Label = $WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/StatusHBox/LabelWeight if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/StatusHBox/LabelWeight") else null
@onready var weight_bar: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/WeightBar if has_node("WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/WeightBar") else null

# Runtime state
var current_tab: String = "item" ## "item", "gear", "etc", "fav"
var is_drop_locked: bool = false
var slots: Array[ItemSlot] = []
var selected_slot: ItemSlot = null

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _is_minimized: bool = false
var _bound_player: Node = null
var _bound_inventory: InventoryComponent = null

const TOTAL_SLOTS: int = 35 ## 7 cols x 5 rows

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resolve_nodes()

	if btn_minimize != null and not btn_minimize.pressed.is_connected(_on_minimize_pressed):
		btn_minimize.pressed.connect(_on_minimize_pressed)
	if btn_close != null and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	if title_bar != null and not title_bar.gui_input.is_connected(_on_title_bar_gui_input):
		title_bar.gui_input.connect(_on_title_bar_gui_input)

	if tab_item != null and not tab_item.pressed.is_connected(func(): switch_tab("item")):
		tab_item.pressed.connect(func(): switch_tab("item"))
	if tab_gear != null and not tab_gear.pressed.is_connected(func(): switch_tab("gear")):
		tab_gear.pressed.connect(func(): switch_tab("gear"))
	if tab_etc != null and not tab_etc.pressed.is_connected(func(): switch_tab("etc")):
		tab_etc.pressed.connect(func(): switch_tab("etc"))
	if tab_fav != null and not tab_fav.pressed.is_connected(func(): switch_tab("fav")):
		tab_fav.pressed.connect(func(): switch_tab("fav"))

	if lock_drop_checkbox != null and not lock_drop_checkbox.toggled.is_connected(_on_lock_drop_toggled):
		lock_drop_checkbox.toggled.connect(_on_lock_drop_toggled)

	_init_slots()
	switch_tab("item")

func _resolve_nodes() -> void:
	if title_bar == null: title_bar = get_node_or_null("WindowFrame/TitleBar") as PanelContainer
	if btn_minimize == null: btn_minimize = get_node_or_null("WindowFrame/TitleBar/HBox/BtnMinimize") as Button
	if btn_close == null: btn_close = get_node_or_null("WindowFrame/TitleBar/HBox/BtnClose") as Button
	if main_panel == null: main_panel = get_node_or_null("WindowFrame/MainPanel") as PanelContainer
	if content_vbox == null: content_vbox = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox") as VBoxContainer
	if grid_container == null: grid_container = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/GridPanel/Margin/GridContainer") as GridContainer
	if tab_item == null: tab_item = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabItem") as Button
	if tab_gear == null: tab_gear = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabGear") as Button
	if tab_etc == null: tab_etc = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabEtc") as Button
	if tab_fav == null: tab_fav = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BodyHBox/TabVBox/TabFav") as Button
	if lock_drop_checkbox == null: lock_drop_checkbox = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/StatusHBox/LockDropCheckBox") as CheckBox
	if label_weight == null: label_weight = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/StatusHBox/LabelWeight") as Label
	if weight_bar == null: weight_bar = get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/BottomSection/WeightBar") as ProgressBar

func _init_slots() -> void:
	if grid_container == null:
		return
	slots.clear()
	for child in grid_container.get_children():
		if child is ItemSlot:
			slots.append(child as ItemSlot)
			if not (child as ItemSlot).slot_clicked.is_connected(_on_slot_clicked):
				(child as ItemSlot).slot_clicked.connect(_on_slot_clicked)

	while slots.size() < TOTAL_SLOTS:
		var slot: ItemSlot = ITEM_SLOT_SCENE.instantiate() as ItemSlot
		grid_container.add_child(slot)
		slot.slot_clicked.connect(_on_slot_clicked)
		slots.append(slot)

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
	if inv == null:
		return
	_bound_inventory = inv
	if not inv.inventory_changed.is_connected(refresh_grid):
		inv.inventory_changed.connect(refresh_grid)
	refresh_grid()

func switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	_update_tab_button_styles()
	refresh_grid()

func _update_tab_button_styles() -> void:
	var tabs := {"item": tab_item, "gear": tab_gear, "etc": tab_etc, "fav": tab_fav}
	for t in tabs:
		var btn: Button = tabs[t]
		if btn != null:
			if t == current_tab:
				btn.modulate = Color(1.2, 1.2, 1.2, 1.0)
			else:
				btn.modulate = Color(0.85, 0.85, 0.85, 1.0)

func refresh_grid() -> void:
	_resolve_nodes()
	if slots.is_empty():
		_init_slots()

	var all_stacks: Array[Dictionary] = []
	if _bound_inventory != null:
		all_stacks = _bound_inventory.get_stacks()

	# Filter stacks based on active tab
	var filtered: Array[Dictionary] = []
	for s: Dictionary in all_stacks:
		var item: ItemDefinition = s["item"] as ItemDefinition
		if item == null:
			continue
		match current_tab:
			"item":
				if item.category == ItemDefinition.Category.CONSUMABLE:
					filtered.append(s)
			"gear":
				if item.category == ItemDefinition.Category.WEAPON or item.category == ItemDefinition.Category.ARMOUR:
					filtered.append(s)
			"etc":
				if item.category == ItemDefinition.Category.MISC or item.category == ItemDefinition.Category.QUEST:
					filtered.append(s)
			"fav":
				if bool(s.get("is_favorite", false)):
					filtered.append(s)

	# Populate slots
	selected_slot = null
	for i in range(TOTAL_SLOTS):
		if i < slots.size():
			var slot: ItemSlot = slots[i]
			if i < filtered.size():
				var entry: Dictionary = filtered[i]
				slot.set_item(entry["item"], int(entry["quantity"]), bool(entry["is_favorite"]))
			else:
				slot.clear_item()

	# Auto-select the first occupied slot in current tab
	if not filtered.is_empty() and slots.size() > 0:
		_select_slot(slots[0])
	else:
		item_selected.emit(null, 0, false)

	_update_weight_display()

func _update_weight_display() -> void:
	var cur_w: int = 1200
	var max_w: int = 2900
	if _bound_inventory != null:
		cur_w = _bound_inventory.get_total_weight()
		max_w = _bound_inventory.max_weight

	if label_weight != null:
		label_weight.text = "Weight: %s / %s" % [_format_number(cur_w), _format_number(max_w)]
	if weight_bar != null:
		weight_bar.max_value = maxi(max_w, 1)
		weight_bar.value = cur_w

func _on_slot_clicked(slot: ItemSlot) -> void:
	_select_slot(slot)

func _select_slot(slot: ItemSlot) -> void:
	for s in slots:
		s.set_selected(false)
	selected_slot = slot
	if selected_slot != null:
		selected_slot.set_selected(true)
		if selected_slot.item_data != null:
			item_selected.emit(selected_slot.item_data, selected_slot.quantity, selected_slot.is_favorite)
		else:
			item_selected.emit(null, 0, false)
	else:
		item_selected.emit(null, 0, false)

func _on_lock_drop_toggled(pressed: bool) -> void:
	is_drop_locked = pressed
	lock_drop_toggled.emit(pressed)

func toggle_window() -> void:
	visible = not visible
	if visible:
		refresh_grid()

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

static func _format_number(n: int) -> String:
	var s: String = str(absi(n))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	if n < 0:
		res = "-" + res
	return res
