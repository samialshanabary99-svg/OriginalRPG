@tool
class_name SpriteRiggerDock
extends Control

const RigDefinitions = preload("res://addons/sprite_rigger/scripts/rig_definitions.gd")
const RigBuilder = preload("res://addons/sprite_rigger/scripts/rig_builder.gd")
const RigCanvas = preload("res://addons/sprite_rigger/ui/rig_canvas.gd")

var plugin: EditorPlugin = null

# State
var current_image_path: String = ""
var current_direction: String = "south"
var z_indices: Dictionary = {}

# UI Node References
var file_dialog: FileDialog
var dir_dialog: FileDialog
var canvas: RigCanvas
var scroll_container: ScrollContainer

var direction_option: OptionButton
var image_path_label: Label
var image_info_label: Label
var coords_label: Label
var status_label: Label

var mode_tabs: TabBar
var instruction_banner: Label

# Joints controls
var joint_option: OptionButton
var joints_tree: Tree
var prev_joint_btn: Button
var next_joint_btn: Button
var clear_joint_btn: Button
var clear_all_joints_btn: Button

# Crops controls
var part_option: OptionButton
var parts_tree: Tree
var clear_crop_btn: Button
var clear_all_crops_btn: Button
var auto_box_btn: Button

# Export controls
var output_dir_edit: LineEdit
var rig_name_edit: LineEdit
var root_origin_option: OptionButton
var generate_btn: Button
var open_scene_btn: Button
var last_generated_scene_path: String = ""

func _ready() -> void:
	_init_z_indices()
	_build_ui()
	_update_direction_paths()
	_refresh_joints_ui()
	_refresh_parts_ui()

func _init_z_indices() -> void:
	z_indices.clear()
	for p in RigDefinitions.PARTS:
		z_indices[p["name"]] = p.get("default_z", 0)

