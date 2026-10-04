class_name CharacterStatsWindow
extends PanelContainer

## Character stats window displaying player level, combat stats, and 6-stat point allocation.

@onready var level_label: Label = %LevelLabel if has_node("%LevelLabel") else null
@onready var points_label: Label = %PointsLabel if has_node("%PointsLabel") else null
@onready var hp_label: Label = %HPLabel if has_node("%HPLabel") else null
@onready var stamina_label: Label = %StaminaLabel if has_node("%StaminaLabel") else null
@onready var attack_label: Label = %AttackLabel if has_node("%AttackLabel") else null
@onready var defense_label: Label = %DefenseLabel if has_node("%DefenseLabel") else null
@onready var close_button: Button = %CloseButton if has_node("%CloseButton") else null
@onready var title_bar: HBoxContainer = %TitleBar if has_node("%TitleBar") else null

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_resolve_nodes()

	if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)

	if title_bar != null and not title_bar.gui_input.is_connected(_on_title_bar_gui_input):
		title_bar.gui_input.connect(_on_title_bar_gui_input)

	if GameState != null:
		if not GameState.leveled_up.is_connected(_on_game_state_changed):
			GameState.leveled_up.connect(_on_game_state_changed)
		if not GameState.job_leveled_up.is_connected(_on_game_state_changed):
			GameState.job_leveled_up.connect(_on_game_state_changed)
		if not GameState.stat_points_changed.is_connected(_on_game_state_changed):
			GameState.stat_points_changed.connect(_on_game_state_changed)
		if not GameState.stats_changed.is_connected(refresh):
			GameState.stats_changed.connect(refresh)
		if not GameState.health_changed.is_connected(_on_health_changed):
			GameState.health_changed.connect(_on_health_changed)
		if not GameState.stamina_changed.is_connected(_on_stamina_changed):
			GameState.stamina_changed.connect(_on_stamina_changed)

	refresh()

func _resolve_nodes() -> void:
	if level_label == null: level_label = get_node_or_null("%LevelLabel") as Label
	if points_label == null: points_label = get_node_or_null("%PointsLabel") as Label
	if hp_label == null: hp_label = get_node_or_null("%HPLabel") as Label
	if stamina_label == null: stamina_label = get_node_or_null("%StaminaLabel") as Label
	if attack_label == null: attack_label = get_node_or_null("%AttackLabel") as Label
	if defense_label == null: defense_label = get_node_or_null("%DefenseLabel") as Label
	if close_button == null: close_button = get_node_or_null("%CloseButton") as Button
	if title_bar == null: title_bar = get_node_or_null("%TitleBar") as HBoxContainer

func _on_game_state_changed(_val: int) -> void:
	refresh()

func _on_health_changed(_cur: int, _max_val: int) -> void:
	refresh()

func _on_stamina_changed(_cur: int, _max_val: int) -> void:
	refresh()

func refresh() -> void:
	_resolve_nodes()
	if GameState == null:
		return

	if level_label != null:
		level_label.text = "Lv. %d / %d" % [GameState.base_level, GameState.job_level]
	if points_label != null:
		points_label.text = "Points: %d" % GameState.stat_points
	if hp_label != null:
		hp_label.text = "%d / %d" % [GameState.hp, GameState.max_hp]
	if stamina_label != null:
		stamina_label.text = "%d / %d" % [GameState.stamina, GameState.max_stamina]
	if attack_label != null:
		attack_label.text = str(GameState.attack)
	if defense_label != null:
		defense_label.text = str(GameState.defence)

func toggle_window() -> void:
	visible = not visible
	if visible:
		refresh()

func _on_close_button_pressed() -> void:
	hide()

# ── Draggable Window Handling ────────────────────────────────────────────────
func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
			else:
				_is_dragging = false

func _process(_delta: float) -> void:
	if _is_dragging:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			global_position = get_global_mouse_position() - _drag_offset
		else:
			_is_dragging = false
