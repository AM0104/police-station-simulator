extends SceneTree

func _initialize() -> void:
	var station: Node3D = (load("res://scenes/Station.tscn") as PackedScene).instantiate()
	root.add_child(station)
	await create_timer(3.0).timeout
	root.get_texture().get_image().save_png("res://.tmp_check/station_direct.png")
	print("ENV=", station.get_node("WorldEnvironment").environment)
	quit()
