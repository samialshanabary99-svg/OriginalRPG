class_name HUD
extends CanvasLayer

## In-game HUD displaying Basic Info Window, Character Stats Window, dialogue panel, and status bindings.

signal return_to_menu_requested()

@onready var dialogue_panel: PanelContainer = $DialoguePanel if has_node("DialoguePanel") else null
@onready var dialogue_label: Label   = $DialoguePanel/MarginContainer/DialogueLabel if has_node("DialoguePanel/MarginContainer/DialogueLabel") else null

@onready var basic_info_window: Control = $BasicInfoWindow if has_node("BasicInfoWindow") else null:
	get:
		if basic_info_window == null and has_node("BasicInfoWindow"):
			basic_info_window = get_node_or_null("BasicInfoWindow") as Control
		return basic_info_window

@onready var character_stats_window: CharacterStatsWindow = $CharacterStatsWindow if has_node("CharacterStatsWindow") else null:
	get:
		if character_stats_window == null and has_node("CharacterStatsWindow"):
			character_stats_window = get_node_or_null("CharacterStatsWindow") as CharacterStatsWindow
		return character_stats_window

var health_bar: ProgressBar:
	get:
		if basic_info_window != null:
			if basic_info_window.get("bar_hp") != null:
				return basic_info_window.bar_hp
			var n = basic_info_window.get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/HpRow/BarHP")
			if n is ProgressBar:
				return n as ProgressBar
		if has_node("MarginContainer/VBoxContainer/HealthBar"):
			return get_node("MarginContainer/VBoxContainer/HealthBar") as ProgressBar
		return null

var health_label: Label:
	get:
		if basic_info_window != null:
			if basic_info_window.get("label_hp") != null:
				return basic_info_window.label_hp
			var n = basic_info_window.get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/HpRow/BarHP/LabelHP")
			if n is Label:
				return n as Label
		if has_node("MarginContainer/VBoxContainer/HealthLabel"):
			return get_node("MarginContainer/VBoxContainer/HealthLabel") as Label
		return null

var mana_bar: ProgressBar:
	get:
		if basic_info_window != null:
			if basic_info_window.get("bar_sp") != null:
				return basic_info_window.bar_sp
			var n = basic_info_window.get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/SpRow/BarSP")
			if n is ProgressBar:
				return n as ProgressBar
		if has_node("MarginContainer/VBoxContainer/ManaBar"):
			return get_node("MarginContainer/VBoxContainer/ManaBar") as ProgressBar
		return null

var mana_label: Label:
	get:
		if basic_info_window != null:
			if basic_info_window.get("label_sp") != null:
				return basic_info_window.label_sp
			var n = basic_info_window.get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/SpRow/BarSP/LabelSP")
			if n is Label:
				return n as Label
		if has_node("MarginContainer/VBoxContainer/ManaLabel"):
			return get_node("MarginContainer/VBoxContainer/ManaLabel") as Label
		return null

var level_label: Label:
	get:
		if has_node("MarginContainer/VBoxContainer/LevelLabel"):
			return get_node("MarginContainer/VBoxContainer/LevelLabel") as Label
		return null

var xp_label: Label:
	get:
		if basic_info_window != null:
			if basic_info_window.get("label_lvl_exp") != null:
				return basic_info_window.label_lvl_exp
			var n = basic_info_window.get_node_or_null("WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/LvlExpRow/BarLvlExp/LabelLvlExp")
			if n is Label:
				return n as Label
		if has_node("MarginContainer/VBoxContainer/XPLabel"):
			return get_node("MarginContainer/VBoxContainer/XPLabel") as Label
		return null

var return_button: Button:
	get:
		if has_node("MarginContainer/VBoxContainer/ReturnButton"):
			return get_node("MarginContainer/VBoxContainer/ReturnButton") as Button
		return null

var toggle_info_button: Button:
	get:
		if has_node("MarginContainer/VBoxContainer/ToggleInfoButton"):
			return get_node("MarginContainer/VBoxContainer/ToggleInfoButton") as Button
		return null

func _ready() -> void:
	if basic_info_window != null and not basic_info_window.is_node_ready():
		basic_info_window._ready()
	if dialogue_panel != null:
		dialogue_panel.visible = false
	if return_button != null:
		return_button.focus_mode = Control.FOCUS_NONE
		if not return_button.pressed.is_connected(_on_return_pressed):
			return_button.pressed.connect(_on_return_pressed)
	if toggle_info_button != null:
		toggle_info_button.focus_mode = Control.FOCUS_NONE
		if not toggle_info_button.pressed.is_connected(toggle_basic_info):
			toggle_info_button.pressed.connect(toggle_basic_info)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_info") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V):
		toggle_basic_info()
	elif event.is_action_pressed("toggle_stats_window") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C):
		toggle_character_stats()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if character_stats_window != null and character_stats_window.visible:
			character_stats_window.hide()
		else:
			_on_return_pressed()

func toggle_basic_info() -> void:
	if basic_info_window != null:
		if basic_info_window.has_method("toggle_window"):
			basic_info_window.toggle_window()
		else:
			basic_info_window.visible = not basic_info_window.visible

func toggle_character_stats() -> void:
	if character_stats_window != null:
		character_stats_window.toggle_window()

func bind_player(player: Node) -> void:
	if player == null:
		return
	if basic_info_window != null and basic_info_window.has_method("bind_player"):
		basic_info_window.bind_player(player)
	GameState.bind_player(player)

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
			if not cs.mana_changed.is_connected(_on_mana_changed):
				cs.mana_changed.connect(_on_mana_changed)
			_on_level_up(cs.level)
			_on_experience_changed(cs.experience, cs.xp_to_next_level())
			_on_mana_changed(cs.current_mana, cs.final_max_mana)

func show_dialogue(text: String) -> void:
	if dialogue_label != null:
		dialogue_label.text = text
	if dialogue_panel != null:
		dialogue_panel.visible = true

func hide_dialogue() -> void:
	if dialogue_panel != null:
		dialogue_panel.visible = false

func _on_health_changed(current: int, maximum: int) -> void:
	if basic_info_window != null and basic_info_window.has_method("update_hp"):
		basic_info_window.update_hp(current, maximum)
	elif health_bar != null:
		health_bar.max_value = float(maximum)
		health_bar.value = float(current)
		if health_label != null:
			health_label.text = "%d / %d" % [current, maximum]

func _on_mana_changed(current: int, maximum: int) -> void:
	if basic_info_window != null and basic_info_window.has_method("update_sp"):
		basic_info_window.update_sp(current, maximum)
	elif mana_bar != null:
		mana_bar.max_value = float(maximum)
		mana_bar.value = float(current)
		if mana_label != null:
			mana_label.text = "%d / %d" % [current, maximum]

func _on_level_up(new_level: int) -> void:
	if level_label != null:
		level_label.text = "Lv %d" % new_level

func _on_experience_changed(current_xp: int, xp_to_next: int) -> void:
	if basic_info_window != null and basic_info_window.has_method("update_lvl_exp"):
		basic_info_window.update_lvl_exp(current_xp, xp_to_next)
	elif xp_label != null:
		xp_label.text = "XP: %d / %d" % [current_xp, xp_to_next]

func _on_return_pressed() -> void:
	return_to_menu_requested.emit()
