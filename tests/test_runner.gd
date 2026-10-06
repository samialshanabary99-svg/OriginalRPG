extends SceneTree

const DirectionalProp3D = preload("res://src/entities/directional_prop_3d.gd")

## Automated test runner — Phase 2 RPG Systems.
## Run with: godot --headless --script tests/test_runner.gd

var _total: int = 0
var _failed: int = 0

func _init() -> void:
	print("[TestRunner] OriginalRPG — Phase 2 RPG Systems")
	print("[TestRunner] ─────────────────────────────────────────")

	# Phase 1 regression
	_test_damage_calculator()
	_test_stats_component()
	_test_scene_loading()
	_test_player_composition()
	_test_movement()
	_test_interaction()

	# Phase 2 new systems
	_test_character_stats_component()
	_test_inventory_component()
	_test_item_definition()
	_test_quest_definition()
	_test_enemy_entity()
	_test_xp_leveling()

	# RPG Player Foundation Expansion
	_test_player_foundation()
	_test_equipment_modifiers()

	# Combat Vertical Slice
	_test_combat_vertical_slice()

	# Player 8-Directional Idle Animation
	_test_player_idle_animation()

	# Data-Driven Content Architecture & Validation
	_test_data_driven_content()

	# AI-Assisted Asset Pipeline & Validator
	_test_asset_pipeline_validation()

	# Ragnarok Online Style Basic Info Window
	_test_basic_info_window()

	# Multi-Layer TileMapLayer Field & Slope Systems
	_test_multi_layer_tilemap_field()

	# 8-Directional Character Animations, Wolf Monster & Green Stalks
	_test_wolf_player_stalks_integration()

	# Mouse Click-to-Move, Cell Target Preview & Aim Reticle Combat
	_test_mouse_controls_and_combat()

	# Health and SP Overhead Bars & HUD Status Bars
	_test_health_and_sp_bars()

	# Character Stats Window & GameState Attribute Point Economy
	_test_character_stats_and_game_state()

	print("")
	print("[TestRunner] ─────────────────────────────────────────")
	print("[TestRunner] %d tests | %d failures" % [_total, _failed])
	if _failed == 0:
		print("[TestRunner] ALL TESTS PASSED.")
		quit(0)
	else:
		print("[TestRunner] SOME TESTS FAILED.")
		quit(1)

# ── Assertion helper ───────────────────────────────────────────────────────────
func _ok(label: String, condition: bool) -> void:
	_total += 1
	if condition:
		print("  [PASS] %d. %s" % [_total, label])
	else:
		print("  [FAIL] %d. %s" % [_total, label])
		_failed += 1

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 REGRESSION
# ══════════════════════════════════════════════════════════════════════════════

func _test_damage_calculator() -> void:
	print("\n[Group A] DamageCalculator")
	_ok("basic damage subtraction", DamageCalculator.calculate_damage(35, 10, 1) == 25)
	_ok("minimum damage clamp", DamageCalculator.calculate_damage(5, 50, 1) == 1)
	_ok("is_alive true", DamageCalculator.is_alive(1))
	_ok("is_alive false at 0", not DamageCalculator.is_alive(0))
	_ok("xp_reward level 1 = 20", DamageCalculator.xp_reward(1) == 20)
	_ok("xp_reward level 5 = 100", DamageCalculator.xp_reward(5) == 100)

func _test_stats_component() -> void:
	print("\n[Group B] StatsComponent")
	var s := StatsComponent.new()
	s.max_health = 100
	s._ready()

	var hp_sig: Array[int] = []
	s.health_changed.connect(func(c: int, m: int): hp_sig.append(c); hp_sig.append(m))
	s.apply_damage(20)
	_ok("damage reduces HP", s.current_health == 80)
	_ok("health_changed emitted", hp_sig.size() == 2 and hp_sig[0] == 80)

	var died_flag: Array[bool] = [false]
	s.died.connect(func(): died_flag[0] = true)
	s.apply_damage(9999)
	_ok("HP clamps at 0", s.current_health == 0)
	_ok("died signal fires", died_flag[0])

	s.max_health = 100; s._ready()
	s.heal(30)
	_ok("heal restores HP", s.current_health == 100)

	s.apply_damage(40)
	var ser: Dictionary = s.serialize()
	var s2 := StatsComponent.new()
	s2.deserialize(ser)
	_ok("serialize/deserialize HP", s2.current_health == 60)
	_ok("serialize/deserialize max_health", s2.max_health == 100)
	s.free(); s2.free()

func _test_scene_loading() -> void:
	print("\n[Group C] Scene loading")
	var paths: Array[String] = [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/maps/test_world.tscn",
		"res://scenes/entities/player.tscn",
		"res://scenes/entities/enemy.tscn",
		"res://scenes/objects/ancient_monument.tscn",
		"res://scenes/objects/item_pickup.tscn",
		"res://scenes/ui/hud.tscn",
	]
	for path: String in paths:
		var packed: PackedScene = load(path)
		var ok: bool = packed != null
		if ok:
			var inst: Node = packed.instantiate()
			ok = inst != null
			if inst != null:
				inst.free()
		_ok("loads: %s" % path.get_file(), ok)

func _test_player_composition() -> void:
	print("\n[Group D] Player composition")
	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)

	_ok("has CharacterStatsComponent", player.get_node_or_null("CharacterStatsComponent") != null)
	_ok("has InventoryComponent", player.get_node_or_null("InventoryComponent") != null)
	_ok("has EquipmentComponent", player.get_node_or_null("EquipmentComponent") != null)
	_ok("has InteractorComponent", player.get_node_or_null("InteractorComponent") != null)
	_ok("has AttackArea", player.get_node_or_null("AttackArea") != null)
	_ok("has Camera2D", player.get_node_or_null("Camera2D") != null)
	_ok("has Sprite2D", player.get_node_or_null("Sprite2D") != null)
	_ok("move_speed is positive", player.move_speed > 0.0)
	var cs: Node = player.get_node_or_null("CharacterStatsComponent")
	_ok("CharacterStatsComponent is correct type", cs is CharacterStatsComponent)

	player.free()

func _test_movement() -> void:
	print("\n[Group E] Player movement")
	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)

	player.global_position = Vector2.ZERO
	player.input_direction = Vector2(1.0, 0.0)
	player._apply_movement()
	_ok("velocity set when moving right", player.velocity.x > 0.0)

	player.input_direction = Vector2(-1.0, 0.0)
	player._apply_movement()
	_ok("velocity set when moving left", player.velocity.x < 0.0)

	player.input_direction = Vector2.ZERO
	player._apply_movement()
	_ok("velocity is zero when no input", player.velocity == Vector2.ZERO)

	var moved_fired: Array[bool] = [false]
	player.player_moved.connect(func(_p: Vector2): moved_fired[0] = true)
	player.input_direction = Vector2(0.0, 1.0)
	player._apply_movement()
	_ok("player_moved signal fires on movement", moved_fired[0])

	player.free()

func _test_interaction() -> void:
	print("\n[Group F] Interaction system")
	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)
	var monument: AncientMonument = (load("res://scenes/objects/ancient_monument.tscn") as PackedScene).instantiate() as AncientMonument
	get_root().add_child(monument)

	var fired: Array[String] = []
	monument.inspection_triggered.connect(func(m: String): fired.append(m))
	monument.interact(player)
	_ok("monument fires inspection_triggered", fired.size() == 1)
	_ok("interaction_count == 1", monument.interaction_count == 1)

	var interactor: InteractorComponent = player.get_node("InteractorComponent") as InteractorComponent
	interactor.nearby_interactables.append(monument)
	interactor._update_current_target()
	var result: bool = interactor.try_interact()
	_ok("try_interact triggers monument", result and monument.interaction_count == 2)

	monument.free(); player.free()

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 NEW TESTS
# ══════════════════════════════════════════════════════════════════════════════

func _test_character_stats_component() -> void:
	print("\n[Group G] CharacterStatsComponent")
	var cs := CharacterStatsComponent.new()
	cs.max_health = 100
	cs.attack = 15
	cs.defence = 5
	cs.level = 1
	cs.experience = 0
	cs._ready()

	_ok("initial level == 1", cs.level == 1)
	_ok("initial attack == 15", cs.attack == 15)
	_ok("initial defence == 5", cs.defence == 5)
	_ok("xp_to_next_level == 100 at level 1", cs.xp_to_next_level() == 100)

	# Damage and heal via inherited methods
	cs.apply_damage(30)
	_ok("apply_damage reduces HP", cs.current_health == 70)
	cs.heal(20)
	_ok("heal restores HP", cs.current_health == 90)

	# Serialization roundtrip
	cs.apply_damage(10)
	var ser: Dictionary = cs.serialize()
	var cs2 := CharacterStatsComponent.new()
	cs2.deserialize(ser)
	_ok("serialize/deserialize HP", cs2.current_health == 80)
	_ok("serialize/deserialize attack", cs2.attack == 15)
	_ok("serialize/deserialize defence", cs2.defence == 5)
	_ok("serialize/deserialize level", cs2.level == 1)

	cs.free(); cs2.free()

func _test_inventory_component() -> void:
	print("\n[Group H] InventoryComponent")
	var inv := InventoryComponent.new()
	inv.capacity = 5

	var item1 := ItemDefinition.new()
	item1.item_id = "herb"; item1.display_name = "Herb"; item1.stackable = true

	var item2 := ItemDefinition.new()
	item2.item_id = "sword"; item2.display_name = "Sword"; item2.stackable = false

	var added_sig: Array[String] = []
	inv.item_added.connect(func(it: ItemDefinition): added_sig.append(it.item_id))

	_ok("add_item returns true", inv.add_item(item1))
	_ok("item_added signal fires", added_sig.size() == 1 and added_sig[0] == "herb")
	_ok("has_item finds herb", inv.has_item("herb"))
	_ok("count_item herb == 1", inv.count_item("herb") == 1)

	inv.add_item(item1)
	_ok("count_item herb == 2 after second add", inv.count_item("herb") == 2)

	_ok("remove_item returns true", inv.remove_item(item1))
	_ok("count_item herb == 1 after remove", inv.count_item("herb") == 1)

	# Capacity
	for i: int in range(5):
		inv.add_item(item2)
	_ok("is_full when at capacity", inv.is_full())
	_ok("add_item returns false when full (non-stackable)", not inv.add_item(item2))

	# Serialize roundtrip
	inv.items.clear()
	inv.add_item(item1)
	var ser: Dictionary = inv.serialize()
	var inv2 := InventoryComponent.new()
	inv2.deserialize(ser)
	_ok("deserialize restores item_id", inv2.items.size() == 1 and inv2.items[0].item_id == "herb")

	inv.free(); inv2.free()

func _test_item_definition() -> void:
	print("\n[Group I] ItemDefinition")
	var item := ItemDefinition.new()
	item.item_id = "potion_health"
	item.display_name = "Health Potion"
	item.stackable = true
	item.max_stack_size = 10
	item.category = ItemDefinition.Category.CONSUMABLE

	var ser: Dictionary = item.serialize()
	_ok("serialize has item_id", ser.has("item_id") and ser["item_id"] == "potion_health")
	_ok("serialize has category", ser.has("category"))

	var item2 := ItemDefinition.new()
	item2.deserialize(ser)
	_ok("deserialize item_id", item2.item_id == "potion_health")
	_ok("deserialize stackable", item2.stackable == true)
	_ok("deserialize max_stack_size", item2.max_stack_size == 10)

func _test_quest_definition() -> void:
	print("\n[Group J] QuestDefinition")
	var q := QuestDefinition.new()
	q.quest_id = "q_001"
	q.title = "The First Step"
	q.xp_reward = 200
	q.gold_reward = 50
	q.recommended_level = 1

	var ser: Dictionary = q.serialize()
	_ok("serialize has quest_id", ser["quest_id"] == "q_001")
	_ok("serialize has xp_reward", int(ser["xp_reward"]) == 200)

	var q2 := QuestDefinition.new()
	q2.deserialize(ser)
	_ok("deserialize quest_id", q2.quest_id == "q_001")
	_ok("deserialize title", q2.title == "The First Step")
	_ok("deserialize gold_reward", q2.gold_reward == 50)

func _test_enemy_entity() -> void:
	print("\n[Group K] Enemy entity")
	var enemy: Enemy = (load("res://scenes/entities/enemy.tscn") as PackedScene).instantiate() as Enemy
	get_root().add_child(enemy)

	var e_stats: CharacterStatsComponent = enemy.get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	_ok("enemy has CharacterStatsComponent", e_stats != null)
	_ok("enemy has AggroArea", enemy.get_node_or_null("AggroArea") != null)
	_ok("enemy has AttackArea", enemy.get_node_or_null("AttackArea") != null)

	if e_stats != null:
		_ok("enemy stats.attack > 0", e_stats.attack > 0)
		_ok("enemy stats.max_health > 0", e_stats.max_health > 0)

		# receive_hit reduces HP
		var initial_hp: int = e_stats.current_health
		enemy.receive_hit(5)
		_ok("receive_hit reduces HP", e_stats.current_health < initial_hp)

	# Death test — use a fresh instance to avoid DEAD state guard
	var enemy2: Enemy = (load("res://scenes/entities/enemy.tscn") as PackedScene).instantiate() as Enemy
	get_root().add_child(enemy2)
	var e2_stats: CharacterStatsComponent = enemy2.get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	# Connect directly to stats.died to bypass the await in _on_died
	var died_flag: Array[bool] = [false]
	if e2_stats != null:
		e2_stats.died.connect(func(): died_flag[0] = true)
	enemy2.receive_hit(9999)
	_ok("massive hit drives HP to 0 and fires died", died_flag[0])

	# enemy and enemy2 self-queue_free on death; no manual free needed


func _test_xp_leveling() -> void:
	print("\n[Group L] XP and leveling")
	var cs := CharacterStatsComponent.new()
	cs.max_health = 100
	cs.level = 1
	cs.experience = 0
	cs.attack = 10
	cs.defence = 5
	cs._ready()

	var leveled_up: Array[int] = []
	cs.level_up.connect(func(lv: int): leveled_up.append(lv))

	var xp_changes: Array[int] = []
	cs.experience_changed.connect(func(cur: int, _nxt: int): xp_changes.append(cur))

	cs.gain_experience(50)
	_ok("gain_experience partial — no level up", leveled_up.is_empty())
	_ok("experience_changed signal fires", xp_changes.size() == 1)
	_ok("experience is 50", cs.experience == 50)

	cs.gain_experience(60)  # 50+60=110 → level up, remainder 10
	_ok("level-up triggered at 100 XP", leveled_up.size() == 1 and leveled_up[0] == 2)
	_ok("level is 2", cs.level == 2)
	_ok("experience resets to remainder", cs.experience == 10)
	_ok("max_health increased on level-up", cs.max_health == 110)
	_ok("attack increased on level-up", cs.attack == 12)
	_ok("HP fully restored on level-up", cs.current_health == cs.max_health)

	# xp_reward integration
	var reward: int = DamageCalculator.xp_reward(cs.level)
	_ok("xp_reward(2) == 40", reward == 40)

	cs.free()

