@tool
extends SceneTree

const DIRECTIONS = ["east", "north", "north-east", "north-west", "south", "south-east", "south-west", "west"]

func _init() -> void:
	print("Starting SpriteFrames generation...")
	var success := true
	success = success and _build_player_frames()
	success = success and _build_wolf_frames()
	success = success and _build_stalks_frames()

	if success:
		print("ALL SpriteFrames generated successfully!")
	else:
		printerr("Some SpriteFrames failed to generate!")
	quit(0 if success else 1)

func _add_animation_to_frames(sf: SpriteFrames, anim_name: String, base_path: String, frame_count: int, fps: float, loop: bool) -> bool:
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	sf.clear(anim_name)

	for i in range(frame_count):
		var fname: String = "frame_%03d.png" % i
		var fpath: String = base_path.path_join(fname)
		var tex: Texture2D = load(fpath) as Texture2D
		if tex == null:
			printerr("Failed to load frame: ", fpath)
			return false
		sf.add_frame(anim_name, tex)
	return true

func _build_player_frames() -> bool:
	print("Building player_sprite_frames.tres...")
	var sf := SpriteFrames.new()
	var base := "res://Young_male_fantasy_novice"

	var anim_defs := {
		"idle": {
			"subpath": "Idle/animations/Breathing_Idle",
			"frames": 4,
			"fps": 5.0,
			"loop": true
		},
		"walk": {
			"subpath": "Walking/animations/Walking",
			"frames": 8,
			"fps": 8.0,
			"loop": true
		},
		"attack": {
			"subpath": "fighting_action..._a/animations/The_character_pulls_the_sword_back_behind_the_righ",
			"frames": 9,
			"fps": 12.0,
			"loop": false
		},
		"damage": {
			"subpath": "Taking_Damage/animations/The_character_recoils_sharply_as_the_torso_jerks_b",
			"frames": 9,
			"fps": 12.0,
			"loop": false
		},
		"die": {
			"subpath": "Dying/animations/Falling_Back_Death",
			"frames": 7,
			"fps": 8.0,
			"loop": false
		}
	}

	for anim_prefix in anim_defs.keys():
		var info: Dictionary = anim_defs[anim_prefix]
		for dir in DIRECTIONS:
			var anim_name: String = "%s_%s" % [anim_prefix, dir]
			var dir_path: String = base.path_join(info["subpath"]).path_join(dir)
			if not _add_animation_to_frames(sf, anim_name, dir_path, info["frames"], info["fps"], info["loop"]):
				return false

		# Add fallback without direction (south)
		var fallback_name: String = anim_prefix
		var south_path: String = base.path_join(info["subpath"]).path_join("south")
		if not _add_animation_to_frames(sf, fallback_name, south_path, info["frames"], info["fps"], info["loop"]):
			return false

	# Add dead state (single last frame of south death)
	if not sf.has_animation("dead"):
		sf.add_animation("dead")
	sf.set_animation_speed("dead", 1.0)
	sf.set_animation_loop("dead", false)
	sf.clear("dead")
	var last_death_frame: String = base.path_join("Dying/animations/Falling_Back_Death/south/frame_006.png")
	var dead_tex: Texture2D = load(last_death_frame) as Texture2D
	if dead_tex != null:
		sf.add_frame("dead", dead_tex)

	var target_path := "res://assets/sprites/player/player_sprite_frames.tres"
	var err := ResourceSaver.save(sf, target_path)
	if err != OK:
		printerr("Failed to save player_sprite_frames.tres: ", err)
		return false
	print("Saved player_sprite_frames.tres with ", sf.get_animation_names().size(), " animations.")
	return true

func _build_wolf_frames() -> bool:
	print("Building wolf_sprite_frames.tres...")
	var sf := SpriteFrames.new()
	var base := "res://A_small_fantasy_wolf_monster"

	var anim_defs := {
		"idle": {
			"subpath": "Idle/animations/Idle",
			"frames": 4,
			"fps": 5.0,
			"loop": true
		},
		"walk": {
			"subpath": "Walking/animations/Walking",
			"frames": 8,
			"fps": 8.0,
			"loop": true
		},
		"attack": {
			"subpath": "Attacking/animations/The_wolf_crouches_low_tightening_its_muscles_befor",
			"frames": 9,
			"fps": 10.0,
			"loop": false
		},
		"damage": {
			"subpath": "Take_Damage/animations/The_character_recoils_sharply_as_the_torso_snaps_b",
			"frames": 9,
			"fps": 12.0,
			"loop": false
		},
		"die": {
			"subpath": "Dying/animations/The_creature_s_knees_buckle_and_collapse_under_its",
			"frames": 7,
			"fps": 8.0,
			"loop": false
		}
	}

	for anim_prefix in anim_defs.keys():
		var info: Dictionary = anim_defs[anim_prefix]
		for dir in DIRECTIONS:
			var anim_name: String = "%s_%s" % [anim_prefix, dir]
			var dir_path: String = base.path_join(info["subpath"]).path_join(dir)
			if not _add_animation_to_frames(sf, anim_name, dir_path, info["frames"], info["fps"], info["loop"]):
				return false

		# Add fallback without direction (south)
		var fallback_name: String = anim_prefix
		var south_path: String = base.path_join(info["subpath"]).path_join("south")
		if not _add_animation_to_frames(sf, fallback_name, south_path, info["frames"], info["fps"], info["loop"]):
			return false

	# Add dead state
	if not sf.has_animation("dead"):
		sf.add_animation("dead")
	sf.set_animation_speed("dead", 1.0)
	sf.set_animation_loop("dead", false)
	sf.clear("dead")
	var last_death_frame: String = base.path_join("Dying/animations/The_creature_s_knees_buckle_and_collapse_under_its/south/frame_006.png")
	var dead_tex: Texture2D = load(last_death_frame) as Texture2D
	if dead_tex != null:
		sf.add_frame("dead", dead_tex)

	var target_path := "res://A_small_fantasy_wolf_monster/wolf_sprite_frames.tres"
	var err := ResourceSaver.save(sf, target_path)
	if err != OK:
		printerr("Failed to save wolf_sprite_frames.tres: ", err)
		return false
	print("Saved wolf_sprite_frames.tres with ", sf.get_animation_names().size(), " animations.")
	return true

func _build_stalks_frames() -> bool:
	print("Building green_stalks_sprite_frames.tres...")
	var sf := SpriteFrames.new()
	var base := "res://green stalks/2D_sprite_asset_isolated_clus/animations/The_tall_green_blades_sway_rhythmically_in_a_fluid"

	for dir in DIRECTIONS:
		var anim_name: String = "sway_%s" % dir
		var dir_path: String = base.path_join(dir)
		if not _add_animation_to_frames(sf, anim_name, dir_path, 9, 6.0, true):
			return false

	# Add "default" and "sway" pointing to south
	var south_path: String = base.path_join("south")
	if not _add_animation_to_frames(sf, "default", south_path, 9, 6.0, true):
		return false
	if not _add_animation_to_frames(sf, "sway", south_path, 9, 6.0, true):
		return false

	var target_path := "res://green stalks/green_stalks_sprite_frames.tres"
	var err := ResourceSaver.save(sf, target_path)
	if err != OK:
		printerr("Failed to save green_stalks_sprite_frames.tres: ", err)
		return false
	print("Saved green_stalks_sprite_frames.tres with ", sf.get_animation_names().size(), " animations.")
	return true
