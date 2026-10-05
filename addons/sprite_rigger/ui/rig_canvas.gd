@tool
class_name RigCanvas
extends Control

const RigDefinitions = preload("res://addons/sprite_rigger/scripts/rig_definitions.gd")

enum Mode {
	JOINTS,
	CROPS
}

signal joint_placed(joint_name: String, pos: Vector2)
signal joint_selected(joint_name: String)
signal crop_rect_defined(part_name: String, rect: Rect2i)
signal crop_rect_selected(part_name: String)
signal cursor_moved(image_pos: Vector2)

var sprite_image: Image = null
var sprite_texture: ImageTexture = null

var zoom: float = 1.0:
	set(val):
		zoom = clampf(val, 0.2, 5.0)
		_update_canvas_size()
		queue_redraw()

var current_mode: Mode = Mode.JOINTS:
	set(val):
		current_mode = val
		queue_redraw()

var active_joint_name: String = "hip":
	set(val):
		active_joint_name = val
		queue_redraw()

var active_part_name: String = "torso":
	set(val):
		active_part_name = val
		queue_redraw()

# Stored data
var joints: Dictionary = {}        # joint_name -> Vector2 (image coords)
var crop_rects: Dictionary = {}    # part_name -> Rect2i (image coords)

# Interaction state
var is_dragging_rect: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_current_pos: Vector2 = Vector2.ZERO
var hover_image_pos: Vector2 = Vector2.ZERO
var is_mouse_over: bool = false

func _init() -> void:
	focus_mode = FOCUS_ALL
	mouse_filter = MOUSE_FILTER_PASS

func set_sprite(img: Image) -> void:
	sprite_image = img
	if sprite_image:
		sprite_texture = ImageTexture.create_from_image(sprite_image)
	else:
		sprite_texture = null
	_update_canvas_size()
	queue_redraw()

func _update_canvas_size() -> void:
	if sprite_image:
		var w = sprite_image.get_width() * zoom
		var h = sprite_image.get_height() * zoom
		custom_minimum_size = Vector2(w, h)
	else:
		custom_minimum_size = Vector2(300, 300)
	size = custom_minimum_size

func clear_all_joints() -> void:
	joints.clear()
	active_joint_name = "hip"
	queue_redraw()

func clear_all_crops() -> void:
	crop_rects.clear()
	active_part_name = "torso"
	queue_redraw()

func clear_joint(j_name: String) -> void:
	joints.erase(j_name)
	queue_redraw()

func clear_crop(p_name: String) -> void:
	crop_rects.erase(p_name)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if sprite_image == null:
		return

	if event is InputEventMouseMotion:
		hover_image_pos = _screen_to_image(event.position)
		is_mouse_over = true
		cursor_moved.emit(hover_image_pos)
		if is_dragging_rect:
			drag_current_pos = hover_image_pos
			queue_redraw()

	elif event is InputEventMouseButton:
		var img_pos = _screen_to_image(event.position)

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if current_mode == Mode.JOINTS:
					_handle_joint_click(img_pos)
				elif current_mode == Mode.CROPS:
					is_dragging_rect = true
					drag_start_pos = img_pos
					drag_current_pos = img_pos
					queue_redraw()
			else:
				# Left mouse button released
				if is_dragging_rect and current_mode == Mode.CROPS:
					is_dragging_rect = false
					drag_current_pos = img_pos
					_finish_crop_drag()
					queue_redraw()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging_rect:
				is_dragging_rect = false
				queue_redraw()
			else:
				if current_mode == Mode.JOINTS:
					clear_joint(active_joint_name)
				elif current_mode == Mode.CROPS:
					clear_crop(active_part_name)

func _handle_joint_click(img_pos: Vector2) -> void:
	joints[active_joint_name] = img_pos
	joint_placed.emit(active_joint_name, img_pos)

	# Auto-advance to next joint
	var current_idx = -1
	for i in range(RigDefinitions.JOINTS.size()):
		if RigDefinitions.JOINTS[i]["name"] == active_joint_name:
			current_idx = i
			break

	if current_idx != -1 and current_idx + 1 < RigDefinitions.JOINTS.size():
		active_joint_name = RigDefinitions.JOINTS[current_idx + 1]["name"]
		joint_selected.emit(active_joint_name)

	queue_redraw()

