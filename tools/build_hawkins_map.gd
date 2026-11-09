extends SceneTree

# Builds scenes/HawkinsStation.tscn: the imported Hawkins Police Station model
# dressed with a night-time parking lot, street furniture and lighting.
# Run headless:
#   godot --headless --path . --script res://tools/build_hawkins_map.gd

const OUT_PATH := "res://scenes/HawkinsStation.tscn"
const MODEL_PATH := "res://assets/models/hawkins_police_station/hawkins_police_station.glb"
const ENTRANCE_SCRIPT := "res://scripts/hawkins_entrance.gd"

var world: Node3D
var instances: Array[Node] = []
var mats: Dictionary = {}

const DOOR_X := 5.45


func _initialize() -> void:
	world = Node3D.new()
	world.name = "HawkinsPoliceStation"
	world.set_script(load("res://scripts/hawkins_station.gd"))

	_build_environment()
	_build_ground()
	_build_building()
	_build_entrance()
	_build_parking()
	_build_street_furniture()
	_build_landscape()
	_build_perimeter()
	_build_hud()
	_build_player()

	_own(world)
	var packed := PackedScene.new()
	var err := packed.pack(world)
	var save_err := ResourceSaver.save(packed, OUT_PATH)
	print("BUILD pack=", err, " save=", save_err, " -> ", OUT_PATH)
	quit()


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

func _mat(key: String, color: Color, roughness: float, metallic := 0.0, emission := Color.BLACK, energy := 0.0) -> StandardMaterial3D:
	if mats.has(key):
		return mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	mats[key] = m
	return m


