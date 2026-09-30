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

func _ready() -> void:
	dialogue_panel.visible = false
	return_button.pressed.connect(_on_return_pressed)

func bind_player(player: Player) -> void:
	if player == null:
		return
	# Support both CharacterStatsComponent and plain StatsComponent
	var s: StatsComponent = player.get_node_or_null("CharacterStatsComponent") as StatsComponent
	if s == null:
		s = player.get_node_or_null("StatsComponent") as StatsComponent
	if s != null:
		s.health_changed.connect(_on_health_changed)
		_on_health_changed(s.current_health, s.max_health)
		if s is CharacterStatsComponent:
			var cs: CharacterStatsComponent = s as CharacterStatsComponent
			cs.level_up.connect(_on_level_up)
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
