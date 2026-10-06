class_name ItemPickup3D
extends Area3D

## In-world 3D item drop entity (Ragnarok Online style).
## Renders the item icon as an elevated billboard sprite with ground shadow and pop-bounce animation.
## Supports automatic proximity pickup and click-to-pickup into Player's InventoryComponent.

signal item_collected(item_def: ItemDefinition, qty: int, by_node: Node)

@export var item_id: String = ""
@export var quantity: int = 1
@export var float_height: float = 0.28
@export var despawn_seconds: float = 120.0

var item_definition: ItemDefinition = null
var _base_y: float = 0.28
var _is_collected: bool = false
var _age: float = 0.0

@onready var sprite: Sprite3D = $Sprite3D if has_node("Sprite3D") else null
@onready var shadow: MeshInstance3D = $Shadow if has_node("Shadow") else null
@onready var collision_shape: CollisionShape3D = $CollisionShape3D if has_node("CollisionShape3D") else null

func _ready() -> void:
	add_to_group("item_pickups")
	collision_layer = 8
	collision_mask = 1 # Detects player CharacterBody3D

	body_entered.connect(_on_body_entered)
	_resolve_nodes()
	_setup_visuals()

func _resolve_nodes() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite3D") as Sprite3D
	if shadow == null:
		shadow = get_node_or_null("Shadow") as MeshInstance3D
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D

func init_drop(p_item_id: String, p_qty: int = 1, p_spawn_pos: Vector3 = Vector3.ZERO) -> void:
	item_id = p_item_id
	quantity = maxi(1, p_qty)
	if p_spawn_pos != Vector3.ZERO:
		position = p_spawn_pos
		if is_inside_tree():
			global_position = p_spawn_pos

	_resolve_nodes()
	_setup_visuals()
	_play_drop_pop_animation()

func _setup_visuals() -> void:
	ContentRegistry.ensure_initialized()
	if not item_id.is_empty():
		item_definition = ContentRegistry.get_item(item_id)

	if sprite != null and item_definition != null:
		var tex: Texture2D = item_definition.get_icon()
		if tex != null:
			sprite.texture = tex
		sprite.pixel_size = 0.016
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD

	if shadow != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.render_priority = 1
		mat.albedo_color = Color(0.0, 0.0, 0.0, 0.35)
		var shadow_tex: Texture2D = load("res://assets/environment/shadows/shadow_oval_soft.png") as Texture2D
		if shadow_tex != null:
			mat.albedo_texture = shadow_tex
		shadow.material_override = mat
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _play_drop_pop_animation() -> void:
	if not is_inside_tree():
		return
	var target_y: float = position.y
	_base_y = float_height
	position.y += 0.6 # Pop into the air
	var tween: Tween = create_tween()
	if tween != null:
		tween.tween_property(self, "position:y", target_y, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_age += delta
	if despawn_seconds > 0.0 and _age >= despawn_seconds:
		queue_free()
		return

	# Gentle floating bob (Ragnarok Online style)
	if sprite != null:
		var bob_offset: float = sin(Time.get_ticks_msec() * 0.005) * 0.035
		sprite.position.y = _base_y + bob_offset

	# Shadow pulse matching height
	if shadow != null:
		var scale_factor: float = 1.0 - (sprite.position.y - _base_y) * 1.5
		shadow.scale = Vector3(scale_factor, 1.0, scale_factor)

func _on_body_entered(body: Node3D) -> void:
	if _is_collected:
		return
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody3D:
		collect(body)

## Collects this drop into the target collector node (player).
func collect(collector: Node) -> bool:
	if _is_collected:
		return false

	var inv: InventoryComponent = null
	if "inventory" in collector and collector.inventory is InventoryComponent:
		inv = collector.inventory
	elif collector.has_node("InventoryComponent"):
		inv = collector.get_node("InventoryComponent") as InventoryComponent

	if inv == null:
		return false

	ContentRegistry.ensure_initialized()
	if item_definition == null and not item_id.is_empty():
		item_definition = ContentRegistry.get_item(item_id)

	if item_definition == null:
		return false

	var success: bool = inv.add_item_by_id(item_id, quantity)
	if not success:
		return false

	_is_collected = true
	item_collected.emit(item_definition, quantity, collector)

	# Visual pickup fly-up effect before freeing
	if is_inside_tree():
		var tween: Tween = create_tween()
		if tween != null:
			tween.set_parallel(true)
			tween.tween_property(self, "position:y", position.y + 0.5, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			if sprite != null:
				tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
			if shadow != null:
				tween.tween_property(shadow, "scale", Vector3.ZERO, 0.18)
			tween.chain().tween_callback(queue_free)
			return true

	queue_free()
	return true
