class_name TestWorld
extends Node2D

## Test map coordinating the prototype gameplay loop.

@onready var player: Player = $Player
@onready var monument: AncientMonument = $AncientMonument
@onready var hud: HUD = $HUD

func _ready() -> void:
	if hud != null and player != null:
		hud.bind_player(player)
		hud.return_to_menu_requested.connect(_on_return_to_menu)

	if monument != null and hud != null:
		monument.inspection_triggered.connect(hud.show_dialogue)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_on_return_to_menu()

func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
