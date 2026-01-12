extends Node
## Controls paranormal anomaly events
##
## Creates atmospheric horror through:
## - Light flickering
## - Radio static bursts
## - Temperature drops (frost overlay)
## - Equipment malfunctions
##
## IMPROVEMENTS:
## - Added intensity scaling based on game progress
## - More varied anomaly types
## - Better timing control

signal anomaly_started(type: String)
signal anomaly_ended(type: String)

@export_group("Timing")
@export var min_interval := 30.0
@export var max_interval := 120.0
@export var enabled := true

@export_group("Intensity")
@export var base_intensity := 1.0
@export var intensity_multiplier := 1.0  # Increases with game progress

var timer := 0.0
var next_time := 0.0
var anomaly_active := false


func _ready() -> void:
	randomize()
	_schedule_next()


func _process(delta: float) -> void:
	if not enabled or anomaly_active:
		return

	timer += delta
	if timer >= next_time:
		_trigger_random()
		_schedule_next()


func _schedule_next() -> void:
	"""Schedule the next anomaly event"""
	timer = 0.0
	# Shorter intervals at higher intensity
	var interval_mod := 1.0 / intensity_multiplier
	next_time = randf_range(min_interval * interval_mod, max_interval * interval_mod)


func _trigger_random() -> void:
	"""Trigger a random anomaly event"""
	var types := ["flicker", "static", "cold", "equipment"]

	# Weight selection based on intensity
	var weights := [0.35, 0.25, 0.25, 0.15]

	# Simple weighted random selection
	var total := 0.0
	for w in weights:
		total += w

	var roll := randf() * total
	var cumulative := 0.0
	var chosen := types[0]

	for i in range(types.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			chosen = types[i]
			break

	match chosen:
		"flicker":
			await _flicker_lights()
		"static":
			await _radio_burst()
		"cold":
			await _temperature_drop()
		"equipment":
			await _equipment_malfunction()


func _flicker_lights() -> void:
	"""Make lights flicker ominously"""
	anomaly_active = true
	anomaly_started.emit("flicker")

	var lights := get_tree().get_nodes_in_group("flickerable")
	var original_states: Array[bool] = []

	# Store original states
	for light in lights:
		original_states.append(light.visible)

	# Flicker sequence
	var flicker_count := randi_range(3, 8)
	for i in range(flicker_count):
		for light in lights:
			light.visible = randf() > 0.5
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout

	# Restore original states
	for i in range(lights.size()):
		lights[i].visible = original_states[i]

	anomaly_ended.emit("flicker")
	anomaly_active = false


func _radio_burst() -> void:
	"""Sudden radio static burst"""
	anomaly_active = true
	anomaly_started.emit("static")

	AudioManager.play_sfx("radio_static")

	# Duration varies
	await get_tree().create_timer(randf_range(1.0, 3.0)).timeout

	anomaly_ended.emit("static")
	anomaly_active = false


func _temperature_drop() -> void:
	"""Trigger frost overlay effect"""
	anomaly_active = true
	anomaly_started.emit("cold")

	# The frost overlay shader should respond to this signal
	# Duration of cold effect
	await get_tree().create_timer(randf_range(5.0, 10.0)).timeout

	anomaly_ended.emit("cold")
	anomaly_active = false


func _equipment_malfunction() -> void:
	"""Equipment acts strangely"""
	anomaly_active = true
	anomaly_started.emit("equipment")

	# Find equipment that can malfunction
	var equipment := get_tree().get_nodes_in_group("equipment")
	if equipment.size() > 0:
		var target = equipment[randi() % equipment.size()]
		if target.has_method("malfunction"):
			target.malfunction()

	await get_tree().create_timer(2.0).timeout

	anomaly_ended.emit("equipment")
	anomaly_active = false


## Increase anomaly intensity (call as game progresses)
func increase_intensity(amount: float = 0.1) -> void:
	intensity_multiplier += amount


## Force trigger a specific anomaly type
func trigger_anomaly(type: String) -> void:
	match type:
		"flicker":
			await _flicker_lights()
		"static":
			await _radio_burst()
		"cold":
			await _temperature_drop()
		"equipment":
			await _equipment_malfunction()
