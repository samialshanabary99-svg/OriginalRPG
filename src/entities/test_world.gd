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
		player.combat_resolved.connect(_on_player_combat_resolved)

	if monument != null and hud != null:
		monument.inspection_triggered.connect(hud.show_dialogue)

	_register_enemies()

func _register_enemies() -> void:
	for child: Node in get_children():
		if child is Enemy:
			_connect_enemy(child as Enemy)

func _connect_enemy(enemy: Enemy) -> void:
	if player != null and enemy.has_signal("targeted"):
		enemy.targeted.connect(player.set_target)
	enemy.enemy_died.connect(_on_enemy_died)

func _on_player_combat_resolved(result: CombatResult) -> void:
	if hud == null or not result.is_valid:
		return
	if result.target_defeated:
		hud.show_dialogue("Enemy defeated! +%d XP" % result.xp_earned)
	elif result.damage_dealt > 0:
		var target_name: String = result.target.name if result.target != null else "Enemy"
		hud.show_dialogue("Hit %s for %d DMG (HP: %d)" % [target_name, result.damage_dealt, result.target_remaining_health])

func _on_enemy_died(_enemy: Enemy) -> void:
	# Dialogue is handled via _on_player_combat_resolved; can be extended for world events
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_on_return_to_menu()

func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
