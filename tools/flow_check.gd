extends SceneTree

func _initialize() -> void:
	var inst: Node3D = (load("res://scenes/HawkinsStation.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	current_scene = inst
	await create_timer(0.8).timeout
	var player: CharacterBody3D = inst.get_node("Player")
	player.global_position = Vector3(5.45, 0.06, 1.5)
	var cam: Camera3D = player.get_node("Head/Camera3D")
	cam.look_at_from_position(Vector3(5.45, 1.45, 1.6), Vector3(5.45, 1.3, 0.0), Vector3.UP)
	await physics_frame
	await physics_frame
	player.call("_update_interaction_ray")
	var target: Node3D = player.call("get_focused_interactable")
	print("TARGET=", target.name if target != null else "none")
	player.emit_signal("interact_requested", target)
	await create_timer(3.5).timeout
	print("CURRENT=", current_scene.name if current_scene != null else "none")
	_dump(root)
	root.get_texture().get_image().save_png("res://.tmp_check/real_transition.png")
	quit()

func _dump(n: Node) -> void:
	if n is CanvasLayer:
		print("CANVAS name=", n.name, " layer=", n.layer)
	for c in n.get_children():
		_dump(c)