func _node(parent: Node, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	return n


func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _plane(parent: Node, name: String, size: Vector2, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(parent: Node, name: String, radius: float, height: float, pos: Vector3, mat: Material, rot := Vector3.ZERO, segments := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = segments
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _sphere(parent: Node, name: String, radius: float, pos: Vector3, mat: Material, segments := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = segments
	sm.rings = maxi(segments / 2, 4)
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _solid(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.rotation_degrees = rot
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	_box(body, "Mesh", size, Vector3.ZERO, mat)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body


func _label(parent: Node, name: String, text: String, pos: Vector3, size: float, color: Color, rot := Vector3.ZERO, outline := 10) -> Label3D:
	var l := Label3D.new()
	l.name = name
	l.text = text
	l.font_size = 64
	l.pixel_size = size / 64.0
	l.modulate = color
	l.outline_size = outline
	l.outline_modulate = Color(0.02, 0.02, 0.02, 0.9)
	l.position = pos
	l.rotation_degrees = rot
	parent.add_child(l)
	return l


func _omni(parent: Node, name: String, pos: Vector3, color: Color, energy: float, range_m: float, shadows := false) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.shadow_enabled = shadows
	parent.add_child(light)
	return light

# ---------------------------------------------------------------------------
# environment
# ---------------------------------------------------------------------------

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.015, 0.025, 0.06)
	sky_mat.sky_horizon_color = Color(0.09, 0.12, 0.17)
	sky_mat.sky_curve = 0.12
	sky_mat.sky_energy_multiplier = 0.55
	sky_mat.ground_bottom_color = Color(0.01, 0.012, 0.018)
	sky_mat.ground_horizon_color = Color(0.06, 0.075, 0.1)
	sky_mat.ground_curve = 0.1
	var sky := Sky.new()
	sky.sky_material = sky_mat

	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.background_energy_multiplier = 0.7
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.33, 0.4, 0.54)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.28
	env.tonemap_white = 6.0
	env.ssao_enabled = false
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.3
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.11, 0.15, 0.2)
	env.fog_light_energy = 0.7
	env.fog_density = 0.009
	env.fog_aerial_perspective = 0.25
	env.fog_sky_affect = 0.65
	we.environment = env
	world.add_child(we)

	var moon_light := DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	moon_light.light_color = Color(0.56, 0.66, 0.95)
	moon_light.light_energy = 0.8
	moon_light.shadow_enabled = true
	moon_light.directional_shadow_max_distance = 80.0
	world.add_child(moon_light)

	var moon := MeshInstance3D.new()
	moon.name = "Moon"
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 2.6
	moon_mesh.height = 5.2
	moon_mesh.radial_segments = 20
	moon_mesh.rings = 10
	moon.mesh = moon_mesh
	var moon_mat := StandardMaterial3D.new()
	moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mat.albedo_color = Color(1.45, 1.4, 1.25)
	moon.material_override = moon_mat
	moon.position = Vector3(-20.0, 28.0, -36.0)
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(moon)

	_build_stars()


func _build_stars() -> void:
	var stars := _node(world, "Stars")
	stars.set_script(load("res://scripts/hawkins_stars.gd"))
# ---------------------------------------------------------------------------
# ground
# ---------------------------------------------------------------------------

func _build_ground() -> void:
	var g := _node(world, "Ground")

	var grass := _mat("grass", Color(0.055, 0.075, 0.055), 0.95)
	var asphalt := _mat("asphalt", Color(0.052, 0.056, 0.06), 0.62, 0.12)
	var road_mat := _mat("road", Color(0.033, 0.036, 0.04), 0.55, 0.15)
	var concrete := _mat("concrete", Color(0.26, 0.26, 0.25), 0.92)
	var slate := _mat("slate", Color(0.17, 0.18, 0.18), 0.8)
	var paint := _mat("paint", Color(0.72, 0.71, 0.6), 0.8)

	_plane(g, "Grass", Vector2(180, 180), Vector3(0, 0.006, 0), grass)
	_box(g, "ParkingLot", Vector3(42, 0.02, 19), Vector3(5, 0.014, 13), asphalt)
	_box(g, "Road", Vector3(120, 0.02, 8), Vector3(0, 0.012, 27.8), road_mat)
	_box(g, "SidewalkFront", Vector3(15.4, 0.02, 3.2), Vector3(5.2, 0.03, 1.6), concrete)
	_box(g, "SidewalkFar", Vector3(120, 0.02, 2.0), Vector3(0, 0.03, 32.8), concrete)
	_box(g, "Walkway", Vector3(2.7, 0.026, 4.6), Vector3(DOOR_X, 0.038, 2.3), slate)

	# road paint
	for i in 24:
		var x := -46.0 + i * 4.0
		_box(g, "LaneDash%d" % i, Vector3(2.2, 0.02, 0.14), Vector3(x, 0.04, 27.8), paint)
	_box(g, "RoadEdgeNorth", Vector3(120, 0.02, 0.12), Vector3(0, 0.04, 24.05), paint)
	_box(g, "RoadEdgeSouth", Vector3(120, 0.02, 0.12), Vector3(0, 0.04, 31.55), paint)

	# parking bay lines
	for i in 13:
		var x := -14.0 + i * 3.2
		_box(g, "BayLine%d" % i, Vector3(0.12, 0.02, 5.4), Vector3(x, 0.036, 8.0), paint)
	_box(g, "BayStopLine", Vector3(41.0, 0.02, 0.12), Vector3(5, 0.036, 10.7), paint)

	# curb between the lot and the road
	_box(g, "Curb", Vector3(42, 0.09, 0.22), Vector3(5, 0.045, 22.62), _mat("curb", Color(0.32, 0.32, 0.3), 0.9))


	# ground collision: an invisible slab under everything
	_collider(g, "GroundCollision", Vector3(180, 1, 180), Vector3(0, -0.5, 0))


func _collider(parent: Node, name: String, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body


# ---------------------------------------------------------------------------
# the imported building
# ---------------------------------------------------------------------------

func _build_building() -> void:
	var holder := _node(world, "PoliceStationModel")
	holder.scale = Vector3(0.01, 0.01, 0.01)
	var model: Node3D = load(MODEL_PATH).instantiate()
	model.name = "HawkinsModel"
	holder.add_child(model)
	instances.append(model)

	# The exported model has no collision. Two boxes cover the L-shaped footprint.
	_collider(world, "BuildingCollisionMain", Vector3(10.6, 2.6, 11.6), Vector3(5.12, 1.3, -5.7))
	_collider(world, "BuildingCollisionWing", Vector3(10.6, 2.6, 5.4), Vector3(5.12, 1.3, -14.2))

# ---------------------------------------------------------------------------
# entrance
# ---------------------------------------------------------------------------

func _build_entrance() -> void:
	var e := _node(world, "Entrance")
	var metal := _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7)
	var warm := _mat("warm_glow", Color(1.0, 0.84, 0.6), 0.4, 0.0, Color(1.0, 0.78, 0.48), 5.0)

	for side in [-1.0, 1.0]:
		var x: float = DOOR_X + side * 1.18
		_box(e, "Sconce_%d" % int(side), Vector3(0.22, 0.34, 0.1), Vector3(x, 1.95, 0.09), metal)
		_box(e, "SconceGlow_%d" % int(side), Vector3(0.15, 0.22, 0.05), Vector3(x, 1.93, 0.155), warm)
		_omni(e, "SconceLight_%d" % int(side), Vector3(x, 1.85, 0.55), Color(1.0, 0.72, 0.42), 1.5, 4.5)

	_omni(e, "DoorLight", Vector3(DOOR_X, 2.15, 0.9), Color(1.0, 0.76, 0.48), 1.0, 3.5)

	var body := StaticBody3D.new()
	body.name = "StationEntrance"
	body.position = Vector3(DOOR_X, 1.05, 0.52)
	body.collision_layer = 4
	body.collision_mask = 0
	body.set_script(load(ENTRANCE_SCRIPT))
	body.add_to_group("interactables", true)
	e.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(1.75, 2.1, 0.55)
	cs.shape = box
	body.add_child(cs)


# ---------------------------------------------------------------------------
# vehicles
# ---------------------------------------------------------------------------

func _build_parking() -> void:
	var p := _node(world, "Vehicles")
	_police_car(p, "PoliceCruiserA", Vector3(-10.8, 0, 7.6), 180.0)
	_police_car(p, "PoliceCruiserB", Vector3(21.2, 0, 7.6), 180.0)
	_sedan(p, "SedanA", Vector3(-14.0, 0, 7.6), 178.0, Color(0.14, 0.2, 0.16))
	_sedan(p, "SedanB", Vector3(18.0, 0, 7.6), 181.0, Color(0.22, 0.1, 0.09))
	_sedan(p, "SedanC", Vector3(-12.5, 0, 17.4), 2.0, Color(0.12, 0.14, 0.19))
	_police_car(p, "PoliceCruiserC", Vector3(9.2, 0, 17.4), 0.0)


func _police_car(parent: Node, name: String, pos: Vector3, yaw: float) -> void:
	var c := _node(parent, name)
	c.position = pos
	c.rotation_degrees.y = yaw
	var body_mat := _mat("police_blue", Color(0.045, 0.07, 0.12), 0.35, 0.35)
	var glass := _mat("glass", Color(0.02, 0.03, 0.04), 0.1, 0.7)
	var black := _mat("rubber", Color(0.015, 0.015, 0.018), 0.9)
	var chrome := _mat("chrome", Color(0.55, 0.57, 0.6), 0.25, 0.9)

	_box(c, "Body", Vector3(2.0, 0.46, 4.8), Vector3(0, 0.62, 0), body_mat)
	_box(c, "Hood", Vector3(1.9, 0.16, 1.5), Vector3(0, 0.92, 1.62), body_mat)
	_box(c, "Trunk", Vector3(1.9, 0.16, 1.1), Vector3(0, 0.92, -1.82), body_mat)
	_box(c, "Cabin", Vector3(1.68, 0.48, 1.95), Vector3(0, 1.14, -0.15), glass)
	_box(c, "Roof", Vector3(1.72, 0.09, 2.0), Vector3(0, 1.42, -0.15), body_mat)
	_box(c, "Skirt", Vector3(2.02, 0.2, 4.4), Vector3(0, 0.42, 0), black)

	# wheels
	for wx in [-0.94, 0.94]:
		for wz in [-1.55, 1.55]:
			_cyl(c, "Wheel", 0.34, 0.24, Vector3(wx, 0.34, wz), black, Vector3(0, 0, 90), 16)

	# light bar
	_box(c, "LightBarBase", Vector3(1.26, 0.07, 0.34), Vector3(0, 1.49, -0.1), black)
	_box(c, "LightBarRed", Vector3(0.5, 0.13, 0.28), Vector3(-0.34, 1.56, -0.1), _mat("beacon_red", Color(0.5, 0.02, 0.02), 0.3, 0.0, Color(1.0, 0.05, 0.05), 7.0))
	_box(c, "LightBarBlue", Vector3(0.5, 0.13, 0.28), Vector3(0.34, 1.56, -0.1), _mat("beacon_blue", Color(0.02, 0.05, 0.5), 0.3, 0.0, Color(0.1, 0.35, 1.0), 7.0))

	# push bar and bumpers
	_box(c, "PushBar", Vector3(1.9, 0.12, 0.14), Vector3(0, 0.6, 2.5), chrome)
	for bx in [-0.65, 0.65]:
		_box(c, "PushBarPost", Vector3(0.1, 0.55, 0.1), Vector3(bx, 0.6, 2.42), chrome)
	_box(c, "RearBumper", Vector3(1.95, 0.14, 0.16), Vector3(0, 0.5, -2.46), chrome)

	# lights
	for lx in [-0.62, 0.62]:
		_box(c, "Headlight", Vector3(0.32, 0.13, 0.06), Vector3(lx, 0.78, 2.42), _mat("headlight", Color(1, 0.95, 0.8), 0.2, 0.0, Color(1.0, 0.92, 0.75), 3.5))
		_box(c, "Taillight", Vector3(0.3, 0.12, 0.06), Vector3(lx, 0.8, -2.42), _mat("taillight", Color(0.4, 0.02, 0.02), 0.3, 0.0, Color(0.9, 0.03, 0.02), 3.0))

	_label(c, "SideLabelL", "POLICE", Vector3(-1.02, 0.78, 0.1), 0.18, Color(0.92, 0.93, 0.95), Vector3(0, -90, 0), 8)
	_label(c, "SideLabelR", "POLICE", Vector3(1.02, 0.78, 0.1), 0.18, Color(0.92, 0.93, 0.95), Vector3(0, 90, 0), 8)

	_collider_under(c, "Collision", Vector3(2.12, 1.55, 5.0), Vector3(0, 0.78, 0))


func _sedan(parent: Node, name: String, pos: Vector3, yaw: float, color: Color) -> void:
	var c := _node(parent, name)
	c.position = pos
	c.rotation_degrees.y = yaw
	var paint := _mat("sedan_" + name, color, 0.38, 0.28)
	var glass := _mat("glass", Color(0.02, 0.03, 0.04), 0.1, 0.7)
	var black := _mat("rubber", Color(0.015, 0.015, 0.018), 0.9)
	var chrome := _mat("chrome", Color(0.55, 0.57, 0.6), 0.25, 0.9)

	_box(c, "Body", Vector3(1.88, 0.48, 4.5), Vector3(0, 0.58, 0), paint)
	_box(c, "Hood", Vector3(1.8, 0.14, 1.25), Vector3(0, 0.86, 1.55), paint)
	_box(c, "Trunk", Vector3(1.8, 0.14, 1.0), Vector3(0, 0.86, -1.7), paint)
	_box(c, "Cabin", Vector3(1.6, 0.42, 2.1), Vector3(0, 1.05, -0.1), glass)
	_box(c, "Roof", Vector3(1.64, 0.08, 1.9), Vector3(0, 1.29, -0.15), paint)
	_box(c, "Skirt", Vector3(1.92, 0.18, 4.2), Vector3(0, 0.4, 0), black)
	for wx in [-0.88, 0.88]:
		for wz in [-1.42, 1.42]:
			_cyl(c, "Wheel", 0.31, 0.22, Vector3(wx, 0.31, wz), black, Vector3(0, 0, 90), 16)
	for lx in [-0.58, 0.58]:
		_box(c, "Headlight", Vector3(0.28, 0.11, 0.06), Vector3(lx, 0.72, 2.26), _mat("headlight", Color(1, 0.93, 0.78), 0.2, 0.0, Color(1.0, 0.9, 0.7), 2.5))
		_box(c, "Taillight", Vector3(0.26, 0.1, 0.06), Vector3(lx, 0.74, -2.26), _mat("taillight", Color(0.4, 0.02, 0.02), 0.3, 0.0, Color(0.9, 0.03, 0.02), 2.5))
	_box(c, "FrontBumper", Vector3(1.9, 0.12, 0.14), Vector3(0, 0.46, 2.28), chrome)

	_collider_under(c, "Collision", Vector3(2.0, 1.4, 4.7), Vector3(0, 0.72, 0))


func _collider_under(parent: Node, name: String, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body

# ---------------------------------------------------------------------------
# street furniture
# ---------------------------------------------------------------------------

func _build_street_furniture() -> void:
	var s := _node(world, "StreetFurniture")
	_street_lamp(s, "LampWest", Vector3(-13.4, 0, 4.6), 1.0, false)
	_street_lamp(s, "LampEast", Vector3(23.4, 0, 4.6), 1.0, false)
	_street_lamp(s, "LampSouthWest", Vector3(-13.4, 0, 20.8), -1.0, false)
	_street_lamp(s, "LampSouthEast", Vector3(23.4, 0, 20.8), -1.0, false)
	_street_lamp(s, "LampGateWest", Vector3(-0.5, 0, 21.2), 1.0, false)
	_street_lamp(s, "LampGateEast", Vector3(11.5, 0, 21.2), 1.0, false)
	_street_lamp(s, "LampRoadWest", Vector3(-28.0, 0, 34.4), -1.0, false)
	_street_lamp(s, "LampRoadEast", Vector3(28.0, 0, 34.4), -1.0, false)
	_street_lamp(s, "LampLotCenterWest", Vector3(-15.2, 0, 12.6), 1.0, false)
	_street_lamp(s, "LampLotCenterEast", Vector3(25.2, 0, 12.6), 1.0, false)
	_street_lamp(s, "LampEntranceWest", Vector3(-2.8, 0, 3.2), 1.0, true)
	_street_lamp(s, "LampEntranceEast", Vector3(12.4, 0, 3.2), 1.0, true)

	_bench(s, "BenchA", Vector3(0.9, 0, 2.45), 0.0)
	_bench(s, "BenchB", Vector3(9.9, 0, 2.45), 0.0)
	_trash_can(s, "TrashA", Vector3(3.25, 0, 3.8))
	_trash_can(s, "TrashB", Vector3(7.65, 0, 3.8))
	_hydrant(s, "Hydrant", Vector3(11.9, 0, 1.2))
	_newspaper_box(s, "NewsBox", Vector3(0.35, 0, 1.25))

	# bollards framing the walkway
	for i in 2:
		var x := 3.4 + i * 4.1
		_cyl(s, "Bollard%d" % i, 0.085, 0.9, Vector3(x, 0.45, 4.35), _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7), Vector3.ZERO, 10)
		_box(s, "BollardBand%d" % i, Vector3(0.19, 0.07, 0.19), Vector3(x, 0.72, 4.35), _mat("warm_glow", Color(1.0, 0.84, 0.6), 0.4, 0.0, Color(1.0, 0.78, 0.48), 5.0))

	# flagpole
	var f := _node(s, "Flagpole")
	f.position = Vector3(-2.4, 0, 1.9)
	_cyl(f, "Base", 0.24, 0.3, Vector3(0, 0.15, 0), _mat("concrete", Color(0.26, 0.26, 0.25), 0.92), Vector3.ZERO, 12)
	_cyl(f, "Pole", 0.055, 8.0, Vector3(0, 4.0, 0), _mat("chrome", Color(0.55, 0.57, 0.6), 0.25, 0.9), Vector3.ZERO, 8)
	_sphere(f, "Finial", 0.11, Vector3(0, 8.05, 0), _mat("gold", Color(0.72, 0.6, 0.3), 0.3, 0.8), 8)
	_box(f, "Flag", Vector3(1.45, 0.9, 0.02), Vector3(0.75, 7.35, 0), _mat("flag", Color(0.16, 0.19, 0.32), 0.85), Vector3(0, 0, -4))
	_box(f, "FlagStripe", Vector3(1.45, 0.16, 0.025), Vector3(0.75, 7.08, 0), _mat("flag_stripe", Color(0.72, 0.72, 0.68), 0.8), Vector3(0, 0, -4))
	_collider_under(f, "Collision", Vector3(0.5, 0.6, 0.5), Vector3(0, 0.3, 0))

	# monument sign by the lot entrance
	var m := _node(s, "MonumentSign")
	m.position = Vector3(-8.0, 0, 20.4)
	m.rotation_degrees.y = 180.0
	var brick := _mat("planter_brick", Color(0.23, 0.11, 0.08), 0.9)
	for px in [-1.5, 1.5]:
		_box(m, "Post", Vector3(0.22, 1.7, 0.22), Vector3(px, 0.85, 0), brick)
	_box(m, "Board", Vector3(3.5, 1.15, 0.16), Vector3(0, 1.5, 0), _mat("sign_board", Color(0.06, 0.075, 0.09), 0.6, 0.2))
	_box(m, "BoardTrim", Vector3(3.6, 0.06, 0.2), Vector3(0, 2.1, 0), _mat("chrome", Color(0.55, 0.57, 0.6), 0.25, 0.9))
	_label(m, "SignTitle", "HAWKINS POLICE", Vector3(0, 1.66, 0.1), 0.28, Color(0.93, 0.89, 0.76), Vector3.ZERO, 6)
	_label(m, "SignSub", "DEPARTMENT  ·  EST. 1953", Vector3(0, 1.33, 0.1), 0.13, Color(0.78, 0.72, 0.56), Vector3.ZERO, 5)
	_collider_under(m, "Collision", Vector3(3.6, 1.8, 0.5), Vector3(0, 0.9, 0))

	# parking sign
	var ps := _node(s, "ParkingSign")
	ps.position = Vector3(12.4, 0, 4.2)
	_cyl(ps, "Pole", 0.05, 2.6, Vector3(0, 1.3, 0), _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7), Vector3.ZERO, 8)
	_box(ps, "Board", Vector3(0.7, 0.7, 0.06), Vector3(0, 2.45, 0), _mat("sign_blue", Color(0.05, 0.1, 0.22), 0.6))
	_label(ps, "Letter", "P", Vector3(0, 2.45, 0.045), 0.4, Color(0.9, 0.92, 0.95), Vector3.ZERO, 6)


func _street_lamp(parent: Node, name: String, pos: Vector3, arm: float, shadows: bool) -> void:
	var l := _node(parent, name)
	l.position = pos
	var metal := _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7)
	_cyl(l, "Base", 0.17, 0.4, Vector3(0, 0.2, 0), metal, Vector3.ZERO, 10)
	_cyl(l, "Pole", 0.075, 6.2, Vector3(0, 3.1, 0), metal, Vector3.ZERO, 10)
	_box(l, "Arm", Vector3(0.1, 0.1, 1.3), Vector3(0, 6.05, arm * 0.62), metal)
	_box(l, "Head", Vector3(0.52, 0.18, 0.3), Vector3(0, 5.98, arm * 1.28), metal)
	_box(l, "Glow", Vector3(0.42, 0.05, 0.22), Vector3(0, 5.88, arm * 1.28), _mat("warm_glow", Color(1.0, 0.84, 0.6), 0.4, 0.0, Color(1.0, 0.78, 0.48), 5.0))
	_omni(l, "Light", Vector3(0, 5.75, arm * 1.28), Color(1.0, 0.73, 0.45), 4.8, 20.0, shadows)
	_collider_under(l, "Collision", Vector3(0.4, 1.0, 0.4), Vector3(0, 0.5, 0))


