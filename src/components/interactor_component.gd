class_name InteractorComponent
extends Area2D

## Player component that detects and interacts with nearby Interactable areas.

signal interaction_target_changed(target: Interactable)

var current_target: Interactable = null
var nearby_interactables: Array[Interactable] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func try_interact() -> bool:
	if current_target != null and is_instance_valid(current_target):
		current_target.interact(get_parent())
		return true
	return false

func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and area.can_interact(get_parent()):
		nearby_interactables.append(area)
		_update_current_target()

func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		nearby_interactables.erase(area)
		if area == current_target:
			area.set_focused(false)
			current_target = null
		_update_current_target()

func _update_current_target() -> void:
	# Filter invalid
	nearby_interactables = nearby_interactables.filter(func(a: Interactable): return is_instance_valid(a) and a.can_interact(get_parent()))
	
	var new_target: Interactable = null
	if not nearby_interactables.is_empty():
		# Pick closest
		var parent_pos: Vector2 = (get_parent() as Node2D).global_position
		nearby_interactables.sort_custom(func(a: Interactable, b: Interactable):
			return parent_pos.distance_squared_to(a.global_position) < parent_pos.distance_squared_to(b.global_position)
		)
		new_target = nearby_interactables[0]

	if new_target != current_target:
		if current_target != null and is_instance_valid(current_target):
			current_target.set_focused(false)
		current_target = new_target
		if current_target != null:
			current_target.set_focused(true)
		interaction_target_changed.emit(current_target)
