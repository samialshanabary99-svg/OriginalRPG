extends SceneTree

## Automated test runner — covers foundation + prototype mechanics.
## Run with: godot --headless --script tests/test_runner.gd

var _total: int = 0
var _failed: int = 0

func _init() -> void:
	print("[TestRunner] Starting OriginalRPG automated tests...")

	_test_damage_calculator()
	_test_stats_component()
	_test_scene_loading()
	_test_player_composition()
	_test_movement()
	_test_interaction()

	print("")
	print("[TestRunner] ─────────────────────────────────")
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

# ── Group A: DamageCalculator ──────────────────────────────────────────────────
func _test_damage_calculator() -> void:
	print("\n[Group A] DamageCalculator")
	_ok("basic damage subtraction", DamageCalculator.calculate_damage(35, 10, 1) == 25)
	_ok("minimum damage clamp", DamageCalculator.calculate_damage(5, 50, 1) == 1)
	_ok("is_alive true", DamageCalculator.is_alive(1))
	_ok("is_alive false at 0", not DamageCalculator.is_alive(0))

# ── Group B: StatsComponent ────────────────────────────────────────────────────
func _test_stats_component() -> void:
	print("\n[Group B] StatsComponent")

	var stats := StatsComponent.new()
	stats.max_health = 100
	stats._ready()

	var hp_sig: Array[int] = []
	stats.health_changed.connect(func(c: int, m: int):
		hp_sig.append(c)
		hp_sig.append(m)
	)
	stats.apply_damage(20)
	_ok("damage reduces HP", stats.current_health == 80)
	_ok("health_changed signal emitted with correct values", hp_sig.size() == 2 and hp_sig[0] == 80 and hp_sig[1] == 100)

	var died_flag: Array[bool] = [false]
	stats.died.connect(func(): died_flag[0] = true)
	stats.apply_damage(9999)
	_ok("HP clamps at 0", stats.current_health == 0)
	_ok("died signal fires at 0 HP", died_flag[0])

	# Reset and heal
	stats.max_health = 100
	stats._ready()
	stats.heal(30)
	_ok("heal restores HP", stats.current_health == 100)

	stats.apply_damage(40)
	var ser: Dictionary = stats.serialize()
	var stats2 := StatsComponent.new()
	stats2.deserialize(ser)
	_ok("serialize/deserialize roundtrip HP", stats2.current_health == 60)
	_ok("serialize/deserialize roundtrip max_health", stats2.max_health == 100)

	stats.free()
	stats2.free()

# ── Group C: Scene loading ─────────────────────────────────────────────────────
func _test_scene_loading() -> void:
	print("\n[Group C] Scene loading")
	var paths: Array[String] = [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/maps/test_world.tscn",
		"res://scenes/entities/player.tscn",
		"res://scenes/objects/ancient_monument.tscn",
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
		_ok("loads and instantiates: %s" % path.get_file(), ok)

# ── Group D: Player component composition ──────────────────────────────────────
func _test_player_composition() -> void:
	print("\n[Group D] Player composition")
	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)

	_ok("has StatsComponent", player.get_node_or_null("StatsComponent") != null)
	_ok("has InteractorComponent", player.get_node_or_null("InteractorComponent") != null)
	_ok("has Camera2D", player.get_node_or_null("Camera2D") != null)
	_ok("has Sprite2D", player.get_node_or_null("Sprite2D") != null)
	_ok("move_speed is positive", player.move_speed > 0.0)

	player.free()

# ── Group E: Movement ─────────────────────────────────────────────────────────
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

# ── Group F: Interaction ──────────────────────────────────────────────────────
func _test_interaction() -> void:
	print("\n[Group F] Interaction system")

	var player: Player = (load("res://scenes/entities/player.tscn") as PackedScene).instantiate() as Player
	get_root().add_child(player)

	var monument: AncientMonument = (load("res://scenes/objects/ancient_monument.tscn") as PackedScene).instantiate() as AncientMonument
	get_root().add_child(monument)

	var fired: Array[String] = []
	monument.inspection_triggered.connect(func(m: String): fired.append(m))

	# Direct interact call
	monument.interact(player)
	_ok("monument.interact fires inspection_triggered", fired.size() == 1)
	_ok("interaction_count increments to 1", monument.interaction_count == 1)

	# Repeat to check counter
	monument.interact(player)
	_ok("interaction_count increments to 2", monument.interaction_count == 2)

	# Interactor component
	var interactor: InteractorComponent = player.get_node("InteractorComponent") as InteractorComponent
	_ok("InteractorComponent is not null after tree insertion", interactor != null)

	if interactor != null:
		interactor.nearby_interactables.append(monument)
		interactor._update_current_target()
		_ok("current_target set to monument", interactor.current_target == monument)

		var result: bool = interactor.try_interact()
		_ok("try_interact returns true and fires monument", result and monument.interaction_count == 3)

	monument.free()
	player.free()
