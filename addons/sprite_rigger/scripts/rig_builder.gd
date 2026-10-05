@tool
class_name RigBuilder
extends RefCounted

const RigDefinitions = preload("res://addons/sprite_rigger/scripts/rig_definitions.gd")

## Builds and saves the Skeleton2D + Bone2D + Sprite2D rig scene and cropped part textures.

static func build_and_save_rig(
	source_image: Image,
	joints: Dictionary,          # bone_name (String) -> Vector2 (image coordinates)
	crop_rects: Dictionary,      # part_name (String) -> Rect2i (image coordinates)
	z_indices: Dictionary,       # part_name (String) -> int
	output_dir: String,          # e.g. "res://assets/sprites/player/south/"
	rig_scene_name: String = "rig.tscn",
	root_node_name: String = "PlayerRig",
	root_origin_mode: String = "image" # "image", "hip", "feet"
) -> Dictionary:
	if source_image == null:
		return {"success": false, "error": "Source sprite image is null."}

	if not joints.has("hip"):
		return {"success": false, "error": "Root joint 'hip' is required to build the rig."}

	# Normalize output directories
	output_dir = output_dir.replace("\\", "/")
	if not output_dir.ends_with("/"):
		output_dir += "/"

	var parts_dir = output_dir.path_join("parts")
	var global_parts_dir = ProjectSettings.globalize_path(parts_dir)
	var global_out_dir = ProjectSettings.globalize_path(output_dir)

	var dir_err = DirAccess.make_dir_recursive_absolute(global_parts_dir)
	if dir_err != OK and not DirAccess.dir_exists_absolute(global_parts_dir):
		return {"success": false, "error": "Failed to create output directory: %s (Error: %d)" % [global_parts_dir, dir_err]}

	var img_w = source_image.get_width()
	var img_h = source_image.get_height()
	var img_bounds = Rect2i(0, 0, img_w, img_h)

	# 1. Crop and save part textures
	var textures: Dictionary = {}
	var saved_parts: Array[String] = []

	for part_def in RigDefinitions.PARTS:
		var part_name: String = part_def["name"]
		if not crop_rects.has(part_name):
			continue

		var rect: Rect2i = crop_rects[part_name]
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue

		var clamped_rect = rect.intersection(img_bounds)
		if clamped_rect.size.x <= 0 or clamped_rect.size.y <= 0:
			continue

		var crop_img: Image = source_image.get_region(clamped_rect)
		var part_res_path = parts_dir.path_join("%s.png" % part_name)
		var part_global_path = ProjectSettings.globalize_path(part_res_path)

		var save_png_err = crop_img.save_png(part_global_path)
		if save_png_err != OK:
			return {"success": false, "error": "Failed to save cropped image: %s (Error: %d)" % [part_global_path, save_png_err]}

		# Create ImageTexture linked to the saved file path
		var tex = ImageTexture.create_from_image(crop_img)
		tex.take_over_path(part_res_path)
		textures[part_name] = tex
		saved_parts.append(part_res_path)

	# 2. Determine root origin offset
	var origin_offset: Vector2 = Vector2.ZERO
	if root_origin_mode == "hip":
		var hip_pos: Vector2 = joints.get("hip", Vector2.ZERO)
		origin_offset = -hip_pos
	elif root_origin_mode == "feet":
		# Calculate ground point below feet
		var hip_x: float = joints.get("hip", Vector2.ZERO).x
		var max_foot_y: float = 0.0
		for bone_name in ["lower_leg_L", "lower_leg_R", "upper_leg_L", "upper_leg_R", "hip"]:
			if joints.has(bone_name):
				max_foot_y = max(max_foot_y, joints[bone_name].y)
		origin_offset = Vector2(-hip_x, -max_foot_y)

	# 3. Construct Node2D and Skeleton2D root
	var root_node = Node2D.new()
	root_node.name = root_node_name

	var skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	root_node.add_child(skeleton)
	skeleton.owner = root_node

	# 4. Construct Bone2D hierarchy
	var created_bones: Dictionary = {}

	for joint_def in RigDefinitions.JOINTS:
		var bone_name: String = joint_def["name"]
		var parent_name: String = joint_def["parent"]

		if not joints.has(bone_name):
			continue

		var bone_img_pos: Vector2 = joints[bone_name]
		var bone_world_pos: Vector2 = bone_img_pos + origin_offset

		var bone = Bone2D.new()
		bone.name = bone_name

		if parent_name == "" or not created_bones.has(parent_name):
			# Root bone attached to Skeleton2D
			skeleton.add_child(bone)
			bone.position = bone_world_pos
		else:
			# Child bone attached to parent Bone2D
			var parent_bone: Bone2D = created_bones[parent_name]
			parent_bone.add_child(bone)
			var parent_img_pos: Vector2 = joints[parent_name]
			# Local position is delta from parent joint
			bone.position = bone_img_pos - parent_img_pos

		bone.owner = root_node
		bone.set_autocalculate_length_and_angle(false)
		created_bones[bone_name] = bone

	# 5. Calculate bone lengths and angles
	for joint_def in RigDefinitions.JOINTS:
		var bone_name: String = joint_def["name"]
		if not created_bones.has(bone_name):
			continue

		var bone: Bone2D = created_bones[bone_name]
		var found_child = false

		# Find first placed child bone in hierarchy
		for other_def in RigDefinitions.JOINTS:
			if other_def["parent"] == bone_name and created_bones.has(other_def["name"]):
				var child_bone: Bone2D = created_bones[other_def["name"]]
				var dir_vec: Vector2 = child_bone.position
				if dir_vec.length() > 0.1:
					bone.set_length(dir_vec.length())
					bone.set_bone_angle(dir_vec.angle())
					found_child = true
					break

		# If leaf bone, provide sensible default angle and length
		if not found_child:
			var default_length = 24.0
			var default_angle = 0.0
			if bone_name == "head":
				default_angle = -PI / 2.0 # Point up
				default_length = 32.0
			elif bone_name in ["lower_leg_L", "lower_leg_R"]:
				default_angle = PI / 2.0  # Point down
				default_length = 24.0
			elif bone_name in ["hand_L", "hand_R"]:
				# Match direction of forearm
				var p_name = joint_def["parent"]
				if joints.has(p_name):
					var arm_dir = joints[bone_name] - joints[p_name]
					default_angle = arm_dir.angle()
					default_length = 16.0
				else:
					default_angle = PI / 2.0
			bone.set_length(default_length)
			bone.set_bone_angle(default_angle)

		bone.rest = bone.transform

	# 6. Attach Sprite2D to each bone
	for part_def in RigDefinitions.PARTS:
		var part_name: String = part_def["name"]
		var bone_name: String = part_def["bone"]

		if not textures.has(part_name) or not created_bones.has(bone_name):
			continue

		var bone: Bone2D = created_bones[bone_name]
		var rect: Rect2i = crop_rects[part_name]
		var clamped_rect = rect.intersection(img_bounds)
		var tex: Texture2D = textures[part_name]

		var sprite = Sprite2D.new()
		sprite.name = "%sSprite" % _to_pascal_case(part_name)
		sprite.texture = tex
		sprite.centered = false

		# Offset: rect top-left relative to joint location on original image
		var joint_img_pos: Vector2 = joints[bone_name]
		sprite.offset = Vector2(clamped_rect.position.x - joint_img_pos.x, clamped_rect.position.y - joint_img_pos.y)

		# Z-Index
		if z_indices.has(part_name):
			sprite.z_index = z_indices[part_name]
		else:
			sprite.z_index = part_def.get("default_z", 0)

		bone.add_child(sprite)
		sprite.owner = root_node

	# 7. Add AnimationPlayer with RESET and idle animation
	_add_idle_animation(root_node, created_bones)

	# 8. Set owners recursively to ensure complete scene serialization
	_set_owner_recursive(root_node, root_node)

	# 9. Pack and save scene
	var packed_scene = PackedScene.new()
	var pack_res = packed_scene.pack(root_node)
	if pack_res != OK:
		root_node.queue_free()
		return {"success": false, "error": "PackedScene.pack() failed with error code: %d" % pack_res}

	var scene_file_res_path = output_dir.path_join(rig_scene_name)
	var scene_global_path = ProjectSettings.globalize_path(scene_file_res_path)
	var save_res = ResourceSaver.save(packed_scene, scene_file_res_path)
	root_node.queue_free()

	if save_res != OK:
		return {"success": false, "error": "ResourceSaver.save() failed to write '%s' (Error: %d)" % [scene_file_res_path, save_res]}

	return {
		"success": true,
		"scene_path": scene_file_res_path,
		"parts_dir": parts_dir,
		"saved_parts": saved_parts,
		"bone_count": created_bones.size()
	}

