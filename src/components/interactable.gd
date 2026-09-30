class_name Interactable
extends Area2D

## Base class for interactive world objects.

signal interacted(interactor: Node)
signal focused()
signal unfocused()

@export var prompt_message: String = "Press E to Interact"
@export var is_interactable: bool = true

func can_interact(_interactor: Node) -> bool:
	return is_interactable

func interact(interactor: Node) -> void:
	if not can_interact(interactor):
		return
	interacted.emit(interactor)

func set_focused(value: bool) -> void:
	if value:
		focused.emit()
	else:
		unfocused.emit()
