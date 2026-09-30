class_name TestWorld
extends Node2D

## Test map coordinating the prototype gameplay loop.
## Wires player, enemies, monument, and HUD together.

@onready var player: Player = $Player
@onready var monument: AncientMonument = $AncientMonument
@onready var hud: HUD = $HUD

func _ready() -> void:
	if hud != null and player != null:
		hud.bind_player(player)
		hud.return_to_menu_requested.connect(_on_return_to_menu)

	if monument != null and hud != null:
		monument.inspection_triggered.connect(hud.show_dialogue)

	# Wire all enemies in scene to grant XP on death
	_register_enemies()

func _register_enemies() -> void:
	for child: Node in get_children():
		if child is Enemy:
			_connect_enemy(child as Enemy)

func _connect_enemy(enemy: Enemy) -> void:
	enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy) -> void:
	if player == null or player.stats == null:
		return
	var xp: int = DamageCalculator.xp_reward(enemy.stats.level)
	player.stats.gain_experience(xp)
	if hud != null:
		hud.show_dialogue("Enemy defeated! +" + str(xp) + " XP")
		# Auto-hide after 2 seconds
		await get_tree().create_timer(2.0).timeout
		hud.hide_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_on_return_to_menu()

func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
