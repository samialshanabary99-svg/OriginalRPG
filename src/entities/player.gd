class_name Player
extends CharacterBody2D

## Core Player controller adhering to decoupled component architecture.

signal player_moved(position: Vector2)

@export var move_speed: float = 200.0

@onready var stats_component: StatsComponent = $StatsComponent
@onready var interactor_component: InteractorComponent = $InteractorComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var input_direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	_handle_input()
	_apply_movement()

func _handle_input() -> void:
	var raw_x: float = Input.get_axis("move_left", "move_right")
	var raw_y: float = Input.get_axis("move_up", "move_down")
	input_direction = Vector2(raw_x, raw_y).normalized()

	if Input.is_action_just_pressed("interact"):
		interact()

func _apply_movement() -> void:
	velocity = input_direction * move_speed
	if is_inside_tree():
		move_and_slide()
	else:
		global_position += velocity * (1.0 / 60.0)

	if velocity.length_squared() > 0.0:
		player_moved.emit(global_position)
		if sprite != null and input_direction.x != 0.0:
			sprite.flip_h = input_direction.x < 0.0


func interact() -> void:
	if interactor_component != null:
		interactor_component.try_interact()
