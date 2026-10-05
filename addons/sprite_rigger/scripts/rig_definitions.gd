@tool
class_name RigDefinitions
extends RefCounted

## Central definitions for joints, hierarchy, body parts, and styling.

# Standard 8 directions
const DIRECTIONS: Array[String] = [
	"south",
	"southwest",
	"west",
	"northwest",
	"north",
	"northeast",
	"east",
	"southeast"
]

# Fixed joint chain ordered hierarchically:
# hip (root)
# ├─ torso
# │  ├─ head
# │  ├─ upper_arm_L → forearm_L → hand_L
# │  └─ upper_arm_R → forearm_R → hand_R
# ├─ upper_leg_L → lower_leg_L
# └─ upper_leg_R → lower_leg_R
const JOINTS: Array[Dictionary] = [
	{
		"name": "hip",
		"parent": "",
		"label": "Hip (Root)",
		"hint": "Center of pelvis / waist",
		"color": Color(0.2, 1.0, 0.4) # Bright green
	},
	{
		"name": "torso",
		"parent": "hip",
		"label": "Torso",
		"hint": "Chest / base of neck",
		"color": Color(0.4, 0.9, 0.3)
	},
	{
		"name": "head",
		"parent": "torso",
		"label": "Head",
		"hint": "Center of head / face",
		"color": Color(1.0, 0.85, 0.2) # Gold
	},
	{
		"name": "upper_arm_L",
		"parent": "torso",
		"label": "Upper Arm (Left)",
		"hint": "Left shoulder joint",
		"color": Color(0.2, 0.8, 1.0) # Cyan
	},
	{
		"name": "forearm_L",
		"parent": "upper_arm_L",
		"label": "Forearm (Left)",
		"hint": "Left elbow joint",
		"color": Color(0.3, 0.6, 1.0)
	},
	{
		"name": "hand_L",
		"parent": "forearm_L",
		"label": "Hand (Left)",
		"hint": "Left wrist / hand",
		"color": Color(0.5, 0.4, 1.0)
	},
	{
		"name": "upper_arm_R",
		"parent": "torso",
		"label": "Upper Arm (Right)",
		"hint": "Right shoulder joint",
		"color": Color(1.0, 0.6, 0.2) # Orange
	},
	{
		"name": "forearm_R",
		"parent": "upper_arm_R",
		"label": "Forearm (Right)",
		"hint": "Right elbow joint",
		"color": Color(1.0, 0.4, 0.2)
	},
	{
		"name": "hand_R",
		"parent": "forearm_R",
		"label": "Hand (Right)",
		"hint": "Right wrist / hand (weapon arm)",
		"color": Color(1.0, 0.25, 0.4)
	},
	{
		"name": "upper_leg_L",
		"parent": "hip",
		"label": "Upper Leg (Left)",
		"hint": "Left hip / top of thigh",
		"color": Color(0.1, 0.9, 0.7)
	},
	{
		"name": "lower_leg_L",
		"parent": "upper_leg_L",
		"label": "Lower Leg (Left)",
		"hint": "Left knee",
		"color": Color(0.0, 0.7, 0.8)
	},
	{
		"name": "upper_leg_R",
		"parent": "hip",
		"label": "Upper Leg (Right)",
		"hint": "Right hip / top of thigh",
		"color": Color(0.9, 0.8, 0.2)
	},
	{
		"name": "lower_leg_R",
		"parent": "upper_leg_R",
		"label": "Lower Leg (Right)",
		"hint": "Right knee",
		"color": Color(0.8, 0.6, 0.1)
	}
]

# Body parts for cropping and sprite attachment
const PARTS: Array[Dictionary] = [
	{
		"name": "torso",
		"bone": "torso",
		"label": "Torso / Chest",
		"default_z": 1,
		"color": Color(0.4, 0.9, 0.3, 0.8)
	},
	{
		"name": "head",
		"bone": "head",
		"label": "Head / Hair",
		"default_z": 4,
		"color": Color(1.0, 0.85, 0.2, 0.8)
	},
	{
		"name": "upper_arm_L",
		"bone": "upper_arm_L",
		"label": "Upper Arm (Left)",
		"default_z": 2,
		"color": Color(0.2, 0.8, 1.0, 0.8)
	},
	{
		"name": "forearm_L",
		"bone": "forearm_L",
		"label": "Forearm (Left)",
		"default_z": 2,
		"color": Color(0.3, 0.6, 1.0, 0.8)
	},
	{
		"name": "hand_L",
		"bone": "hand_L",
		"label": "Hand (Left)",
		"default_z": 3,
		"color": Color(0.5, 0.4, 1.0, 0.8)
	},
	{
		"name": "upper_arm_R",
		"bone": "upper_arm_R",
		"label": "Upper Arm (Right)",
		"default_z": 2,
		"color": Color(1.0, 0.6, 0.2, 0.8)
	},
	{
		"name": "forearm_R",
		"bone": "forearm_R",
		"label": "Forearm (Right)",
		"default_z": 2,
		"color": Color(1.0, 0.4, 0.2, 0.8)
	},
	{
		"name": "hand_R",
		"bone": "hand_R",
		"label": "Hand (Right)",
		"default_z": 3,
		"color": Color(1.0, 0.25, 0.4, 0.8)
	},
	{
		"name": "upper_leg_L",
		"bone": "upper_leg_L",
		"label": "Upper Leg (Left)",
		"default_z": -1,
		"color": Color(0.1, 0.9, 0.7, 0.8)
	},
	{
		"name": "lower_leg_L",
		"bone": "lower_leg_L",
		"label": "Lower Leg & Foot (Left)",
		"default_z": -1,
		"color": Color(0.0, 0.7, 0.8, 0.8)
	},
	{
		"name": "upper_leg_R",
		"bone": "upper_leg_R",
		"label": "Upper Leg (Right)",
		"default_z": -1,
		"color": Color(0.9, 0.8, 0.2, 0.8)
	},
	{
		"name": "lower_leg_R",
		"bone": "lower_leg_R",
		"label": "Lower Leg & Foot (Right)",
		"default_z": -1,
		"color": Color(0.8, 0.6, 0.1, 0.8)
	},
	{
		"name": "hip",
		"bone": "hip",
		"label": "Hip / Pelvis (Optional)",
		"default_z": 0,
		"color": Color(0.2, 1.0, 0.4, 0.8)
	}
]

static func get_joint_def(joint_name: String) -> Dictionary:
	for j in JOINTS:
		if j["name"] == joint_name:
			return j
	return {}

static func get_part_def(part_name: String) -> Dictionary:
	for p in PARTS:
		if p["name"] == part_name:
			return p
	return {}

static func get_parent_bone(bone_name: String) -> String:
	for j in JOINTS:
		if j["name"] == bone_name:
			return j["parent"]
	return ""
