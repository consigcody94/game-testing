extends Node
## Global game state manager
##
## Handles:
## - Inventory system
## - Game flags/progress
## - Terminal UI
## - Interaction prompts
## - Save/load (basic)

signal prompt_changed(text: String, visible: bool)
signal terminal_opened(terminal: Node)
signal terminal_closed
signal game_event(event_name: String, data: Dictionary)

# Player inventory
var inventory: Array[String] = []

# Discovered log entries (terminal_id_index format)
var discovered_logs: Array[String] = []

# Game state flags
var game_flags: Dictionary = {}

# Currently active terminal
var active_terminal: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Show interaction prompt to player
func show_interaction_prompt(text: String) -> void:
	prompt_changed.emit(text, true)


## Hide interaction prompt
func hide_interaction_prompt() -> void:
	prompt_changed.emit("", false)


## Check if player has an item
func has_item(item_id: String) -> bool:
	return item_id in inventory


## Add item to player inventory
func add_item(item_id: String) -> void:
	if not has_item(item_id):
		inventory.append(item_id)
		game_event.emit("item_acquired", {"item_id": item_id})


## Remove item from inventory
func remove_item(item_id: String) -> void:
	var idx := inventory.find(item_id)
	if idx >= 0:
		inventory.remove_at(idx)


## Set a game flag
func set_flag(flag: String, value: bool = true) -> void:
	game_flags[flag] = value
	game_event.emit("flag_changed", {"flag": flag, "value": value})


## Get a game flag value
func get_flag(flag: String) -> bool:
	return game_flags.get(flag, false)


## Open a terminal UI
func open_terminal(terminal: Node) -> void:
	active_terminal = terminal
	terminal_opened.emit(terminal)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


## Close the terminal UI
func close_terminal() -> void:
	active_terminal = null
	terminal_closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


## Get number of discovered logs
func get_discovered_log_count() -> int:
	return discovered_logs.size()


## Basic save game data
func get_save_data() -> Dictionary:
	return {
		"inventory": inventory.duplicate(),
		"discovered_logs": discovered_logs.duplicate(),
		"game_flags": game_flags.duplicate(),
	}


## Basic load game data
func load_save_data(data: Dictionary) -> void:
	if data.has("inventory"):
		inventory = data["inventory"]
	if data.has("discovered_logs"):
		discovered_logs = data["discovered_logs"]
	if data.has("game_flags"):
		game_flags = data["game_flags"]
