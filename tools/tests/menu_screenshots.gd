extends SceneTree
## Скриншоты экранов меню: SHOT_DIR=<папка> godot --path . --resolution 1280x720 -s $PWD/tools/tests/menu_screenshots.gd
func _initialize() -> void:
	_run.call_deferred()
func _shot(n: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + n + ".png")
func _run() -> void:
	var s = load("res://scenes/ui/start_screen.tscn").instantiate()
	root.add_child(s)
	for i in 30: await process_frame
	await create_timer(0.5).timeout
	await _shot("start")
	s.queue_free()
	root.get_node("Game").completed_levels.append(0)
	var r = load("res://scenes/ui/room_select.tscn").instantiate()
	root.add_child(r)
	for i in 40: await process_frame
	await _shot("rooms")
	quit()
