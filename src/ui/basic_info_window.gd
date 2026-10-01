class_name BasicInfoWindow
extends Control

## Ragnarok Online style "Basic Info" status window.
## Displays character portrait, name, job, ID, level/job EXP bars,
## HP, SP, Stamina, Power, Weight, and Money.
##
## Features:
##   - Draggable by clicking and dragging the wood title bar
##   - Minimizable via [-] button (collapses to compact state)
##   - Closable via [X] button or toggled via hotkey (V)
##   - Fully signal-bound to Player, CharacterStatsComponent, and InventoryComponent

signal window_closed()
signal window_minimized(is_minimized: bool)

@onready var title_bar: PanelContainer = $WindowFrame/TitleBar
@onready var btn_minimize: Button = $WindowFrame/TitleBar/HBox/BtnMinimize
@onready var btn_close: Button = $WindowFrame/TitleBar/HBox/BtnClose

@onready var content_container: VBoxContainer = $WindowFrame/MainPanel/Margin/ContentVBox
@onready var exp_section: VBoxContainer = $WindowFrame/MainPanel/Margin/ContentVBox/ExpSection
@onready var stats_section: VBoxContainer = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection
@onready var footer_section: VBoxContainer = $WindowFrame/MainPanel/Margin/ContentVBox/FooterSection

# Profile Header
@onready var portrait_rect: TextureRect = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/PortraitFrame/PortraitTexture
@onready var label_name: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/LabelName
@onready var label_job: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/SubHBox/LabelJob
@onready var label_id: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/SubHBox/LabelID

# EXP Bars
@onready var bar_lvl_exp: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/LvlExpRow/BarLvlExp
@onready var label_lvl_exp: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/LvlExpRow/BarLvlExp/LabelLvlExp
@onready var bar_job_exp: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/JobExpRow/BarJobExp
@onready var label_job_exp: Label = $WindowFrame/MainPanel/Margin/ContentVBox/HeaderHBox/ProfileInfo/JobExpRow/BarJobExp/LabelJobExp

# Attribute Bars
@onready var bar_hp: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/HpRow/BarHP
@onready var label_hp: Label = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/HpRow/BarHP/LabelHP

@onready var bar_sp: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/SpRow/BarSP
@onready var label_sp: Label = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/SpRow/BarSP/LabelSP

@onready var bar_stamina: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/StaminaRow/BarStamina
@onready var label_stamina: Label = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/StaminaRow/BarStamina/LabelStamina

@onready var bar_power: ProgressBar = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/PowerRow/BarPower
@onready var label_power: Label = $WindowFrame/MainPanel/Margin/ContentVBox/StatsSection/PowerRow/BarPower/LabelPower

# Bottom stats
@onready var label_weight_val: Label = $WindowFrame/MainPanel/Margin/ContentVBox/FooterSection/WeightRow/LabelWeightVal
@onready var label_money_val: Label = $WindowFrame/MainPanel/Margin/ContentVBox/FooterSection/MoneyRow/LabelMoneyVal

# Runtime state
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _is_minimized: bool = false
var _bound_player: Player = null

# Fallback values when not wired to specific data
var current_stamina: int = 95
var max_stamina: int = 100
var current_power: int = 75
var max_power: int = 100
var current_weight: int = 1200
var max_weight: int = 2900
var current_money: int = 80000000
var job_level: int = 1
var job_exp: int = 900
var job_max_exp: int = 1800

func _ready() -> void:
	if btn_minimize != null:
		btn_minimize.pressed.connect(_on_minimize_pressed)
	if btn_close != null:
		btn_close.pressed.connect(_on_close_pressed)
	if title_bar != null:
		title_bar.gui_input.connect(_on_title_bar_gui_input)

	# Initial refresh with default/fallback data
	_update_all_displays()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_info"):
		toggle_window()

func toggle_window() -> void:
	visible = not visible

func _on_minimize_pressed() -> void:
	_is_minimized = not _is_minimized
	if stats_section != null:
		stats_section.visible = not _is_minimized
	if footer_section != null:
		footer_section.visible = not _is_minimized
	if exp_section != null:
		exp_section.visible = not _is_minimized
	window_minimized.emit(_is_minimized)

func _on_close_pressed() -> void:
	visible = false
	window_closed.emit()

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

