extends CharacterBody3D
class_name StationNPC

# A living police-station NPC.
#
# The NPC uses a NavigationAgent3D on a baked NavigationRegion3D. It can patrol
# a route (Marker3D nodes sharing `waypoint_group`), receive a one-off manual
# destination, or stop and face the player while talking.
#
# Interaction is intentionally generic: the NPC joins the "interactables"
# group and exposes get_localized_title()/set_highlighted(), exactly like the
# files in Chapter 1. Station.gd handles the actual E press and dialogue.

signal arrived_at_destination

enum State { IDLE, WALKING, TALKING }

@export var npc_name: String = "Officer"
@export var npc_name_ru: String = ""
@export var role: String = "Clerk"
@export_enum("Clerk", "Detective", "Chief", "Officer", "Secretary") var role_type: String = "Clerk"
@export var dialogue: DialogueLine
@export var uniform_color: Color = Color(0.18, 0.24, 0.27)
@export var walk_speed: float = 1.5
@export var idle_time_min: float = 2.5
@export var idle_time_max: float = 6.0
## Marker3D nodes in this group form a patrol loop. Leave empty for a
## stationary NPC. Markers are sorted by node name, so use P01, P02, ...
@export var waypoint_group: StringName = &""
@export var start_active: bool = true

@onready var visual: Node3D = $Visual
@onready var body_mesh: MeshInstance3D = $Visual/Body
@onready var left_arm: MeshInstance3D = $Visual/LeftArm
@onready var right_arm: MeshInstance3D = $Visual/RightArm
@onready var name_label: Label3D = $NameLabel
@onready var role_label: Label3D = $RoleLabel
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var focus_ring: MeshInstance3D = $FocusRing

var state: State = State.IDLE
var active: bool = false
var is_talking: bool = false

var _waypoints: Array[Node3D] = []
var _waypoint_index: int = 0
var _manual_mode: bool = false
var _manual_arrival: bool = false
var _idle_timer: float = 0.0
var _bob_time: float = 0.0
var _gravity: float = 9.8
var _player: Node3D = null
var _rng := RandomNumberGenerator.new()
var _base_visual_y: float = 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("npcs")
	_rng.randomize()
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_base_visual_y = visual.position.y

	# Name and rank above the head.
	_refresh_locale_texts()
	Loc.locale_changed.connect(_on_locale_changed)
	_apply_look()

	agent.path_desired_distance = 0.55
	agent.target_desired_distance = 0.75
	agent.avoidance_enabled = false

	set_highlighted(false)
	if start_active:
		activate()


## Called by Station after the navmesh is ready. Delays are staggered slightly
## so the whole office does not start walking on the same frame.
func activate() -> void:
	if active:
		return
	active = true
	_collect_waypoints()
	_idle_timer = _rng.randf_range(0.4, 2.0)
	if not _waypoints.is_empty():
		state = State.IDLE
	else:
		state = State.IDLE


## Starts a one-off walk. If manual_arrival is true, arrived_at_destination is
## emitted when the NPC gets there (used for the Chief's scripted entrance).
func send_to_position(target: Vector3, manual_arrival: bool = true) -> void:
	if not is_inside_tree():
		return
	_manual_mode = true
	_manual_arrival = manual_arrival
	_waypoint_index = 0
	agent.target_position = target
	state = State.WALKING


## Returns to the circular patrol route.
func resume_patrol() -> void:
	_manual_mode = false
	_manual_arrival = false
	state = State.IDLE
	_idle_timer = _rng.randf_range(0.1, 0.8)
	if not _waypoints.is_empty() and active:
		_waypoint_index = 0


## Stops, turns toward the player, and suspends pathing.
func begin_talking(player: Node3D) -> void:
	_player = player
	is_talking = true
	state = State.TALKING
	velocity = Vector3.ZERO
	agent.target_position = global_position
	name_label.modulate = Color(1.0, 0.82, 0.5)
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() > 0.001:
		rotation.y = atan2(-to_player.x, -to_player.z)