func _build_ui() -> void:
	# Main layout: VBoxContainer
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(root_vbox)

	# --- Header Bar ---
	var header_panel = PanelContainer.new()
	root_vbox.add_child(header_panel)
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	header_panel.add_child(header_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "Sprite Rigger"
	title_lbl.add_theme_font_size_override("font_size", 16)
	header_hbox.add_child(title_lbl)

	header_hbox.add_child(VSeparator.new())

	var dir_lbl = Label.new()
	dir_lbl.text = "Direction:"
	header_hbox.add_child(dir_lbl)

	direction_option = OptionButton.new()
	for i in range(RigDefinitions.DIRECTIONS.size()):
		var d = RigDefinitions.DIRECTIONS[i]
		direction_option.add_item(d.capitalize(), i)
	direction_option.selected = 0
	direction_option.item_selected.connect(_on_direction_selected)
	header_hbox.add_child(direction_option)

	header_hbox.add_child(VSeparator.new())

	var load_btn = Button.new()
	load_btn.text = "📁 Load Sprite Image..."
	load_btn.pressed.connect(_on_load_sprite_pressed)
	header_hbox.add_child(load_btn)

	# Quick sample buttons if available on desktop
	var quick_south_btn = Button.new()
	quick_south_btn.text = "Load South.png"
	quick_south_btn.pressed.connect(func(): _try_load_quick_file("South.png"))
	header_hbox.add_child(quick_south_btn)

	var quick_north_btn = Button.new()
	quick_north_btn.text = "Load North.png"
	quick_north_btn.pressed.connect(func(): _try_load_quick_file("North.png"))
	header_hbox.add_child(quick_north_btn)

	image_info_label = Label.new()
	image_info_label.text = "No image loaded"
	image_info_label.size_flags_horizontal = SIZE_EXPAND_FILL
	image_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_hbox.add_child(image_info_label)

	# --- Instruction Banner ---
	var banner_panel = PanelContainer.new()
	banner_panel.custom_minimum_size = Vector2(0, 32)
	root_vbox.add_child(banner_panel)

	var banner_hbox = HBoxContainer.new()
	banner_panel.add_child(banner_hbox)

	instruction_banner = Label.new()
	instruction_banner.text = "Step 1: Click on the character sprite to place each joint in order."
	instruction_banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	instruction_banner.size_flags_horizontal = SIZE_EXPAND_FILL
	banner_hbox.add_child(instruction_banner)

	coords_label = Label.new()
	coords_label.text = "X: 0  Y: 0"
	coords_label.custom_minimum_size = Vector2(100, 0)
	coords_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	banner_hbox.add_child(coords_label)

	# --- Middle Section: Split between Canvas (Left) and Controls Sidebar (Right) ---
	var split = HSplitContainer.new()
	split.size_flags_horizontal = SIZE_EXPAND_FILL
	split.size_flags_vertical = SIZE_EXPAND_FILL
	split.split_offset = 600
	root_vbox.add_child(split)

	# Left Side: Canvas area with Zoom Bar
	var canvas_vbox = VBoxContainer.new()
	canvas_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	canvas_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	split.add_child(canvas_vbox)

	var zoom_bar = HBoxContainer.new()
	canvas_vbox.add_child(zoom_bar)
	var z_lbl = Label.new()
	z_lbl.text = "Zoom:"
	zoom_bar.add_child(z_lbl)

	for z_val in [0.5, 1.0, 1.5, 2.0]:
		var z_btn = Button.new()
		z_btn.text = "%d%%" % int(z_val * 100)
		z_btn.pressed.connect(func(): if canvas: canvas.zoom = z_val)
		zoom_bar.add_child(z_btn)

	var fit_btn = Button.new()
	fit_btn.text = "Fit View"
	fit_btn.pressed.connect(_on_fit_view_pressed)
	zoom_bar.add_child(fit_btn)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
	canvas_vbox.add_child(scroll_container)

	canvas = RigCanvas.new()
	canvas.joint_placed.connect(_on_canvas_joint_placed)
	canvas.joint_selected.connect(_on_canvas_joint_selected)
	canvas.crop_rect_defined.connect(_on_canvas_crop_defined)
	canvas.crop_rect_selected.connect(_on_canvas_crop_selected)
	canvas.cursor_moved.connect(_on_canvas_cursor_moved)
	scroll_container.add_child(canvas)

	# Right Side: Tabs for Joints, Crops, Export
	var sidebar_panel = PanelContainer.new()
	sidebar_panel.custom_minimum_size = Vector2(340, 0)
	sidebar_panel.size_flags_vertical = SIZE_EXPAND_FILL
	split.add_child(sidebar_panel)

	var sidebar_vbox = VBoxContainer.new()
	sidebar_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	sidebar_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	sidebar_panel.add_child(sidebar_vbox)

	mode_tabs = TabBar.new()
	mode_tabs.add_tab("1. Place Joints")
	mode_tabs.add_tab("2. Crop Body Parts")
	mode_tabs.add_tab("3. Generate Rig")
	mode_tabs.tab_changed.connect(_on_mode_tab_changed)
	sidebar_vbox.add_child(mode_tabs)

	# Tab 1 Container: Joints
	var joints_tab = VBoxContainer.new()
	joints_tab.name = "JointsTab"
	joints_tab.size_flags_vertical = SIZE_EXPAND_FILL
	sidebar_vbox.add_child(joints_tab)

	var joint_header_hbox = HBoxContainer.new()
	joints_tab.add_child(joint_header_hbox)
	var active_j_lbl = Label.new()
	active_j_lbl.text = "Target:"
	joint_header_hbox.add_child(active_j_lbl)

	joint_option = OptionButton.new()
	for i in range(RigDefinitions.JOINTS.size()):
		var j = RigDefinitions.JOINTS[i]
		joint_option.add_item("%s (%s)" % [j["label"], j["name"]], i)
	joint_option.item_selected.connect(_on_joint_option_selected)
	joint_option.size_flags_horizontal = SIZE_EXPAND_FILL
	joint_header_hbox.add_child(joint_option)

	var joint_btn_hbox = HBoxContainer.new()
	joints_tab.add_child(joint_btn_hbox)

	prev_joint_btn = Button.new()
	prev_joint_btn.text = "◀ Prev"
	prev_joint_btn.pressed.connect(_on_prev_joint_pressed)
	joint_btn_hbox.add_child(prev_joint_btn)

	next_joint_btn = Button.new()
	next_joint_btn.text = "Next ▶"
	next_joint_btn.pressed.connect(_on_next_joint_pressed)
	joint_btn_hbox.add_child(next_joint_btn)

	clear_joint_btn = Button.new()
	clear_joint_btn.text = "Clear Current"
	clear_joint_btn.pressed.connect(_on_clear_current_joint_pressed)
	joint_btn_hbox.add_child(clear_joint_btn)

	clear_all_joints_btn = Button.new()
	clear_all_joints_btn.text = "Clear All"
	clear_all_joints_btn.pressed.connect(_on_clear_all_joints_pressed)
	joint_btn_hbox.add_child(clear_all_joints_btn)

	joints_tree = Tree.new()
	joints_tree.columns = 2
	joints_tree.set_column_title(0, "Joint")
	joints_tree.set_column_title(1, "Position (X, Y)")
	joints_tree.set_column_titles_visible(true)
	joints_tree.size_flags_vertical = SIZE_EXPAND_FILL
	joints_tree.item_selected.connect(_on_joints_tree_selected)
	joints_tab.add_child(joints_tree)

	# Tab 2 Container: Crops
	var crops_tab = VBoxContainer.new()
	crops_tab.name = "CropsTab"
	crops_tab.size_flags_vertical = SIZE_EXPAND_FILL
	crops_tab.visible = false
	sidebar_vbox.add_child(crops_tab)

	var part_header_hbox = HBoxContainer.new()
	crops_tab.add_child(part_header_hbox)
	var active_p_lbl = Label.new()
	active_p_lbl.text = "Target Part:"
	part_header_hbox.add_child(active_p_lbl)

	part_option = OptionButton.new()
	for i in range(RigDefinitions.PARTS.size()):
		var p = RigDefinitions.PARTS[i]
		part_option.add_item("%s (%s)" % [p["label"], p["name"]], i)
	part_option.item_selected.connect(_on_part_option_selected)
	part_option.size_flags_horizontal = SIZE_EXPAND_FILL
	part_header_hbox.add_child(part_option)

	var crops_btn_hbox = HBoxContainer.new()
	crops_tab.add_child(crops_btn_hbox)

	clear_crop_btn = Button.new()
	clear_crop_btn.text = "Clear Box"
	clear_crop_btn.pressed.connect(_on_clear_current_crop_pressed)
	crops_btn_hbox.add_child(clear_crop_btn)

	clear_all_crops_btn = Button.new()
	clear_all_crops_btn.text = "Clear All Boxes"
	clear_all_crops_btn.pressed.connect(_on_clear_all_crops_pressed)
	crops_btn_hbox.add_child(clear_all_crops_btn)

	auto_box_btn = Button.new()
	auto_box_btn.text = "⚡ Guess from Joints"
	auto_box_btn.tooltip_text = "Generate initial crop boxes centered on placed joints."
	auto_box_btn.pressed.connect(_on_auto_box_pressed)
	crops_btn_hbox.add_child(auto_box_btn)

	parts_tree = Tree.new()
	parts_tree.columns = 3
	parts_tree.set_column_title(0, "Part")
	parts_tree.set_column_title(1, "Rect (X, Y, W, H)")
	parts_tree.set_column_title(2, "Z-Index")
	parts_tree.set_column_titles_visible(true)
	parts_tree.size_flags_vertical = SIZE_EXPAND_FILL
	parts_tree.item_selected.connect(_on_parts_tree_selected)
	crops_tab.add_child(parts_tree)

	# Tab 3 Container: Export
	var export_tab = VBoxContainer.new()
	export_tab.name = "ExportTab"
	export_tab.size_flags_vertical = SIZE_EXPAND_FILL
	export_tab.visible = false
	sidebar_vbox.add_child(export_tab)

	var form_grid = GridContainer.new()
	form_grid.columns = 2
	export_tab.add_child(form_grid)

	var out_lbl = Label.new()
	out_lbl.text = "Output Directory:"
	form_grid.add_child(out_lbl)

	var out_dir_hbox = HBoxContainer.new()
	out_dir_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	output_dir_edit = LineEdit.new()
	output_dir_edit.text = "res://assets/sprites/player/%s/" % current_direction
	output_dir_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	out_dir_hbox.add_child(output_dir_edit)
	var browse_dir_btn = Button.new()
	browse_dir_btn.text = "..."
	browse_dir_btn.pressed.connect(_on_browse_output_dir_pressed)
	out_dir_hbox.add_child(browse_dir_btn)
	form_grid.add_child(out_dir_hbox)

	var rig_lbl = Label.new()
	rig_lbl.text = "Root Node Name:"
	form_grid.add_child(rig_lbl)
	rig_name_edit = LineEdit.new()
	rig_name_edit.text = "Player" + current_direction.capitalize()
	rig_name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	form_grid.add_child(rig_name_edit)

	var origin_lbl = Label.new()
	origin_lbl.text = "Skeleton Origin:"
	form_grid.add_child(origin_lbl)
	root_origin_option = OptionButton.new()
	root_origin_option.add_item("Image Coordinates (0,0)", 0)
	root_origin_option.add_item("Origin at Hip", 1)
	root_origin_option.add_item("Origin at Feet (Ground)", 2)
	root_origin_option.selected = 0
	root_origin_option.size_flags_horizontal = SIZE_EXPAND_FILL
	form_grid.add_child(root_origin_option)

	export_tab.add_child(HSeparator.new())

	generate_btn = Button.new()
	generate_btn.text = "🚀 GENERATE RIG SCENE"
	generate_btn.custom_minimum_size = Vector2(0, 44)
	generate_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	generate_btn.pressed.connect(_on_generate_rig_pressed)
	export_tab.add_child(generate_btn)

	open_scene_btn = Button.new()
	open_scene_btn.text = "Open Generated Scene in Editor"
	open_scene_btn.disabled = true
	open_scene_btn.pressed.connect(_on_open_scene_pressed)
	export_tab.add_child(open_scene_btn)

	export_tab.add_child(HSeparator.new())

	status_label = Label.new()
	status_label.text = "Ready to rig. Follow steps 1 -> 2 -> 3."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	export_tab.add_child(status_label)

	# --- Bottom Status Bar ---
	var status_panel = PanelContainer.new()
	root_vbox.add_child(status_panel)
	var status_hbox = HBoxContainer.new()
	status_panel.add_child(status_hbox)

	image_path_label = Label.new()
	image_path_label.text = "No image file loaded."
	image_path_label.size_flags_horizontal = SIZE_EXPAND_FILL
	status_hbox.add_child(image_path_label)

	# File Dialog
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.png, *.webp, *.jpg, *.jpeg ; Image Files"]
	file_dialog.file_selected.connect(_load_image_file)
	add_child(file_dialog)

	# Dir Dialog
	dir_dialog = FileDialog.new()
	dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dir_dialog.access = FileDialog.ACCESS_RESOURCES
	dir_dialog.dir_selected.connect(func(d): output_dir_edit.text = d + "/")
	add_child(dir_dialog)

func _on_direction_selected(idx: int) -> void:
	current_direction = RigDefinitions.DIRECTIONS[idx]
	_update_direction_paths()

func _update_direction_paths() -> void:
	output_dir_edit.text = "res://assets/sprites/player/%s/" % current_direction
	rig_name_edit.text = "Player" + current_direction.capitalize()

func _on_load_sprite_pressed() -> void:
	file_dialog.popup_centered_ratio(0.7)

func _on_browse_output_dir_pressed() -> void:
	dir_dialog.popup_centered_ratio(0.7)

func _try_load_quick_file(filename: String) -> void:
	var candidates = [
		"C:/Users/SAMI/Desktop/" + filename,
		"C:/Users/SAMI/Desktop/" + filename.to_lower(),
		"res://assets/sprites/" + filename,
		"res://" + filename
	]
	for p in candidates:
		if FileAccess.file_exists(p):
			_load_image_file(p)
			return
	status_label.text = "Quick file not found: %s" % filename

func _load_image_file(path: String) -> void:
	var img = Image.load_from_file(path)
	if img == null:
		status_label.text = "Error: Failed to load image from %s" % path
		return

	current_image_path = path
	canvas.set_sprite(img)

	image_path_label.text = path
	image_info_label.text = "%dx%d px" % [img.get_width(), img.get_height()]
	status_label.text = "Loaded '%s'. Now place joints." % path.get_file()

	_on_fit_view_pressed()
	_update_banner()

func _on_fit_view_pressed() -> void:
	if canvas.sprite_image == null or scroll_container == null:
		return
	var viewport_w = scroll_container.size.x
	var viewport_h = scroll_container.size.y
	if viewport_w <= 10 or viewport_h <= 10:
		return
	var img_w = float(canvas.sprite_image.get_width())
	var img_h = float(canvas.sprite_image.get_height())
	var fit_zoom = minf(viewport_w / img_w, viewport_h / img_h)
	canvas.zoom = clampf(fit_zoom * 0.95, 0.2, 3.0)

func _on_mode_tab_changed(tab: int) -> void:
	var sidebar = mode_tabs.get_parent()
	var joints_tab = sidebar.get_node("JointsTab")
	var crops_tab = sidebar.get_node("CropsTab")
	var export_tab = sidebar.get_node("ExportTab")

	joints_tab.visible = (tab == 0)
	crops_tab.visible = (tab == 1)
	export_tab.visible = (tab == 2)

	if tab == 0:
		canvas.current_mode = RigCanvas.Mode.JOINTS
	elif tab == 1:
		canvas.current_mode = RigCanvas.Mode.CROPS
	elif tab == 2:
		canvas.current_mode = RigCanvas.Mode.CROPS

	_update_banner()

func _update_banner() -> void:
	if canvas.current_mode == RigCanvas.Mode.JOINTS:
		var j_def = RigDefinitions.get_joint_def(canvas.active_joint_name)
		var label_str = j_def.get("label", canvas.active_joint_name)
		var hint_str = j_def.get("hint", "")
		instruction_banner.text = "Place Joint [%s]: Click on %s" % [label_str, hint_str]
	elif canvas.current_mode == RigCanvas.Mode.CROPS:
		var p_def = RigDefinitions.get_part_def(canvas.active_part_name)
		var label_str = p_def.get("label", canvas.active_part_name)
		instruction_banner.text = "Crop Box [%s]: Click and drag a rectangle over this part." % label_str

# --- Canvas Callbacks ---
func _on_canvas_joint_placed(j_name: String, _pos: Vector2) -> void:
	_refresh_joints_ui()
	_update_banner()

func _on_canvas_joint_selected(j_name: String) -> void:
	for i in range(RigDefinitions.JOINTS.size()):
		if RigDefinitions.JOINTS[i]["name"] == j_name:
			joint_option.selected = i
			break
	_update_banner()

func _on_canvas_crop_defined(p_name: String, _rect: Rect2i) -> void:
	_refresh_parts_ui()
	_update_banner()

func _on_canvas_crop_selected(p_name: String) -> void:
	for i in range(RigDefinitions.PARTS.size()):
		if RigDefinitions.PARTS[i]["name"] == p_name:
			part_option.selected = i
			break
	_update_banner()

func _on_canvas_cursor_moved(img_pos: Vector2) -> void:
	coords_label.text = "X: %d  Y: %d" % [int(img_pos.x), int(img_pos.y)]

# --- Joint Controls ---
func _on_joint_option_selected(idx: int) -> void:
	var j_name = RigDefinitions.JOINTS[idx]["name"]
	canvas.active_joint_name = j_name
	_update_banner()

func _on_prev_joint_pressed() -> void:
	var cur_idx = joint_option.selected
	if cur_idx > 0:
		joint_option.selected = cur_idx - 1
		_on_joint_option_selected(cur_idx - 1)

func _on_next_joint_pressed() -> void:
	var cur_idx = joint_option.selected
	if cur_idx + 1 < RigDefinitions.JOINTS.size():
		joint_option.selected = cur_idx + 1
		_on_joint_option_selected(cur_idx + 1)

func _on_clear_current_joint_pressed() -> void:
	canvas.clear_joint(canvas.active_joint_name)
	_refresh_joints_ui()

func _on_clear_all_joints_pressed() -> void:
	canvas.clear_all_joints()
	_refresh_joints_ui()

func _refresh_joints_ui() -> void:
	joints_tree.clear()
	var root_item = joints_tree.create_item()

	for j_def in RigDefinitions.JOINTS:
		var j_name: String = j_def["name"]
		var item = joints_tree.create_item(root_item)
		var label_str: String = j_def.get("label", j_name)
		item.set_text(0, label_str)
		item.set_metadata(0, j_name)

		if canvas.joints.has(j_name):
			var pos: Vector2 = canvas.joints[j_name]
			item.set_text(1, "(%d, %d)" % [int(pos.x), int(pos.y)])
			item.set_custom_color(1, Color(0.3, 1.0, 0.4))
		else:
			item.set_text(1, "Not placed")
			item.set_custom_color(1, Color(0.8, 0.4, 0.4))

func _on_joints_tree_selected() -> void:
	var item = joints_tree.get_selected()
	if item:
		var j_name = item.get_metadata(0)
		canvas.active_joint_name = j_name
		for i in range(RigDefinitions.JOINTS.size()):
			if RigDefinitions.JOINTS[i]["name"] == j_name:
				joint_option.selected = i
				break
		_update_banner()

# --- Crop Controls ---
func _on_part_option_selected(idx: int) -> void:
	var p_name = RigDefinitions.PARTS[idx]["name"]
	canvas.active_part_name = p_name
	_update_banner()

func _on_clear_current_crop_pressed() -> void:
	canvas.clear_crop(canvas.active_part_name)
	_refresh_parts_ui()

func _on_clear_all_crops_pressed() -> void:
	canvas.clear_all_crops()
	_refresh_parts_ui()

func _on_auto_box_pressed() -> void:
	if canvas.sprite_image == null:
		return

	# Helper to generate reasonable bounding boxes around placed joints
	for p_def in RigDefinitions.PARTS:
		var p_name = p_def["name"]
		var b_name = p_def["bone"]
		if not canvas.joints.has(b_name):
			continue

		var j_pos: Vector2 = canvas.joints[b_name]
		var box_w = 40
		var box_h = 40
		var offset_y = -20

		if p_name == "torso":
			box_w = 70
			box_h = 70
			offset_y = -35
		elif p_name == "head":
			box_w = 50
			box_h = 50
			offset_y = -40
		elif p_name in ["upper_arm_L", "upper_arm_R"]:
			box_w = 30
			box_h = 45
			offset_y = -10
		elif p_name in ["forearm_L", "forearm_R"]:
			box_w = 26
			box_h = 40
			offset_y = -5
		elif p_name in ["upper_leg_L", "upper_leg_R"]:
			box_w = 32
			box_h = 60
			offset_y = -10
		elif p_name in ["lower_leg_L", "lower_leg_R"]:
			box_w = 32
			box_h = 60
			offset_y = -5

		var rect = Rect2i(int(j_pos.x - box_w / 2.0), int(j_pos.y + offset_y), box_w, box_h)
		canvas.crop_rects[p_name] = rect

	canvas.queue_redraw()
	_refresh_parts_ui()

func _refresh_parts_ui() -> void:
	parts_tree.clear()
	var root_item = parts_tree.create_item()

	for p_def in RigDefinitions.PARTS:
		var p_name: String = p_def["name"]
		var item = parts_tree.create_item(root_item)
		var label_str: String = p_def.get("label", p_name)
		item.set_text(0, label_str)
		item.set_metadata(0, p_name)

		if canvas.crop_rects.has(p_name):
			var r: Rect2i = canvas.crop_rects[p_name]
			item.set_text(1, "[%d, %d, %d, %d]" % [r.position.x, r.position.y, r.size.x, r.size.y])
			item.set_custom_color(1, Color(0.3, 1.0, 0.4))
		else:
			item.set_text(1, "Not drawn")
			item.set_custom_color(1, Color(0.8, 0.4, 0.4))

		var z_val = z_indices.get(p_name, p_def.get("default_z", 0))
		item.set_text(2, str(z_val))

func _on_parts_tree_selected() -> void:
	var item = parts_tree.get_selected()
	if item:
		var p_name = item.get_metadata(0)
		canvas.active_part_name = p_name
		for i in range(RigDefinitions.PARTS.size()):
			if RigDefinitions.PARTS[i]["name"] == p_name:
				part_option.selected = i
				break
		_update_banner()

# --- Export & Generate ---
func _on_generate_rig_pressed() -> void:
	if canvas.sprite_image == null:
		status_label.text = "Error: Please load a sprite image first!"
		return

	if not canvas.joints.has("hip"):
		status_label.text = "Error: Joint 'hip' (root) must be placed!"
		return

	var out_dir = output_dir_edit.text.strip_edges()
	var rig_name = rig_name_edit.text.strip_edges()
	if rig_name.is_empty():
		rig_name = "Player" + current_direction.capitalize()

	var origin_mode = "image"
	if root_origin_option.selected == 1:
		origin_mode = "hip"
	elif root_origin_option.selected == 2:
		origin_mode = "feet"

	status_label.text = "Generating rig..."

	var res = RigBuilder.build_and_save_rig(
		canvas.sprite_image,
		canvas.joints,
		canvas.crop_rects,
		z_indices,
		out_dir,
		"rig.tscn",
		rig_name,
		origin_mode
	)

	if res.get("success", false):
		last_generated_scene_path = res["scene_path"]
		open_scene_btn.disabled = false
		status_label.text = "✓ SUCCESS: Rig scene saved at:\n%s\nSaved %d part textures into:\n%s" % [
			res["scene_path"],
			res["saved_parts"].size(),
			res["parts_dir"]
		]

		# Rescan editor filesystem if running inside Godot editor
		if Engine.is_editor_hint():
			var editor_fs = null
			if plugin:
				editor_fs = plugin.get_editor_interface().get_resource_filesystem()
			elif ClassDB.class_exists("EditorInterface"):
				var ei = Engine.get_singleton("EditorInterface")
				if ei:
					editor_fs = ei.get_resource_filesystem()
			if editor_fs:
				editor_fs.scan()
	else:
		status_label.text = "❌ FAILED: %s" % res.get("error", "Unknown error")

func _on_open_scene_pressed() -> void:
	if last_generated_scene_path.is_empty():
		return
	if plugin:
		plugin.get_editor_interface().open_scene_from_path(last_generated_scene_path)
	elif ClassDB.class_exists("EditorInterface"):
		var ei = Engine.get_singleton("EditorInterface")
		if ei:
			ei.open_scene_from_path(last_generated_scene_path)
