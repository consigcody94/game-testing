extends Interactable
## Interactive door that can be opened/closed
##
## Features:
## - Smooth rotation animation
## - Lock/unlock functionality
## - Sound effects

@export var open_angle := 90.0
@export var open_speed := 2.0
@export var locked := false
@export var required_key := ""  # Item ID needed to unlock

var is_open := false
var target_rotation := 0.0
var initial_rotation: float


func _ready() -> void:
	super._ready()
	initial_rotation = rotation.y
	_update_interaction_text()
	one_shot = false  # Doors can be used multiple times


func _process(delta: float) -> void:
	# Smooth rotation towards target
	rotation.y = lerp_angle(rotation.y, target_rotation, open_speed * delta)


func _on_interact(player: Node) -> void:
	if locked:
		# Check if player has the key
		if required_key != "" and GameManager.has_item(required_key):
			locked = false
			AudioManager.play_sfx("switch_click")
			_update_interaction_text()
			return

		AudioManager.play_sfx("door_locked")
		return

	# Toggle open/closed state
	is_open = !is_open
	target_rotation = initial_rotation + deg_to_rad(open_angle if is_open else 0)
	_update_interaction_text()
	AudioManager.play_sfx("door_open")


func _update_interaction_text() -> void:
	if locked:
		if required_key != "":
			interaction_text = "Locked (requires key)"
		else:
			interaction_text = "Locked"
	else:
		interaction_text = "Close Door" if is_open else "Open Door"


## Lock the door
func lock() -> void:
	locked = true
	_update_interaction_text()


## Unlock the door
func unlock() -> void:
	locked = false
	_update_interaction_text()


## Force open the door
func force_open() -> void:
	is_open = true
	locked = false
	target_rotation = initial_rotation + deg_to_rad(open_angle)
	_update_interaction_text()


## Force close the door
func force_close() -> void:
	is_open = false
	target_rotation = initial_rotation
	_update_interaction_text()
