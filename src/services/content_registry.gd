class_name ContentRegistry
extends RefCounted

## Centralized, data-driven content registry for OriginalRPG.
## Loads, validates, and provides fast runtime access to:
##   - CharacterDefinition (res://data/characters/)
##   - EnemyDefinition     (res://data/enemies/)
##   - ItemDefinition      (res://data/items/)
##   - SkillDefinition     (res://data/skills/)
##
## All definitions are immutable at runtime and shared.

static var _characters: Dictionary = {}
static var _enemies: Dictionary = {}
static var _items: Dictionary = {}
static var _skills: Dictionary = {}
static var _validation_errors: Array[String] = []
static var _is_initialized: bool = false

# ── Initialization & Directory Loading ────────────────────────────────────────

## Scans res://data/ and registers all valid definitions.
## If any definition is malformed, errors are collected in _validation_errors.
static func load_all(base_dir: String = "res://data") -> Dictionary:
	clear()
	var loaded_count: int = 0

	loaded_count += _load_category(base_dir.path_join("characters"), "character")
	loaded_count += _load_category(base_dir.path_join("enemies"), "enemy")
	loaded_count += _load_category(base_dir.path_join("items"), "item")
	loaded_count += _load_category(base_dir.path_join("skills"), "skill")

	_is_initialized = true
	return {
		"loaded": loaded_count,
		"errors": _validation_errors.duplicate()
	}

static func ensure_initialized() -> void:
	if not _is_initialized:
		load_all()

static func clear() -> void:
	_characters.clear()
	_enemies.clear()
	_items.clear()
	_skills.clear()
	_validation_errors.clear()
	_is_initialized = false

# ── Category Loader Helper ───────────────────────────────────────────────────

static func _load_category(dir_path: String, type_name: String) -> int:
	var count: int = 0
	var files: Array[String] = _scan_json_files(dir_path)
	for file_path: String in files:
		var result: Dictionary = _read_json_file(file_path)
		if result.has("error"):
			_validation_errors.append("File error [%s]: %s" % [file_path, result["error"]])
			continue

		var data: Dictionary = result["data"]
		var load_res: Dictionary = load_definition_from_dict(data, type_name)
		if load_res.has("error"):
			_validation_errors.append("Validation error [%s]: %s" % [file_path, load_res["error"]])
		elif load_res.has("definition"):
			count += 1
	return count

static func _scan_json_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			result.append(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

static func _read_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {"error": "File does not exist"}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"error": "Could not open file (Error %d)" % FileAccess.get_open_error()}
	var text := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return {"error": "JSON parse error: %s (line %d)" % [json.get_error_message(), json.get_error_line()]}
	if not json.data is Dictionary:
		return {"error": "JSON root must be an object (Dictionary)"}
	return {"data": json.data as Dictionary}

# ── Dynamic Definition Factory & Validator ───────────────────────────────────

static func load_definition_from_dict(data: Dictionary, type_name: String) -> Dictionary:
	match type_name.to_lower():
		"character":
			var def := CharacterDefinition.new()
			def.deserialize(data)
			var errs := def.validate()
			if not errs.is_empty():
				return {"error": ", ".join(errs)}
			register_character(def)
			return {"definition": def}
		"enemy":
			var def := EnemyDefinition.new()
			def.deserialize(data)
			var errs := def.validate()
			if not errs.is_empty():
				return {"error": ", ".join(errs)}
			register_enemy(def)
			return {"definition": def}
		"item":
			var def := ItemDefinition.new()
			def.deserialize(data)
			var errs := def.validate()
			if not errs.is_empty():
				return {"error": ", ".join(errs)}
			register_item(def)
			return {"definition": def}
		"skill":
			var def := SkillDefinition.new()
			def.deserialize(data)
			var errs := def.validate()
			if not errs.is_empty():
				return {"error": ", ".join(errs)}
			register_skill(def)
			return {"definition": def}
		_:
			return {"error": "Unknown definition type: %s" % type_name}

