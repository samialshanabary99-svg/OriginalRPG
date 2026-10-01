extends SceneTree

func _init() -> void:
	print("[Generator] Creating Player SpriteFrames resource...")

	var sf := SpriteFrames.new()
	# Clear default animation
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")

	var directions: Array[String] = [
		"south", "south-east", "east", "north-east",
		"north", "north-west", "west", "south-west"
	]

	var base_path: String = "res://assets/sprites/player/idle/animations/Breathing_Idle"

	for dir: String in directions:
		var anim_name: StringName = StringName("idle_" + dir)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 5.0)
		sf.set_animation_loop(anim_name, true)

		for i in range(4):
			var frame_file: String = "%s/%s/frame_%03d.png" % [base_path, dir, i]
			var tex: Texture2D = load(frame_file) as Texture2D
			if tex != null:
				sf.add_frame(anim_name, tex)
			else:
				printerr("Failed to load frame: ", frame_file)

		print("  Added animation: ", anim_name, " with ", sf.get_frame_count(anim_name), " frames")

	# Also add default alias for idle
	var default_name := &"idle"
	sf.add_animation(default_name)
	sf.set_animation_speed(default_name, 5.0)
	sf.set_animation_loop(default_name, true)
	for i in range(4):
		var tex: Texture2D = load("%s/south/frame_%03d.png" % [base_path, i]) as Texture2D
		if tex != null:
			sf.add_frame(default_name, tex)

	var save_path := "res://assets/sprites/player/player_sprite_frames.tres"
	var err := ResourceSaver.save(sf, save_path)
	if err == OK:
		print("[Generator] Successfully saved SpriteFrames to: ", save_path)
		quit(0)
	else:
		printerr("[Generator] Error saving SpriteFrames: ", err)
		quit(1)
