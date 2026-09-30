class_name AncientMonument
extends Interactable

## Example interactive object in the test world.

signal inspection_triggered(message: String)

@export var monument_name: String = "Ancient Rune Pillar"
@export var lore_text: String = "Ancient runes glow faintly with forgotten knowledge. The foundation of this world is solid."

@onready var prompt_label: Label = $PromptLabel
@onready var sprite: Sprite2D = $Sprite2D

var interaction_count: int = 0

func _init() -> void:
	# Connect core signals immediately so they work whether in-tree or in tests
	interacted.connect(_on_interacted)

func _ready() -> void:
	prompt_message = "Press E to Read [%s]" % monument_name
	if has_node("PromptLabel"):
		$PromptLabel.text = prompt_message
		$PromptLabel.visible = false
	focused.connect(_on_focused)
	unfocused.connect(_on_unfocused)


func _on_focused() -> void:
	if has_node("PromptLabel"):
		$PromptLabel.visible = true
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.3, 1.3, 1.0, 1.0)

func _on_unfocused() -> void:
	if has_node("PromptLabel"):
		$PromptLabel.visible = false
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_interacted(_interactor: Node) -> void:
	interaction_count += 1
	var msg: String = "%s (Interaction #%d): \"%s\"" % [monument_name, interaction_count, lore_text]
	inspection_triggered.emit(msg)
	print("[Monument] %s" % msg)