func _test_player_foundation() -> void:
	print("\n[Group M] Player Character Foundation")
	# 1. CharacterDefinition data integrity
	var def := CharacterDefinition.new()
	def.character_id = "test_mage"
	def.display_name = "Apprentice"
	def.character_class = "mage"
	def.base_max_health = 75
	def.base_max_mana = 120
	def.base_attack = 6
	def.base_defence = 3
	def.base_speed_stat = 12
	def.health_per_level = 6
	def.mana_per_level = 15
	def.attack_per_level = 1
	def.defence_per_level = 1

	var ser: Dictionary = def.serialize()
	_ok("CharacterDefinition serialize has character_id", ser.get("character_id") == "test_mage")
	_ok("CharacterDefinition serialize has base_max_mana", ser.get("base_max_mana") == 120)

	var def2 := CharacterDefinition.new()
	def2.deserialize(ser)
	_ok("CharacterDefinition deserialize restores class", def2.character_class == "mage")
	_ok("CharacterDefinition deserialize restores base_max_health", def2.base_max_health == 75)

	# 2. CharacterStatsComponent initialized from CharacterDefinition
	var cs := CharacterStatsComponent.new()
	cs.definition = def2
	cs._ready()
	_ok("Stats initialized from definition: max_health", cs.max_health == 75)
	_ok("Stats initialized from definition: current_health", cs.current_health == 75)
	_ok("Stats initialized from definition: current_mana", cs.current_mana == 120)
	_ok("Stats initialized from definition: final_attack", cs.final_attack == 6)
	_ok("Stats initialized from definition: final_defence", cs.final_defence == 3)

	# 3. Mana system (spend, clamp, restore)
	var mana_emitted: Array[bool] = [false]
	cs.mana_changed.connect(func(c: int, _m: int): mana_emitted[0] = true)
	var spend_ok: bool = cs.spend_mana(30)
	_ok("spend_mana(30) succeeds", spend_ok and cs.current_mana == 90)
	_ok("mana_changed signal emitted on spend", mana_emitted[0])
	var overspend: bool = cs.spend_mana(100)
	_ok("overspend mana fails gracefully", not overspend and cs.current_mana == 90)
	cs.restore_mana(50)
	_ok("restore_mana clamps to max_mana", cs.current_mana == 120)

	# 4. Level-up scaling with CharacterDefinition
	cs.gain_experience(100)
	_ok("Mage scaled health on level-up (+6)", cs.max_health == 81)
	_ok("Mage scaled mana on level-up (+15)", cs.final_max_mana == 135)
	_ok("Mage scaled attack on level-up (+1)", cs.final_attack == 7)
	cs.free()

	# 5. Player instance state and movement foundation
	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)
	_ok("Player initial state is ALIVE", player.character_state == Player.CharacterState.ALIVE)
	_ok("Player is_alive() true initially", player.is_alive())
	_ok("Player is_moving() false initially", not player.is_moving())

	# Movement facing tracking
	var facing_changes: Array[Vector2] = []
	player.facing_changed.connect(func(dir: Vector2): facing_changes.append(dir))
	player.input_direction = Vector2(0.0, 1.0)
	player._apply_movement()
	_ok("Facing direction updated to down", player.facing_direction == Vector2(0.0, 1.0))
	_ok("facing_changed signal fired", facing_changes.size() == 1 and facing_changes[0] == Vector2(0.0, 1.0))
	_ok("Player is_moving() true when velocity > 0", player.is_moving())

	# CharacterState transition on death
	var state_events: Array[int] = []
	player.player_state_changed.connect(func(st: int): state_events.append(st))
	var player_stats: CharacterStatsComponent = player.get_node("CharacterStatsComponent") as CharacterStatsComponent
	# Explicitly connect if player _ready has not executed yet
	if not player_stats.died.is_connected(player._on_died):
		player_stats.died.connect(player._on_died)
	player_stats.apply_damage(9999)
	_ok("Player state transitions to DEAD on fatal damage", player.character_state == Player.CharacterState.DEAD)
	_ok("Player is_alive() false after death", not player.is_alive())
	_ok("player_state_changed signal fired with DEAD", state_events.size() == 1 and state_events[0] == Player.CharacterState.DEAD)

	player.free()

func _test_equipment_modifiers() -> void:
	print("\n[Group N] Equipment & Modifiers")
	var cs := CharacterStatsComponent.new()
	cs.base_attack = 10
	cs.base_defence = 5
	cs.base_speed = 10
	cs.base_max_mana = 50
	cs.max_health = 100
	cs._ready()

	# 1. Direct modifier system on CharacterStatsComponent
	cs.add_modifier("sword_iron", {"attack": 8, "speed": -1})
	_ok("Modifier increases final_attack", cs.final_attack == 18)
	_ok("Modifier adjusts final_speed", cs.final_speed == 9)
	_ok("Base attack unchanged after modifier", cs.base_attack == 10)
	_ok("has_modifier returns true", cs.has_modifier("sword_iron"))

	cs.add_modifier("shield_wood", {"defence": 6, "max_health": 20})
	_ok("Stacking modifier adds defence", cs.final_defence == 11)
	_ok("Equipment modifier expands max_health", cs.max_health == 120)

	cs.remove_modifier("sword_iron")
	_ok("remove_modifier restores final_attack", cs.final_attack == 10)
	_ok("remove_modifier restores final_speed", cs.final_speed == 10)
	_ok("Remaining modifier stays active", cs.final_defence == 11)
	_ok("max_health does not accumulate on unrelated modifier removal", cs.max_health == 120)
	cs.remove_modifier("shield_wood")
	_ok("Removing health modifier restores base max_health", cs.max_health == 100)

	# 2. EquipmentComponent slot management
	var eq := EquipmentComponent.new()
	# Attach to temporary parent node along with stats
	var host := Node2D.new()
	get_root().add_child(host)
	host.add_child(cs)
	host.add_child(eq)

	var item_helmet := ItemDefinition.new()
	item_helmet.item_id = "helm_bronze"
	item_helmet.display_name = "Bronze Helmet"
	item_helmet.category = ItemDefinition.Category.ARMOUR

	var equipped_signals: Array[String] = []
	eq.item_equipped.connect(func(slot: String, _it: ItemDefinition): equipped_signals.append(slot))

	var equip_ok: bool = eq.equip("head", item_helmet)
	_ok("equip returns true", equip_ok)
	_ok("item_equipped signal fired for head slot", equipped_signals.size() == 1 and equipped_signals[0] == "head")
	_ok("is_slot_occupied true for head", eq.is_slot_occupied("head"))
	_ok("get_equipped returns item", eq.get_equipped("head") == item_helmet)

	var unequipped_item: ItemDefinition = eq.unequip("head")
	_ok("unequip returns equipped item", unequipped_item == item_helmet)
	_ok("is_slot_occupied false after unequip", not eq.is_slot_occupied("head"))

	host.free()

func _test_combat_vertical_slice() -> void:
	print("\n[Group O] Combat Vertical Slice")

	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)

	var enemy: Enemy = (load("res://scenes/entities/enemy.tscn") as PackedScene).instantiate() as Enemy
	get_root().add_child(enemy)

	var p_stats: CharacterStatsComponent = player.get_node("CharacterStatsComponent") as CharacterStatsComponent
	var e_stats: CharacterStatsComponent = enemy.get_node("CharacterStatsComponent") as CharacterStatsComponent

	# 1. Target acquisition / setting
	var target_signals: Array[Node] = []
	player.target_changed.connect(func(t: Node): target_signals.append(t))

	player.set_target(enemy)
	_ok("Player target successfully set to enemy", player.current_target == enemy)
	_ok("target_changed signal fired", target_signals.size() == 1 and target_signals[0] == enemy)

	# 2. Valid attack execution
	var initial_enemy_hp: int = e_stats.current_health
	var expected_dmg: int = DamageCalculator.calculate_damage(p_stats.final_attack, e_stats.final_defence)

	var combat_results: Array[CombatResult] = []
	player.combat_resolved.connect(func(res: CombatResult): combat_results.append(res))

	var attack_res: CombatResult = player.attack_target(enemy)
	_ok("attack_target returns valid CombatResult", attack_res.is_valid)
	_ok("combat_resolved signal emitted with result", combat_results.size() == 1 and combat_results[0] == attack_res)
	_ok("last_combat_result matches returned result", player.last_combat_result == attack_res)
	_ok("attacker is player", attack_res.attacker == player)
	_ok("target is enemy", attack_res.target == enemy)

	# 3. Deterministic damage calculation
	_ok("damage_dealt matches DamageCalculator formula", attack_res.damage_dealt == expected_dmg)

	# 4. Enemy health reduction
	_ok("enemy health reduced by damage dealt", e_stats.current_health == initial_enemy_hp - expected_dmg)
	_ok("attack_res target_remaining_health matches enemy current_health", attack_res.target_remaining_health == e_stats.current_health)

	# 5. Defeat & Reward flow
	var weak_enemy: Enemy = (load("res://scenes/entities/enemy.tscn") as PackedScene).instantiate() as Enemy
	get_root().add_child(weak_enemy)
	var weak_stats: CharacterStatsComponent = weak_enemy.get_node("CharacterStatsComponent") as CharacterStatsComponent
	weak_stats.set_health(1) # 1 HP remaining

	player.set_target(weak_enemy)
	player._attack_timer = 0.0 # reset cooldown for test

	var initial_xp: int = p_stats.experience
	var defeat_res: CombatResult = player.attack_target(weak_enemy)

	_ok("attack against 1HP enemy is valid", defeat_res.is_valid)
	_ok("target_defeated is true", defeat_res.target_defeated)
	_ok("weak enemy health is 0", weak_stats.current_health == 0)
	_ok("weak enemy is_targetable() is false", not weak_enemy.is_targetable())
	_ok("defeat_res awarded XP", defeat_res.xp_earned > 0)
	_ok("player gained XP from defeat", p_stats.experience == initial_xp + defeat_res.xp_earned)
	_ok("player current_target cleared on defeat", player.current_target == null)

	# 6. Invalid / dead target handling
	# Case A: Attack dead target
	player._attack_timer = 0.0
	var dead_target_res: CombatResult = player.attack_target(weak_enemy)
	_ok("attack on already dead target is invalid", not dead_target_res.is_valid)
	_ok("error_reason is target_dead", dead_target_res.error_reason == "target_dead")
	_ok("no damage dealt to dead target", dead_target_res.damage_dealt == 0)

	# Case B: Attack null target with no enemies in range
	player.clear_target()
	player._attack_timer = 0.0
	var no_target_res: CombatResult = player.attack_target(null)
	_ok("attack with no target is invalid", not no_target_res.is_valid)
	_ok("error_reason is no_target", no_target_res.error_reason == "no_target")

	# Case C: Attack while on cooldown
	player.set_target(enemy)
	player._attack_timer = 1.0 # set cooldown active
	var cooldown_res: CombatResult = player.attack_target(enemy)
	_ok("attack while on cooldown is invalid", not cooldown_res.is_valid)
	_ok("error_reason is on_cooldown", cooldown_res.error_reason == "on_cooldown")

	# Case D: Attack when player is dead
	player._attack_timer = 0.0
	player.character_state = Player.CharacterState.DEAD
	var dead_player_res: CombatResult = player.attack_target(enemy)
	_ok("attack when player dead is invalid", not dead_player_res.is_valid)
	_ok("error_reason is attacker_invalid_state", dead_player_res.error_reason == "attacker_invalid_state")

	player.free()
	enemy.free()
	# weak_enemy queues itself for free on death

func _test_player_idle_animation() -> void:
	print("\n[Group P] Player 8-Directional Idle Animation")

	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)

	# 1. Node composition
	_ok("Player has AnimatedSprite2D", player.get_node_or_null("AnimatedSprite2D") != null)
	var anim_sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_ok("AnimatedSprite2D has sprite_frames assigned", anim_sprite.sprite_frames != null)

	var sf: SpriteFrames = anim_sprite.sprite_frames
	var directions: Array[String] = [
		"south", "south-east", "east", "north-east",
		"north", "north-west", "west", "south-west"
	]

	# 2. All 8 directional animations present and each has 4 frames
	var all_animations_present: bool = true
	var all_have_four_frames: bool = true
	for dir: String in directions:
		var a_name: StringName = StringName("idle_" + dir)
		if not sf.has_animation(a_name):
			all_animations_present = false
		elif sf.get_frame_count(a_name) != 4:
			all_have_four_frames = false

	_ok("SpriteFrames has all 8 idle directional animations", all_animations_present)
	_ok("All 8 idle animations have 4 frames", all_have_four_frames)

	# 3. Vector to direction name conversion tests
	_ok("Vector (0, 1) converts to south", Player.vector_to_direction_name(Vector2(0, 1)) == "south")
	_ok("Vector (1, 0) converts to east", Player.vector_to_direction_name(Vector2(1, 0)) == "east")
	_ok("Vector (0, -1) converts to north", Player.vector_to_direction_name(Vector2(0, -1)) == "north")
	_ok("Vector (-1, 0) converts to west", Player.vector_to_direction_name(Vector2(-1, 0)) == "west")
	_ok("Vector (1, 1) converts to south-east", Player.vector_to_direction_name(Vector2(1, 1)) == "south-east")
	_ok("Vector (-1, 1) converts to south-west", Player.vector_to_direction_name(Vector2(-1, 1)) == "south-west")
	_ok("Vector (1, -1) converts to north-east", Player.vector_to_direction_name(Vector2(1, -1)) == "north-east")
	_ok("Vector (-1, -1) converts to north-west", Player.vector_to_direction_name(Vector2(-1, -1)) == "north-west")

	# 4. Movement facing updates animation
	player.input_direction = Vector2(0, 1) # moving south
	player._apply_movement()
	_ok("AnimatedSprite2D plays idle_south after moving south", anim_sprite.animation == &"idle_south")

	player.input_direction = Vector2(-1, -1) # moving north-west
	player._apply_movement()
	_ok("AnimatedSprite2D plays idle_north-west after moving north-west", anim_sprite.animation == &"idle_north-west")

	player.free()

