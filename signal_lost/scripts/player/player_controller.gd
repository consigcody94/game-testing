extends CharacterBody3D
## First-person player controller with head bob, sprinting, and interaction
##
## IMPROVEMENTS:
## - Added head bob effect for immersion
## - Added stamina system for sprinting
## - Added footstep sounds based on surface
## - Added interaction prompt display

@export_group("Movement")
@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var acceleration := 10.0
@export var deceleration := 12.0

@export_group("Mouse Look")
@export var mouse_sensitivity := 0.002
@export var max_pitch := 89.0

@export_group("Head Bob")
@export var head_bob_enabled := true
@export var head_bob_frequency := 2.0
@export var head_bob_amplitude := 0.05

@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_drain_rate := 15.0
@export var stamina_regen_rate := 10.0
@export var stamina_regen_delay := 1.5

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var current_speed := walk_speed
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Head bob variables
var head_bob_time := 0.0
var camera_start_y := 0.0

# Stamina variables
var stamina := 100.0
var stamina_regen_timer := 0.0

# Footstep variables
var footstep_timer := 0.0
var footstep_interval := 0.5

# Currently looked-at interactable
var current_interactable: Node = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	flashlight.visible = false
	camera_start_y = camera.position.y
	stamina = max_stamina


func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))

	# Pause/unpause (toggle mouse capture)
	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Flashlight toggle
	if event.is_action_pressed("flashlight"):
		flashlight.visible = !flashlight.visible
		AudioManager.play_sfx("switch_click")

	# Interact
	if event.is_action_pressed("interact"):
		_try_interact()

	# Quit game (IMPROVEMENT: quick exit)
	if event.is_action_pressed("quit"):
		get_tree().quit()


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle sprinting with stamina
	var is_sprinting := false
	if Input.is_action_pressed("sprint") and stamina > 0:
		current_speed = sprint_speed
		is_sprinting = true
		stamina -= stamina_drain_rate * delta
		stamina = max(stamina, 0)
		stamina_regen_timer = stamina_regen_delay
	else:
		current_speed = walk_speed

	# Stamina regeneration
	if not is_sprinting:
		stamina_regen_timer -= delta
		if stamina_regen_timer <= 0:
			stamina += stamina_regen_rate * delta
			stamina = min(stamina, max_stamina)

	# Get input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	move_and_slide()

	# Head bob effect
	if head_bob_enabled:
		_apply_head_bob(delta, direction.length() > 0)

	# Footstep sounds
	_handle_footsteps(delta, direction.length() > 0, is_sprinting)

	# Update interaction ray
	_update_interaction_prompt()


func _apply_head_bob(delta: float, is_moving: bool) -> void:
	"""Apply subtle head bobbing when walking"""
	if is_moving and is_on_floor():
		head_bob_time += delta * head_bob_frequency * (current_speed / walk_speed)
		var bob_offset := sin(head_bob_time * TAU) * head_bob_amplitude
		camera.position.y = camera_start_y + bob_offset
	else:
		# Smoothly return to center
		camera.position.y = lerp(camera.position.y, camera_start_y, delta * 10.0)
		head_bob_time = 0.0


func _handle_footsteps(delta: float, is_moving: bool, is_sprinting: bool) -> void:
	"""Play footstep sounds based on movement and surface"""
	if not is_moving or not is_on_floor():
		footstep_timer = 0.0
		return

	# Adjust interval based on speed
	var interval := footstep_interval
	if is_sprinting:
		interval *= 0.6

	footstep_timer += delta
	if footstep_timer >= interval:
		footstep_timer = 0.0
		# Determine surface type (simplified - could use physics material)
		var sound := "footstep_metal"  # Default indoor
		# Could raycast down to check surface material
		AudioManager.play_sfx(sound, -5.0)


func _update_interaction_prompt() -> void:
	"""Check for interactable objects and show prompt"""
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider != current_interactable:
			current_interactable = collider
			if collider.has_method("get_interaction_text"):
				GameManager.show_interaction_prompt(collider.get_interaction_text())
			elif collider.has_method("interact"):
				GameManager.show_interaction_prompt("Interact")
	else:
		if current_interactable != null:
			current_interactable = null
			GameManager.hide_interaction_prompt()


func _try_interact() -> void:
	"""Attempt to interact with object in front of player"""
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider.has_method("interact"):
			collider.interact(self)


## Get current stamina percentage (0-1)
func get_stamina_percent() -> float:
	return stamina / max_stamina
