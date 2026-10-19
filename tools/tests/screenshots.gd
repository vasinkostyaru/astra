extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _shot(n: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + n + ".png")
func _run() -> void:
	var level = load("res://levels/level_01_kids_room.tscn").instantiate()
	root.add_child(level)
	for i in 50: await physics_frame
	await _shot("astra_start")
	Input.action_press(&"move_right")
	for i in 70: await physics_frame
	await _shot("astra_running")
	Input.action_release(&"move_right")
	var p: Node3D = level.get_node("Player")
	level._apply_light(1.0)
	p.global_position = Vector3(16.0, 2.4, 0); p.reset_physics_interpolation()
	for i in 200: await physics_frame
	var cam = level.get_node("SideCamera")
	cam.global_position = cam._desired_position(p.global_position)
	for i in 5: await physics_frame
	await _shot("astra_exit")
	quit()