# ── Data Binding ─────────────────────────────────────────────────────────────
func bind_player(player: Player) -> void:
	if player == null:
		return
	_bound_player = player

	# Character identity
	var p_name: String = "VALKYRIA"
	var p_class: String = "Job Novice"
	var p_id: String = "ID: 1024567"

	if player.stats != null and player.stats.definition != null:
		var def := player.stats.definition
		if not def.display_name.is_empty():
			p_name = def.display_name.to_upper()
		if not def.character_class.is_empty():
			p_class = "Job " + def.character_class.capitalize()
		if not def.character_id.is_empty():
			p_id = "ID: " + def.character_id

	set_character_info(p_name, p_class, p_id)

	# Stats binding
	if player.stats != null:
		var s: CharacterStatsComponent = player.stats
		s.health_changed.connect(_on_health_changed)
		s.mana_changed.connect(_on_mana_changed)
		s.level_up.connect(_on_level_up)
		s.experience_changed.connect(_on_experience_changed)
		s.stats_recomputed.connect(_on_stats_recomputed)

		_on_health_changed(s.current_health, s.max_health)
		_on_mana_changed(s.current_mana, s.final_max_mana)
		_on_level_up(s.level)
		_on_experience_changed(s.experience, s.xp_to_next_level())
		_on_stats_recomputed()

	# Inventory binding
	if player.inventory != null:
		player.inventory.inventory_changed.connect(_on_inventory_changed)
		_on_inventory_changed()

func set_character_info(c_name: String, job: String, c_id: String) -> void:
	if label_name != null:
		label_name.text = c_name
	if label_job != null:
		label_job.text = job
	if label_id != null:
		label_id.text = c_id

func set_portrait(tex: Texture2D) -> void:
	if portrait_rect != null and tex != null:
		portrait_rect.texture = tex

func update_hp(current: int, maximum: int) -> void:
	if bar_hp != null:
		bar_hp.max_value = maxi(maximum, 1)
		bar_hp.value = current
	if label_hp != null:
		label_hp.text = "%d / %d" % [current, maximum]

func update_sp(current: int, maximum: int) -> void:
	if bar_sp != null:
		bar_sp.max_value = maxi(maximum, 1)
		bar_sp.value = current
	if label_sp != null:
		label_sp.text = "%d / %d" % [current, maximum]

func update_lvl_exp(current_xp: int, next_xp: int) -> void:
	if bar_lvl_exp != null:
		bar_lvl_exp.max_value = maxi(next_xp, 1)
		bar_lvl_exp.value = current_xp
	if label_lvl_exp != null:
		label_lvl_exp.text = "%d / %d" % [current_xp, next_xp]

func update_job_exp(current_jxp: int, next_jxp: int) -> void:
	job_exp = current_jxp
	job_max_exp = next_jxp
	if bar_job_exp != null:
		bar_job_exp.max_value = maxi(next_jxp, 1)
		bar_job_exp.value = current_jxp
	if label_job_exp != null:
		label_job_exp.text = "%d / %d" % [current_jxp, next_jxp]

func update_stamina(current: int, maximum: int) -> void:
	current_stamina = current
	max_stamina = maximum
	if bar_stamina != null:
		bar_stamina.max_value = maxi(maximum, 1)
		bar_stamina.value = current
	if label_stamina != null:
		label_stamina.text = "%d / %d" % [current, maximum]

func update_power(current: int, maximum: int = 100) -> void:
	current_power = current
	max_power = maximum
	if bar_power != null:
		bar_power.max_value = maxi(maximum, 1)
		bar_power.value = current
	if label_power != null:
		label_power.text = "%d / %d" % [current, maximum]

func update_weight(current: int, maximum: int) -> void:
	current_weight = current
	max_weight = maximum
	if label_weight_val != null:
		label_weight_val.text = "%d / %d" % [current, maximum]

func update_money(amount: int) -> void:
	current_money = amount
	if label_money_val != null:
		label_money_val.text = _format_number(amount)

# ── Signal Listeners ──────────────────────────────────────────────────────────
func _on_health_changed(current: int, maximum: int) -> void:
	update_hp(current, maximum)

func _on_mana_changed(current: int, maximum: int) -> void:
	update_sp(current, maximum)

func _on_level_up(_new_level: int) -> void:
	if _bound_player != null and _bound_player.stats != null:
		update_lvl_exp(_bound_player.stats.experience, _bound_player.stats.xp_to_next_level())

func _on_experience_changed(current_xp: int, xp_to_next: int) -> void:
	update_lvl_exp(current_xp, xp_to_next)

func _on_stats_recomputed() -> void:
	if _bound_player != null and _bound_player.stats != null:
		var atk: int = _bound_player.stats.final_attack
		update_power(atk, 100)

func _on_inventory_changed() -> void:
	if _bound_player != null and _bound_player.inventory != null:
		var inv: InventoryComponent = _bound_player.inventory
		var count: int = inv.items.size()
		# Compute weight: e.g. base weight 1200 + items * 50
		var calculated_weight: int = 1200 + (count * 50)
		var max_wt: int = 2900
		update_weight(calculated_weight, max_wt)

# ── Helper Formatting ─────────────────────────────────────────────────────────
func _update_all_displays() -> void:
	update_stamina(current_stamina, max_stamina)
	update_power(current_power, max_power)
	update_job_exp(job_exp, job_max_exp)
	update_weight(current_weight, max_weight)
	update_money(current_money)

static func _format_number(n: int) -> String:
	var s: String = str(absi(n))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	if n < 0:
		res = "-" + res
	return res