func _finish_crop_drag() -> void:
	var min_x = int(min(drag_start_pos.x, drag_current_pos.x))
	var min_y = int(min(drag_start_pos.y, drag_current_pos.y))
	var max_x = int(max(drag_start_pos.x, drag_current_pos.x))
	var max_y = int(max(drag_start_pos.y, drag_current_pos.y))
	var w = max_x - min_x
	var h = max_y - min_y

	# Only register if sufficiently sized
	if w >= 3 and h >= 3:
		var rect = Rect2i(min_x, min_y, w, h)
		crop_rects[active_part_name] = rect
		crop_rect_defined.emit(active_part_name, rect)

		# Auto-advance to next part
		var current_idx = -1
		for i in range(RigDefinitions.PARTS.size()):
			if RigDefinitions.PARTS[i]["name"] == active_part_name:
				current_idx = i
				break

		if current_idx != -1 and current_idx + 1 < RigDefinitions.PARTS.size():
			active_part_name = RigDefinitions.PARTS[current_idx + 1]["name"]
			crop_rect_selected.emit(active_part_name)

func _screen_to_image(screen_pos: Vector2) -> Vector2:
	if sprite_image == null:
		return Vector2.ZERO
	var img_pos = (screen_pos / zoom).floor()
	var img_w = float(sprite_image.get_width())
	var img_h = float(sprite_image.get_height())
	img_pos.x = clampf(img_pos.x, 0.0, img_w - 1.0)
	img_pos.y = clampf(img_pos.y, 0.0, img_h - 1.0)
	return img_pos

func _image_to_screen(img_pos: Vector2) -> Vector2:
	return img_pos * zoom