func _bench(parent: Node, name: String, pos: Vector3, yaw: float) -> void:
	var b := _node(parent, name)
	b.position = pos
	b.rotation_degrees.y = yaw
	var wood := _mat("bench_wood", Color(0.22, 0.14, 0.08), 0.85)
	var metal := _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7)
	_box(b, "Seat", Vector3(1.8, 0.09, 0.5), Vector3(0, 0.45, 0), wood)
	_box(b, "Back", Vector3(1.8, 0.48, 0.07), Vector3(0, 0.72, -0.23), wood)
	for lx in [-0.75, 0.75]:
		_box(b, "Leg", Vector3(0.08, 0.42, 0.42), Vector3(lx, 0.2, 0), metal)
	_box(b, "Frame", Vector3(1.86, 0.06, 0.06), Vector3(0, 0.5, 0.24), metal)
	_collider_under(b, "Collision", Vector3(1.85, 0.9, 0.6), Vector3(0, 0.45, 0))


func _trash_can(parent: Node, name: String, pos: Vector3) -> void:
	var t := _node(parent, name)
	t.position = pos
	var green := _mat("bin_green", Color(0.07, 0.11, 0.08), 0.7, 0.2)
	_cyl(t, "Body", 0.29, 0.85, Vector3(0, 0.43, 0), green, Vector3.ZERO, 12)
	_cyl(t, "Lid", 0.32, 0.08, Vector3(0, 0.88, 0), _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7), Vector3.ZERO, 12)
	_collider_under(t, "Collision", Vector3(0.62, 0.95, 0.62), Vector3(0, 0.47, 0))


