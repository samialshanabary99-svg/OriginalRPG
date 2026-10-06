class_name ItemEditorWindow
extends Control

## Ragnarok-Style Item Info Editor Window (ItemInfo & Properties Editor).
## Allows visual inspection and editing of item properties, descriptions, stats, and image resources.
## Saves changes atomically to disk (res://data/items/<id>.json and res://data/iteminfo.json)
## and reloads ContentRegistry in real time.

signal item_saved(item_id: String)
signal item_deleted(item_id: String)

@onready var title_bar: PanelContainer = $WindowFrame/TitleBar if has_node("WindowFrame/TitleBar") else null
@onready var btn_close: Button = $WindowFrame/TitleBar/HBox/BtnClose if has_node("WindowFrame/TitleBar/HBox/BtnClose") else null
@onready var btn_minimize: Button = $WindowFrame/TitleBar/HBox/BtnMinimize if has_node("WindowFrame/TitleBar/HBox/BtnMinimize") else null
@onready var main_panel: PanelContainer = $WindowFrame/MainPanel if has_node("WindowFrame/MainPanel") else null

# Left column controls
@onready var search_input: LineEdit = $WindowFrame/MainPanel/Margin/HBox/LeftCol/SearchBox/SearchInput if has_node("WindowFrame/MainPanel/Margin/HBox/LeftCol/SearchBox/SearchInput") else null
@onready var item_list: ItemList = $WindowFrame/MainPanel/Margin/HBox/LeftCol/ItemList if has_node("WindowFrame/MainPanel/Margin/HBox/LeftCol/ItemList") else null
@onready var btn_new_item: Button = $WindowFrame/MainPanel/Margin/HBox/LeftCol/ListActions/BtnNewItem if has_node("WindowFrame/MainPanel/Margin/HBox/LeftCol/ListActions/BtnNewItem") else null
@onready var btn_delete_item: Button = $WindowFrame/MainPanel/Margin/HBox/LeftCol/ListActions/BtnDelete if has_node("WindowFrame/MainPanel/Margin/HBox/LeftCol/ListActions/BtnDelete") else null

# Right column inspector controls
@onready var edit_id: LineEdit = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowId/EditId if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowId/EditId") else null
@onready var edit_name: LineEdit = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowName/EditName if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowName/EditName") else null
@onready var opt_category: OptionButton = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCategory/OptCategory if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCategory/OptCategory") else null
@onready var edit_desc: TextEdit = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/DescBox/EditDesc if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/DescBox/EditDesc") else null

# Visual / Image controls
@onready var edit_icon_path: LineEdit = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/PathRow/EditIconPath if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/PathRow/EditIconPath") else null
@onready var preview_icon: TextureRect = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/PreviewBox/PreviewIcon if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/PreviewBox/PreviewIcon") else null
@onready var opt_preset_icons: OptionButton = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/PathRow/OptPresetIcons if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/PathRow/OptPresetIcons") else null

# Attributes & Stats
@onready var spin_weight: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowWeight/SpinWeight if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowWeight/SpinWeight") else null
@onready var spin_price: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowPrice/SpinPrice if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowPrice/SpinPrice") else null
@onready var chk_stackable: CheckBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowStack/ChkStackable if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowStack/ChkStackable") else null
@onready var spin_max_stack: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowStack/SpinMaxStack if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowStack/SpinMaxStack") else null

@onready var spin_heal: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowHeal/SpinHeal if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowHeal/SpinHeal") else null
@onready var spin_mana: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowMana/SpinMana if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowMana/SpinMana") else null

@onready var opt_equip_slot: OptionButton = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowEquip/OptEquipSlot if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowEquip/OptEquipSlot") else null
@onready var spin_attack: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCombatStats/SpinAttack if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCombatStats/SpinAttack") else null
@onready var spin_defence: SpinBox = $WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCombatStats/SpinDefence if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCombatStats/SpinDefence") else null

