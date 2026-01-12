extends Node3D
## Controls environmental weather effects
##
## Features:
## - Wind intensity variation
## - Snow particle management
## - Fog density changes
## - Temperature-based effects

signal weather_changed(conditions: Dictionary)

@export_group("Wind")
@export var wind_enabled := true
@export var wind_base_strength := 1.0
@export var wind_variation := 0.5
@export var wind_change_speed := 0.1

@export_group("Visibility")
@export var fog_density_min := 0.01
@export var fog_density_max := 0.04

var current_wind_strength := 1.0
var target_wind_strength := 1.0
var wind_timer := 0.0
var wind_change_interval := 5.0

# Reference to world environment
var environment: Environment = null


func _ready() -> void:
	# Find the WorldEnvironment
	var world_env := get_tree().get_first_node_in_group("world_environment")
	if world_env and world_env is WorldEnvironment:
		environment = world_env.environment

	_schedule_wind_change()


func _process(delta: float) -> void:
	if not wind_enabled:
		return

	# Smoothly interpolate wind strength
	current_wind_strength = lerp(current_wind_strength, target_wind_strength, delta * wind_change_speed)

	# Update wind timer
	wind_timer += delta
	if wind_timer >= wind_change_interval:
		_schedule_wind_change()

	# Update audio based on wind
	_update_wind_audio()


func _schedule_wind_change() -> void:
	"""Schedule a new wind strength target"""
	wind_timer = 0.0
	wind_change_interval = randf_range(3.0, 10.0)

	# Calculate new wind strength
	var variation := randf_range(-wind_variation, wind_variation)
	target_wind_strength = clamp(wind_base_strength + variation, 0.2, 2.0)


func _update_wind_audio() -> void:
	"""Adjust wind audio volume based on strength"""
	# This could modulate the wind ambience volume
	pass


## Set fog density (0-1 normalized)
func set_fog_intensity(intensity: float) -> void:
	if environment:
		var density := lerp(fog_density_min, fog_density_max, clamp(intensity, 0, 1))
		environment.fog_density = density


## Get current wind strength
func get_wind_strength() -> float:
	return current_wind_strength


## Trigger a blizzard event
func start_blizzard(duration: float = 30.0) -> void:
	var original_strength := wind_base_strength
	var original_fog := fog_density_max

	# Increase effects
	wind_base_strength = 2.0
	set_fog_intensity(1.0)

	weather_changed.emit({
		"event": "blizzard",
		"active": true
	})

	await get_tree().create_timer(duration).timeout

	# Restore
	wind_base_strength = original_strength
	set_fog_intensity(0.5)

	weather_changed.emit({
		"event": "blizzard",
		"active": false
	})
