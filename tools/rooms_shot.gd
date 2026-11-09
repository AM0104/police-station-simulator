extends SceneTree

func _initialize() -> void:
	var station: Node3D = (load("res://scenes/Station.tscn") as PackedScene).instantiate()
	root.add_child(station)
	current_scene = station
	await create_timer(1.6).timeout
	var cam: Camera3D = _find_camera(station)
	cam.global_position = Vector3(0.0, 1.7, 7.6)
	cam.look_at(Vector3(0.0, 1.4, 0.0), Vector3.UP)
	cam.global_position = Vector3(6.8, 4.5, -4.2)
	cam.look_at(Vector3(6.8, 4.2, -6.3), Vector3.UP)
	cam.global_position = Vector3(6.8, 3.7, -3.6)
	cam.look_at(Vector3(6.8, 3.4, -6.2), Vector3.UP)
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("res://.tmp_check/office.png")
	quit()

func _find_camera(n: Node) -> Camera3D:
	if n is Camera3D:
		return n
	for c in n.get_children():
		var f := _find_camera(c)
		if f != null:
			return f
	return null
