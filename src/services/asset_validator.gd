class_name AssetValidator
extends RefCounted

## Automated validator for OriginalRPG's asset pipeline.
## Enforces rules established in docs/assets/ASSET_PIPELINE.md:
##   1. File format & extension checks (.png, .svg, .tres, .res, .json)
##   2. Strict naming conventions (snake_case, lowercase, no spaces or special symbols)
##   3. Image dimensions (square/grid multiples, standard tiers)
##   4. Transparency (RGBA alpha channel present)
##   5. Manifest registration (assets recorded in docs/assets/ASSET_MANIFEST.md)

const ALLOWED_IMAGE_EXTENSIONS: Array[String] = ["png", "svg"]
const ALLOWED_DATA_EXTENSIONS: Array[String] = ["tres", "res", "json", "gdshader"]

## Standard size tiers for raster assets (width or height)
const VALID_ICON_SIZES: Array[int] = [16, 24, 32, 48, 64, 128]
const VALID_SPRITE_FRAME_SIZES: Array[int] = [32, 64, 128, 256, 512]
const VALID_TILE_SIZES: Array[int] = [16, 32, 48, 64]

# ── File & Path Validation ───────────────────────────────────────────────────

## Validates a single file against asset rules.
## Returns Dictionary: {"valid": bool, "errors": Array[String], "warnings": Array[String]}
static func validate_file(file_path: String) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var file_name: String = file_path.get_file()
	var ext: String = file_path.get_extension().to_lower()

	# 1. Extension check
	if ext.is_empty():
		errors.append("File '%s' has no extension." % file_name)
		return {"valid": false, "errors": errors, "warnings": warnings}

	if ext == "import" or ext == "uid":
		# Skip Godot metadata sidecars
		return {"valid": true, "errors": [], "warnings": []}

	var all_allowed := ALLOWED_IMAGE_EXTENSIONS + ALLOWED_DATA_EXTENSIONS
	if not all_allowed.has(ext):
		errors.append("Disallowed file format '.%s' for '%s'. Allowed: %s" % [ext, file_name, ", ".join(all_allowed)])

	# 2. Naming convention check
	var name_errs := check_naming_convention(file_name)
	errors.append_array(name_errs)

	# 3. Image-specific validation (PNG)
	if ext == "png":
		if FileAccess.file_exists(file_path):
			var img := Image.new()
			var global_path: String = ProjectSettings.globalize_path(file_path)
			var load_err: Error = img.load(global_path)
			if load_err != OK:
				errors.append("Corrupted or unreadable PNG image at '%s' (Error %d)." % [file_path, load_err])
			else:
				var img_errs := check_image_properties(img, file_path)
				errors.append_array(img_errs)
		else:
			errors.append("File not found on disk: %s" % file_path)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings
	}

# ── Naming Convention Checks ─────────────────────────────────────────────────

## Enforces lowercase snake_case (or hyphenated directory segments for directions).
static func check_naming_convention(file_name: String) -> Array[String]:
	var errors: Array[String] = []
	var base_name: String = file_name.get_basename()

	# Disallow spaces
	if file_name.contains(" "):
		errors.append("Filename '%s' contains whitespace. Use snake_case." % file_name)

	# Disallow uppercase
	if file_name != file_name.to_lower():
		errors.append("Filename '%s' contains uppercase characters. Use lowercase." % file_name)

	# Check valid characters: a-z, 0-9, _, -, .
	var regex := RegEx.new()
	regex.compile("^[a-z0-9_\\-\\.]+$")
	if not regex.search(file_name):
		errors.append("Filename '%s' contains invalid characters. Only a-z, 0-9, '_', '-', '.' permitted." % file_name)

	return errors

# ── Image Property & Transparency Checks ─────────────────────────────────────

