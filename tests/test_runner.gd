extends SceneTree

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

	# Test input response on Player3D
	Input.action_press("move_right")
	p3d._physics_process(0.016)
	_ok("Player3D moves East (+X) on move_right (D / Right)", p3d.velocity.x > 0.0)
	Input.action_release("move_right")

	Input.action_press("move_left")
	p3d._physics_process(0.016)
	_ok("Player3D moves West (-X) on move_left (A / Left)", p3d.velocity.x < 0.0)
	Input.action_release("move_left")

	Input.action_press("move_up")
	p3d._physics_process(0.016)
	_ok("Player3D moves North (-Z) on move_up (W / Up)", p3d.velocity.z < 0.0)
	Input.action_release("move_up")

	Input.action_press("move_down")
	p3d._physics_process(0.016)
	_ok("Player3D moves South (+Z) on move_down (S / Down)", p3d.velocity.z > 0.0)
	Input.action_release("move_down")

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

	# Test camera-relative movement when rotated 90 deg clockwise
	# With 90 deg yaw: cam_forward = (-1, 0, 0)
	# So pressing move_up (forward into screen) should move in -X direction
	Input.action_press("move_up")
	p3d._physics_process(0.016)
	_ok("Camera-relative movement: W moves into screen relative to camera angle", p3d.velocity.x < -0.1)
	Input.action_release("move_up")

	# Reset camera back to default
	p3d.reset_camera_view()
	p3d._update_camera(0.0)

	world_3d.queue_free()




