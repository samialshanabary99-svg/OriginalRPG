extends SceneTree

## Standalone CLI asset validator for OriginalRPG.
## Run with: godot --headless -s scripts/validate_assets.gd

func _init() -> void:
	print("==========================================")
	print(" OriginalRPG — Asset Pipeline Validator ")
	print("==========================================")

	var dir_res: Dictionary = AssetValidator.validate_directory("res://assets")
	var manifest_res: Dictionary = AssetValidator.check_manifest_coverage("res://assets", "docs/assets/ASSET_MANIFEST.md")

	print("\n[1/2] Asset File Inspection:")
	print("  Files checked: %d" % int(dir_res.get("files_checked", 0)))
	if dir_res.get("valid", false):
		print("  Status: PASSED (All files conform to naming, format, and dimension rules)")
	else:
		print("  Status: FAILED")
		for err: String in dir_res.get("errors", []):
			print("    [ERROR] %s" % err)

	print("\n[2/2] Manifest Coverage Inspection:")
	print("  Checked disk assets: %d" % int(manifest_res.get("checked_count", 0)))
	print("  Unmanifested assets: %d" % int(manifest_res.get("missing_count", 0)))
	if manifest_res.get("valid", false):
		print("  Status: PASSED (All assets documented in ASSET_MANIFEST.md)")
	else:
		print("  Status: FAILED")
		for err: String in manifest_res.get("errors", []):
			print("    [ERROR] %s" % err)

	var overall_passed: bool = bool(dir_res.get("valid", false)) and bool(manifest_res.get("valid", false))

	print("\n==========================================")
	if overall_passed:
		print(" RESULT: ALL ASSET CHECKS PASSED.")
		print("==========================================")
		quit(0)
	else:
		print(" RESULT: ASSET VALIDATION FAILURES DETECTED.")
		print("==========================================")
		quit(1)