# Actions & Feedback
@onready var btn_save: Button = $WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnSave if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnSave") else null
@onready var btn_revert: Button = $WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnRevert if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnRevert") else null
@onready var btn_give_bag: Button = $WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnGiveBag if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnGiveBag") else null
@onready var label_status: Label = $WindowFrame/MainPanel/Margin/HBox/RightCol/LabelStatus if has_node("WindowFrame/MainPanel/Margin/HBox/RightCol/LabelStatus") else null

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _is_minimized: bool = false
var _items_cache: Array[ItemDefinition] = []
var _selected_item_id: String = ""

const PRESET_ICONS: Array[Dictionary] = [
	{"name": "Apple (32px)", "path": "res://assets/icons/items/icon_item_apple.png"},
	{"name": "Consumable Potion (32px)", "path": "res://assets/ui/icons/icon_item_consumable.png"},
	{"name": "Gear / Weapon (32px)", "path": "res://assets/ui/icons/icon_item_gear.png"},
	{"name": "Etc / Misc (32px)", "path": "res://assets/ui/icons/icon_item_etc.png"},
	{"name": "Favorite Star (32px)", "path": "res://assets/ui/icons/icon_item_fav.png"},
	{"name": "HP Heart (32px)", "path": "res://assets/ui/icons/icon_hp.png"},
	{"name": "SP Orb (32px)", "path": "res://assets/ui/icons/icon_sp.png"},
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resolve_nodes()
	_setup_options()
	_connect_signals()
	refresh_item_list()
	if not _items_cache.is_empty():
		select_item(_items_cache[0].item_id)

func _resolve_nodes() -> void:
	if title_bar == null: title_bar = get_node_or_null("WindowFrame/TitleBar") as PanelContainer
	if btn_close == null: btn_close = get_node_or_null("WindowFrame/TitleBar/HBox/BtnClose") as Button
	if btn_minimize == null: btn_minimize = get_node_or_null("WindowFrame/TitleBar/HBox/BtnMinimize") as Button
	if main_panel == null: main_panel = get_node_or_null("WindowFrame/MainPanel") as PanelContainer

	if search_input == null: search_input = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/LeftCol/SearchBox/SearchInput") as LineEdit
	if item_list == null: item_list = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/LeftCol/ItemList") as ItemList
	if btn_new_item == null: btn_new_item = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/LeftCol/ListActions/BtnNewItem") as Button
	if btn_delete_item == null: btn_delete_item = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/LeftCol/ListActions/BtnDelete") as Button

	if edit_id == null: edit_id = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowId/EditId") as LineEdit
	if edit_name == null: edit_name = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowName/EditName") as LineEdit
	if opt_category == null: opt_category = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCategory/OptCategory") as OptionButton
	if edit_desc == null: edit_desc = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/DescBox/EditDesc") as TextEdit

	if edit_icon_path == null: edit_icon_path = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/HBox/PathCol/EditIconPath") as LineEdit
	if preview_icon == null: preview_icon = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/HBox/PreviewBox/PreviewIcon") as TextureRect
	if opt_preset_icons == null: opt_preset_icons = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/ImageBox/HBox/PathCol/OptPresetIcons") as OptionButton

	if spin_weight == null: spin_weight = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowWeight/SpinWeight") as SpinBox
	if spin_price == null: spin_price = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowPrice/SpinPrice") as SpinBox
	if chk_stackable == null: chk_stackable = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowStack/ChkStackable") as CheckBox
	if spin_max_stack == null: spin_max_stack = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowStack/SpinMaxStack") as SpinBox

	if spin_heal == null: spin_heal = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowHeal/SpinHeal") as SpinBox
	if spin_mana == null: spin_mana = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowMana/SpinMana") as SpinBox

	if opt_equip_slot == null: opt_equip_slot = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowEquip/OptEquipSlot") as OptionButton
	if spin_attack == null: spin_attack = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCombatStats/SpinAttack") as SpinBox
	if spin_defence == null: spin_defence = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/Scroll/Fields/RowCombatStats/SpinDefence") as SpinBox

	if btn_save == null: btn_save = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnSave") as Button
	if btn_revert == null: btn_revert = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnRevert") as Button
	if btn_give_bag == null: btn_give_bag = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/ActionRow/BtnGiveBag") as Button
	if label_status == null: label_status = get_node_or_null("WindowFrame/MainPanel/Margin/HBox/RightCol/LabelStatus") as Label

func _setup_options() -> void:
	if opt_category != null:
		opt_category.clear()
		opt_category.add_item("Misc (Etc)", int(ItemDefinition.Category.MISC))
		opt_category.add_item("Weapon", int(ItemDefinition.Category.WEAPON))
		opt_category.add_item("Armor", int(ItemDefinition.Category.ARMOUR))
		opt_category.add_item("Consumable", int(ItemDefinition.Category.CONSUMABLE))
		opt_category.add_item("Quest Item", int(ItemDefinition.Category.QUEST))

	if opt_equip_slot != null:
		opt_equip_slot.clear()
		opt_equip_slot.add_item("(None / Not Gear)", 0)
		opt_equip_slot.add_item("weapon", 1)
		opt_equip_slot.add_item("offhand", 2)
		opt_equip_slot.add_item("head", 3)
		opt_equip_slot.add_item("chest", 4)
		opt_equip_slot.add_item("legs", 5)
		opt_equip_slot.add_item("feet", 6)

	if opt_preset_icons != null:
		opt_preset_icons.clear()
		opt_preset_icons.add_item("-- Select Icon Preset --", 0)
		for idx: int in range(PRESET_ICONS.size()):
			var p: Dictionary = PRESET_ICONS[idx]
			opt_preset_icons.add_item(p["name"], idx + 1)

func _connect_signals() -> void:
	if title_bar != null and not title_bar.gui_input.is_connected(_on_title_bar_gui_input):
		title_bar.gui_input.connect(_on_title_bar_gui_input)
	if btn_close != null and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	if btn_minimize != null and not btn_minimize.pressed.is_connected(_on_minimize_pressed):
		btn_minimize.pressed.connect(_on_minimize_pressed)

	if item_list != null and not item_list.item_selected.is_connected(_on_item_selected):
		item_list.item_selected.connect(_on_item_selected)
	if search_input != null and not search_input.text_changed.is_connected(_on_search_changed):
		search_input.text_changed.connect(_on_search_changed)
	if btn_new_item != null and not btn_new_item.pressed.is_connected(_on_new_item_pressed):
		btn_new_item.pressed.connect(_on_new_item_pressed)
	if btn_delete_item != null and not btn_delete_item.pressed.is_connected(_on_delete_item_pressed):
		btn_delete_item.pressed.connect(_on_delete_item_pressed)

	if edit_icon_path != null and not edit_icon_path.text_changed.is_connected(_on_icon_path_changed):
		edit_icon_path.text_changed.connect(_on_icon_path_changed)
	if opt_preset_icons != null and not opt_preset_icons.item_selected.is_connected(_on_preset_icon_selected):
		opt_preset_icons.item_selected.connect(_on_preset_icon_selected)

	if btn_save != null and not btn_save.pressed.is_connected(_on_save_pressed):
		btn_save.pressed.connect(_on_save_pressed)
	if btn_revert != null and not btn_revert.pressed.is_connected(_on_revert_pressed):
		btn_revert.pressed.connect(_on_revert_pressed)
	if btn_give_bag != null and not btn_give_bag.pressed.is_connected(_on_give_bag_pressed):
		btn_give_bag.pressed.connect(_on_give_bag_pressed)

# ── List & Selection ─────────────────────────────────────────────────────────

func refresh_item_list(filter_text: String = "") -> void:
	ContentRegistry.ensure_initialized()
	_items_cache = ContentRegistry.get_all_items()
	_items_cache.sort_custom(func(a: ItemDefinition, b: ItemDefinition) -> bool:
		return a.item_id < b.item_id
	)

	if item_list == null:
		return
	item_list.clear()

	var filter_lower: String = filter_text.strip_edges().to_lower()
	var selected_idx: int = -1

	for idx: int in range(_items_cache.size()):
		var item: ItemDefinition = _items_cache[idx]
		if not filter_lower.is_empty():
			var match_id: bool = item.item_id.to_lower().contains(filter_lower)
			var match_name: bool = item.display_name.to_lower().contains(filter_lower)
			if not match_id and not match_name:
				continue

		var label: String = "%s (%s)" % [item.display_name, item.item_id]
		var icon_tex: Texture2D = item.get_icon()
		var list_idx: int = item_list.add_item(label, icon_tex)
		item_list.set_item_metadata(list_idx, item.item_id)

		if item.item_id == _selected_item_id:
			selected_idx = list_idx

	if selected_idx >= 0:
		item_list.select(selected_idx)

func select_item(id: String) -> void:
	_selected_item_id = id
	var def: ItemDefinition = ContentRegistry.get_item(id)
	if def == null:
		return
	_populate_fields(def)
	_set_status("Loaded item: " + id, Color(0.2, 0.6, 0.2))

func _populate_fields(def: ItemDefinition) -> void:
	if edit_id != null: edit_id.text = def.item_id
	if edit_name != null: edit_name.text = def.display_name
	if edit_desc != null: edit_desc.text = def.description

	if opt_category != null:
		for i in range(opt_category.item_count):
			if opt_category.get_item_id(i) == int(def.category):
				opt_category.selected = i
				break

	if edit_icon_path != null: edit_icon_path.text = def.icon_path
	_update_preview_icon(def.icon_path)

	if spin_weight != null: spin_weight.value = def.weight
	if spin_price != null: spin_price.value = def.price
	if chk_stackable != null: chk_stackable.button_pressed = def.stackable
	if spin_max_stack != null: spin_max_stack.value = def.max_stack_size

	if spin_heal != null: spin_heal.value = def.heal_amount
	if spin_mana != null: spin_mana.value = def.mana_amount

	if opt_equip_slot != null:
		var slot_idx: int = 0
		for i in range(opt_equip_slot.item_count):
			if opt_equip_slot.get_item_text(i) == def.equip_slot:
				slot_idx = i
				break
		opt_equip_slot.selected = slot_idx

	var atk: int = int(def.stat_modifiers.get("attack", 0))
	var def_val: int = int(def.stat_modifiers.get("defence", 0))
	if spin_attack != null: spin_attack.value = atk
	if spin_defence != null: spin_defence.value = def_val

func _update_preview_icon(path: String) -> void:
	if preview_icon == null:
		return
	if not path.is_empty() and ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		preview_icon.texture = tex
	else:
		preview_icon.texture = null

# ── Event Callbacks ──────────────────────────────────────────────────────────

func _on_item_selected(index: int) -> void:
	var id: String = str(item_list.get_item_metadata(index))
	select_item(id)

func _on_search_changed(new_text: String) -> void:
	refresh_item_list(new_text)

func _on_icon_path_changed(new_path: String) -> void:
	_update_preview_icon(new_path)

func _on_preset_icon_selected(index: int) -> void:
	if index <= 0 or index > PRESET_ICONS.size():
		return
	var chosen: Dictionary = PRESET_ICONS[index - 1]
	var p: String = chosen["path"]
	if edit_icon_path != null:
		edit_icon_path.text = p
	_update_preview_icon(p)

func _on_new_item_pressed() -> void:
	var new_id: String = "item_new_%d" % (randi() % 900 + 100)
	var new_item: ItemDefinition = ItemDefinition.new()
	new_item.item_id = new_id
	new_item.display_name = "New Item"
	new_item.description = "A newly crafted item."
	new_item.category = ItemDefinition.Category.CONSUMABLE
	new_item.icon_path = "res://assets/icons/items/icon_item_apple.png"
	new_item.weight = 5
	new_item.price = 20
	new_item.stackable = true
	new_item.max_stack_size = 99
	new_item.heal_amount = 10

	var err: Error = ContentRegistry.save_item_to_disk(new_item)
	if err == OK:
		_selected_item_id = new_id
		refresh_item_list()
		select_item(new_id)
		_set_status("Created new item: " + new_id, Color(0.2, 0.7, 0.2))

func _on_delete_item_pressed() -> void:
	if _selected_item_id.is_empty():
		return
	var id_to_delete: String = _selected_item_id
	ContentRegistry.delete_item_from_disk(id_to_delete)
	item_deleted.emit(id_to_delete)
	_selected_item_id = ""
	refresh_item_list()
	if not _items_cache.is_empty():
		select_item(_items_cache[0].item_id)
	_set_status("Deleted item: " + id_to_delete, Color(0.8, 0.3, 0.2))

func _on_revert_pressed() -> void:
	if not _selected_item_id.is_empty():
		select_item(_selected_item_id)

func _on_save_pressed() -> void:
	var id_val: String = edit_id.text.strip_edges() if edit_id != null else ""
	if id_val.is_empty():
		_set_status("Error: Item ID cannot be empty!", Color(0.9, 0.2, 0.2))
		return

	var def: ItemDefinition = ItemDefinition.new()
	def.item_id = id_val
	def.display_name = edit_name.text.strip_edges() if edit_name != null else id_val
	def.description = edit_desc.text if edit_desc != null else ""
	def.category = (opt_category.get_selected_id() if opt_category != null else 0) as ItemDefinition.Category
	def.icon_path = edit_icon_path.text.strip_edges() if edit_icon_path != null else ""

	def.weight = int(spin_weight.value) if spin_weight != null else 10
	def.price = int(spin_price.value) if spin_price != null else 10
	def.stackable = chk_stackable.button_pressed if chk_stackable != null else true
	def.max_stack_size = int(spin_max_stack.value) if spin_max_stack != null else 99

	def.heal_amount = int(spin_heal.value) if spin_heal != null else 0
	def.mana_amount = int(spin_mana.value) if spin_mana != null else 0

	var slot_txt: String = opt_equip_slot.get_item_text(opt_equip_slot.selected) if opt_equip_slot != null else ""
	if slot_txt.begins_with("("):
		slot_txt = ""
	def.equip_slot = slot_txt

	var mods: Dictionary = {}
	var atk: int = int(spin_attack.value) if spin_attack != null else 0
	var def_val: int = int(spin_defence.value) if spin_defence != null else 0
	if atk != 0: mods["attack"] = atk
	if def_val != 0: mods["defence"] = def_val
	def.stat_modifiers = mods

	var errs: Array[String] = def.validate()
	if not errs.is_empty():
		_set_status("Validation Error: " + errs[0], Color(0.9, 0.2, 0.2))
		return

	var save_err: Error = ContentRegistry.save_item_to_disk(def)
	if save_err == OK:
		_selected_item_id = def.item_id
		refresh_item_list()
		select_item(def.item_id)
		item_saved.emit(def.item_id)
		_set_status("Item [%s] saved to disk and reloaded successfully!" % def.display_name, Color(0.2, 0.8, 0.3))
	else:
		_set_status("File write error (code %d)" % save_err, Color(0.9, 0.2, 0.2))

func _on_give_bag_pressed() -> void:
	if _selected_item_id.is_empty():
		return
	var players: Array = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	if players.is_empty():
		_set_status("No player active in world to receive item.", Color(0.8, 0.6, 0.2))
		return
	var p: Node = players[0]
	var inv: InventoryComponent = p.get_node_or_null("InventoryComponent") as InventoryComponent
	if inv == null and "inventory" in p:
		inv = p.inventory
	if inv != null:
		var ok: bool = inv.add_item_by_id(_selected_item_id, 5)
		if ok:
			_set_status("Gave 5x [%s] to player inventory!" % _selected_item_id, Color(0.2, 0.8, 0.3))
		else:
			_set_status("Could not add item (Inventory full or overweight)", Color(0.9, 0.4, 0.2))

func _set_status(msg: String, col: Color = Color.WHITE) -> void:
	if label_status != null:
		label_status.text = msg
		label_status.modulate = col

# ── Window Dragging & Minimizing ─────────────────────────────────────────────

func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
			else:
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var target_pos: Vector2 = get_global_mouse_position() - _drag_offset
		var vp_rect: Rect2 = get_viewport_rect()
		var clamped_x: float = clampf(target_pos.x, 0.0, maxf(0.0, vp_rect.size.x - size.x))
		var clamped_y: float = clampf(target_pos.y, 0.0, maxf(0.0, vp_rect.size.y - (32.0 if _is_minimized else size.y)))
		global_position = Vector2(clamped_x, clamped_y)

func _on_minimize_pressed() -> void:
	_is_minimized = not _is_minimized
	if main_panel != null:
		main_panel.visible = not _is_minimized
	if btn_minimize != null:
		btn_minimize.text = "+" if _is_minimized else "-"

func _on_close_pressed() -> void:
	visible = false
