class_name HUD
extends CanvasLayer

## In-game HUD displaying HP, level, XP, interaction dialogue, and return option.

signal return_to_menu_requested()

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var level_label: Label  = $MarginContainer/VBoxContainer/LevelLabel
@onready var xp_label: Label     = $MarginContainer/VBoxContainer/XPLabel
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_label: Label = $DialoguePanel/MarginContainer/DialogueLabel
@onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton
@onready var toggle_info_button: Button = $MarginContainer/VBoxContainer/ToggleInfoButton if has_node("MarginContainer/VBoxContainer/ToggleInfoButton") else null
@onready var basic_info_window: Control = $BasicInfoWindow if has_node("BasicInfoWindow") else null:
	get:
		if basic_info_window == null and has_node("BasicInfoWindow"):
			basic_info_window = get_node_or_null("BasicInfoWindow") as Control
		return basic_info_window

func _ready() -> void:
	dialogue_panel.visible = false
	return_button.pressed.connect(_on_return_pressed)
	if toggle_info_button != null:
		toggle_info_button.pressed.connect(toggle_basic_info)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_info") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V):
		toggle_basic_info()

func toggle_basic_info() -> void:
	if basic_info_window != null:
		if basic_info_window.has_method("toggle_window"):
			basic_info_window.toggle_window()
		else:
			basic_info_window.visible = not basic_info_window.visible

func bind_player(player: Node) -> void:
	if player == null:
		return
	if basic_info_window != null and basic_info_window.has_method("bind_player"):
		basic_info_window.bind_player(player)
	# Support both CharacterStatsComponent and plain StatsComponent
	var s: StatsComponent = player.get_node_or_null("CharacterStatsComponent") as StatsComponent
	if s == null:
		s = player.get_node_or_null("StatsComponent") as StatsComponent
	if s != null:
		if not s.health_changed.is_connected(_on_health_changed):
			s.health_changed.connect(_on_health_changed)
		_on_health_changed(s.current_health, s.max_health)
		if s is CharacterStatsComponent:
			var cs: CharacterStatsComponent = s as CharacterStatsComponent
			if not cs.level_up.is_connected(_on_level_up):
				cs.level_up.connect(_on_level_up)
			if not cs.experience_changed.is_connected(_on_experience_changed):
				cs.experience_changed.connect(_on_experience_changed)
			_on_level_up(cs.level)
			_on_experience_changed(cs.experience, cs.xp_to_next_level())

func show_dialogue(text: String) -> void:
	dialogue_label.text = text
	dialogue_panel.visible = true

func hide_dialogue() -> void:
	dialogue_panel.visible = false

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP: %d / %d" % [current, maximum]

func _on_level_up(new_level: int) -> void:
	if level_label != null:
		level_label.text = "Lv %d" % new_level

func _on_experience_changed(current_xp: int, xp_to_next: int) -> void:
	if xp_label != null:
		xp_label.text = "XP: %d / %d" % [current_xp, xp_to_next]

func _on_return_pressed() -> void:
	return_to_menu_requested.emit()
