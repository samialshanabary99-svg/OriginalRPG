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
