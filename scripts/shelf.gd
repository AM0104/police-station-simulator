extends Node3D

# Shelf dressing generator.
#
# The shelf contains dozens of small file boxes. Rendering them as individual
# MeshInstance3D nodes would add ~100 draw calls to the basement. Instead the
# files are packed into one MultiMesh per shelf, with per-instance transforms
# and colours. That is one draw call for all files on this shelf, and shadows
# are disabled for them because they are small background props.

## Different seeds give each shelf a subtly different arrangement.
@export var shelf_seed: int = 1

@onready var file_multi_mesh: MultiMeshInstance3D = $Visual/Files

const ROW_BASES: Array[float] = [0.252, 0.852, 1.452, 2.052]
const SLOT_COUNT := 23
const SLOT_START := -1.24
const SLOT_STEP := 0.112

const FILE_COLORS: Array[Color] = [
	Color(0.55, 0.49, 0.36),
	Color(0.68, 0.62, 0.49),
	Color(0.42, 0.45, 0.35),
	Color(0.49, 0.41, 0.29),
	Color(0.60, 0.53, 0.37),
	Color(0.35, 0.36, 0.30),
]


func _ready() -> void:
	_build_file_instances()


func _build_file_instances() -> void:
	if file_multi_mesh == null or file_multi_mesh.multimesh == null:
		push_warning("Shelf: Files MultiMeshInstance3D is not configured.")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = shelf_seed * 7919 + 1987

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []

	for row_index in ROW_BASES.size():
		var row_base := ROW_BASES[row_index]
		for slot in SLOT_COUNT:
			# Leave occasional gaps so the shelf looks handled, not cloned.
			if rng.randf() < 0.17:
				continue

			var width_scale := rng.randf_range(0.86, 1.14)
			var height_scale := rng.randf_range(0.82, 1.18)
			var tilt := deg_to_rad(rng.randf_range(-2.0, 2.0))
			var x := SLOT_START + slot * SLOT_STEP + rng.randf_range(-0.007, 0.007)

			# The base BoxMesh is 0.3 m tall; centre it on the shelf plank.
			var y := row_base + 0.15 * height_scale
			var basis := Basis(Vector3(0, 0, 1), tilt).scaled(
				Vector3(width_scale, height_scale, 1.0)
			)
			transforms.append(Transform3D(basis, Vector3(x, y, 0.02)))
			colors.append(FILE_COLORS[rng.randi_range(0, FILE_COLORS.size() - 1)])

	var multi_mesh := file_multi_mesh.multimesh
	multi_mesh.instance_count = transforms.size()
	multi_mesh.visible_instance_count = transforms.size()

	for index in transforms.size():
		multi_mesh.set_instance_transform(index, transforms[index])
		multi_mesh.set_instance_color(index, colors[index])
