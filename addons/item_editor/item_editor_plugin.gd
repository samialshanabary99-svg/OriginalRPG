@tool
extends EditorPlugin

var dock: Control

func _enter_tree() -> void:
	var dock_scene: PackedScene = preload("res://scenes/ui/item_editor_window.tscn")
	if dock_scene:
		dock = dock_scene.instantiate()
		dock.name = "Item Editor"
		add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)

	add_tool_menu_item("Open Item Editor", _on_open_tool_menu)

func _exit_tree() -> void:
	remove_tool_menu_item("Open Item Editor")
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null

func _on_open_tool_menu() -> void:
	if dock:
		dock.show()
		var p: Node = dock.get_parent()
		if p is TabContainer:
			(p as TabContainer).current_tab = dock.get_index()
		elif p != null:
			var grand_p: Node = p.get_parent()
			if grand_p is TabContainer:
				(grand_p as TabContainer).current_tab = p.get_index()