func _hydrant(parent: Node, name: String, pos: Vector3) -> void:
	var h := _node(parent, name)
	h.position = pos
	var red := _mat("hydrant_red", Color(0.42, 0.07, 0.05), 0.6)
	_cyl(h, "Base", 0.16, 0.12, Vector3(0, 0.06, 0), red, Vector3.ZERO, 10)
	_cyl(h, "Body", 0.13, 0.55, Vector3(0, 0.34, 0), red, Vector3.ZERO, 12)
	_sphere(h, "Cap", 0.14, Vector3(0, 0.62, 0), red, 10)
	for side in [-1.0, 1.0]:
		_cyl(h, "Nozzle", 0.055, 0.18, Vector3(side * 0.15, 0.42, 0), red, Vector3(0, 0, 90), 8)
	_collider_under(h, "Collision", Vector3(0.4, 0.75, 0.4), Vector3(0, 0.37, 0))


func _newspaper_box(parent: Node, name: String, pos: Vector3) -> void:
	var n := _node(parent, name)
	n.position = pos
	_box(n, "Body", Vector3(0.5, 0.85, 0.45), Vector3(0, 0.45, 0), _mat("news_blue", Color(0.08, 0.13, 0.22), 0.55, 0.25))
	_box(n, "Window", Vector3(0.36, 0.3, 0.02), Vector3(0, 0.62, 0.235), _mat("glass", Color(0.02, 0.03, 0.04), 0.1, 0.7))
	_box(n, "Leg", Vector3(0.08, 0.12, 0.08), Vector3(0, 0.06, 0), _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7))
	_collider_under(n, "Collision", Vector3(0.55, 0.9, 0.5), Vector3(0, 0.45, 0))


