extends Node3D

# Runtime star field. Built as one MultiMeshInstance3D so the whole sky costs a
# single draw call (important on integrated GPUs).

const STAR_COUNT := 110


func _ready() -> void:
	seed(1983)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 5
	sm.rings = 3
	mm.mesh = sm
	mm.instance_count = STAR_COUNT
	for i in STAR_COUNT:
		var yaw := randf_range(0.0, TAU)
		var pitch := randf_range(0.1, 1.4)
		var r := randf_range(60.0, 95.0)
		var p := Vector3(cos(yaw) * cos(pitch) * r, sin(pitch) * r, sin(yaw) * cos(pitch) * r)
		var s := randf_range(0.45, 1.2)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), p))

	var field := MultiMeshInstance3D.new()
	field.name = "StarField"
	field.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.6, 1.6, 1.7)
	field.material_override = mat
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(field)