static func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_set_owner_recursive(child, scene_root)

static func _to_pascal_case(s: String) -> String:
	var parts = s.split("_")
	var result = ""
	for p in parts:
		if p.length() > 0:
			result += p.capitalize()
	return result

static func _add_idle_animation(root_node: Node2D, created_bones: Dictionary) -> void:
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root_node.add_child(anim_player)
	anim_player.owner = root_node

	var anim_lib = AnimationLibrary.new()

	var reset_anim = Animation.new()
	reset_anim.length = 0.001

	var idle_anim = Animation.new()
	idle_anim.length = 1.8
	idle_anim.loop_mode = Animation.LOOP_LINEAR

	var hip_bone: Bone2D = created_bones.get("hip")
	if not hip_bone:
		return

	var base_hip_pos: Vector2 = hip_bone.position

	var tracks_data = [
		{"path": "Skeleton2D/hip:position", "bone": "hip", "rest": base_hip_pos, "dip": base_hip_pos + Vector2(0, 3.0)},
		{"path": "Skeleton2D/hip/torso:rotation", "bone": "torso", "rest": 0.0, "dip": deg_to_rad(-2.0)},
		{"path": "Skeleton2D/hip/torso/head:rotation", "bone": "head", "rest": 0.0, "dip": deg_to_rad(1.8)},
		{"path": "Skeleton2D/hip/torso/upper_arm_L:rotation", "bone": "upper_arm_L", "rest": 0.0, "dip": deg_to_rad(-3.5)},
		{"path": "Skeleton2D/hip/torso/upper_arm_L/forearm_L:rotation", "bone": "forearm_L", "rest": 0.0, "dip": deg_to_rad(2.5)},
		{"path": "Skeleton2D/hip/torso/upper_arm_L/forearm_L/hand_L:rotation", "bone": "hand_L", "rest": 0.0, "dip": deg_to_rad(1.5)},
		{"path": "Skeleton2D/hip/torso/upper_arm_R:rotation", "bone": "upper_arm_R", "rest": 0.0, "dip": deg_to_rad(3.5)},
		{"path": "Skeleton2D/hip/torso/upper_arm_R/forearm_R:rotation", "bone": "forearm_R", "rest": 0.0, "dip": deg_to_rad(-2.5)},
		{"path": "Skeleton2D/hip/torso/upper_arm_R/forearm_R/hand_R:rotation", "bone": "hand_R", "rest": 0.0, "dip": deg_to_rad(1.0)},
		{"path": "Skeleton2D/hip/upper_leg_L:rotation", "bone": "upper_leg_L", "rest": 0.0, "dip": deg_to_rad(1.0)},
		{"path": "Skeleton2D/hip/upper_leg_L/lower_leg_L:rotation", "bone": "lower_leg_L", "rest": 0.0, "dip": deg_to_rad(-1.0)},
		{"path": "Skeleton2D/hip/upper_leg_R:rotation", "bone": "upper_leg_R", "rest": 0.0, "dip": deg_to_rad(-1.0)},
		{"path": "Skeleton2D/hip/upper_leg_R/lower_leg_R:rotation", "bone": "lower_leg_R", "rest": 0.0, "dip": deg_to_rad(1.0)},
	]

	for t in tracks_data:
		var bone_name: String = t["bone"]
		if not created_bones.has(bone_name):
			continue

		var np = NodePath(t["path"])

		var r_idx = reset_anim.add_track(Animation.TYPE_VALUE)
		reset_anim.track_set_path(r_idx, np)
		reset_anim.track_insert_key(r_idx, 0.0, t["rest"])

		var i_idx = idle_anim.add_track(Animation.TYPE_VALUE)
		idle_anim.track_set_path(i_idx, np)
		idle_anim.track_set_interpolation_type(i_idx, Animation.INTERPOLATION_CUBIC)
		idle_anim.track_insert_key(i_idx, 0.0, t["rest"])
		idle_anim.track_insert_key(i_idx, 0.9, t["dip"])
		idle_anim.track_insert_key(i_idx, 1.8, t["rest"])

	anim_lib.add_animation("RESET", reset_anim)
	anim_lib.add_animation("idle", idle_anim)
	anim_player.add_animation_library("", anim_lib)
	anim_player.autoplay = "idle"