# ---------------------------------------------------------------------------
# landscape
# ---------------------------------------------------------------------------

func _build_landscape() -> void:
	var l := _node(world, "Landscape")
	var brick := _mat("planter_brick", Color(0.23, 0.11, 0.08), 0.9)
	var bush := _mat("bush", Color(0.055, 0.09, 0.055), 0.95)

	# planters flanking the entrance
	for px in [3.55, 7.35]:
		var planter := _node(l, "Planter_%d" % int(px * 10))
		planter.position = Vector3(px, 0, 0.8)
		_box(planter, "Box", Vector3(1.0, 0.55, 0.8), Vector3(0, 0.27, 0), brick)
		_box(planter, "Soil", Vector3(0.84, 0.06, 0.64), Vector3(0, 0.53, 0), _mat("soil", Color(0.06, 0.045, 0.03), 1.0))
		_sphere(planter, "Bush", 0.4, Vector3(-0.2, 0.75, 0), bush)
		_sphere(planter, "Bush2", 0.32, Vector3(0.22, 0.7, 0.05), bush)
		_collider_under(planter, "Collision", Vector3(1.05, 0.9, 0.85), Vector3(0, 0.4, 0))

	# low hedges along the facade
	for hx in [-1.6, 12.0]:
		_box(l, "Hedge_%d" % int(hx * 10), Vector3(2.4, 0.8, 0.75), Vector3(hx, 0.4, 0.85), bush)
		_collider_under(l, "HedgeCollision_%d" % int(hx * 10), Vector3(2.4, 0.85, 0.8), Vector3(hx, 0.42, 0.85))

	var trees := [
		Vector3(-19.5, 0, 2.0), Vector3(-20.5, 0, 14.0), Vector3(-18.5, 0, -9.0),
		Vector3(29.0, 0, 3.0), Vector3(29.5, 0, 17.0), Vector3(28.0, 0, -8.0),
		Vector3(2.5, 0, -23.0), Vector3(18.0, 0, -23.5),
		Vector3(-30.0, 0, 26.0), Vector3(36.0, 0, 26.5), Vector3(-34.0, 0, 12.0),
	]
	for i in trees.size():
		_tree(l, "Tree%d" % i, trees[i], 1.0 + float(i % 3) * 0.12)