static func check_image_properties(img: Image, file_path: String) -> Array[String]:
	var errors: Array[String] = []
	var w: int = img.get_width()
	var h: int = img.get_height()

	if w <= 0 or h <= 0:
		errors.append("Invalid dimensions (%dx%d) for '%s'." % [w, h, file_path])
		return errors

	# Check transparency capability (must have alpha channel)
	var format: Image.Format = img.get_format()
	var has_alpha: bool = (
		format == Image.FORMAT_RGBA8 or
		format == Image.FORMAT_LA8 or
		format == Image.FORMAT_RGBAF or
		format == Image.FORMAT_RGBAH
	)
	if not has_alpha:
		errors.append("Image '%s' does not have an alpha channel (format is %d). RGBA8 required." % [file_path, format])

	# Check dimension standards based on folder hint
	var p_lower: String = file_path.to_lower()
	if p_lower.contains("icon"):
		if w != h:
			errors.append("Icon '%s' is not square (%dx%d)." % [file_path, w, h])
		elif not VALID_ICON_SIZES.has(w):
			errors.append("Icon '%s' dimension %d is not a standard icon size (%s)." % [file_path, w, str(VALID_ICON_SIZES)])
	elif p_lower.contains("tile"):
		if not VALID_TILE_SIZES.has(w) or not VALID_TILE_SIZES.has(h):
			errors.append("Tile '%s' dimensions (%dx%d) do not match valid tile sizes (%s)." % [file_path, w, h, str(VALID_TILE_SIZES)])
	elif p_lower.contains("player") or p_lower.contains("character") or p_lower.contains("monster") or p_lower.contains("enemy"):
		if w % 16 != 0 or h % 16 != 0:
			errors.append("Sprite frame '%s' dimensions (%dx%d) are not divisible by 16px grid." % [file_path, w, h])

	return errors

# ── Directory Scanning & Validation ──────────────────────────────────────────

## Recursively scans a directory and validates all asset files.
static func validate_directory(dir_path: String) -> Dictionary:
	var total_files: int = 0
	var all_errors: Array[String] = []
	var all_warnings: Array[String] = []

	var files := _collect_files_recursive(dir_path)
	for f: String in files:
		if f.ends_with(".import") or f.ends_with(".uid") or f.contains("/parts/") or f.ends_with("rig.tscn"):
			continue
		total_files += 1
		var res := validate_file(f)
		if not res["valid"]:
			all_errors.append_array(res["errors"])
		all_warnings.append_array(res["warnings"])

	return {
		"valid": all_errors.is_empty(),
		"files_checked": total_files,
		"errors": all_errors,
		"warnings": all_warnings
	}

# ── Manifest Verification ────────────────────────────────────────────────────

## Checks that all non-metadata assets in assets/ are referenced in the manifest.
static func check_manifest_coverage(assets_dir: String = "res://assets", manifest_path: String = "docs/assets/ASSET_MANIFEST.md") -> Dictionary:
	var errors: Array[String] = []
	var missing: Array[String] = []

	var manifest_text: String = ""
	if FileAccess.file_exists(manifest_path):
		var f := FileAccess.open(manifest_path, FileAccess.READ)
		if f != null:
			manifest_text = f.get_as_text()
	else:
		errors.append("Asset manifest file not found at: %s" % manifest_path)
		return {"valid": false, "errors": errors, "missing": missing}

	var files := _collect_files_recursive(assets_dir)
	for file_path: String in files:
		if file_path.ends_with(".import") or file_path.ends_with(".uid"):
			continue
		# Search for relative path or file name in manifest
		var rel_path: String = file_path.replace("res://", "")
		var file_name: String = file_path.get_file()
		var base_dir: String = file_path.get_base_dir().replace("res://", "")

		var found: bool = manifest_text.contains(rel_path) or manifest_text.contains(file_name)
		var check_dir: String = base_dir
		while not found and not check_dir.is_empty() and check_dir != "assets":
			if manifest_text.contains(check_dir):
				found = true
				break
			check_dir = check_dir.get_base_dir()

		if not found:
			missing.append(rel_path)

	if not missing.is_empty():
		for m: String in missing:
			errors.append("Asset '%s' is present on disk but missing from ASSET_MANIFEST.md" % m)

	return {
		"valid": errors.is_empty(),
		"checked_count": files.size(),
		"missing_count": missing.size(),
		"missing": missing,
		"errors": errors
	}

# ── Helpers ───────────────────────────────────────────────────────────────────

static func _collect_files_recursive(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if item == "." or item == "..":
			item = dir.get_next()
			continue
		var full_path := dir_path.path_join(item)
		if dir.current_is_dir():
			result.append_array(_collect_files_recursive(full_path))
		else:
			result.append(full_path)
		item = dir.get_next()
	dir.list_dir_end()
	return result
