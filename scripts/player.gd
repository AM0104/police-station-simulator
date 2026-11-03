extends CharacterBody3D
class_name ArchivePlayer

# First-person controller for the archive.
#
# Movement: WASD. Look: mouse. Interact: E. Esc is handled by Archive.gd and
# opens the settings overlay (which releases the cursor). The player itself only
# walks, looks, plays footsteps, and reports what the interaction ray touches.

signal interact_requested(target: Node3D)
signal focus_changed(folder_title: String, focused: bool)

@export_group("Movement")
## Target walking speed in metres per second.
@export var move_speed: float = 3.0
## How quickly the player reaches the target speed (higher = snappier).
@export var acceleration: float = 12.0
## Distance travelled per generated footstep.
@export var footstep_stride: float = 1.45

@export_group("Look")
## Mouse look sensitivity in radians per pixel.
@export var mouse_sensitivity: float = 0.0022
## Maximum up/down look angle in degrees.
@export var look_limit_degrees: float = 85.0
## Initial downward pitch, so the player starts looking toward the desk.
@export_range(-45.0, 20.0, 1.0) var start_pitch_degrees: float = -12.0
## Small vertical camera bob while walking. Set to 0 to disable.
@export var head_bob_amount: float = 0.022
@export var head_bob_frequency: float = 9.0

@export_group("Interaction")
## The interaction ray's length in metres.
@export var ray_length: float = 2.5
## The ray only needs to be re-cast a few times per second. This is one of the
## cheap physics optimisations: the highlight responds quickly without doing a
## fresh scene query every physics frame.
@export var focus_check_interval: float = 0.06

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay

## While true, movement, look, and interaction are suspended (menus, dialogue).
var controls_locked: bool = false

var _focused_folder: Node3D = null
var _pitch: float = 0.0
var _bob_time: float = 0.0
var _base_camera_height: float = 0.0
var _gravity: float = 9.8
var _focus_check_timer: float = 0.0
var _stride_distance: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_base_camera_height = camera.position.y

	# Start with a slight downward tilt toward the desk.
	_pitch = deg_to_rad(start_pitch_degrees)
	head.rotation.x = _pitch

	# The game starts with the mouse captured and the player looking at the desk.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interaction_ray.target_position = Vector3(0.0, 0.0, -ray_length)
	interaction_ray.enabled = true
	Loc.locale_changed.connect(_on_locale_changed)


func _unhandled_input(event: InputEvent) -> void:
	# Look around only while the mouse is captured and gameplay is active.
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not controls_locked:
			rotate_y(-event.relative.x * mouse_sensitivity)
			_pitch = clampf(
				_pitch - event.relative.y * mouse_sensitivity,
				deg_to_rad(-look_limit_degrees),
				deg_to_rad(look_limit_degrees)
			)
			head.rotation.x = _pitch
		return

	# Esc is handled by Archive.gd: it opens the Settings overlay, which
	# releases the cursor. Clicking the game window captures it again.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not controls_locked:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# E opens the file currently under the crosshair. Re-cast the ray once before
	# checking, so a quick turn-and-press still feels responsive.
	if event.is_action_pressed("interact"):
		if controls_locked or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		_update_interaction_ray()
		if is_instance_valid(_focused_folder):
			interact_requested.emit(_focused_folder)


func _physics_process(delta: float) -> void:
	# While any UI is open, keep the body still but let gravity settle it.
	if controls_locked or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * 2.0 * delta)
		move_and_slide()
		_set_focused_folder(null)
		_reset_head_bob(delta)
		return

	_apply_gravity(delta)

	# get_vector gives us a smooth, normalized 2D input.
	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	# Local -Z is forward in Godot. Rotate the input by the body's yaw.
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y))
	var target_velocity := direction * move_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	move_and_slide()
	_update_head_bob(delta, Vector2(velocity.x, velocity.z).length())
	_update_footsteps(delta, input_vector.length())
	_update_focus_check(delta)


## Applies standard gravity and keeps the player glued to the floor.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		# A small downward bias prevents bouncing at floor transitions.
		velocity.y = -0.5


## Very light footstep bob. The camera moves, the collision capsule does not.
func _update_head_bob(delta: float, horizontal_speed: float) -> void:
	var movement_ratio := clampf(horizontal_speed / maxf(move_speed, 0.001), 0.0, 1.0)
	if movement_ratio > 0.05 and is_on_floor():
		_bob_time += delta * head_bob_frequency * movement_ratio
		camera.position.y = _base_camera_height + sin(_bob_time) * head_bob_amount
	else:
		_reset_head_bob(delta)


func _reset_head_bob(delta: float) -> void:
	_bob_time = 0.0
	camera.position.y = lerpf(camera.position.y, _base_camera_height, minf(delta * 8.0, 1.0))


## Accumulates travelled distance and triggers a synthesised footstep.
func _update_footsteps(delta: float, input_strength: float) -> void:
	if input_strength <= 0.05 or not is_on_floor():
		return

	_stride_distance += Vector2(velocity.x, velocity.z).length() * delta
	if _stride_distance >= footstep_stride:
		_stride_distance = 0.0
		AudioManager.play_footstep()


## Throttled focus ray. A 60 ms cadence is invisible in normal play and cuts
## unnecessary physics queries while walking around the room.
func _update_focus_check(delta: float) -> void:
	_focus_check_timer -= delta
	if _focus_check_timer > 0.0:
		return
	_focus_check_timer = focus_check_interval
	_update_interaction_ray()


func _on_locale_changed(_new_locale: String) -> void:
	refresh_focus_text()


## Re-emits the localized title of the focused file after a language change.
func refresh_focus_text() -> void:
	if is_instance_valid(_focused_folder):
		focus_changed.emit(_get_folder_title(_focused_folder), true)
	else:
		focus_changed.emit("", false)


func _get_folder_title(folder: Node3D) -> String:
	if folder.has_method("get_localized_title"):
		return str(folder.call("get_localized_title"))
	return str(folder.get("folder_title"))


## Casts the 2.5 m ray from the camera and highlights the object it hits.
## "folders" is kept for Chapter 1; "interactables" lets later chapters add
## phones, drawers, doors, etc. without changing the player scene.
func _update_interaction_ray() -> void:
	var hit_folder: Node3D = null
	if interaction_ray.is_colliding():
		var collider := interaction_ray.get_collider()
		if collider is Node3D and (
			collider.is_in_group("folders") or collider.is_in_group("interactables")
		):
			hit_folder = collider

	_set_focused_folder(hit_folder)


## Changes the highlighted interactable, if necessary, and tells the HUD about it.
func _set_focused_folder(folder: Node3D) -> void:
	if folder == _focused_folder:
		return

	if is_instance_valid(_focused_folder) and _focused_folder.has_method("set_highlighted"):
		_focused_folder.call("set_highlighted", false)
	_focused_folder = folder

	if is_instance_valid(_focused_folder):
		if _focused_folder.has_method("set_highlighted"):
			_focused_folder.call("set_highlighted", true)
		focus_changed.emit(_get_folder_title(_focused_folder), true)
	else:
		focus_changed.emit("", false)


## Returns the interactable currently under the ray, or null. Station scripts use
## this to build context-specific prompts without changing the focus signal.
func get_focused_interactable() -> Node3D:
	return _focused_folder


## Called by the Archive while menus or the final screen are open.
func set_controls_locked(locked: bool) -> void:
	controls_locked = locked
	if locked:
		_set_focused_folder(null)
		velocity.x = 0.0
		velocity.z = 0.0
		_stride_distance = 0.0
		_focus_check_timer = 0.0