## Validates a raw JSON string against the schema for type_name without registering it.
## Returns an array of error messages (empty if valid).
static func validate_json_string(json_string: String, type_name: String) -> Array[String]:
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		return ["JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()]]
	if not json.data is Dictionary:
		return ["Root element must be a JSON object (Dictionary)"]

	var data: Dictionary = json.data as Dictionary
	match type_name.to_lower():
		"character":
			var def := CharacterDefinition.new()
			def.deserialize(data)
			return def.validate()
		"enemy":
			var def := EnemyDefinition.new()
			def.deserialize(data)
			return def.validate()
		"item":
			var def := ItemDefinition.new()
			def.deserialize(data)
			return def.validate()
		"skill":
			var def := SkillDefinition.new()
			def.deserialize(data)
			return def.validate()
		_:
			return ["Unknown definition type: %s" % type_name]

# ── Registration ─────────────────────────────────────────────────────────────

static func register_character(def: CharacterDefinition) -> bool:
	if def == null or def.character_id.is_empty():
		return false
	_characters[def.character_id] = def
	return true

static func register_enemy(def: EnemyDefinition) -> bool:
	if def == null or def.enemy_id.is_empty():
		return false
	_enemies[def.enemy_id] = def
	return true

static func register_item(def: ItemDefinition) -> bool:
	if def == null or def.item_id.is_empty():
		return false
	_items[def.item_id] = def
	return true

static func register_skill(def: SkillDefinition) -> bool:
	if def == null or def.skill_id.is_empty():
		return false
	_skills[def.skill_id] = def
	return true

# ── Lookups ───────────────────────────────────────────────────────────────────

static func get_character(id: String) -> CharacterDefinition:
	ensure_initialized()
	return _characters.get(id) as CharacterDefinition

static func get_enemy(id: String) -> EnemyDefinition:
	ensure_initialized()
	return _enemies.get(id) as EnemyDefinition

static func get_item(id: String) -> ItemDefinition:
	ensure_initialized()
	return _items.get(id) as ItemDefinition

static func get_skill(id: String) -> SkillDefinition:
	ensure_initialized()
	return _skills.get(id) as SkillDefinition

static func has_character(id: String) -> bool:
	ensure_initialized()
	return _characters.has(id)

static func has_enemy(id: String) -> bool:
	ensure_initialized()
	return _enemies.has(id)

static func has_item(id: String) -> bool:
	ensure_initialized()
	return _items.has(id)

static func has_skill(id: String) -> bool:
	ensure_initialized()
	return _skills.has(id)

static func get_all_enemies() -> Array[EnemyDefinition]:
	ensure_initialized()
	var arr: Array[EnemyDefinition] = []
	for def: EnemyDefinition in _enemies.values():
		arr.append(def)
	return arr

static func get_all_items() -> Array[ItemDefinition]:
	ensure_initialized()
	var arr: Array[ItemDefinition] = []
	for def: ItemDefinition in _items.values():
		arr.append(def)
	return arr

static func get_all_skills() -> Array[SkillDefinition]:
	ensure_initialized()
	var arr: Array[SkillDefinition] = []
	for def: SkillDefinition in _skills.values():
		arr.append(def)
	return arr

static func get_all_characters() -> Array[CharacterDefinition]:
	ensure_initialized()
	var arr: Array[CharacterDefinition] = []
	for def: CharacterDefinition in _characters.values():
		arr.append(def)
	return arr

static func get_validation_errors() -> Array[String]:
	return _validation_errors.duplicate()

# ── Ragnarok-Style ItemInfo & Disk Persistence ────────────────────────────────

## Saves an item definition to res://data/items/<item_id>.json, updates in-memory registry,
## and syncs the centralized res://data/iteminfo.json.
static func save_item_to_disk(item: ItemDefinition, base_dir: String = "res://data") -> Error:
	if item == null or item.item_id.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	var errs: Array[String] = item.validate()
	if not errs.is_empty():
		return ERR_INVALID_DATA

	var items_dir: String = base_dir.path_join("items")
	if not DirAccess.dir_exists_absolute(items_dir):
		DirAccess.make_dir_recursive_absolute(items_dir)
	var file_path: String = items_dir.path_join(item.item_id + ".json")
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(item.serialize(), "  "))
	file.close()

	register_item(item)
	export_iteminfo(base_dir.path_join("iteminfo.json"))
	return OK

## Deletes an item file from res://data/items/<item_id>.json, removes from memory, and updates iteminfo.json.
static func delete_item_from_disk(item_id: String, base_dir: String = "res://data") -> Error:
	if item_id.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	var file_path: String = base_dir.path_join("items").path_join(item_id + ".json")
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
	_items.erase(item_id)
	export_iteminfo(base_dir.path_join("iteminfo.json"))
	return OK

## Exports all registered items into a single Ragnarok-style iteminfo.json database.
static func export_iteminfo(target_path: String = "res://data/iteminfo.json") -> Error:
	ensure_initialized()
	var items_dict: Dictionary = {}
	var sorted_keys: Array = _items.keys()
	sorted_keys.sort()
	for id: String in sorted_keys:
		var item: ItemDefinition = _items[id]
		items_dict[id] = item.serialize()

	var data: Dictionary = {
		"version": "1.0.0",
		"description": "OriginalRPG Ragnarok-Style Item Database (ItemInfo). Editable directly or via Item Info Editor.",
		"items": items_dict
	}
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return OK

## Imports and registers all items from a Ragnarok-style iteminfo.json database.
static func import_iteminfo(source_path: String = "res://data/iteminfo.json") -> int:
	if not FileAccess.file_exists(source_path):
		return 0
	var res := _read_json_file(source_path)
	if res.has("error") or not res.has("data"):
		return 0
	var root: Dictionary = res["data"]
	var count: int = 0
	if root.has("items") and root["items"] is Dictionary:
		var items_map: Dictionary = root["items"]
		for id: String in items_map:
			var item_data: Dictionary = items_map[id]
			var def := ItemDefinition.new()
			def.deserialize(item_data)
			if def.validate().is_empty():
				register_item(def)
				count += 1
	return count