## Called when the dialogue closes.
func end_talking() -> void:
	is_talking = false
	_player = null
	state = State.IDLE
	_idle_timer = _rng.randf_range(1.0, 2.5)
	name_label.modulate = Color(0.93, 0.9, 0.78)
	visual.position.y = _base_visual_y


## Story-safety helper: places an NPC at a destination if a route is blocked.
func teleport_to_position(target: Vector3) -> void:
	global_position = target
	velocity = Vector3.ZERO
	state = State.IDLE
	_manual_mode = false
	_manual_arrival = false
	agent.target_position = target


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if state == State.TALKING:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		move_and_slide()
		_face_player(delta)
		return

	if state == State.IDLE:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		_reset_bob(delta)
		if active and not _waypoints.is_empty() and not _manual_mode:
			_idle_timer -= delta
			if _idle_timer <= 0.0:
				_begin_next_waypoint()
		return

	# WALKING
	if not active:
		return
	if agent.is_navigation_finished():
		_arrive()
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var next_position := agent.get_next_path_position()
	var direction := next_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	move_and_slide()

	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 8.0, 1.0))
	_update_bob(delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = -0.5


func _begin_next_waypoint() -> void:
	if _waypoints.is_empty():
		return
	_waypoint_index = _waypoint_index % _waypoints.size()
	var point := _waypoints[_waypoint_index]
	if point == null or not is_instance_valid(point):
		_waypoint_index += 1
		return
	agent.target_position = point.global_position
	state = State.WALKING


func _arrive() -> void:
	state = State.IDLE
	if _manual_mode:
		_manual_mode = false
		agent.target_position = global_position
		if _manual_arrival:
			_manual_arrival = false
			arrived_at_destination.emit()
		return

	_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)
	if not _waypoints.is_empty():
		_waypoint_index = (_waypoint_index + 1) % _waypoints.size()


func _collect_waypoints() -> void:
	_waypoints.clear()
	if waypoint_group == &"":
		return
	for node in get_tree().get_nodes_in_group(waypoint_group):
		if node is Node3D:
			_waypoints.append(node)
	_waypoints.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.name < b.name)


func _face_player(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.001:
		return
	var target_yaw := atan2(-to_player.x, -to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 6.0, 1.0))


func _update_bob(delta: float) -> void:
	_bob_time += delta * 8.0
	visual.position.y = _base_visual_y + sin(_bob_time) * 0.025


func _reset_bob(delta: float) -> void:
	_bob_time = 0.0
	visual.position.y = lerpf(visual.position.y, _base_visual_y, minf(delta * 8.0, 1.0))


func _apply_look() -> void:
	var uniform := StandardMaterial3D.new()
	uniform.albedo_color = uniform_color
	uniform.roughness = 0.85
	uniform.metallic = 0.02
	body_mesh.material_override = uniform
	left_arm.material_override = uniform
	right_arm.material_override = uniform

	# The Chief and detectives get a noir fedora; other roles stay bareheaded.
	var hat := get_node_or_null("Visual/Hat")
	if hat != null:
		hat.visible = role_type == "Chief" or role_type == "Detective"


func get_localized_title() -> String:
	if Loc.is_russian() and not npc_name_ru.strip_edges().is_empty():
		return npc_name_ru
	return npc_name


func _refresh_locale_texts() -> void:
	name_label.text = get_localized_title()
	role_label.text = get_role()


func _localized_role() -> String:
	var role_key := "station.role." + role.to_lower()
	return Loc.t(role_key)


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_locale_texts()


## Player ray highlight.
func set_highlighted(highlighted: bool) -> void:
	if focus_ring == null:
		return
	focus_ring.visible = highlighted
	name_label.modulate = Color(1.0, 0.82, 0.5) if highlighted else Color(0.93, 0.9, 0.78)


## Exposed for the station's story controller and dialogue UI.
func get_role() -> String:
	return _localized_role()


func get_state() -> State:
	return state
