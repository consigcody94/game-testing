extends Node
## Global audio manager for sound effects and ambience
##
## Features:
## - SFX playback with caching
## - Ambient loop management with crossfade
## - Volume control per category

const SFX_PATH := "res://assets/audio/sfx/"
const AMBIENCE_PATH := "res://assets/audio/ambience/"
const MUSIC_PATH := "res://assets/audio/music/"

@export var master_volume := 1.0
@export var sfx_volume := 1.0
@export var ambience_volume := 0.7
@export var music_volume := 0.5

# Audio stream cache
var sfx_cache: Dictionary = {}

# Active ambience players
var ambience_players: Array[AudioStreamPlayer] = []

# Active music player
var music_player: AudioStreamPlayer = null


func _ready() -> void:
	# Preload common sound effects
	_preload_sfx("switch_click")
	_preload_sfx("door_open")
	_preload_sfx("door_locked")
	_preload_sfx("footstep_snow")
	_preload_sfx("footstep_metal")
	_preload_sfx("radio_static")
	_preload_sfx("heartbeat")


func _preload_sfx(sfx_name: String) -> void:
	"""Preload a sound effect into cache"""
	var path := SFX_PATH + sfx_name + ".ogg"
	if ResourceLoader.exists(path):
		sfx_cache[sfx_name] = load(path)


## Play a sound effect
func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream = sfx_cache.get(sfx_name)

	# Try to load if not cached
	if not stream:
		var path := SFX_PATH + sfx_name + ".ogg"
		if ResourceLoader.exists(path):
			stream = load(path)
			sfx_cache[sfx_name] = stream
		else:
			push_warning("SFX not found: " + sfx_name)
			return

	# Create temporary player
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


## Play a sound effect at a 3D position
func play_sfx_3d(sfx_name: String, position: Vector3, volume_db: float = 0.0) -> void:
	var stream = sfx_cache.get(sfx_name)

	if not stream:
		var path := SFX_PATH + sfx_name + ".ogg"
		if ResourceLoader.exists(path):
			stream = load(path)
			sfx_cache[sfx_name] = stream
		else:
			return

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	player.global_position = position
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


## Start an ambient sound loop
func start_ambience(ambience_name: String, fade_time: float = 2.0) -> void:
	var path := AMBIENCE_PATH + ambience_name + ".ogg"
	if not ResourceLoader.exists(path):
		push_warning("Ambience not found: " + ambience_name)
		return

	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = -80  # Start silent
	add_child(player)
	player.play()
	ambience_players.append(player)

	# Fade in
	var target_db := linear_to_db(ambience_volume * master_volume)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, fade_time)


## Stop a specific ambience track
func stop_ambience(ambience_name: String, fade_time: float = 2.0) -> void:
	for player in ambience_players:
		if player.stream and ambience_name in player.stream.resource_path:
			var tween := create_tween()
			tween.tween_property(player, "volume_db", -80.0, fade_time)
			tween.tween_callback(func():
				ambience_players.erase(player)
				player.queue_free()
			)
			break


## Stop all ambient sounds
func stop_all_ambience(fade_time: float = 2.0) -> void:
	for player in ambience_players:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_time)
		tween.tween_callback(player.queue_free)
	ambience_players.clear()


## Start background music
func play_music(music_name: String, fade_time: float = 3.0) -> void:
	var path := MUSIC_PATH + music_name + ".ogg"
	if not ResourceLoader.exists(path):
		push_warning("Music not found: " + music_name)
		return

	# Fade out existing music
	if music_player:
		var old_player := music_player
		var tween := create_tween()
		tween.tween_property(old_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(old_player.queue_free)

	# Create new music player
	music_player = AudioStreamPlayer.new()
	music_player.stream = load(path)
	music_player.volume_db = -80
	add_child(music_player)
	music_player.play()

	# Fade in
	var target_db := linear_to_db(music_volume * master_volume)
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", target_db, fade_time)


## Stop music
func stop_music(fade_time: float = 2.0) -> void:
	if music_player:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func():
			music_player.queue_free()
			music_player = null
		)
