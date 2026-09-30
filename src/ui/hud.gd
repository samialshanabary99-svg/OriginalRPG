class_name HUD
extends CanvasLayer

## In-game HUD displaying stats, interaction dialogue, and pause/return options.

signal return_to_menu_requested()

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/MarginContainer/DialogueLabel
@onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	dialogue_panel.visible = false
	return_button.pressed.connect(_on_return_pressed)

func bind_player(player: Player) -> void:
	if player != null and player.stats_component != null:
		player.stats_component.health_changed.connect(_on_health_changed)
		_on_health_changed(player.stats_component.current_health, player.stats_component.max_health)

func show_dialogue(text: String) -> void:
	dialogue_label.text = text
	dialogue_panel.visible = true

func hide_dialogue() -> void:
	dialogue_panel.visible = false

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP: %d / %d" % [current, maximum]

func _on_return_pressed() -> void:
	return_to_menu_requested.emit()
