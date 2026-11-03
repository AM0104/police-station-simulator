extends StaticBody3D
class_name StationInteractable

# Generic ray-interactable prop (folder, chief's desk, evidence box, etc.).
#
# Custom interaction rules live in Station.gd, keyed by interaction_id. This
# script only owns presentation (highlight) and the optional consume() helper.

@export var interaction_id: String = "object"
@export var display_name: String = "Object"
@export var consumed: bool = false

var _highlighted: bool = false
var _highlight_material: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("interactables")
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.3, 0.22, 0.1)
	_highlight_material.roughness = 0.55
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(1.0, 0.55, 0.16)
	_highlight_material.emission_energy_multiplier = 0.22
	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			_meshes.append(child)


func get_localized_title() -> String:
	return display_name


func get_interaction_id() -> String:
	return interaction_id


func set_highlighted(highlighted: bool) -> void:
	if consumed:
		return
	_highlighted = highlighted
	for mesh in _meshes:
		if is_instance_valid(mesh):
			mesh.material_override = _highlight_material if highlighted else null


## Removes a picked-up object from the world without freeing the node. Delayed
## story references (e.g. quest checks) remain valid.
func consume() -> void:
	if consumed:
		return
	consumed = true
	visible = false
	collision_layer = 0
	collision_mask = 0


func is_consumed() -> bool:
	return consumed
