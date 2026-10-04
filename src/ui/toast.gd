class_name Toast
extends RefCounted

## Lightweight toast feedback system for floating temporary notifications.

static func show_toast(message: String, duration: float = 2.0) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.16, 0.9)
	sb.border_color = Color(0.35, 0.35, 0.45, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)

	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	panel.offset_left = -100.0
	panel.offset_top = -140.0
	panel.offset_right = 100.0
	panel.offset_bottom = -100.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 1.0))
	panel.add_child(label)

	panel.modulate.a = 0.0
	tree.root.add_child(panel)

	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duration)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(panel.queue_free)
