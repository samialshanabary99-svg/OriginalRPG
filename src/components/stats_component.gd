class_name StatsComponent
extends Node

## Reusable component providing health, attributes, and serialization.

signal health_changed(current: int, maximum: int)
signal died()

@export var max_health: int = 100
var current_health: int = 100

func _ready() -> void:
	current_health = max_health

func set_health(value: int) -> void:
	var clamped: int = clampi(value, 0, max_health)
	if clamped != current_health:
		current_health = clamped
		health_changed.emit(current_health, max_health)
		if current_health == 0:
			died.emit()

func apply_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	set_health(current_health - amount)

func heal(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	set_health(current_health + amount)



func serialize() -> Dictionary:
	return {
		"max_health": max_health,
		"current_health": current_health
	}

func deserialize(data: Dictionary) -> void:
	if data.has("max_health"):
		max_health = int(data["max_health"])
	if data.has("current_health"):
		current_health = int(data["current_health"])
