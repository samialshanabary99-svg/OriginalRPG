class_name Player
extends CharacterBody2D

## Core Player controller adhering to decoupled component architecture.
## Uses CharacterStatsComponent (extends StatsComponent) for full RPG stats.

signal player_moved(position: Vector2)
signal player_attacked()

@export var move_speed: float = 200.0
@export var attack_cooldown: float = 0.6

@onready var stats: CharacterStatsComponent = $CharacterStatsComponent
@onready var interactor_component: InteractorComponent = $InteractorComponent
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var input_direction: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_handle_input()
	_apply_movement()

func _handle_input() -> void:
	var raw_x: float = Input.get_axis("move_left", "move_right")
	var raw_y: float = Input.get_axis("move_up", "move_down")
	input_direction = Vector2(raw_x, raw_y).normalized()

	if Input.is_action_just_pressed("interact"):
		interact()

	if Input.is_action_just_pressed("attack"):
		_try_attack()

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

func _try_attack() -> void:
	if _attack_timer > 0.0 or stats == null:
		return
	_attack_timer = attack_cooldown
	player_attacked.emit()

	# Hit all enemies overlapping the AttackArea
	if attack_area == null:
		return
	for body: Node in attack_area.get_overlapping_bodies():
		if body is Enemy:
			(body as Enemy).receive_hit(stats.attack)
