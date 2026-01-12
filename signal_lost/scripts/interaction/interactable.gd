class_name Interactable
extends StaticBody3D
## Base class for all interactable objects in the game
##
## Extend this class to create interactive props like doors,
## terminals, switches, etc.

@export var interaction_text := "Interact"
@export var one_shot := false
@export var highlight_on_hover := true

var has_been_used := false

signal interacted(player: Node)


func _ready() -> void:
	add_to_group("interactable")
	# Layer 3 = Interactable (for raycast detection)
	collision_layer = 4


## Returns the text shown when player looks at this object
func get_interaction_text() -> String:
	return interaction_text


## Called when player interacts with this object
func interact(player: Node) -> void:
	if one_shot and has_been_used:
		return

	has_been_used = true
	_on_interact(player)
	interacted.emit(player)


## Override in child classes to implement specific behavior
func _on_interact(_player: Node) -> void:
	pass


## Reset the interactable (for reusable objects)
func reset() -> void:
	has_been_used = false
