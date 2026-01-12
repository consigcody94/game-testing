extends Interactable
## Computer terminal for reading data logs
##
## Features:
## - Multiple log entries
## - Navigation between entries
## - Tracks discovered logs

@export var terminal_id := ""
@export_multiline var log_entries: Array[String] = []

var current_entry := 0


func _ready() -> void:
	super._ready()
	interaction_text = "Access Terminal"
	one_shot = false  # Can access terminal multiple times


func _on_interact(_player: Node) -> void:
	GameManager.open_terminal(self)


## Get the currently displayed log entry
func get_current_log() -> String:
	if log_entries.is_empty():
		return "NO DATA AVAILABLE\n\n> SYSTEM ERROR 0x4F21\n> DATA CORRUPTION DETECTED"
	return log_entries[current_entry]


## Get current entry index (1-based for display)
func get_current_entry_number() -> int:
	return current_entry + 1


## Get total number of entries
func get_total_entries() -> int:
	return log_entries.size()


## Navigate to next log entry
func next_entry() -> void:
	if log_entries.is_empty():
		return
	current_entry = (current_entry + 1) % log_entries.size()
	_mark_discovered()


## Navigate to previous log entry
func previous_entry() -> void:
	if log_entries.is_empty():
		return
	current_entry -= 1
	if current_entry < 0:
		current_entry = log_entries.size() - 1
	_mark_discovered()


func _mark_discovered() -> void:
	"""Mark current log as discovered in GameManager"""
	if terminal_id != "":
		var log_id := "%s_%d" % [terminal_id, current_entry]
		if not log_id in GameManager.discovered_logs:
			GameManager.discovered_logs.append(log_id)
