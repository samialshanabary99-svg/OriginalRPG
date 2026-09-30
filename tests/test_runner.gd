extends SceneTree

## Lightweight automated test runner for headless CI and agent verification.

func _init() -> void:
	print("[TestRunner] Starting automated tests...")
	var total_tests: int = 0
	var failed_tests: int = 0

	# Test 1: DamageCalculator
	total_tests += 1
	var dmg: int = DamageCalculator.calculate_damage(35, 10, 1)
	if dmg == 25:
		print("  [PASS] DamageCalculator basic calculation")
	else:
		print("  [FAIL] DamageCalculator basic calculation (expected 25, got %d)" % dmg)
		failed_tests += 1

	total_tests += 1
	var min_dmg: int = DamageCalculator.calculate_damage(5, 50, 1)
	if min_dmg == 1:
		print("  [PASS] DamageCalculator minimum damage clamp")
	else:
		print("  [FAIL] DamageCalculator minimum damage clamp (expected 1, got %d)" % min_dmg)
		failed_tests += 1

	# Test 2: StatsComponent Lifecycle & Signals
	total_tests += 1
	var stats := StatsComponent.new()
	stats.max_health = 100
	stats._ready()

	var signal_captured: Array[int] = []
	stats.health_changed.connect(func(cur: int, max_hp: int):
		signal_captured.append(cur)
		signal_captured.append(max_hp)
	)
	stats.apply_damage(20)

	if stats.current_health == 80 and signal_captured.size() == 2 and signal_captured[0] == 80 and signal_captured[1] == 100:
		print("  [PASS] StatsComponent damage & signal emission")
	else:
		print("  [FAIL] StatsComponent damage & signal emission (captured: %s, hp: %d)" % [str(signal_captured), stats.current_health])
		failed_tests += 1


	# Test 3: StatsComponent Serialization
	total_tests += 1
	var serialized: Dictionary = stats.serialize()
	var fresh_stats := StatsComponent.new()
	fresh_stats.deserialize(serialized)
	if fresh_stats.current_health == 80 and fresh_stats.max_health == 100:
		print("  [PASS] StatsComponent serialize / deserialize roundtrip")
	else:
		print("  [FAIL] StatsComponent serialization failed")
		failed_tests += 1

	stats.free()
	fresh_stats.free()

	# Summary
	print("[TestRunner] Completed %d tests. Failures: %d" % [total_tests, failed_tests])
	if failed_tests > 0:
		quit(1)
	else:
		print("[TestRunner] ALL TESTS PASSED.")
		quit(0)