func _tree(parent: Node, name: String, pos: Vector3, scale: float) -> void:
	var t := _node(parent, name)
	t.position = pos
	t.scale = Vector3(scale, scale, scale)
	var bark := _mat("bark", Color(0.09, 0.06, 0.04), 0.95)
	var leaves := _mat("leaves", Color(0.035, 0.06, 0.04), 0.95)
	_cyl(t, "Trunk", 0.2, 3.4, Vector3(0, 1.7, 0), bark, Vector3.ZERO, 8)
	_sphere(t, "FoliageA", 1.7, Vector3(0, 4.4, 0), leaves, 10)
	_sphere(t, "FoliageB", 1.25, Vector3(-0.75, 3.9, 0.35), leaves, 10)
	_sphere(t, "FoliageC", 1.15, Vector3(0.8, 4.0, -0.4), leaves, 10)
	_sphere(t, "FoliageD", 1.0, Vector3(0.1, 5.3, 0.2), leaves, 8)
	_collider_under(t, "Collision", Vector3(0.55, 3.0, 0.55), Vector3(0, 1.5, 0))


# ---------------------------------------------------------------------------
# perimeter
# ---------------------------------------------------------------------------

func _build_perimeter() -> void:
	var p := _node(world, "Perimeter")
	_fence_line(p, "FenceBack", Vector2(-16.5, -19.0), Vector2(26.5, -19.0))
	_fence_line(p, "FenceWest", Vector2(-16.5, -19.0), Vector2(-16.5, 22.0))
	_fence_line(p, "FenceEast", Vector2(26.5, -19.0), Vector2(26.5, 22.0))

	var brick := _mat("planter_brick", Color(0.23, 0.11, 0.08), 0.9)
	for gx in [-16.5, 26.5]:
		var gate := _node(p, "GatePillar_%d" % int(gx * 10))
		gate.position = Vector3(gx, 0, 22.0)
		_box(gate, "Pillar", Vector3(0.6, 2.1, 0.6), Vector3(0, 1.05, 0), brick)
		_box(gate, "Cap", Vector3(0.7, 0.12, 0.7), Vector3(0, 2.16, 0), _mat("concrete", Color(0.26, 0.26, 0.25), 0.92))
		_collider_under(gate, "Collision", Vector3(0.65, 2.2, 0.65), Vector3(0, 1.1, 0))

	# dumpster pen behind the building
	var d := _node(p, "DumpsterPen")
	d.position = Vector3(13.6, 0, -9.0)
	var green := _mat("bin_green", Color(0.07, 0.11, 0.08), 0.7, 0.2)
	_box(d, "Dumpster", Vector3(2.5, 1.25, 1.5), Vector3(0, 0.73, 0), green)
	_box(d, "Lid", Vector3(2.55, 0.08, 1.6), Vector3(0, 1.4, -0.02), _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7), Vector3(-4, 0, 0))
	_box(d, "WheelA", Vector3(0.18, 0.18, 0.18), Vector3(-0.9, 0.09, 0.68), _mat("rubber", Color(0.015, 0.015, 0.018), 0.9))
	_box(d, "WheelB", Vector3(0.18, 0.18, 0.18), Vector3(0.9, 0.09, 0.68), _mat("rubber", Color(0.015, 0.015, 0.018), 0.9))
	_collider_under(d, "Collision", Vector3(2.6, 1.5, 1.7), Vector3(0, 0.75, 0))
	_fence_line(d, "PenWest", Vector2(-1.9, -1.6), Vector2(-1.9, 1.2))
	_fence_line(d, "PenEast", Vector2(1.9, -1.6), Vector2(1.9, 1.2))
	_fence_line(d, "PenBack", Vector2(-1.9, -1.6), Vector2(1.9, -1.6))


