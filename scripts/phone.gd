extends StaticBody3D
class_name DutyPhone

# The desk telephone in the duty room.
#
# It is a normal interactable: the player's RayCast3D finds it through the
# "interactables" group and CallManager receives interact_requested. The phone
# owns its presentation only (highlight + ringing animation + ring audio);
# call logic belongs to CallManager.

@onready var handset: Node3D = $Handset
@onready var ring_player: AudioStreamPlayer3D = $RingPlayer
@onready var button_lamp: MeshInstance3D = $Base/ButtonLamp

var _ringing: bool = false
var _handset_base_position: Vector3 = Vector3.ZERO
var _lamp_base_rotation: Vector3 = Vector3.ZERO
var _shake_time: float = 0.0

var _highlight_material: StandardMaterial3D
var _highlight_lamp_material: StandardMaterial3D
var _visual_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("interactables")
	_handset_base_position = handset.position
	_lamp_base_rotation = button_lamp.rotation
	ring_player.stream = AudioManager.get_sfx_stream("ring")
	set_process(false)

	# Every visible part of the phone lights up amber when the interaction ray
	# touches it. The dial is deliberately left alone so its paper face stays
	# readable against the highlighted housing.
	_visual_meshes = [$Base, $Cord]
	for child in handset.get_children():
		if child is MeshInstance3D:
			_visual_meshes.append(child)
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.3, 0.19, 0.095)
	_highlight_material.roughness = 0.48
	_highlight_material.metallic = 0.25
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(1.0, 0.46, 0.12)
	_highlight_material.emission_energy_multiplier = 0.35

	_highlight_lamp_material = StandardMaterial3D.new()
	_highlight_lamp_material.albedo_color = Color(0.42, 0.1, 0.055)
	_highlight_lamp_material.emission_enabled = true
	_highlight_lamp_material.emission = Color(1.0, 0.22, 0.08)
	_highlight_lamp_material.emission_energy_multiplier = 2.6


func _process(delta: float) -> void:
	# A restrained mechanical rattle: the bell hammers inside the housing.
	_shake_time += delta
	if _ringing:
		var jitter := sin(_shake_time * 72.0) * 0.0035
		handset.position = _handset_base_position + Vector3(jitter, 0.0, -jitter * 0.6)
		button_lamp.rotate_x(delta * 7.0)


## Called by CallManager when a new call arrives.
func start_ringing() -> void:
	if _ringing:
		return
	_ringing = true
	ring_player.play()
	button_lamp.material_override = _highlight_lamp_material
	set_process(true)


## Stops ring audio and the handset shake.
func stop_ringing() -> void:
	if not _ringing:
		return
	_ringing = false
	ring_player.stop()
	handset.position = _handset_base_position
	button_lamp.rotation = _lamp_base_rotation
	button_lamp.material_override = null
	set_process(false)


func is_ringing() -> bool:
	return _ringing


## The HUD prompt uses this title.
func get_localized_title() -> String:
	return Loc.t("duty.phone.label")


## Player ray highlight, compatible with the Chapter 1 folder interface.
func set_highlighted(highlighted: bool) -> void:
	for mesh in _visual_meshes:
		mesh.material_override = _highlight_material if highlighted else null

	# Keep the red lamp when ringing, even if the ray leaves the phone.
	button_lamp.material_override = _highlight_lamp_material if _ringing else null