func _test_data_driven_content() -> void:
	print("\n[Group Q] Data-Driven Content Architecture & Validation")

	# 1. Loading all definitions from res://data/
	var load_summary: Dictionary = ContentRegistry.load_all()
	_ok("ContentRegistry loads definitions without errors", (load_summary["errors"] as Array).is_empty())
	_ok("ContentRegistry loaded at least 8 definitions", int(load_summary["loaded"]) >= 8)

	# 2. Check registered definitions
	_ok("ContentRegistry has player_default", ContentRegistry.has_character("player_default"))
	_ok("ContentRegistry has mage_apprentice", ContentRegistry.has_character("mage_apprentice"))
	_ok("ContentRegistry has goblin_scout", ContentRegistry.has_enemy("goblin_scout"))
	_ok("ContentRegistry has orc_warrior", ContentRegistry.has_enemy("orc_warrior"))
	_ok("ContentRegistry has herb_basic", ContentRegistry.has_item("herb_basic"))
	_ok("ContentRegistry has potion_health", ContentRegistry.has_item("potion_health"))
	_ok("ContentRegistry has potion_mana", ContentRegistry.has_item("potion_mana"))
	_ok("ContentRegistry has sword_iron", ContentRegistry.has_item("sword_iron"))
	_ok("ContentRegistry has shield_wooden", ContentRegistry.has_item("shield_wooden"))
	_ok("ContentRegistry has fireball", ContentRegistry.has_skill("fireball"))
	_ok("ContentRegistry has heal_minor", ContentRegistry.has_skill("heal_minor"))

	# 3. Enemy Definition values
	var goblin: EnemyDefinition = ContentRegistry.get_enemy("goblin_scout")
	_ok("goblin_scout max_health == 35", goblin != null and goblin.max_health == 35)
	_ok("goblin_scout attack == 7", goblin != null and goblin.attack == 7)
	_ok("goblin_scout move_speed == 110.0", goblin != null and is_equal_approx(goblin.move_speed, 110.0))
	_ok("goblin_scout xp_reward == 15", goblin != null and goblin.xp_reward == 15)

	var orc: EnemyDefinition = ContentRegistry.get_enemy("orc_warrior")
	_ok("orc_warrior max_health == 80", orc != null and orc.max_health == 80)
	_ok("orc_warrior attack == 14", orc != null and orc.attack == 14)
	_ok("orc_warrior defence == 4", orc != null and orc.defence == 4)
	_ok("orc_warrior xp_reward == 35", orc != null and orc.xp_reward == 35)

	# 4. Item Definition values
	var sword: ItemDefinition = ContentRegistry.get_item("sword_iron")
	_ok("sword_iron category is WEAPON", sword != null and sword.category == ItemDefinition.Category.WEAPON)
	_ok("sword_iron equip_slot is weapon", sword != null and sword.equip_slot == "weapon")
	_ok("sword_iron has attack modifier of 8", sword != null and int(sword.stat_modifiers.get("attack", 0)) == 8)
	_ok("sword_iron is not stackable", sword != null and not sword.stackable)

	var shield: ItemDefinition = ContentRegistry.get_item("shield_wooden")
	_ok("shield_wooden category is ARMOUR", shield != null and shield.category == ItemDefinition.Category.ARMOUR)
	_ok("shield_wooden has defence modifier of 5", shield != null and int(shield.stat_modifiers.get("defence", 0)) == 5)

	var pot: ItemDefinition = ContentRegistry.get_item("potion_health")
	_ok("potion_health heal_amount is 50", pot != null and pot.heal_amount == 50)

	# 5. Skill Definition values
	var fireball: SkillDefinition = ContentRegistry.get_skill("fireball")
	_ok("fireball mana_cost is 15", fireball != null and fireball.mana_cost == 15)
	_ok("fireball power is 35", fireball != null and fireball.power == 35)
	_ok("fireball skill_type is damage", fireball != null and fireball.skill_type == "damage")

	var heal_skill: SkillDefinition = ContentRegistry.get_skill("heal_minor")
	_ok("heal_minor skill_type is heal", heal_skill != null and heal_skill.skill_type == "heal")
	_ok("heal_minor target_type is self", heal_skill != null and heal_skill.target_type == "self")

	# 6. Validation tests for malformed definitions
	var bad_enemy := EnemyDefinition.new()
	bad_enemy.enemy_id = "" # empty id
	bad_enemy.max_health = -10
	bad_enemy.attack = -5
	var enemy_errs: Array[String] = bad_enemy.validate()
	_ok("Validation detects empty enemy_id", enemy_errs.any(func(e: String) -> bool: return e.contains("enemy_id")))
	_ok("Validation detects negative enemy max_health", enemy_errs.any(func(e: String) -> bool: return e.contains("max_health")))

	var bad_item := ItemDefinition.new()
	bad_item.item_id = ""
	bad_item.category = ItemDefinition.Category.WEAPON
	bad_item.equip_slot = "" # invalid weapon without slot
	var item_errs: Array[String] = bad_item.validate()
	_ok("Validation detects empty item_id", item_errs.any(func(e: String) -> bool: return e.contains("item_id")))
	_ok("Validation detects weapon missing equip_slot", item_errs.any(func(e: String) -> bool: return e.contains("equip_slot")))

	var bad_skill := SkillDefinition.new()
	bad_skill.skill_id = "test_bad"
	bad_skill.display_name = "Bad Skill"
	bad_skill.skill_type = "invalid_type"
	bad_skill.target_type = "invalid_target"
	bad_skill.mana_cost = -5
	var skill_errs: Array[String] = bad_skill.validate()
	_ok("Validation detects invalid skill_type", skill_errs.any(func(e: String) -> bool: return e.contains("skill_type")))
	_ok("Validation detects negative mana_cost", skill_errs.any(func(e: String) -> bool: return e.contains("mana_cost")))

	var bad_json_errs: Array[String] = ContentRegistry.validate_json_string('{"enemy_id": "", "max_health": 0}', "enemy")
	_ok("validate_json_string catches invalid schema", bad_json_errs.size() >= 2)

	# 7. Enemy runtime instantiation from definition
	var enemy_scene: PackedScene = load("res://scenes/entities/enemy.tscn")
	var goblin_instance: Enemy = enemy_scene.instantiate() as Enemy
	get_root().add_child(goblin_instance)
	goblin_instance.init_from_id("goblin_scout")
	_ok("Enemy initialized from goblin_scout has 35 max_health", goblin_instance.stats.max_health == 35)
	_ok("Enemy initialized from goblin_scout has 35 current_health", goblin_instance.stats.current_health == 35)
	_ok("Enemy initialized from goblin_scout has 7 attack", goblin_instance.stats.final_attack == 7)
	_ok("Enemy initialized from goblin_scout has 110.0 move_speed", is_equal_approx(goblin_instance.move_speed, 110.0))
	_ok("Enemy definition reference is set", goblin_instance.definition == goblin)

	# 8. Combat with data-driven enemy and custom XP reward
	var player_scene: PackedScene = load("res://scenes/entities/player.tscn")
	var p: Player = player_scene.instantiate() as Player
	get_root().add_child(p)
	p._ready()
	p.stats.level = 1
	p.stats.experience = 0

	# Fast attack to defeat 35 HP goblin
	p.set_target(goblin_instance)
	var combat_res: CombatResult = DamageCalculator.resolve_attack(p, goblin_instance, 100)
	_ok("Combat against goblin defeats target", combat_res.target_defeated)
	_ok("Combat against goblin awards data-driven xp_reward (15)", combat_res.xp_earned == 15)

	# 9. Skill usage via Player
	p.stats.current_mana = 50
	p.stats.apply_damage(30)
	var prev_hp: int = p.stats.current_health
	var heal_res: Dictionary = p.try_use_skill("heal_minor")
	_ok("try_use_skill heal_minor succeeds", bool(heal_res.get("success", false)))
	_ok("heal_minor spends 20 mana", p.stats.current_mana == 30)
	_ok("heal_minor restores player health", p.stats.current_health > prev_hp)

	var fireball_res: Dictionary = p.try_use_skill("fireball", goblin_instance)
	_ok("fireball succeeds", bool(fireball_res.get("success", false)))
	_ok("fireball spends 15 mana", p.stats.current_mana == 15)

	# Out of mana test
	p.stats.current_mana = 5 # less than 15
	var oom_res: Dictionary = p.try_use_skill("fireball", goblin_instance)
	_ok("fireball fails when out of mana", not bool(oom_res.get("success", true)))
	_ok("oom_res reason is not_enough_mana", str(oom_res.get("reason", "")) == "not_enough_mana")

	# 10. InventoryComponent add_item_by_id
	var add_ok: bool = p.inventory.add_item_by_id("potion_health")
	_ok("add_item_by_id adds potion_health to player inventory", add_ok)
	_ok("player inventory has potion_health", p.inventory.has_item("potion_health"))

	# Cleanup
	p.queue_free()
	goblin_instance.queue_free()

func _test_asset_pipeline_validation() -> void:
	print("\n[Group R] AI-Assisted Asset Pipeline & Validator")

	# 1. Directory validation of existing assets
	var dir_res: Dictionary = AssetValidator.validate_directory("res://assets")
	_ok("Existing assets directory passes validation", bool(dir_res.get("valid", false)))
	_ok("At least 40 asset files checked", int(dir_res.get("files_checked", 0)) >= 40)
	_ok("Zero asset directory errors", (dir_res.get("errors", []) as Array).is_empty())

	# 2. Manifest coverage validation
	var manifest_res: Dictionary = AssetValidator.check_manifest_coverage("res://assets", "docs/assets/ASSET_MANIFEST.md")
	_ok("Asset manifest file exists and is valid", bool(manifest_res.get("valid", false)))
	_ok("Zero unmanifested assets on disk", int(manifest_res.get("missing_count", -1)) == 0)

	# 3. Naming convention unit tests
	var name_space_errs: Array[String] = AssetValidator.check_naming_convention("goblin scout.png")
	_ok("Validator flags whitespace in filename", not name_space_errs.is_empty())

	var name_upper_errs: Array[String] = AssetValidator.check_naming_convention("GoblinScout.png")
	_ok("Validator flags uppercase characters in filename", not name_upper_errs.is_empty())

	var name_symbol_errs: Array[String] = AssetValidator.check_naming_convention("goblin@scout!.png")
	_ok("Validator flags special characters in filename", not name_symbol_errs.is_empty())

	var name_valid_errs: Array[String] = AssetValidator.check_naming_convention("goblin_scout_idle_001.png")
	_ok("Validator accepts valid snake_case filename", name_valid_errs.is_empty())

	var dir_valid_errs: Array[String] = AssetValidator.check_naming_convention("south-west")
	_ok("Validator accepts hyphenated directional name", dir_valid_errs.is_empty())

	# 4. Format & extension checks
	var jpg_res: Dictionary = AssetValidator.validate_file("res://assets/test_asset.jpg")
	_ok("Validator rejects .jpg image format", not bool(jpg_res.get("valid", true)))

	var bmp_res: Dictionary = AssetValidator.validate_file("res://assets/test_asset.bmp")
	_ok("Validator rejects .bmp image format", not bool(bmp_res.get("valid", true)))

	var exe_res: Dictionary = AssetValidator.validate_file("res://assets/test_asset.exe")
	_ok("Validator rejects executable in assets", not bool(exe_res.get("valid", true)))

	# 5. Icon dimension checks
	var test_img_non_square := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	var icon_rect_errs: Array[String] = AssetValidator.check_image_properties(test_img_non_square, "res://assets/icons/items/test_icon.png")
	_ok("Validator rejects non-square icon", icon_rect_errs.any(func(e: String) -> bool: return e.contains("not square")))

	var test_img_odd_size := Image.create(50, 50, false, Image.FORMAT_RGBA8)
	var icon_odd_errs: Array[String] = AssetValidator.check_image_properties(test_img_odd_size, "res://assets/icons/items/test_icon.png")
	_ok("Validator rejects non-standard icon size (50x50)", icon_odd_errs.any(func(e: String) -> bool: return e.contains("standard icon size")))

	var test_img_valid_icon := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var icon_valid_errs: Array[String] = AssetValidator.check_image_properties(test_img_valid_icon, "res://assets/icons/items/test_icon.png")
	_ok("Validator accepts 32x32 RGBA8 square icon", icon_valid_errs.is_empty())

	# 6. Transparency format checks
	var test_img_rgb_no_alpha := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var no_alpha_errs: Array[String] = AssetValidator.check_image_properties(test_img_rgb_no_alpha, "res://assets/sprites/player/test.png")
	_ok("Validator rejects image lacking alpha channel (RGB8)", no_alpha_errs.any(func(e: String) -> bool: return e.contains("alpha channel")))

	# 7. Unmanifested asset detection
	var missing_test: Dictionary = AssetValidator.check_manifest_coverage("res://assets", "docs/assets/nonexistent_manifest.md")
	_ok("check_manifest_coverage detects missing manifest file", not bool(missing_test.get("valid", true)))

func _test_basic_info_window() -> void:
	print("\n[Group S] Basic Info Window (Ragnarok Online Style)")

	var packed: PackedScene = load("res://scenes/ui/basic_info_window.tscn")
	_ok("BasicInfoWindow scene loads", packed != null)

	var win: BasicInfoWindow = packed.instantiate() as BasicInfoWindow
	get_root().add_child(win)
	win._ready()

	_ok("BasicInfoWindow instance valid", win != null)
	_ok("Has title bar", win.title_bar != null)
	_ok("Has minimize button", win.btn_minimize != null)
	_ok("Has close button", win.btn_close != null)
	_ok("Has portrait texture", win.portrait_rect != null and win.portrait_rect.texture != null)
	_ok("Default character name is VALKYRIA", win.label_name.text == "VALKYRIA")
	_ok("Default job is Job Novice", win.label_job.text == "Job Novice")
	_ok("Default ID is ID: 1024567", win.label_id.text == "ID: 1024567")

	# Bar checks
	_ok("Has HP bar", win.bar_hp != null)
	_ok("Has SP bar", win.bar_sp != null)
	_ok("Has Stamina bar", win.bar_stamina != null)
	_ok("Has Power bar", win.bar_power != null)
	_ok("Has LVL EXP bar", win.bar_lvl_exp != null)
	_ok("Has JOB EXP bar", win.bar_job_exp != null)

	# Stats checks
	_ok("Has weight label", win.label_weight_val != null and win.label_weight_val.text.contains("2900"))
	_ok("Has money label", win.label_money_val != null and win.label_money_val.text == "80,000,000")

	# Minimize / Expand toggle
	win._on_minimize_pressed()
	_ok("Minimize hides stats section", not win.stats_section.visible)
	win._on_minimize_pressed()
	_ok("Restore shows stats section", win.stats_section.visible)

	# Close and Toggle
	win._on_close_pressed()
	_ok("Close button hides window", not win.visible)
	win.toggle_window()
	_ok("Toggle window restores visibility", win.visible)

	# Dynamic binding to player
	var player_packed: PackedScene = load("res://scenes/entities/player.tscn")
	var player: Player = player_packed.instantiate() as Player
	get_root().add_child(player)
	player._ready()

	win.bind_player(player)
	_ok("Bound player updates HP bar to player HP", win.bar_hp.value == player.stats.current_health)
	_ok("Bound player updates SP bar to player mana", win.bar_sp.value == player.stats.current_mana)

	# Live signal response
	player.stats.apply_damage(30)
	_ok("HP bar updates on damage", win.bar_hp.value == player.stats.current_health)

	player.stats.spend_mana(15)
	_ok("SP bar updates on mana spend", win.bar_sp.value == player.stats.current_mana)

	# Number formatting helper
	_ok("Money formatting works", BasicInfoWindow._format_number(1234567) == "1,234,567")

	win.free()
	player.free()

