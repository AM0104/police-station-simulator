extends Node3D
class_name StationDoor

# Automatic swinging door.
#
# Area3D detects the player or an NPC approaching and opens the door. The
# AnimationPlayer is populated at runtime so the door scene stays self-contained
# and no imported animation resource is needed. Door colliders live on physics
# layer 4 ("Doors"), which the station's navmesh bake ignores; the navigation
# path therefore runs through the doorway while the physical door still blocks
# the player until it swings open.

@export var door_label: String = "OFFICE"
@export var open_angle_degrees: float = 105.0
@export var open_time: float = 0.55
@export var close_delay: float = 1.4
@export var start_closed: bool = true

@onready var pivot: Node3D = $Pivot
@onready var door_body: StaticBody3D = $Pivot/DoorBody
@onready var trigger: Area3D = $Trigger
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label3D = $DoorLabel

var is_open: bool = false
var _occupants: int = 0
var _close_serial: int = 0
var _collision_serial: int = 0


func _ready() -> void:
	label.text = door_label
	add_to_group("doors")
	_build_animations()
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	if not start_closed:
		pivot.rotation.y = deg_to_rad(open_angle_degrees)
		is_open = true
		door_body.collision_layer = 0
	else:
		door_body.collision_layer = 8


func _build_animations() -> void:
	var library := AnimationLibrary.new()
	var open := _make_animation(0.0, deg_to_rad(open_angle_degrees))
	open.length = open_time
	library.add_animation("open", open)
	var close := _make_animation(deg_to_rad(open_angle_degrees), 0.0)
	close.length = open_time
	library.add_animation("close", close)
	animation_player.add_animation_library("door", library)


func _make_animation(from_angle: float, to_angle: float) -> Animation:
	var animation := Animation.new()
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("Pivot:rotation:y"))
	animation.track_insert_key(track, 0.0, from_angle)
	animation.track_insert_key(track, open_time, to_angle)
	animation.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	return animation


func open() -> void:
	if is_open:
		return
	_close_serial += 1
	_collision_serial += 1
	is_open = true
	# Do not let the swinging collision panel push the player away while the
	# door is animating. The area trigger still prevents closing on someone.
	door_body.collision_layer = 0
	animation_player.play("door/open")
	AudioManager.play_sfx("click", 0.08, -10.0)


func close() -> void:
	if not is_open or _occupants > 0:
		return
	is_open = false
	animation_player.play("door/close")
	AudioManager.play_sfx("click", 0.08, -12.0)
	_restore_collision_when_closed()


func _restore_collision_when_closed() -> void:
	_collision_serial += 1
	var serial := _collision_serial
	await get_tree().create_timer(open_time + 0.05).timeout
	if serial != _collision_serial or is_open or _occupants > 0:
		return
	door_body.collision_layer = 8


func _on_body_entered(body: Node3D) -> void:
	if not (body.is_in_group("player") or body.is_in_group("npcs")):
		return
	_occupants += 1
	_close_serial += 1
	open()


func _on_body_exited(body: Node3D) -> void:
	if not (body.is_in_group("player") or body.is_in_group("npcs")):
		return
	_occupants = maxi(_occupants - 1, 0)
	if _occupants == 0:
		_schedule_close()


func _schedule_close() -> void:
	_close_serial += 1
	var serial := _close_serial
	await get_tree().create_timer(close_delay).timeout
	if serial != _close_serial or _occupants > 0:
		return
	close()