func _image_rect_to_screen(r: Rect2i) -> Rect2:
	return Rect2(
		float(r.position.x) * zoom,
		float(r.position.y) * zoom,
		float(r.size.x) * zoom,
		float(r.size.y) * zoom
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		is_mouse_over = false
		queue_redraw()

func _draw() -> void:
	# 1. Background checkerboard
	var canvas_rect = Rect2(Vector2.ZERO, size)
	_draw_checkerboard(canvas_rect)

	# 2. Sprite Texture
	if sprite_texture:
		var dest_rect = Rect2(Vector2.ZERO, Vector2(sprite_image.get_width(), sprite_image.get_height()) * zoom)
		draw_texture_rect(sprite_texture, dest_rect, false)
	else:
		# Draw helper message
		var font = get_theme_default_font()
		var msg = "No Sprite Loaded. Click 'Load Sprite Image' to begin."
		draw_string(font, Vector2(20, 40), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
		return

	# 3. Draw Crop Rectangles
	for part_def in RigDefinitions.PARTS:
		var p_name: String = part_def["name"]
		if not crop_rects.has(p_name):
			continue

		var img_rect: Rect2i = crop_rects[p_name]
		var scr_rect: Rect2 = _image_rect_to_screen(img_rect)
		var base_color: Color = part_def.get("color", Color(0.2, 0.8, 0.2, 0.7))
		var is_active = (current_mode == Mode.CROPS and p_name == active_part_name)

		# Semi-transparent fill
		var fill_color = Color(base_color.r, base_color.g, base_color.b, 0.25 if not is_active else 0.45)
		draw_rect(scr_rect, fill_color, true)

		# Border outline
		var border_color = Color(base_color.r, base_color.g, base_color.b, 1.0)
		var border_width = 3.0 if is_active else 1.5
		draw_rect(scr_rect, border_color, false, border_width)

		# Part label
		var font = get_theme_default_font()
		var label_text = "%s [%d,%d]" % [part_def.get("label", p_name), img_rect.size.x, img_rect.size.y]
		draw_string(font, scr_rect.position + Vector2(4, 14), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# 4. Draw currently dragging rubber-band rectangle
	if is_dragging_rect and current_mode == Mode.CROPS:
		var min_x = min(drag_start_pos.x, drag_current_pos.x)
		var min_y = min(drag_start_pos.y, drag_current_pos.y)
		var w = abs(drag_current_pos.x - drag_start_pos.x)
		var h = abs(drag_current_pos.y - drag_start_pos.y)
		var drag_img_rect = Rect2i(int(min_x), int(min_y), int(w), int(h))
		var drag_scr_rect = _image_rect_to_screen(drag_img_rect)

		var cur_part_def = RigDefinitions.get_part_def(active_part_name)
		var p_color = cur_part_def.get("color", Color.YELLOW)
		draw_rect(drag_scr_rect, Color(p_color.r, p_color.g, p_color.b, 0.35), true)
		draw_rect(drag_scr_rect, Color(1, 1, 1, 1.0), false, 2.0)

		var font = get_theme_default_font()
		var dim_str = "%dx%d" % [int(w), int(h)]
		draw_string(font, drag_scr_rect.position + Vector2(4, -4), dim_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)

	# 5. Draw Bone Connections
	for j_def in RigDefinitions.JOINTS:
		var j_name: String = j_def["name"]
		var p_name: String = j_def["parent"]
		if p_name != "" and joints.has(j_name) and joints.has(p_name):
			var p_scr = _image_to_screen(joints[p_name])
			var j_scr = _image_to_screen(joints[j_name])
			var bone_color = Color(0.2, 1.0, 0.6, 0.85)
			# Draw bone line
			draw_line(p_scr, j_scr, Color(0, 0, 0, 0.9), 4.0) # Shadow outline
			draw_line(p_scr, j_scr, bone_color, 2.5)

	# 6. Draw Joint Markers
	for j_def in RigDefinitions.JOINTS:
		var j_name: String = j_def["name"]
		if not joints.has(j_name):
			continue

		var j_pos: Vector2 = joints[j_name]
		var scr_pos: Vector2 = _image_to_screen(j_pos)
		var is_active = (current_mode == Mode.JOINTS and j_name == active_joint_name)
		var j_color: Color = j_def.get("color", Color.GREEN)

		var radius = (7.0 if is_active else 5.0) * max(1.0, zoom * 0.7)

		# Dark outer shadow
		draw_circle(scr_pos, radius + 2.0, Color(0, 0, 0, 0.8))
		# Main filled joint circle
		draw_circle(scr_pos, radius, j_color)
		# Inner white core
		draw_circle(scr_pos, radius * 0.45, Color.WHITE)

		if is_active:
			# Pulsing / prominent outer ring
			draw_arc(scr_pos, radius + 4.0, 0.0, TAU, 32, Color.WHITE, 2.0)

		# Label next to joint
		var font = get_theme_default_font()
		var label_str = j_def.get("label", j_name)
		draw_string(font, scr_pos + Vector2(radius + 4, 4), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# 7. Hover crosshair
	if is_mouse_over and not is_dragging_rect:
		var hover_scr = _image_to_screen(hover_image_pos)
		var cross_color = Color(1.0, 1.0, 1.0, 0.5)
		draw_line(Vector2(hover_scr.x, 0), Vector2(hover_scr.x, size.y), cross_color, 1.0)
		draw_line(Vector2(0, hover_scr.y), Vector2(size.x, hover_scr.y), cross_color, 1.0)

func _draw_checkerboard(rect: Rect2) -> void:
	var tile_size = 16.0
	var col1 = Color(0.18, 0.18, 0.18, 1.0)
	var col2 = Color(0.22, 0.22, 0.22, 1.0)
	draw_rect(rect, col1, true)

	var cols = int(ceil(rect.size.x / tile_size))
	var rows = int(ceil(rect.size.y / tile_size))
	for y in range(rows):
		for x in range(cols):
			if (x + y) % 2 == 1:
				var tr = Rect2(Vector2(x * tile_size, y * tile_size), Vector2(tile_size, tile_size))
				draw_rect(tr, col2, true)
