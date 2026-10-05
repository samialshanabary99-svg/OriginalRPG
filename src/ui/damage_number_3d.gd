class_name DamageNumber3D
extends Label3D

## Ragnarok Online style floating combat damage number.
## Features:
##   - Bold outlined typography facing the camera (billboard)
##   - Distinct color themes:
##       * Pure White with black outline for damage dealt to enemies
##       * Ragnarok Red with black outline for damage dealt to the player
##       * Golden Yellow with larger scale for critical hits
##       * Ice White / Cyan for "MISS"
##       * Emerald Green for heals / recovery
##   - Signature RO bounce arc: rapid upward pop with impact scale,
##     floating deceleration, and smooth alpha fadeout
##   - Random horizontal jitter to keep consecutive attacks legible
##   - Automatic cleanup on animation completion

enum Type {
	DAMAGE_TO_ENEMY,
	DAMAGE_TO_PLAYER,
	CRITICAL,
	MISS,
	HEAL
}

const COLOR_DAMAGE_TO_ENEMY: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_DAMAGE_TO_PLAYER: Color = Color(1.0, 0.22, 0.22, 1.0)
const COLOR_CRITICAL: Color = Color(1.0, 0.88, 0.15, 1.0)
const COLOR_MISS: Color = Color(0.85, 0.92, 1.0, 1.0)
const COLOR_HEAL: Color = Color(0.28, 0.95, 0.35, 1.0)

@export var duration: float = 0.70
@export var float_height: float = 0.55
@export var pop_scale: float = 1.25
@export var damage_type: Type = Type.DAMAGE_TO_ENEMY

var _tween: Tween = null

func _ready() -> void:
	_animate()

## Configures the damage label properties, styling, and starting position.
func setup(text_str: String, type: Type, start_pos: Vector3) -> void:
	text = text_str
	damage_type = type
	position = start_pos

	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	render_priority = 30
	outline_render_priority = 29
	outline_size = 10
	outline_modulate = Color.BLACK
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pixel_size = 0.005
	shaded = false
	double_sided = true

	match type:
		Type.DAMAGE_TO_ENEMY:
			modulate = COLOR_DAMAGE_TO_ENEMY
			font_size = 32
		Type.DAMAGE_TO_PLAYER:
			modulate = COLOR_DAMAGE_TO_PLAYER
			font_size = 32
		Type.CRITICAL:
			modulate = COLOR_CRITICAL
			font_size = 38
		Type.MISS:
			modulate = COLOR_MISS
			font_size = 28
		Type.HEAL:
			modulate = COLOR_HEAL
			font_size = 32

## Triggers the Ragnarok Online pop and floating upward animation.
func _animate() -> void:
	scale = Vector3(pop_scale, pop_scale, pop_scale)
	var end_y: float = position.y + float_height
	var drift_x: float = position.x + randf_range(-0.10, 0.10)

	_tween = create_tween()
	if _tween == null:
		return
	_tween.set_parallel(true)

	# 1. Impact pop: quick scale down from 1.25 to 1.0 in 0.08s
	_tween.tween_property(self, "scale", Vector3.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Upward float arc with gentle horizontal drift
	_tween.tween_property(self, "position:y", end_y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", drift_x, duration).set_trans(Tween.TRANS_LINEAR)

	# 3. Fade out during the second half of the flight
	var fade_delay: float = duration * 0.45
	var fade_time: float = duration * 0.55
	_tween.tween_property(self, "modulate:a", 0.0, fade_time).set_delay(fade_delay).set_ease(Tween.EASE_IN)

	# 4. Self cleanup
	_tween.chain().tween_callback(queue_free)

## Static factory: spawns a damage number floating over a target entity in world space.
static func spawn(
	target: Node,
	amount: Variant,
	type: Type = Type.DAMAGE_TO_ENEMY,
	custom_offset: Vector3 = Vector3.ZERO
) -> DamageNumber3D:
	if target == null:
		return null

	var world_pos: Vector3 = Vector3.ZERO
	if target is Node3D:
		var n3d: Node3D = target as Node3D
		world_pos = n3d.global_position if n3d.is_inside_tree() else n3d.position

	# Default elevation over target head (Player head ~ 1.5m, Wolf head ~ 1.1m)
	var default_y: float = 1.15
	if target.is_in_group("player") or (target.name != null and "Player" in target.name):
		default_y = 1.45
	elif target.is_in_group("enemies") or (target.name != null and "Enemy" in target.name):
		default_y = 1.05

	var spawn_pos: Vector3 = world_pos + Vector3(0.0, default_y, 0.0) + custom_offset
	# Slight horizontal jitter so rapid consecutive numbers do not completely overlap
	spawn_pos.x += randf_range(-0.18, 0.18)
	spawn_pos.z += randf_range(-0.12, 0.12)

	var parent_node: Node = null
	if target is Node and target.get_parent() != null:
		parent_node = target.get_parent()
	elif target.is_inside_tree():
		parent_node = target.get_tree().current_scene
		if parent_node == null:
			parent_node = target.get_tree().root
	if parent_node == null and target is Node:
		parent_node = target

	var dmg_label: DamageNumber3D = DamageNumber3D.new()
	dmg_label.setup(str(amount), type, spawn_pos)

	if parent_node != null:
		parent_node.add_child(dmg_label)
		if dmg_label.is_inside_tree():
			dmg_label.global_position = spawn_pos

	return dmg_label

## Static factory: spawns a damage number directly at specific world coordinates.
static func spawn_at(
	parent_node: Node,
	world_pos: Vector3,
	amount: Variant,
	type: Type = Type.DAMAGE_TO_ENEMY
) -> DamageNumber3D:
	if parent_node == null:
		return null

	var spawn_pos: Vector3 = world_pos
	spawn_pos.x += randf_range(-0.18, 0.18)
	spawn_pos.z += randf_range(-0.12, 0.12)

	var dmg_label: DamageNumber3D = DamageNumber3D.new()
	dmg_label.setup(str(amount), type, spawn_pos)
	parent_node.add_child(dmg_label)
	if dmg_label.is_inside_tree():
		dmg_label.global_position = spawn_pos
	return dmg_label
