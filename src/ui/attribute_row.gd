class_name AttributeRow
extends HBoxContainer

## Reusable attribute row for STR, AGI, VIT, INT, DEX, LUK with live point cost and spend button.

@export var stat_name: String = "STR"

@onready var name_label: Label = $NameLabel if has_node("NameLabel") else null
@onready var value_label: Label = $ValueLabel if has_node("ValueLabel") else null
@onready var cost_label: Label = $CostLabel if has_node("CostLabel") else null
@onready var minus_button: Button = $MinusButton if has_node("MinusButton") else null
@onready var plus_button: Button = $PlusButton if has_node("PlusButton") else null

func _ready() -> void:
	_resolve_nodes()
	if name_label != null:
		name_label.text = stat_name
	if plus_button != null and not plus_button.pressed.is_connected(_on_plus_pressed):
		plus_button.pressed.connect(_on_plus_pressed)
	if minus_button != null:
		minus_button.disabled = true # Locked in v1 per design specification

	if GameState != null:
		if not GameState.stat_points_changed.is_connected(_on_stat_points_changed):
			GameState.stat_points_changed.connect(_on_stat_points_changed)
		if not GameState.stats_changed.is_connected(refresh):
			GameState.stats_changed.connect(refresh)

	refresh()

func _resolve_nodes() -> void:
	if name_label == null: name_label = get_node_or_null("NameLabel") as Label
	if value_label == null: value_label = get_node_or_null("ValueLabel") as Label
	if cost_label == null: cost_label = get_node_or_null("CostLabel") as Label
	if minus_button == null: minus_button = get_node_or_null("MinusButton") as Button
	if plus_button == null: plus_button = get_node_or_null("PlusButton") as Button

func _on_stat_points_changed(_pts: int) -> void:
	refresh()

func refresh() -> void:
	_resolve_nodes()
	if GameState == null or not GameState.stats.has(stat_name):
		return

	var current: int = int(GameState.stats[stat_name])
	if value_label != null:
		value_label.text = str(current)
	var cost: int = GameState.stat_increase_cost(current)
	if cost_label != null:
		cost_label.text = "Cost: %d" % cost
	if plus_button != null:
		plus_button.disabled = GameState.stat_points < cost
	if minus_button != null:
		minus_button.disabled = true

func _on_plus_pressed() -> void:
	if GameState != null and GameState.try_increase_stat(stat_name):
		refresh()
		Toast.show_toast("+1 %s" % stat_name)