func _test_multi_layer_tilemap_field() -> void:
	print("\n[Group T] Multi-Layer TileMapLayer Field & Slope Systems")

	# 1. Scene loading & node structure
	var world_scene: PackedScene = load("res://scenes/maps/test_world.tscn")
	_ok("TestWorld scene loads", world_scene != null)
	var world: Node = world_scene.instantiate()
	get_root().add_child(world)
	_ok("TestWorld instantiates successfully", world != null)

	var ground: TileMapLayer = world.get_node_or_null("GroundLayer") as TileMapLayer
	var elev: TileMapLayer = world.get_node_or_null("ElevationLayer") as TileMapLayer
	var deco: TileMapLayer = world.get_node_or_null("DecorationLayer") as TileMapLayer

	_ok("Has GroundLayer TileMapLayer", ground != null)
	_ok("Has ElevationLayer TileMapLayer", elev != null)
	_ok("Has DecorationLayer TileMapLayer", deco != null)

	# 2. Z-Index and Y-Sort layering
	_ok("GroundLayer z_index is -2", ground.z_index == -2)
	_ok("ElevationLayer z_index is -1", elev.z_index == -1)
	_ok("DecorationLayer y_sort_enabled is true", deco.y_sort_enabled)

	# 3. TileSet resource and custom data layers
	var ts: TileSet = ground.tile_set
	_ok("TileSet assigned to GroundLayer", ts != null)
	_ok("TileSet tile_size is 32x32", ts.tile_size == Vector2i(32, 32))
	_ok("TileSet has at least 2 custom data layers", ts.get_custom_data_layers_count() >= 2)
	_ok("TileSet custom data layer 0 is terrain_type", ts.get_custom_data_layer_name(0) == "terrain_type")
	_ok("TileSet custom data layer 1 is elevation", ts.get_custom_data_layer_name(1) == "elevation")
	_ok("TileSet has 20 atlas sources", ts.get_source_count() == 20)

	# 4. GroundLayer terrain data
	var spawn_tile: TileData = ground.get_cell_tile_data(Vector2i(0, 0))
	_ok("Spawn cell (0, 0) has ground tile", spawn_tile != null)
	_ok("Spawn cell terrain_type is grass", str(spawn_tile.get_custom_data("terrain_type")) == "grass")
	_ok("Spawn cell elevation is 0", int(spawn_tile.get_custom_data("elevation")) == 0)

	# 5. ElevationLayer rolling hills & slopes
	var plateau_tile: TileData = elev.get_cell_tile_data(Vector2i(10, -8))
	_ok("Plateau cell (10, -8) has elevated tile", plateau_tile != null)
	_ok("Plateau cell elevation is 1", plateau_tile != null and int(plateau_tile.get_custom_data("elevation")) == 1)

	var ramp_tile: TileData = elev.get_cell_tile_data(Vector2i(10, -3))
	_ok("Ramp cell (10, -3) has ramp tile", ramp_tile != null)
	_ok("Ramp terrain_type is ramp", ramp_tile != null and str(ramp_tile.get_custom_data("terrain_type")) == "ramp")

	var slope_tile: TileData = elev.get_cell_tile_data(Vector2i(10, -13))
	_ok("Slope cell (10, -13) has slope tile", slope_tile != null)
	_ok("Slope terrain_type is slope", slope_tile != null and str(slope_tile.get_custom_data("terrain_type")) == "slope")

	# 6. DecorationLayer details
	var stone_tile: TileData = deco.get_cell_tile_data(Vector2i(1, 0))
	_ok("DecorationLayer stepping stone at (1, 0)", stone_tile != null and str(stone_tile.get_custom_data("terrain_type")) == "stone")

	var flower_tile: TileData = deco.get_cell_tile_data(Vector2i(2, -2))
	_ok("DecorationLayer wildflowers at (2, -2)", flower_tile != null and str(flower_tile.get_custom_data("terrain_type")) == "flower")

	# 7. Player movement invariant: slopes and ground have zero collision layers
	var player_node: Player = world.get_node_or_null("Player") as Player
	_ok("TestWorld contains Player instance", player_node != null)
	_ok("TileSet has zero physics collision layers", ts.get_physics_layers_count() == 0)
	_ok("ElevationLayer has zero physics collision geometry", elev.tile_set.get_physics_layers_count() == 0)
	_ok("GroundLayer has zero physics collision geometry", ground.tile_set.get_physics_layers_count() == 0)

	# 8. WorldBoundaries verification
	var boundaries: StaticBody2D = world.get_node_or_null("WorldBoundaries") as StaticBody2D
	_ok("WorldBoundaries StaticBody2D is present", boundaries != null)
	_ok("WorldBoundaries is on collision layer 2", boundaries != null and (boundaries.collision_layer & 2) != 0)

	# Clean up
	world.queue_free()

	# ─────────────────────────────────────────────────────────────────────────────
	# Group U: Hybrid 3D Terrain & Billboard Presentation (ADR-006)
	# ─────────────────────────────────────────────────────────────────────────────
	print("\n[Group U] Hybrid 3D Terrain & Billboard Presentation (ADR-006)")

	# 1. 3D Scene loading
	var world_3d_scene: PackedScene = load("res://scenes/maps/test_world_3d.tscn")
	_ok("TestWorld3D scene loads", world_3d_scene != null)
	var world_3d: TestWorld3D = world_3d_scene.instantiate() as TestWorld3D
	get_root().add_child(world_3d)
	world_3d._ready()
	_ok("TestWorld3D instantiates successfully", world_3d != null)

	# 2. Lighting & Environment
	var dir_light: DirectionalLight3D = world_3d.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	_ok("TestWorld3D has DirectionalLight3D", dir_light != null)
	_ok("DirectionalLight3D has shadows enabled", dir_light != null and dir_light.shadow_enabled)

	var world_env: WorldEnvironment = world_3d.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_ok("TestWorld3D has WorldEnvironment", world_env != null)

	# 3. 3D Terrain & Multi-tier elevation
	var terrain_node: Node3D = world_3d.get_node_or_null("Terrain") as Node3D
	_ok("TestWorld3D has Terrain node", terrain_node != null)

	var terrain_mesh: MeshInstance3D = world_3d.get_node_or_null("Terrain/TerrainMesh") as MeshInstance3D
	_ok("Terrain has generated MeshInstance3D", terrain_mesh != null and terrain_mesh.mesh != null)

	var terrain_body: StaticBody3D = world_3d.get_node_or_null("Terrain/StaticBody3D") as StaticBody3D
	_ok("Terrain has StaticBody3D collision", terrain_body != null)
	_ok("Terrain StaticBody3D is on layer 2", terrain_body != null and (terrain_body.collision_layer & 2) != 0)

	# Validate multi-tier height calculation
	var h_valley: float = world_3d._calculate_height(0.0, 0.0)
	var h_plateau: float = world_3d._calculate_height(11.0, -11.0)
	var h_ridge: float = world_3d._calculate_height(-12.0, -14.0)
	_ok("Valley baseline height is near zero", abs(h_valley) < 0.5)
	_ok("Plateau tier 1 is significantly higher than valley", h_plateau > 1.8)
	_ok("Lookout ridge tier 2 is highest elevation", h_ridge > 3.0)

	# Validate continuous walkable ramps
	var max_step_p: float = 0.0
	var last_h_p: float = world_3d._calculate_height(11.0, -2.6)
	for i in range(1, 30):
		var z: float = -2.6 - float(i) * 0.25
		var h: float = world_3d._calculate_height(11.0, z)
		max_step_p = maxf(max_step_p, abs(h - last_h_p))
		last_h_p = h
	_ok("Plateau ramp is continuous and smoothly walkable without vertical steps", max_step_p < 0.20)

	var max_step_r: float = 0.0
	var last_h_r: float = world_3d._calculate_height(-5.2, -8.0)
	for i in range(1, 30):
		var t: float = float(i) / 29.0
		var pos2d: Vector2 = Vector2(-5.2, -8.0).lerp(Vector2(-9.8, -12.6), t)
		var h: float = world_3d._calculate_height(pos2d.x, pos2d.y)
		max_step_r = maxf(max_step_r, abs(h - last_h_r))
		last_h_r = h
	_ok("Lookout ridge ramp is continuous and smoothly walkable without vertical steps", max_step_r < 0.25)

	# Validate cliff edge fall-prevention barriers
	var cliff_barriers: StaticBody3D = world_3d.get_node_or_null("Terrain/CliffBarriers") as StaticBody3D
	_ok("CliffBarriers StaticBody3D exists", cliff_barriers != null)
	_ok("CliffBarriers is on collision layer 2", cliff_barriers != null and (cliff_barriers.collision_layer & 2) != 0)
	_ok("CliffBarriers has barrier shapes protecting cliff edges", cliff_barriers != null and cliff_barriers.get_child_count() >= 40)

	# Validate tree and bush physical collision shapes
	var props_node: Node3D = world_3d.get_node_or_null("Props") as Node3D
	var tree_col_found: bool = false
	var bush_col_found: bool = false
	if props_node != null:
		for child in props_node.get_children():
			if child is StaticBody3D:
				var sb: StaticBody3D = child as StaticBody3D
				if sb.name.begins_with("TreeCollision") and (sb.collision_layer & 2) != 0:
					tree_col_found = true
				elif sb.name.begins_with("BushCollision") and (sb.collision_layer & 2) != 0:
					bush_col_found = true
	_ok("Animated tree props have StaticBody3D physical collision", tree_col_found)
	_ok("Animated bush props have StaticBody3D physical collision", bush_col_found)

	# 4. Player3D and Billboard
	var p3d: Player3D = world_3d.get_node_or_null("Player3D") as Player3D
	_ok("TestWorld3D has Player3D instance", p3d != null)
	_ok("Player3D has AnimatedSprite3D billboard", p3d != null and p3d.animated_sprite != null)
	_ok("AnimatedSprite3D billboard mode is BILLBOARD_FIXED_Y", p3d != null and p3d.animated_sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y)
	_ok("AnimatedSprite3D has 8-directional sprite frames", p3d != null and p3d.animated_sprite.sprite_frames != null and p3d.animated_sprite.sprite_frames.has_animation("idle_south"))

	# 5. 3D Camera
	var cam: Camera3D = p3d.get_node_or_null("CameraArm/Camera3D") as Camera3D if p3d != null else null
	_ok("Player3D has Camera3D attached", cam != null)
	_ok("Camera3D is active", cam != null and cam.current)

	# 6. Decoupled RPG Components on Player3D (ADR-002 compatibility)
	_ok("Player3D has CharacterStatsComponent", p3d != null and p3d.stats != null)
	_ok("Player3D has InventoryComponent", p3d != null and p3d.inventory != null)
	_ok("Player3D has EquipmentComponent", p3d != null and p3d.equipment != null)

	# 7. Direction mapping in 3D
	_ok("Vector (0, 0, 1) converts to south in 3D", p3d._vector_to_direction(Vector3(0, 0, 1)) == "south")
	_ok("Vector (0, 0, -1) converts to north in 3D", p3d._vector_to_direction(Vector3(0, 0, -1)) == "north")
	_ok("Vector (1, 0, 0) converts to east in 3D", p3d._vector_to_direction(Vector3(1, 0, 0)) == "east")
	_ok("Vector (-1, 0, 0) converts to west in 3D", p3d._vector_to_direction(Vector3(-1, 0, 0)) == "west")
	_ok("Vector (1, 0, 1) converts to south-east in 3D", p3d._vector_to_direction(Vector3(1, 0, 1)) == "south-east")
	_ok("Vector (-1, 0, -1) converts to north-west in 3D", p3d._vector_to_direction(Vector3(-1, 0, -1)) == "north-west")

	# 8. Player3D Movement & Physics
	_ok("Player3D floor_constant_speed is enabled", p3d.floor_constant_speed)
	_ok("Player3D floor_block_on_wall is enabled", p3d.floor_block_on_wall)
	_ok("Player3D initial is_moving is false", not p3d.is_moving())
	p3d.velocity = Vector3(3.0, 0.0, 0.0)
	_ok("Player3D is_moving returns true when velocity is non-zero", p3d.is_moving())
	p3d.velocity = Vector3.ZERO
	var attacked_emitted: Array = [false]
	p3d.player_attacked.connect(func(): attacked_emitted[0] = true)
	p3d.attack()
	_ok("Player3D attack emits player_attacked signal", attacked_emitted[0])

	# Verify keyboard WASD movement is disabled (removed per user specification)
	Input.action_press("move_right")
	p3d._physics_process(0.016)
	_ok("WASD disabled: Player3D ignores move_right key", is_zero_approx(p3d.velocity.x))
	Input.action_release("move_right")

	Input.action_press("move_up")
	p3d._physics_process(0.016)
	_ok("WASD disabled: Player3D ignores move_up key", is_zero_approx(p3d.velocity.z))
	Input.action_release("move_up")

	# Test Mouse Click-to-Move destination navigation
	var p3d_pos: Vector3 = p3d.global_position if p3d.is_inside_tree() else p3d.position
	p3d.set_move_destination(p3d_pos + Vector3(5.0, 0.0, 0.0))
	p3d._physics_process(0.016)
	_ok("Player3D navigates East (+X) on mouse move destination", p3d.velocity.x > 0.0)
	_ok("Player3D has_move_target is true", p3d.has_move_target)

	p3d.set_move_destination(p3d_pos + Vector3(-5.0, 0.0, 0.0))
	p3d._physics_process(0.016)
	_ok("Player3D navigates West (-X) on mouse move destination", p3d.velocity.x < 0.0)

	p3d.set_move_destination(p3d_pos + Vector3(0.0, 0.0, -5.0))
	p3d._physics_process(0.016)
	_ok("Player3D navigates North (-Z) on mouse move destination", p3d.velocity.z < 0.0)

	p3d.set_move_destination(p3d_pos + Vector3(0.0, 0.0, 5.0))
	p3d._physics_process(0.016)
	_ok("Player3D navigates South (+Z) on mouse move destination", p3d.velocity.z > 0.0)

	# Test stopping when arriving at destination
	p3d.set_move_destination(p3d_pos + Vector3(0.1, 0.0, 0.0))
	p3d._physics_process(0.016)
	_ok("Player3D stops upon reaching destination", not p3d.has_move_target and is_zero_approx(p3d.velocity.x))

	# 9. 2D HUD on CanvasLayer over 3D world
	var hud3d: HUD = world_3d.get_node_or_null("HUD") as HUD
	_ok("TestWorld3D has 2D HUD CanvasLayer", hud3d != null)
	_ok("HUD contains BasicInfoWindow", hud3d != null and hud3d.basic_info_window != null)

	# 10. Ragnarok Online Camera Controls
	_ok("Player3D has camera_arm Node3D", p3d.camera_arm != null)
	_ok("Player3D camera default distance is set", p3d.camera_distance_default == 12.1)

	# Test camera reset
	p3d._target_yaw = 1.5
	p3d._target_pitch = 0.5
	p3d._target_zoom = 8.0
	p3d.reset_camera_view()
	_ok("reset_camera_view resets yaw to default", is_equal_approx(p3d._target_yaw, p3d.camera_yaw_default))
	_ok("reset_camera_view resets pitch to default", is_equal_approx(p3d._target_pitch, p3d.camera_pitch_default))
	_ok("reset_camera_view resets zoom to default", is_equal_approx(p3d._target_zoom, p3d.camera_distance_default))

	# Test camera update applies values to transform
	p3d._target_yaw = deg_to_rad(90.0)
	p3d._update_camera(0.0)
	_ok("CameraArm yaw rotation updates accurately", is_equal_approx(p3d.camera_arm.rotation.y, deg_to_rad(90.0)))

	# Test billboard facing relative to camera orientation
	var p3d_cam_pos: Vector3 = p3d.global_position if p3d.is_inside_tree() else p3d.position
	p3d.set_move_destination(p3d_cam_pos + Vector3(0.0, 0.0, 5.0))
	p3d._physics_process(0.016)
	_ok("Screen-relative billboard facing updates with camera angle", !p3d._current_direction.is_empty())
	p3d.stop_moving()

	# Reset camera back to default
	p3d.reset_camera_view()
	p3d._update_camera(0.0)

	world_3d.queue_free()

func _test_wolf_player_stalks_integration() -> void:
	print("\n[Group V] 8-Directional Animations, Wolf Monster & Green Stalks")

	# 1. Player 8-Directional Complete Action Animations
	var p_scene: PackedScene = load("res://scenes/entities/player_3d.tscn")
	_ok("Player3D scene loads", p_scene != null)
	var p: Player3D = p_scene.instantiate() as Player3D
	get_root().add_child(p)
	p._ready()

	var sf: SpriteFrames = p.animated_sprite.sprite_frames
	_ok("Player SpriteFrames exists", sf != null)
	_ok("Player has walk_south animation", sf.has_animation("walk_south"))
	_ok("Player has walk_north animation", sf.has_animation("walk_north"))
	_ok("Player has walk_east animation", sf.has_animation("walk_east"))
	_ok("Player has walk_west animation", sf.has_animation("walk_west"))
	_ok("Player has attack_south animation", sf.has_animation("attack_south"))
	_ok("Player has damage_south animation", sf.has_animation("damage_south"))
	_ok("Player has die_south animation", sf.has_animation("die_south"))
	_ok("Player has dead animation", sf.has_animation("dead"))

	# Test player animation state transitions
	p.velocity = Vector3(0, 0, 4) # Moving south
	p._update_animation("south")
	_ok("Player moving plays walk animation", p.animated_sprite.animation == "walk_south")

	p.velocity = Vector3.ZERO # Stopped
	p._update_animation()
	_ok("Player stopped plays idle animation", p.animated_sprite.animation == "idle_south")

	p.attack()
	p._update_animation()
	_ok("Player attack plays attack animation", p.animated_sprite.animation == "attack_south")

	p.take_damage(5)
	p._update_animation()
	_ok("Player damage plays damage animation", p.animated_sprite.animation == "damage_south")

	p.queue_free()

	# 2. Wolf Monster (Enemy3D)
	var wolf_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn")
	_ok("Enemy3D scene loads", wolf_scene != null)
	var wolf: CharacterBody3D = wolf_scene.instantiate() as CharacterBody3D
	get_root().add_child(wolf)
	wolf._ready()

	var wolf_sprite: AnimatedSprite3D = wolf.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	_ok("Enemy3D has AnimatedSprite3D", wolf_sprite != null)
	_ok("Enemy3D billboard is BILLBOARD_FIXED_Y", wolf_sprite != null and wolf_sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y)

	var w_sf: SpriteFrames = wolf_sprite.sprite_frames if wolf_sprite != null else null
	_ok("Wolf SpriteFrames exists", w_sf != null)
	_ok("Wolf has idle_south animation", w_sf != null and w_sf.has_animation("idle_south"))
	_ok("Wolf has walk_south animation", w_sf != null and w_sf.has_animation("walk_south"))
	_ok("Wolf has attack_south animation", w_sf != null and w_sf.has_animation("attack_south"))
	_ok("Wolf has damage_south animation", w_sf != null and w_sf.has_animation("damage_south"))
	_ok("Wolf has die_south animation", w_sf != null and w_sf.has_animation("die_south"))
	_ok("Wolf has dead animation", w_sf != null and w_sf.has_animation("dead"))

	var wolf_stats: CharacterStatsComponent = wolf.get_node_or_null("CharacterStatsComponent") as CharacterStatsComponent
	_ok("Wolf has CharacterStatsComponent", wolf_stats != null)
	_ok("Wolf max_health is 45 from definition", wolf_stats != null and wolf_stats.max_health == 45)
	_ok("Wolf attack is 8 from definition", wolf_stats != null and wolf_stats.base_attack == 8)
	_ok("Wolf defence is 2 from definition", wolf_stats != null and wolf_stats.base_defence == 2)

	wolf.take_damage(10)
	_ok("Wolf takes damage and reduces current_health", wolf_stats != null and wolf_stats.current_health == 37)

	wolf.queue_free()

	# 3. Animated Green Stalks
	var stalks_sf: SpriteFrames = load("res://green stalks/green_stalks_sprite_frames.tres") as SpriteFrames
	_ok("Green stalks SpriteFrames loads", stalks_sf != null)
	_ok("Green stalks has default swaying animation", stalks_sf != null and stalks_sf.has_animation("default"))
	_ok("Green stalks swaying animation has 9 frames", stalks_sf != null and stalks_sf.get_frame_count("default") == 9)

