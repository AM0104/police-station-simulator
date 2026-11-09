extends SceneTree

func _initialize() -> void:
	var station: Node3D = (load("res://scenes/Station.tscn") as PackedScene).instantiate()
	root.add_child(station)
	current_scene = station
	await process_frame
	await create_timer(0.4).timeout
	_lights(station)
	quit()

func _lights(n: Node) -> void:
	if n is OmniLight3D:
		print(n.get_path(), " pos=", n.global_position, " e=", n.light_energy, " r=", n.omni_range)
	for c in n.get_children():
		_lights(c)