func _fence_line(parent: Node, name: String, from: Vector2, to: Vector2) -> void:
	var line := _node(parent, name)
	var metal := _mat("metal_dark", Color(0.055, 0.06, 0.065), 0.45, 0.7)
	var delta := to - from
	var length := delta.length()
	if length < 0.01:
		return
	var dir := delta / length
	var yaw := rad_to_deg(atan2(-dir.y, dir.x))
	var posts := maxi(int(ceil(length / 2.8)), 1)
	for i in posts + 1:
		var t := float(i) / float(posts)
		var point := from + delta * t
		_box(line, "Post", Vector3(0.09, 1.5, 0.09), Vector3(point.x, 0.75, point.y), metal)
	for h in [0.35, 0.85, 1.3]:
		_box(line, "Rail", Vector3(length, 0.055, 0.055), Vector3((from.x + to.x) * 0.5, h, (from.y + to.y) * 0.5), metal, Vector3(0, yaw, 0))

# ---------------------------------------------------------------------------
# HUD and player
# ---------------------------------------------------------------------------

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 5
	world.add_child(hud)

	var ui := Control.new()
	ui.name = "Root"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ui)

	var title := Label.new()
	title.name = "Title"
	title.text = "ХОКИНС  ·  ПОЛИЦЕЙСКИЙ УЧАСТОК"
	title.position = Vector2(32, 24)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.86, 0.77, 0.57))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.9))
	ui.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "ХОКИНС, ИНДИАНА  ·  НОЧНАЯ СМЕНА"
	subtitle.position = Vector2(33, 52)
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.55, 0.52))
	subtitle.add_theme_constant_override("outline_size", 4)
	subtitle.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.9))
	ui.add_child(subtitle)

	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.anchor_left = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_top = 1.0
	prompt.anchor_bottom = 1.0
	prompt.offset_left = -320
	prompt.offset_right = 320
	prompt.offset_top = -112
	prompt.offset_bottom = -78
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.95, 0.87, 0.68))
	prompt.add_theme_constant_override("outline_size", 8)
	prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	prompt.visible = false
	ui.add_child(prompt)

	var hint := Label.new()
	hint.name = "Hint"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 32
	hint.offset_top = -46
	hint.offset_right = 760
	hint.offset_bottom = -22
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.57))
	hint.add_theme_constant_override("outline_size", 4)
	hint.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.9))
	ui.add_child(hint)

	var cross := ColorRect.new()
	cross.name = "Crosshair"
	cross.anchor_left = 0.5
	cross.anchor_right = 0.5
	cross.anchor_top = 0.5
	cross.anchor_bottom = 0.5
	cross.offset_left = -2
	cross.offset_right = 2
	cross.offset_top = -2
	cross.offset_bottom = 2
	cross.color = Color(1, 1, 1, 0.5)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(cross)

	var fade_layer := CanvasLayer.new()
	fade_layer.name = "Fade"
	fade_layer.layer = 20
	world.add_child(fade_layer)
	var fade := ColorRect.new()
	fade.name = "Rect"
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)


func _build_player() -> void:
	var player: Node3D = load("res://scenes/Player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(DOOR_X, 0.06, 11.2)
	player.rotation_degrees.y = 0.0
	player.set("start_pitch_degrees", -2.0)
	world.add_child(player)
	instances.append(player)


# ---------------------------------------------------------------------------
# serialisation
# ---------------------------------------------------------------------------

func _own(node: Node) -> void:
	for child in node.get_children():
		child.owner = world
		if instances.has(child):
			continue
		_own(child)