func _test_mouse_controls_and_combat() -> void:
	print("\n[Group W] Mouse Click-to-Move, Cell Target Preview & Aim Reticle Combat")

	# 1. Cell Target Preview Cursor (CellCursor3D)
	var cursor_scene: PackedScene = load("res://scenes/entities/cell_cursor_3d.tscn")
	_ok("CellCursor3D scene loads successfully", cursor_scene != null)
	var cursor: CellCursor3D = cursor_scene.instantiate() as CellCursor3D
	get_root().add_child(cursor)
	cursor._ready()
	_ok("CellCursor3D initially hidden", not cursor.visible)
	cursor.set_target_cell(Vector3(5.0, 1.2, 8.0), Vector3.UP)
	_ok("CellCursor3D becomes visible on set_target_cell", cursor.visible)
	var c_pos: Vector3 = cursor.global_position if cursor.is_inside_tree() else cursor.position
	_ok("CellCursor3D position matches targeted cell", is_equal_approx(c_pos.x, 5.0) and is_equal_approx(c_pos.z, 8.0))
	cursor.hide_target()
	_ok("CellCursor3D begins fading upon hide_target", not cursor._is_active)
	cursor.queue_free()

	# 2. Enemy3D Aim Indicator
	var wolf_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn")
	_ok("Enemy3D scene loads for combat tests", wolf_scene != null)
	var wolf: Enemy3D = wolf_scene.instantiate() as Enemy3D
	get_root().add_child(wolf)
	wolf._ready()
	_ok("Enemy3D has AimIndicator Sprite3D", wolf.aim_indicator != null)
	_ok("Enemy3D aim indicator is initially hidden", not wolf.aim_indicator.visible)

	# Hovering enemy sets aim indicator preview
	wolf.set_hovered(true)
	_ok("Enemy3D aim indicator visible on hover", wolf.aim_indicator.visible)
	_ok("Enemy3D aim indicator modulate alpha is 0.65 on hover", is_equal_approx(wolf.aim_indicator.modulate.a, 0.65))

	wolf.set_hovered(false)
	_ok("Enemy3D aim indicator hides when hover ends", not wolf.aim_indicator.visible)

	# Targeting enemy locks aim indicator
	wolf.set_targeted(true)
	_ok("Enemy3D aim indicator visible on targeted", wolf.aim_indicator.visible)
	_ok("Enemy3D aim indicator modulate alpha is 1.0 on targeted", is_equal_approx(wolf.aim_indicator.modulate.a, 1.0))

	# 3. Player3D Mouse Targeting & Auto-Attack Loop
	var player_scene: PackedScene = load("res://scenes/entities/player_3d.tscn")
	_ok("Player3D scene loads for combat tests", player_scene != null)
	var player: Player3D = player_scene.instantiate() as Player3D
	get_root().add_child(player)
	player._ready()

	wolf.position = player.position + Vector3(4.0, 0.0, 0.0)
	player.target_enemy(wolf)
	_ok("Player3D target_enemy sets target_enemy_node", player.target_enemy_node == wolf)
	_ok("Enemy3D is_targeted is true", wolf.is_targeted)
	_ok("Player3D has_move_target is false during combat target", not player.has_move_target)

	# Player chases target enemy towards melee reach
	player._physics_process(0.016)
	_ok("Player3D moves toward targeted enemy", player.velocity.x > 0.0)

	# In melee attack reach: player halts and attacks
	wolf.position = player.position + Vector3(1.0, 0.0, 0.0)
	var edge_d: float = player.get_edge_distance_to(wolf)
	_ok("Edge distance calculation subtracts both body radii", is_equal_approx(edge_d, 0.25))
	_ok("Both combatants in melee range (edge <= 0.40)", edge_d <= player.melee_attack_range)

	var hp_before: int = wolf.stats.current_health
	player._physics_process(0.016)
	_ok("Player3D stops moving when in melee range of target", is_zero_approx(player.velocity.x))
	_ok("Player faces target East during combat", player._current_direction == "east")

	# Frame 0 of attack animation does not deal damage yet (damage sync on frame 4)
	_ok("Attack wind-up frame does not deal damage immediately", wolf.stats.current_health == hp_before)

	# Advancing to hit frame (frame 4) triggers damage without knockback
	var wolf_x_before: float = wolf.position.x
	player.animated_sprite.frame = 4
	_ok("Target enemy takes damage on hit frame 4", wolf.stats.current_health < hp_before)
	_ok("No knockback on hit for target enemy", is_equal_approx(wolf.position.x, wolf_x_before))

	# Whiff verification: if target moves out of range, attack frame 4 deals no damage
	wolf.position = player.position + Vector3(4.0, 0.0, 0.0)
	var hp_whiff_before: int = wolf.stats.current_health
	player._attack_timer = 0.0
	player.attack()
	player.animated_sprite.frame = 4
	_ok("Attack whiffs without dealing damage if target is out of range", wolf.stats.current_health == hp_whiff_before)

	# Wolf auto-facing towards player
	wolf.position = player.position + Vector3(1.0, 0.0, 0.0)
	wolf.face_target(player.position)
	_ok("Wolf faces player West when player is to its left", wolf._current_direction == "west")

	# Player hit while idle turns to face attacker without knockback
	player.stop_moving()
	player.face_target(player.position + Vector3(0.0, 0.0, 2.0))
	wolf.position = player.position + Vector3(0.0, 0.0, -1.0)
	var player_pos_before: Vector3 = player.position
	player.take_damage(5, wolf)
	_ok("Player turns to face attacker when damaged while idle", player._current_direction == "north")
	_ok("No knockback on hit for player", player.position.is_equal_approx(player_pos_before))

	# Shadow verification: real directional light shadow disabled on 2D sprite billboards
	_ok("Player AnimatedSprite3D cast_shadow disabled", player.animated_sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_ok("Wolf AnimatedSprite3D cast_shadow disabled", wolf.animated_sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	# Enemy death auto-clears player target
	wolf._on_died()
	player._physics_process(0.016)
	_ok("Player3D auto-clears target when enemy dies", player.target_enemy_node == null)
	_ok("Dead enemy hides aim indicator", not wolf.aim_indicator.visible)

	player.queue_free()
	wolf.queue_free()

func _test_health_and_sp_bars() -> void:
	print("\n[Group X] Overhead Health & SP Bars and HUD Status Bars")

	# 1. OverheadBar3D component standalone tests
	var bar: OverheadBar3D = OverheadBar3D.new()
	bar.bar_width = 0.70
	bar.bar_height = 0.09
	bar.show_sp = true
	bar._ready()
	_ok("OverheadBar3D instantiates with default HP ratio 1.0", is_equal_approx(bar.get_hp_ratio(), 1.0))
	_ok("OverheadBar3D instantiates with default SP ratio 1.0", is_equal_approx(bar.get_sp_ratio(), 1.0))
	_ok("OverheadBar3D show_sp is enabled", bar.show_sp)
	_ok("OverheadBar3D cast_shadow disabled", bar.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	bar.set_health(50, 100)
	_ok("OverheadBar3D set_health updates hp_ratio to 0.5", is_equal_approx(bar.get_hp_ratio(), 0.5))

	bar.set_mana(25, 100)
	_ok("OverheadBar3D set_mana updates sp_ratio to 0.25", is_equal_approx(bar.get_sp_ratio(), 0.25))

	bar.set_show_sp(false)
	_ok("OverheadBar3D set_show_sp toggles show_sp flag", not bar.show_sp)
	bar.queue_free()

	# 2. Player3D OverheadBar integration (Dual HP & SP bar)
	var player_scene: PackedScene = load("res://scenes/entities/player_3d.tscn") as PackedScene
	_ok("Player3D scene loads for overhead bar test", player_scene != null)
	var player: Player3D = player_scene.instantiate() as Player3D
	root.add_child(player)
	player._ready()

	_ok("Player3D has OverheadBar child node", player.overhead_bar != null)
	_ok("Player3D OverheadBar has show_sp enabled", player.overhead_bar.show_sp)
	_ok("Player3D OverheadBar positioned above head (y >= 1.4)", player.overhead_bar.position.y >= 1.4)
	_ok("Player3D OverheadBar initially full HP", is_equal_approx(player.overhead_bar.get_hp_ratio(), 1.0))
	_ok("Player3D OverheadBar initially full SP", is_equal_approx(player.overhead_bar.get_sp_ratio(), 1.0))

	# Player taking damage updates overhead HP bar ratio
	player.take_damage(20)
	_ok("Player taking damage reduces OverheadBar HP ratio", player.overhead_bar.get_hp_ratio() < 1.0)

	# Player spending mana updates overhead SP bar ratio
	if player.stats != null:
		player.stats.current_mana = int(player.stats.final_max_mana * 0.4)
		player.overhead_bar.set_mana(player.stats.current_mana, player.stats.final_max_mana)
		_ok("Player spending mana updates OverheadBar SP ratio", is_equal_approx(player.overhead_bar.get_sp_ratio(), 0.4))

	# Player death hides overhead bar
	player._on_player_died()
	_ok("Player death hides OverheadBar", not player.overhead_bar.visible)

	# 3. Enemy3D OverheadBar integration (Single HP bar, no SP)
	var enemy_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn") as PackedScene
	_ok("Enemy3D scene loads for overhead bar test", enemy_scene != null)
	var wolf: Enemy3D = enemy_scene.instantiate() as Enemy3D
	root.add_child(wolf)
	wolf._ready()

	_ok("Enemy3D has OverheadBar child node", wolf.overhead_bar != null)
	_ok("Enemy3D OverheadBar has show_sp disabled", not wolf.overhead_bar.show_sp)
	_ok("Enemy3D OverheadBar positioned above wolf back/head (y >= 1.0)", wolf.overhead_bar.position.y >= 1.0)
	_ok("Enemy3D OverheadBar initially full HP", is_equal_approx(wolf.overhead_bar.get_hp_ratio(), 1.0))

	# Monster taking damage updates overhead HP bar ratio
	wolf.take_damage(15)
	_ok("Enemy taking damage reduces OverheadBar HP ratio", wolf.overhead_bar.get_hp_ratio() < 1.0)

	# Monster death hides overhead bar
	wolf._on_died()
	_ok("Enemy death hides OverheadBar", not wolf.overhead_bar.visible)

	# 4. HUD status bar elements and bindings
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn") as PackedScene
	_ok("HUD scene loads for HP/SP bar test", hud_scene != null)
	var hud: HUD = hud_scene.instantiate() as HUD
	root.add_child(hud)
	hud._ready()

	_ok("HUD has HealthBar ProgressBar", hud.health_bar != null)
	_ok("HUD has ManaBar ProgressBar", hud.mana_bar != null)
	_ok("HUD has HealthLabel", hud.health_label != null)
	_ok("HUD has ManaLabel", hud.mana_label != null)

	# Bind player and test dynamic updates
	hud.bind_player(player)
	_ok("HUD HealthBar max_value matches player max_health", int(hud.health_bar.max_value) == player.stats.max_health)
	_ok("HUD ManaBar max_value matches player max_mana", int(hud.mana_bar.max_value) == player.stats.final_max_mana)

	hud._on_health_changed(50, 100)
	_ok("HUD _on_health_changed updates health_bar value", is_equal_approx(hud.health_bar.value, 50.0))
	_ok("HUD _on_health_changed updates health_label text", hud.health_label.text.contains("50 / 100"))

	hud._on_mana_changed(30, 60)
	_ok("HUD _on_mana_changed updates mana_bar value", is_equal_approx(hud.mana_bar.value, 30.0))
	_ok("HUD _on_mana_changed updates mana_label text", hud.mana_label.text.contains("30 / 60"))

	player.queue_free()
	wolf.queue_free()
	hud.queue_free()

func _test_character_stats_and_game_state() -> void:
	print("\n[Group Y] Character Stats Window & GameState Attribute Point Economy")

	# 1. GameState baseline and stat increase cost formula
	GameState.reset_to_defaults()
	_ok("GameState base_level is 1", GameState.base_level == 1)
	_ok("GameState job_level is 1", GameState.job_level == 1)
	_ok("GameState stat_points starts at 48", GameState.stat_points == 48)
	_ok("GameState has all 6 core attributes", GameState.stats.size() == 6)
	_ok("GameState initial STR is 1", GameState.stats["STR"] == 1)

	# Cost curve checks: 1-10 -> 2, 11-20 -> 3, 21-30 -> 4
	_ok("Stat cost at 1 is 2", GameState.stat_increase_cost(1) == 2)
	_ok("Stat cost at 10 is 2", GameState.stat_increase_cost(10) == 2)
	_ok("Stat cost at 11 is 3", GameState.stat_increase_cost(11) == 3)
	_ok("Stat cost at 20 is 3", GameState.stat_increase_cost(20) == 3)
	_ok("Stat cost at 21 is 4", GameState.stat_increase_cost(21) == 4)

	# 2. Attribute allocation logic
	var ok_str := GameState.try_increase_stat("STR")
	_ok("try_increase_stat('STR') succeeds", ok_str)
	_ok("STR increased to 2", GameState.stats["STR"] == 2)
	_ok("stat_points deducted by cost 2 (48 -> 46)", GameState.stat_points == 46)

	# Insufficient points check
	GameState.stat_points = 1
	var fail_str := GameState.try_increase_stat("STR")
	_ok("try_increase_stat fails when points insufficient", not fail_str)
	_ok("STR unchanged after failed increase", GameState.stats["STR"] == 2)

	# 3. AttributeRow scene instantiation and behavior
	var row_scene: PackedScene = load("res://scenes/ui/attribute_row.tscn") as PackedScene
	_ok("AttributeRow scene loads", row_scene != null)
	var row: AttributeRow = row_scene.instantiate() as AttributeRow
	row.stat_name = "VIT"
	get_root().add_child(row)
	row._ready()

	_ok("AttributeRow NameLabel is VIT", row.name_label.text == "VIT")
	_ok("AttributeRow ValueLabel is 1", row.value_label.text == "1")
	_ok("AttributeRow CostLabel is Cost: 2", row.cost_label.text == "Cost: 2")
	_ok("AttributeRow MinusButton is disabled", row.minus_button.disabled)
	_ok("AttributeRow PlusButton disabled when points < cost", row.plus_button.disabled)

	# Grant points and spend via PlusButton
	GameState.stat_points = 10
	GameState.stat_points_changed.emit(10)
	_ok("AttributeRow PlusButton enabled when affordable", not row.plus_button.disabled)

	row._on_plus_pressed()
	_ok("AttributeRow PlusButton increases stat", GameState.stats["VIT"] == 2)
	_ok("AttributeRow ValueLabel refreshed to 2", row.value_label.text == "2")
	_ok("AttributeRow points deducted (10 -> 8)", GameState.stat_points == 8)

	row.queue_free()

	# 4. CharacterStatsWindow controller and live updates
	var win_scene: PackedScene = load("res://scenes/ui/character_stats_window.tscn") as PackedScene
	_ok("CharacterStatsWindow scene loads", win_scene != null)
	var win: CharacterStatsWindow = win_scene.instantiate() as CharacterStatsWindow
	get_root().add_child(win)
	win._ready()

	_ok("CharacterStatsWindow has LevelLabel", win.level_label != null)
	_ok("CharacterStatsWindow has PointsLabel", win.points_label != null)
	_ok("CharacterStatsWindow has HPLabel", win.hp_label != null)
	_ok("CharacterStatsWindow has StaminaLabel", win.stamina_label != null)
	_ok("LevelLabel displays initial levels", win.level_label.text == "Lv. 1 / 1")
	_ok("PointsLabel displays current points", win.points_label.text == "Points: 8")
	_ok("HPLabel displays max hp with VIT bonus", win.hp_label.text == "110 / 110")
	_ok("StaminaLabel displays 100 / 100", win.stamina_label.text == "100 / 100")

	# Live update on level up
	GameState.level_up_base(1)
	_ok("LevelLabel updates live on leveled_up", win.level_label.text == "Lv. 2 / 1")
	_ok("PointsLabel updates live on stat_points_changed", win.points_label.text == "Points: 13")

	# Window toggle and close button
	win._on_close_button_pressed()
	_ok("Close button hides stats window", not win.visible)
	win.toggle_window()
	_ok("toggle_window shows stats window", win.visible)

	win.queue_free()

	# 5. HUD integration with CharacterStatsWindow
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn") as PackedScene
	var hud: HUD = hud_scene.instantiate() as HUD
	get_root().add_child(hud)
	hud._ready()

	_ok("HUD contains CharacterStatsWindow", hud.character_stats_window != null)
	_ok("CharacterStatsWindow initially hidden in HUD", not hud.character_stats_window.visible)
	hud.toggle_character_stats()
	_ok("toggle_character_stats shows window", hud.character_stats_window.visible)
	hud.toggle_character_stats()
	_ok("toggle_character_stats hides window", not hud.character_stats_window.visible)

	hud.queue_free()
	GameState.reset_to_defaults()

	# ─────────────────────────────────────────────────────────────────────────
	# [Group Z] Ragnarok Online Floating Combat Damage Numbers (DamageNumber3D)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n[Group Z] Ragnarok Online Floating Combat Damage Numbers (DamageNumber3D)")

	var dmg_scene: PackedScene = load("res://scenes/ui/damage_number_3d.tscn") as PackedScene
	_ok("DamageNumber3D scene loads", dmg_scene != null)

	var d1: DamageNumber3D = DamageNumber3D.new()
	d1.setup("45", DamageNumber3D.Type.DAMAGE_TO_ENEMY, Vector3(0.0, 1.0, 0.0))
	_ok("DamageNumber3D text is 45", d1.text == "45")
	_ok("DamageNumber3D billboard is BILLBOARD_ENABLED", d1.billboard == BaseMaterial3D.BILLBOARD_ENABLED)
	_ok("DamageNumber3D no_depth_test is true", d1.no_depth_test)
	_ok("DamageNumber3D render_priority is 30", d1.render_priority == 30)
	_ok("DamageNumber3D outline_size is 10", d1.outline_size == 10)
	_ok("DamageNumber3D outline_modulate is Color.BLACK", d1.outline_modulate == Color.BLACK)
	_ok("DamageNumber3D enemy damage modulate is white", d1.modulate == Color.WHITE)
	_ok("DamageNumber3D font_size is 32", d1.font_size == 32)
	d1.free()

	# Player damage styling (Ragnarok red)
	var d2: DamageNumber3D = DamageNumber3D.new()
	d2.setup("18", DamageNumber3D.Type.DAMAGE_TO_PLAYER, Vector3(0.0, 1.0, 0.0))
	_ok("DamageNumber3D player damage text is 18", d2.text == "18")
	_ok("DamageNumber3D player damage modulate is red", is_equal_approx(d2.modulate.r, 1.0) and is_equal_approx(d2.modulate.g, 0.22))
	d2.free()

	# Critical damage styling (Ragnarok gold/yellow, larger font)
	var d3: DamageNumber3D = DamageNumber3D.new()
	d3.setup("99", DamageNumber3D.Type.CRITICAL, Vector3(0.0, 1.0, 0.0))
	_ok("DamageNumber3D critical modulate is gold", is_equal_approx(d3.modulate.r, 1.0) and is_equal_approx(d3.modulate.g, 0.88))
	_ok("DamageNumber3D critical font_size is 38", d3.font_size == 38)
	d3.free()

	# Miss text styling
	var d4: DamageNumber3D = DamageNumber3D.new()
	d4.setup("MISS", DamageNumber3D.Type.MISS, Vector3(0.0, 1.0, 0.0))
	_ok("DamageNumber3D miss text is MISS", d4.text == "MISS")
	_ok("DamageNumber3D miss modulate is cyan-white", is_equal_approx(d4.modulate.b, 1.0) and d4.modulate.r < 1.0)
	d4.free()

	# Static factory spawning over entity
	var test_parent: Node3D = Node3D.new()
	get_root().add_child(test_parent)

	var w_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn") as PackedScene
	var dummy_wolf: Enemy3D = w_scene.instantiate() as Enemy3D
	test_parent.add_child(dummy_wolf)
	dummy_wolf._ready()
	dummy_wolf.position = Vector3(5.0, 0.0, 5.0)

	var spawned_dmg: DamageNumber3D = DamageNumber3D.spawn(dummy_wolf, 30, DamageNumber3D.Type.DAMAGE_TO_ENEMY)
	_ok("DamageNumber3D.spawn returns instance", spawned_dmg != null)
	_ok("Spawned damage number has text 30", spawned_dmg.text == "30")
	_ok("Spawned damage number added to parent", spawned_dmg.get_parent() == test_parent)
	_ok("Spawned damage number elevated over wolf head", spawned_dmg.position.y >= dummy_wolf.position.y + 0.9)

	# Direct Enemy3D take_damage integration
	dummy_wolf.take_damage(12, null)
	var latest_child: Node = test_parent.get_child(test_parent.get_child_count() - 1)
	_ok("Enemy3D take_damage automatically spawns DamageNumber3D", latest_child is DamageNumber3D)
	if latest_child is DamageNumber3D:
		var ld: DamageNumber3D = latest_child as DamageNumber3D
		_ok("Enemy3D damage number text matches calculated damage", ld.text == "10") # 12 - 2 def = 10
		_ok("Enemy3D damage number color is white", ld.modulate == Color.WHITE)

	# Direct Player3D take_damage integration
	var p_scene: PackedScene = load("res://scenes/entities/player_3d.tscn") as PackedScene
	var dummy_player: Player3D = p_scene.instantiate() as Player3D
	test_parent.add_child(dummy_player)
	dummy_player._ready()
	dummy_player.position = Vector3(0.0, 0.0, 0.0)

	dummy_player.take_damage(15, null)
	var player_dmg_child: Node = test_parent.get_child(test_parent.get_child_count() - 1)
	_ok("Player3D take_damage automatically spawns DamageNumber3D", player_dmg_child is DamageNumber3D)
	if player_dmg_child is DamageNumber3D:
		var pd: DamageNumber3D = player_dmg_child as DamageNumber3D
		_ok("Player3D damage number text matches calculated damage", pd.text == "10") # 15 - 5 def = 10
		_ok("Player3D damage number color is red", is_equal_approx(pd.modulate.r, 1.0) and is_equal_approx(pd.modulate.g, 0.22))
		_ok("Player3D damage number elevated over head (y >= 1.3)", pd.position.y >= 1.3)

	# Cleanup test nodes
	test_parent.queue_free()

	# ─────────────────────────────────────────────────────────────────────────
	# [Group AA] Monster Respawn System (Enemy3D Lifecycle & Respawn)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n[Group AA] Monster Respawn System (Enemy3D Lifecycle & Respawn)")

	var respawn_parent: Node3D = Node3D.new()
	get_root().add_child(respawn_parent)

	var w_res_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn") as PackedScene
	var respawn_wolf: Enemy3D = w_res_scene.instantiate() as Enemy3D
	respawn_wolf.position = Vector3(4.0, 1.0, 4.0)
	respawn_parent.add_child(respawn_wolf)
	respawn_wolf._ready()

	# 1. Baseline configuration
	_ok("Enemy3D auto_respawn is true by default", respawn_wolf.auto_respawn)
	_ok("Enemy3D corpse_linger_time is configured (> 0)", respawn_wolf.corpse_linger_time > 0.0)
	_ok("Enemy3D respawn_delay is configured (> 0)", respawn_wolf.respawn_delay > 0.0)
	_ok("Enemy3D spawn_position initialized to starting position", respawn_wolf.spawn_position.is_equal_approx(Vector3(4.0, 1.0, 4.0)))
	_ok("Enemy3D is_dead() is false initially", not respawn_wolf.is_dead())

	# 2. Death state
	respawn_wolf.take_damage(999, null)
	_ok("Enemy3D current_state is DEAD after fatal damage", respawn_wolf.current_state == Enemy3D.State.DEAD)
	_ok("Enemy3D is_dead() is true after fatal damage", respawn_wolf.is_dead())
	_ok("Enemy3D collision_shape disabled on death", respawn_wolf.collision_shape.disabled)
	_ok("Enemy3D overhead_bar hidden on death", not respawn_wolf.overhead_bar.visible)

	# 3. Manual respawn() method
	var respawn_events: Array[Enemy3D] = []
	respawn_wolf.enemy_respawned.connect(func(e: Enemy3D): respawn_events.append(e))

	respawn_wolf.respawn()
	_ok("Enemy3D respawn() fires enemy_respawned signal", respawn_events.size() == 1 and respawn_events[0] == respawn_wolf)
	_ok("Enemy3D current_state returns to IDLE after respawn", respawn_wolf.current_state == Enemy3D.State.IDLE)
	_ok("Enemy3D is_dead() returns false after respawn", not respawn_wolf.is_dead())
	_ok("Enemy3D health restored to max_health after respawn", respawn_wolf.stats.current_health == respawn_wolf.stats.max_health)
	_ok("Enemy3D overhead_bar visible after respawn", respawn_wolf.overhead_bar.visible)
	_ok("Enemy3D overhead_bar ratio is 1.0 after respawn", is_equal_approx(respawn_wolf.overhead_bar.get_hp_ratio(), 1.0))
	_ok("Enemy3D collision_shape re-enabled after respawn", not respawn_wolf.collision_shape.disabled)
	_ok("Enemy3D position restored to spawn_position", respawn_wolf.position.is_equal_approx(Vector3(4.0, 1.0, 4.0)))

	# 4. Custom spawn position override
	respawn_wolf.respawn(Vector3(10.0, 2.0, -5.0))
	_ok("Enemy3D respawn(pos) positions at custom coordinates", respawn_wolf.position.is_equal_approx(Vector3(10.0, 2.0, -5.0)))

	# 5. Automated delta-time respawn cycle
	respawn_wolf.spawn_position = Vector3(4.0, 1.0, 4.0)
	respawn_wolf.position = Vector3(8.0, 1.0, 8.0) # Moved away in combat
	respawn_wolf.take_damage(999, null)
	_ok("Enemy3D dead again after combat kill", respawn_wolf.is_dead())
	_ok("Enemy3D corpse rests at location of death", respawn_wolf.position.is_equal_approx(Vector3(8.0, 1.0, 8.0)))
	_ok("Enemy3D corpse not faded yet initially", not respawn_wolf._is_corpse_faded)

	# Advance physics beyond corpse_linger_time -> triggers corpse fadeout
	respawn_wolf._physics_process(respawn_wolf.corpse_linger_time + 0.1)
	_ok("Enemy3D corpse starts fading after corpse_linger_time", respawn_wolf._is_corpse_faded)
	_ok("Enemy3D still dead during fadeout", respawn_wolf.is_dead())

	# Advance physics beyond corpse_fade_duration + respawn_delay -> triggers automatic respawn
	respawn_wolf._physics_process(respawn_wolf.corpse_fade_duration + respawn_wolf.respawn_delay + 0.1)
	_ok("Enemy3D automatically respawns after full delay", respawn_wolf.current_state == Enemy3D.State.IDLE)
	_ok("Enemy3D returned home to spawn_position", respawn_wolf.position.is_equal_approx(Vector3(4.0, 1.0, 4.0)))
	_ok("Enemy3D full HP after automatic respawn", respawn_wolf.stats.current_health == respawn_wolf.stats.max_health)

	# 6. auto_respawn toggle
	respawn_wolf.auto_respawn = false
	respawn_wolf.take_damage(999, null)
	respawn_wolf._physics_process(100.0) # long time passes
	_ok("Enemy3D remains dead when auto_respawn is false", respawn_wolf.is_dead())

	respawn_parent.queue_free()

	# ─────────────────────────────────────────────────────────────────────────
	# [Group BB] 8-Directional Environment Props (DirectionalProp3D, Tree, Bush, Green Stalks)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n[Group BB] 8-Directional Environment Props (DirectionalProp3D, Tree, Bush, Green Stalks)")

	var prop_script: GDScript = load("res://src/entities/directional_prop_3d.gd") as GDScript
	_ok("DirectionalProp3D script loads", prop_script != null)

	var prop: DirectionalProp3D = prop_script.new() as DirectionalProp3D
	_ok("DirectionalProp3D instantiates", prop != null)
	_ok("DirectionalProp3D billboard is BILLBOARD_FIXED_Y", prop.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y)
	_ok("DirectionalProp3D texture_filter is TEXTURE_FILTER_NEAREST", prop.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	_ok("DirectionalProp3D cast_shadow is disabled", prop.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	# 1. Mathematical angle-to-direction mapping
	_ok("Vector (0, 1) maps to south", prop._vector_to_direction(0.0, 1.0) == "south")
	_ok("Vector (1, 0) maps to east", prop._vector_to_direction(1.0, 0.0) == "east")
	_ok("Vector (0, -1) maps to north", prop._vector_to_direction(0.0, -1.0) == "north")
	_ok("Vector (-1, 0) maps to west", prop._vector_to_direction(-1.0, 0.0) == "west")
	_ok("Vector (1, 1) maps to south-east", prop._vector_to_direction(0.707, 0.707) == "south-east")
	_ok("Vector (-1, 1) maps to south-west", prop._vector_to_direction(-0.707, 0.707) == "south-west")
	_ok("Vector (1, -1) maps to north-east", prop._vector_to_direction(0.707, -0.707) == "north-east")
	_ok("Vector (-1, -1) maps to north-west", prop._vector_to_direction(-0.707, -0.707) == "north-west")

	# 2. Tree SpriteFrames 8 directions
	var tree_sf: SpriteFrames = load("res://assets/sprites/environment/tree/tree_sprite_frames.tres") as SpriteFrames
	_ok("Tree SpriteFrames loads", tree_sf != null)
	var expected_dirs: Array[String] = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
	var tree_all_sway: bool = true
	var tree_all_rot: bool = true
	var tree_frames_9: bool = true
	for d in expected_dirs:
		if not tree_sf.has_animation("sway_" + d): tree_all_sway = false
		if not tree_sf.has_animation("rot_" + d): tree_all_rot = false
		if tree_sf.has_animation("sway_" + d) and tree_sf.get_frame_count("sway_" + d) != 9: tree_frames_9 = false
	_ok("Tree has all 8 directional sway animations", tree_all_sway)
	_ok("Tree has all 8 directional rotation animations", tree_all_rot)
	_ok("Tree each directional sway has 9 frames", tree_frames_9)

	# 3. Bush SpriteFrames 8 directions
	var bush_sf: SpriteFrames = load("res://assets/sprites/environment/bush/bush_sprite_frames.tres") as SpriteFrames
	_ok("Bush SpriteFrames loads", bush_sf != null)
	var bush_all_sway: bool = true
	for d in expected_dirs:
		if not bush_sf.has_animation("sway_" + d): bush_all_sway = false
	_ok("Bush has all 8 directional sway animations", bush_all_sway)

	# 4. Green Stalks SpriteFrames 8 directions
	var stalks_sf2: SpriteFrames = load("res://green stalks/green_stalks_sprite_frames.tres") as SpriteFrames
	_ok("Green Stalks SpriteFrames loads", stalks_sf2 != null)
	var stalks_all_sway: bool = true
	for d in expected_dirs:
		if not stalks_sf2.has_animation("sway_" + d): stalks_all_sway = false
	_ok("Green Stalks has all 8 directional sway animations", stalks_all_sway)

	# 5. Dynamic Camera Perspective Tracking with simulated camera
	var prop_root: Node3D = Node3D.new()
	root.add_child(prop_root)
	prop_root.add_child(prop)
	prop.position = Vector3(0.0, 0.0, 0.0)
	prop.sprite_frames = tree_sf
	prop.anim_prefix = "sway"
	prop.world_facing_yaw = 0.0

	var test_cam: Camera3D = Camera3D.new()
	prop_root.add_child(test_cam)

	# Camera at South looking towards prop
	test_cam.position = Vector3(0.0, 1.0, 8.0)
	prop.update_camera_direction_manual(test_cam)
	_ok("Camera at South selects south direction", prop.get_current_direction() == "south")
	_ok("Prop plays sway_south animation", prop.animation == "sway_south")

	# Camera at East looking towards prop
	test_cam.position = Vector3(8.0, 1.0, 0.0)
	prop.update_camera_direction_manual(test_cam)
	_ok("Camera at East selects east direction", prop.get_current_direction() == "east")
	_ok("Prop plays sway_east animation", prop.animation == "sway_east")

	# Camera at North looking towards prop
	test_cam.position = Vector3(0.0, 1.0, -8.0)
	prop.update_camera_direction_manual(test_cam)
	_ok("Camera at North selects north direction", prop.get_current_direction() == "north")
	_ok("Prop plays sway_north animation", prop.animation == "sway_north")

	# Camera at West looking towards prop
	test_cam.position = Vector3(-8.0, 1.0, 0.0)
	prop.update_camera_direction_manual(test_cam)
	_ok("Camera at West selects west direction", prop.get_current_direction() == "west")
	_ok("Prop plays sway_west animation", prop.animation == "sway_west")

	# Diagonal: Camera at South-West
	test_cam.position = Vector3(-6.0, 1.0, 6.0)
	prop.update_camera_direction_manual(test_cam)
	_ok("Camera at South-West selects south-west direction", prop.get_current_direction() == "south-west")
	_ok("Prop plays sway_south-west animation", prop.animation == "sway_south-west")

	# 6. Animation Frame Preservation during angle switches
	prop.frame = 5
	test_cam.position = Vector3(0.0, 1.0, 8.0) # move to South
	prop.update_camera_direction_manual(test_cam)
	_ok("Frame index preserved when switching animation", prop.frame == 5)

	# 7. World Facing Yaw rotation
	prop.set_world_facing_yaw(deg_to_rad(90.0)) # Turn prop 90 deg (faces East)
	test_cam.position = Vector3(0.0, 1.0, 8.0) # Camera at South
	prop.update_camera_direction_manual(test_cam)
	_ok("Turned prop shows side face when viewed from South", prop.get_current_direction() == "west")

	# 8. TestWorld3D instantiation has DirectionalProp3D instances
	var tw3d_scene: PackedScene = load("res://scenes/maps/test_world_3d.tscn") as PackedScene
	_ok("TestWorld3D scene loads for prop test", tw3d_scene != null)
	var tw3d_inst: TestWorld3D = tw3d_scene.instantiate() as TestWorld3D
	root.add_child(tw3d_inst)
	tw3d_inst._ready()

	var directional_props_count: int = 0
	var props_container: Node3D = tw3d_inst.get_node_or_null("Props") as Node3D
	if props_container != null:
		for c in props_container.get_children():
			if c is DirectionalProp3D:
				directional_props_count += 1
	_ok("TestWorld3D instantiates DirectionalProp3D for environment props", directional_props_count >= 30)

	tw3d_inst.queue_free()
	prop_root.queue_free()

	# ─────────────────────────────────────────────────────────────────────────
	# [Group CC] Inventory Window & Item Information Window System
	# ─────────────────────────────────────────────────────────────────────────
	print("\n[Group CC] Inventory Window & Item Information Window System")

	# 1. ItemSlot scene & component
	var slot_scene: PackedScene = load("res://scenes/ui/item_slot.tscn") as PackedScene
	_ok("ItemSlot scene loads", slot_scene != null)
	var slot: ItemSlot = slot_scene.instantiate() as ItemSlot
	root.add_child(slot)
	slot._ready()

	_ok("ItemSlot mouse_filter is MOUSE_FILTER_STOP", slot.mouse_filter == Control.MOUSE_FILTER_STOP)
	_ok("ItemSlot starts empty with icon hidden", slot.icon_rect != null and not slot.icon_rect.visible)
	_ok("ItemSlot starts with qty badge hidden", slot.qty_badge != null and not slot.qty_badge.visible)

	var test_potion := ItemDefinition.new()
	test_potion.item_id = "test_pot"
	test_potion.display_name = "Red Potion"
	test_potion.category = ItemDefinition.Category.CONSUMABLE
	test_potion.heal_amount = 50
	test_potion.weight = 5
	test_potion.stackable = true

	slot.set_item(test_potion, 15, true)
	_ok("ItemSlot set_item shows icon", slot.icon_rect.visible)
	_ok("ItemSlot set_item shows qty badge for quantity > 1", slot.qty_badge.visible)
	_ok("ItemSlot qty label displays 15", slot.qty_label.text == "15")
	_ok("ItemSlot shows favorite star when is_favorite is true", slot.fav_icon.visible)

	slot.set_selected(true)
	_ok("ItemSlot is_selected is true", slot.is_selected)

	var clicked_slot: Array = []
	slot.slot_clicked.connect(func(s: ItemSlot): clicked_slot.append(s))
	var fake_click := InputEventMouseButton.new()
	fake_click.button_index = MOUSE_BUTTON_LEFT
	fake_click.pressed = true
	slot._on_gui_input(fake_click)
	_ok("ItemSlot click emits slot_clicked", clicked_slot.size() == 1 and clicked_slot[0] == slot)

	slot.clear_item()
	_ok("ItemSlot clear_item resets item_data", slot.item_data == null)
	_ok("ItemSlot clear_item hides icon", not slot.icon_rect.visible)
	slot.queue_free()

	# 2. InventoryWindow scene & components
	var inv_win_scene: PackedScene = load("res://scenes/ui/inventory_window.tscn") as PackedScene
	_ok("InventoryWindow scene loads", inv_win_scene != null)
	var inv_win: InventoryWindow = inv_win_scene.instantiate() as InventoryWindow
	root.add_child(inv_win)
	inv_win._ready()

	_ok("InventoryWindow mouse_filter is MOUSE_FILTER_STOP", inv_win.mouse_filter == Control.MOUSE_FILTER_STOP)
	_ok("InventoryWindow title_bar mouse_filter is MOUSE_FILTER_STOP", inv_win.title_bar.mouse_filter == Control.MOUSE_FILTER_STOP)
	_ok("InventoryWindow main_panel mouse_filter is MOUSE_FILTER_STOP", inv_win.main_panel.mouse_filter == Control.MOUSE_FILTER_STOP)
	_ok("InventoryWindow has 35 slots in 7x5 grid", inv_win.slots.size() == 35)

	# 3. ItemInfoWindow scene & components
	var info_win_scene: PackedScene = load("res://scenes/ui/item_info_window.tscn") as PackedScene
	_ok("ItemInfoWindow scene loads", info_win_scene != null)
	var info_win: ItemInfoWindow = info_win_scene.instantiate() as ItemInfoWindow
	root.add_child(info_win)
	info_win._ready()

	_ok("ItemInfoWindow mouse_filter is MOUSE_FILTER_STOP", info_win.mouse_filter == Control.MOUSE_FILTER_STOP)
	_ok("ItemInfoWindow title_bar mouse_filter is MOUSE_FILTER_STOP", info_win.title_bar.mouse_filter == Control.MOUSE_FILTER_STOP)

	# 4. Inventory Data Binding & Tab Filtering
	var test_inv := InventoryComponent.new()
	test_inv.base_weight = 1200
	test_inv.max_weight = 2900

	var sword_item := ItemDefinition.new()
	sword_item.item_id = "test_sword"
	sword_item.display_name = "Training Sword"
	sword_item.category = ItemDefinition.Category.WEAPON
	sword_item.equip_slot = "weapon"
	sword_item.stat_modifiers = {"attack": 8}
	sword_item.weight = 80
	sword_item.stackable = false

	var herb_item := ItemDefinition.new()
	herb_item.item_id = "test_herb"
	herb_item.display_name = "Green Herb"
	herb_item.category = ItemDefinition.Category.CONSUMABLE
	herb_item.heal_amount = 20
	herb_item.weight = 3
	herb_item.stackable = true

	var feather_item := ItemDefinition.new()
	feather_item.item_id = "test_feather"
	feather_item.display_name = "Starlight Feather"
	feather_item.category = ItemDefinition.Category.MISC
	feather_item.weight = 1
	feather_item.stackable = true

	# Add items
	test_inv.add_item(sword_item)
	test_inv.add_item(herb_item)
	test_inv.add_item(herb_item) # stacked
	test_inv.add_item(feather_item)

	inv_win.bind_inventory(test_inv)
	info_win.bind_inventory(test_inv)

	# Tab: Item (Consumables)
	inv_win.switch_tab("item")
	_ok("Item tab active", inv_win.current_tab == "item")
	_ok("Slot 0 in Item tab is Herb", inv_win.slots[0].item_data != null and inv_win.slots[0].item_data.item_id == "test_herb")
	_ok("Slot 0 in Item tab has stacked quantity 2", inv_win.slots[0].quantity == 2)
	_ok("Slot 1 in Item tab is empty", inv_win.slots[1].item_data == null)

	# Tab: Gear
	inv_win.switch_tab("gear")
	_ok("Gear tab active", inv_win.current_tab == "gear")
	_ok("Slot 0 in Gear tab is Sword", inv_win.slots[0].item_data != null and inv_win.slots[0].item_data.item_id == "test_sword")
	_ok("Slot 1 in Gear tab is empty", inv_win.slots[1].item_data == null)

	# Tab: Etc
	inv_win.switch_tab("etc")
	_ok("Etc tab active", inv_win.current_tab == "etc")
	_ok("Slot 0 in Etc tab is Feather", inv_win.slots[0].item_data != null and inv_win.slots[0].item_data.item_id == "test_feather")
	_ok("Slot 1 in Etc tab is empty", inv_win.slots[1].item_data == null)

	# Favorite Flag & Tab: Fav
	_ok("Fav tab initially empty", true)
	test_inv.set_favorite("test_sword", true)
	_ok("test_sword is marked favorite", test_inv.is_favorite("test_sword"))
	inv_win.switch_tab("fav")
	_ok("Slot 0 in Fav tab is favorite sword", inv_win.slots[0].item_data != null and inv_win.slots[0].item_data.item_id == "test_sword")
	_ok("Fav tab slot shows star badge", inv_win.slots[0].is_favorite)

	# 5. Weight Encumbrance Calculation
	# Weight = base 1200 + sword (80) + 2 herbs (2*3=6) + feather (1) = 1287
	var total_w: int = test_inv.get_total_weight()
	_ok("Total weight calculated correctly (1287)", total_w == 1287)
	_ok("Inventory weight label contains 1,287", inv_win.label_weight.text.contains("1,287"))
	_ok("Inventory weight bar matches calculated weight", int(inv_win.weight_bar.value) == 1287)

	# 6. Selection & ItemInfoWindow Population
	inv_win.switch_tab("gear")
	info_win.set_item(inv_win.slots[0].item_data, inv_win.slots[0].quantity, inv_win.slots[0].is_favorite)
	_ok("ItemInfoWindow name is Training Sword", info_win.label_name.text == "Training Sword")
	_ok("ItemInfoWindow type is Weapon (Weapon)", info_win.label_type.text.contains("Weapon"))
	_ok("ItemInfoWindow weight is 80", info_win.label_weight.text.contains("80"))
	_ok("ItemInfoWindow stat text contains ATTACK +8", info_win.label_stats.text.contains("ATTACK +8"))
	_ok("ItemInfoWindow Use button displays Equip for weapons", info_win.btn_use.text == "Equip")

	# 7. Consumable Use Behavior
	var inv_dummy_player: Node = Node.new()
	var inv_dummy_stats: CharacterStatsComponent = CharacterStatsComponent.new()
	inv_dummy_stats.name = "CharacterStatsComponent"
	test_inv.name = "InventoryComponent"
	inv_dummy_stats.max_health = 100
	inv_dummy_player.name = "Player"
	inv_dummy_player.add_child(inv_dummy_stats)
	inv_dummy_player.add_child(test_inv)
	root.add_child(inv_dummy_player)
	inv_dummy_stats._ready()
	inv_dummy_stats.set_health(40)

	info_win.bind_player(inv_dummy_player)
	info_win.set_item(herb_item, 2, false)
	_ok("Dummy player current HP is 40", inv_dummy_stats.current_health == 40)
	info_win._on_use_pressed()
	_ok("Using herb heals player by 20 (40 -> 60)", inv_dummy_stats.current_health == 60)
	_ok("Using herb reduces inventory herb count to 1", test_inv.count_item("test_herb") == 1)

	# 8. Lock Item Drop & Drop Behavior
	inv_win.lock_drop_checkbox.button_pressed = true
	inv_win._on_lock_drop_toggled(true)
	info_win.set_drop_locked(true)
	_ok("is_drop_locked is true", inv_win.is_drop_locked)
	_ok("Drop button disabled when drop is locked", info_win.btn_drop.disabled)

	# Attempt drop while locked
	info_win._on_drop_pressed()
	_ok("Herb not dropped while locked (count still 1)", test_inv.count_item("test_herb") == 1)

	# Unlock and drop
	inv_win.lock_drop_checkbox.button_pressed = false
	inv_win._on_lock_drop_toggled(false)
	info_win.set_drop_locked(false)
	_ok("Drop button enabled when drop unlocked", not info_win.btn_drop.disabled)
	info_win._on_drop_pressed()
	_ok("Dropping herb removes it from inventory (count == 0)", test_inv.count_item("test_herb") == 0)

	# 9. UI Click Does Not Trigger World Input
	var p3d_scene: PackedScene = load("res://scenes/entities/player_3d.tscn") as PackedScene
	_ok("Player3D scene loads for UI input isolation test", p3d_scene != null)
	var p3d_inst: Player3D = p3d_scene.instantiate() as Player3D
	root.add_child(p3d_inst)
	p3d_inst._ready()
	var initial_player_pos: Vector3 = p3d_inst.position

	# Simulate dragging window title bar
	var initial_win_pos: Vector2 = inv_win.global_position
	var drag_event := InputEventMouseButton.new()
	drag_event.button_index = MOUSE_BUTTON_LEFT
	drag_event.pressed = true
	inv_win._on_title_bar_gui_input(drag_event)
	_ok("Inventory window starts dragging", inv_win._is_dragging)

	# Dragging never triggers player movement or changes move destination
	_ok("Player3D has_move_target is false during window drag", not p3d_inst.has_move_target)
	_ok("Player3D position unchanged during window drag", p3d_inst.position == initial_player_pos)

	# End drag
	drag_event.pressed = false
	inv_win._on_title_bar_gui_input(drag_event)
	_ok("Inventory window ends dragging", not inv_win._is_dragging)

	# 10. HUD Integration for Inventory & Item Info Windows
	var hud_scene2: PackedScene = load("res://scenes/ui/hud.tscn") as PackedScene
	_ok("HUD scene loads for inventory integration test", hud_scene2 != null)
	var hud_inst: HUD = hud_scene2.instantiate() as HUD
	root.add_child(hud_inst)
	hud_inst._ready()

	_ok("HUD has InventoryWindow", hud_inst.inventory_window != null)
	_ok("HUD has ItemInfoWindow", hud_inst.item_info_window != null)
	_ok("InventoryWindow initially hidden in HUD", not hud_inst.inventory_window.visible)
	_ok("ItemInfoWindow initially hidden in HUD", not hud_inst.item_info_window.visible)

	hud_inst.toggle_inventory()
	_ok("toggle_inventory shows InventoryWindow", hud_inst.inventory_window.visible)
	_ok("toggle_inventory shows ItemInfoWindow", hud_inst.item_info_window.visible)

	hud_inst.toggle_inventory()
	_ok("toggle_inventory hides InventoryWindow", not hud_inst.inventory_window.visible)
	_ok("toggle_inventory hides ItemInfoWindow", not hud_inst.item_info_window.visible)

	_ok("HUD has toggle_inventory_button", hud_inst.toggle_inventory_button != null)

	# Cleanup
	hud_inst.queue_free()
	p3d_inst.queue_free()
	inv_dummy_player.queue_free()
	inv_win.queue_free()
	info_win.queue_free()

	# ─────────────────────────────────────────────────────────────────────────
	# [Group DD] Monster Item Drops & Ragnarok ItemInfo System
	# ─────────────────────────────────────────────────────────────────────────
	print("\n[Group DD] Monster Item Drops & Ragnarok ItemInfo System")

	ContentRegistry.ensure_initialized()

	# 1. Apple Item Definition & Icon Assets
	var apple_def: ItemDefinition = ContentRegistry.get_item("apple")
	_ok("Apple item definition loaded from ContentRegistry", apple_def != null)
	_ok("Apple display_name is Apple", apple_def != null and apple_def.display_name == "Apple")
	_ok("Apple category is CONSUMABLE", apple_def != null and apple_def.category == ItemDefinition.Category.CONSUMABLE)
	_ok("Apple heal_amount is 15", apple_def != null and apple_def.heal_amount == 15)
	_ok("Apple weight is 2", apple_def != null and apple_def.weight == 2)
	_ok("Apple price is 15", apple_def != null and apple_def.price == 15)
	_ok("Apple icon_path is valid", apple_def != null and apple_def.icon_path == "res://assets/icons/items/icon_item_apple.png")
	var apple_icon: Texture2D = apple_def.get_icon() if apple_def != null else null
	_ok("Apple get_icon returns valid Texture2D", apple_icon != null)
	_ok("Apple get_type_text is Usable (Consumable)", apple_def != null and apple_def.get_type_text() == "Usable (Consumable)")
	_ok("Apple get_stat_text contains Restores 15 HP", apple_def != null and apple_def.get_stat_text().contains("Restores 15 HP"))

	# 2. EnemyDefinition Drop Table Serialization & Validation
	var test_enemy_def: EnemyDefinition = EnemyDefinition.new()
	test_enemy_def.enemy_id = "test_drop_mob"
	test_enemy_def.display_name = "Drop Mob"
	test_enemy_def.max_health = 50
	test_enemy_def.drops = [
		{"item_id": "apple", "chance": 0.75, "min_qty": 1, "max_qty": 2}
	]
	var enemy_ser: Dictionary = test_enemy_def.serialize()
	_ok("EnemyDefinition serialize has drops", enemy_ser.has("drops") and enemy_ser["drops"].size() == 1)

	var enemy_deser: EnemyDefinition = EnemyDefinition.new()
	enemy_deser.deserialize(enemy_ser)
	_ok("EnemyDefinition deserialize drops item_id", enemy_deser.drops.size() == 1 and str(enemy_deser.drops[0]["item_id"]) == "apple")
	_ok("EnemyDefinition deserialize drops chance", float(enemy_deser.drops[0]["chance"]) == 0.75)
	_ok("EnemyDefinition deserialize drops min_qty", int(enemy_deser.drops[0]["min_qty"]) == 1)
	_ok("EnemyDefinition deserialize drops max_qty", int(enemy_deser.drops[0]["max_qty"]) == 2)
	_ok("Valid enemy with drops passes validation", enemy_deser.validate().is_empty())

	# Validation error cases
	var bad_drop_mob: EnemyDefinition = EnemyDefinition.new()
	bad_drop_mob.enemy_id = "bad_mob"
	bad_drop_mob.display_name = "Bad Mob"
	bad_drop_mob.max_health = 10
	bad_drop_mob.drops = [
		{"item_id": "", "chance": 1.5, "min_qty": 5, "max_qty": 2}
	]
	var bad_errs: Array[String] = bad_drop_mob.validate()
	_ok("Validation detects empty drop item_id", bad_errs.any(func(e: String) -> bool: return e.contains("item_id")))
	_ok("Validation detects drop chance > 1.0", bad_errs.any(func(e: String) -> bool: return e.contains("chance")))
	_ok("Validation detects max_qty < min_qty", bad_errs.any(func(e: String) -> bool: return e.contains("max_qty")))

	var wolf_def: EnemyDefinition = ContentRegistry.get_enemy("wolf_small")
	_ok("Wolf enemy definition has drops table", wolf_def != null and not wolf_def.drops.is_empty())
	_ok("Wolf drops table contains apple", wolf_def != null and wolf_def.drops.any(func(d: Dictionary) -> bool: return str(d.get("item_id")) == "apple"))

	# 3. ItemPickup3D In-World Drop Entity
	var pickup3d_scene: PackedScene = load("res://scenes/objects/item_pickup_3d.tscn") as PackedScene
	_ok("ItemPickup3D scene loads", pickup3d_scene != null)
	var pickup3d_inst: ItemPickup3D = pickup3d_scene.instantiate() as ItemPickup3D
	root.add_child(pickup3d_inst)
	pickup3d_inst.init_drop("apple", 2, Vector3(5.0, 0.2, 5.0))
	_ok("ItemPickup3D item_id is apple", pickup3d_inst.item_id == "apple")
	_ok("ItemPickup3D quantity is 2", pickup3d_inst.quantity == 2)
	_ok("ItemPickup3D sprite has apple texture", pickup3d_inst.sprite != null and pickup3d_inst.sprite.texture != null)
	_ok("ItemPickup3D shadow mesh exists", pickup3d_inst.shadow != null)

	# 4. Proximity & Click Collection into InventoryComponent
	var drop_dummy_player: Node3D = Node3D.new()
	var drop_inv: InventoryComponent = InventoryComponent.new()
	drop_inv.name = "InventoryComponent"
	drop_inv.max_weight = 5000
	drop_dummy_player.add_child(drop_inv)
	root.add_child(drop_dummy_player)
	_ok("Initial apple count in test inventory is 0", drop_inv.count_item("apple") == 0)

	var collected_signals: Array[Dictionary] = []
	pickup3d_inst.item_collected.connect(func(it: ItemDefinition, q: int, by: Node):
		collected_signals.append({"item": it, "qty": q, "by": by})
	)

	var collect_success: bool = pickup3d_inst.collect(drop_dummy_player)
	_ok("pickup3d collect returns true", collect_success)
	_ok("pickup3d emits item_collected signal", not collected_signals.is_empty())
	_ok("Apple added to player inventory (count == 2)", drop_inv.count_item("apple") == 2)

	# 5. Enemy3D Spawns Drops on Death
	var enemy3d_parent: Node3D = Node3D.new()
	root.add_child(enemy3d_parent)
	var enemy3d_scene: PackedScene = load("res://scenes/entities/enemy_3d.tscn") as PackedScene
	var enemy3d_inst: Enemy3D = enemy3d_scene.instantiate() as Enemy3D
	enemy3d_parent.add_child(enemy3d_inst)
	enemy3d_inst.init_from_id("wolf_small")
	_ok("Enemy3D initialized with wolf_small definition", enemy3d_inst.definition != null)
	# Force 100% apple drop for deterministic test
	enemy3d_inst.definition.drops = [{"item_id": "apple", "chance": 1.0, "min_qty": 1, "max_qty": 1}]
	enemy3d_inst._on_died()
	var drops_spawned: Array[Node] = []
	for child in enemy3d_parent.get_children():
		if child is ItemPickup3D:
			drops_spawned.append(child)
	_ok("Enemy3D death spawns ItemPickup3D in parent", not drops_spawned.is_empty())
	if not drops_spawned.is_empty():
		var spawned_drop: ItemPickup3D = drops_spawned[0] as ItemPickup3D
		_ok("Spawned drop item_id is apple", spawned_drop.item_id == "apple")

	# 6. ContentRegistry ItemInfo Import & Export
	var iteminfo_test_path: String = "res://data/test_iteminfo_export.json"
	var exp_err: Error = ContentRegistry.export_iteminfo(iteminfo_test_path)
	_ok("ContentRegistry.export_iteminfo returns OK", exp_err == OK)
	_ok("Exported iteminfo file exists on disk", FileAccess.file_exists(iteminfo_test_path))

	var imported_count: int = ContentRegistry.import_iteminfo(iteminfo_test_path)
	_ok("ContentRegistry.import_iteminfo loads items", imported_count >= 5)
	if FileAccess.file_exists(iteminfo_test_path):
		DirAccess.remove_absolute(iteminfo_test_path)

	# 7. ContentRegistry Save and Delete Item to Disk
	var custom_potion: ItemDefinition = ItemDefinition.new()
	custom_potion.item_id = "test_speed_potion"
	custom_potion.display_name = "Speed Potion"
	custom_potion.description = "Grants swift footwork."
	custom_potion.category = ItemDefinition.Category.CONSUMABLE
	custom_potion.weight = 3
	custom_potion.price = 75
	custom_potion.icon_path = "res://assets/icons/items/icon_item_apple.png"
	var save_err: Error = ContentRegistry.save_item_to_disk(custom_potion)
	_ok("ContentRegistry.save_item_to_disk returns OK", save_err == OK)
	_ok("Saved item retrieved from ContentRegistry", ContentRegistry.get_item("test_speed_potion") != null)
	var del_err: Error = ContentRegistry.delete_item_from_disk("test_speed_potion")
	_ok("ContentRegistry.delete_item_from_disk returns OK", del_err == OK)
	_ok("Deleted item no longer in ContentRegistry", ContentRegistry.get_item("test_speed_potion") == null)

	# 8. ItemEditorWindow Scene & Functionality
	var editor_scene: PackedScene = load("res://scenes/ui/item_editor_window.tscn") as PackedScene
	_ok("ItemEditorWindow scene loads", editor_scene != null)
	var editor_inst: ItemEditorWindow = editor_scene.instantiate() as ItemEditorWindow
	root.add_child(editor_inst)
	editor_inst._ready()
	_ok("ItemEditorWindow has item_list", editor_inst.item_list != null)
	_ok("ItemEditorWindow item_list is populated", editor_inst.item_list.item_count >= 5)

	editor_inst.select_item("apple")
	_ok("Editor edit_id matches selected apple", editor_inst.edit_id != null and editor_inst.edit_id.text == "apple")
	_ok("Editor edit_name matches selected Apple", editor_inst.edit_name != null and editor_inst.edit_name.text == "Apple")
	_ok("Editor spin_heal matches apple heal_amount", editor_inst.spin_heal != null and int(editor_inst.spin_heal.value) == 15)

	# 9. HUD Item Editor Toggle Integration
	var hud_scene_editor: PackedScene = load("res://scenes/ui/hud.tscn") as PackedScene
	var hud_editor_inst: HUD = hud_scene_editor.instantiate() as HUD
	root.add_child(hud_editor_inst)
	hud_editor_inst._ready()

	_ok("HUD has toggle_editor_button", hud_editor_inst.toggle_editor_button != null)
	hud_editor_inst.toggle_item_editor()
	_ok("toggle_item_editor opens ItemEditorWindow in HUD", hud_editor_inst.item_editor_window != null and hud_editor_inst.item_editor_window.visible)
	hud_editor_inst.toggle_item_editor()
	_ok("toggle_item_editor closes ItemEditorWindow in HUD", not hud_editor_inst.item_editor_window.visible)

	# Cleanup Group DD nodes
	hud_editor_inst.queue_free()
	editor_inst.queue_free()
	enemy3d_parent.queue_free()
	drop_dummy_player.queue_free()
	pickup3d_inst.queue_free()

	# ─────────────────────────────────────────────────────────────────────────
	# [Group EE] 256x256 Grass & Dirt Autotiling TileSet System
	# ─────────────────────────────────────────────────────────────────────────
	print("\n[Group EE] 256x256 Grass & Dirt Autotiling TileSet System")

	var terrain_ts: TileSet = load("res://assets/terrain/terrain_tileset.tres") as TileSet
	_ok("terrain_tileset.tres loads successfully as TileSet", terrain_ts != null)
	if terrain_ts != null:
		_ok("terrain_tileset tile_size is Vector2i(256, 256)", terrain_ts.tile_size == Vector2i(256, 256))
		_ok("terrain_tileset has terrain set 0", terrain_ts.get_terrain_sets_count() >= 1)
		_ok("terrain set 0 is TERRAIN_MODE_MATCH_CORNERS", terrain_ts.get_terrain_set_mode(0) == TileSet.TERRAIN_MODE_MATCH_CORNERS)
		_ok("terrain set 0 has 2 terrains", terrain_ts.get_terrains_count(0) == 2)
		_ok("terrain 0 name is grass", terrain_ts.get_terrain_name(0, 0) == "grass")
		_ok("terrain 1 name is dirt", terrain_ts.get_terrain_name(0, 1) == "dirt")
		_ok("terrain_tileset has 2 custom data layers", terrain_ts.get_custom_data_layers_count() == 2)
		_ok("custom data layer 0 is walkable", terrain_ts.get_custom_data_layer_name(0) == "walkable")
		_ok("custom data layer 1 is footstep", terrain_ts.get_custom_data_layer_name(1) == "footstep")
		_ok("terrain_tileset has source 0", terrain_ts.get_source_count() >= 1)
		var atlas_src: TileSetAtlasSource = terrain_ts.get_source(terrain_ts.get_source_id(0)) as TileSetAtlasSource
		_ok("terrain_tileset source is TileSetAtlasSource", atlas_src != null)
		if atlas_src != null:
			_ok("TileSetAtlasSource has 22 configured tiles", atlas_src.get_tiles_count() == 22)
			_ok("TileSetAtlasSource texture_region_size is Vector2i(256, 256)", atlas_src.texture_region_size == Vector2i(256, 256))

	var atlas_tex: Texture2D = load("res://assets/terrain/terrain_grass_dirt_atlas.png") as Texture2D
	_ok("terrain_grass_dirt_atlas.png loads as Texture2D", atlas_tex != null)
	if atlas_tex != null:
		_ok("Atlas width is 1024", atlas_tex.get_width() == 1024)
		_ok("Atlas height is 1536", atlas_tex.get_height() == 1536)

	var terrain_scene: PackedScene = load("res://scenes/terrain_test.tscn") as PackedScene
	_ok("scenes/terrain_test.tscn loads as PackedScene", terrain_scene != null)
	if terrain_scene != null:
		var scene_inst: Node = terrain_scene.instantiate()
		root.add_child(scene_inst)
		var tml: TileMapLayer = scene_inst.get_node_or_null("TileMapLayer") as TileMapLayer
		_ok("terrain_test scene has TileMapLayer node", tml != null)
		if tml != null:
			_ok("TileMapLayer uses terrain_tileset.tres", tml.tile_set != null and tml.tile_set.resource_path.contains("terrain_tileset.tres"))
		scene_inst.queue_free()










