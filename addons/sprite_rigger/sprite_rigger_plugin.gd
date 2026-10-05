@tool
extends EditorPlugin

var dock: Control

func _enter_tree() -> void:
	var dock_scene = preload("res://addons/sprite_rigger/ui/sprite_rigger_dock.tscn")
	if dock_scene:
		dock = dock_scene.instantiate()
		dock.name = "Sprite Rigger"
		dock.plugin = self
		add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)

	add_tool_menu_item("Open Sprite Rigger", _on_open_tool_menu)

func _exit_tree() -> void:
	remove_tool_menu_item("Open Sprite Rigger")
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null

func _on_open_tool_menu() -> void:
	if dock:
		dock.show()
		var p = dock.get_parent()
		if p is TabContainer:
			p.current_tab = dock.get_index()
		elif p != null:
			var grand_p = p.get_parent()
			if grand_p is TabContainer:
				grand_p.current_tab = p.get_index()
