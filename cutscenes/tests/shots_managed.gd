extends SceneTree
## Проверка управляемого показа: ролик идёт в SubViewport поверх «игры».
## Запуск: SHOT_DIR=<папка> godot --path . --fixed-fps 60 --resolution 1280x720 -s cutscenes/tests/shots_managed.gd

const TIMES: Array[float] = [1.5, 5.2, 8.4]

var _frame: int = 0


func _initialize() -> void:
	_go.call_deferred()


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")


func _wait_to(seconds: float) -> void:
	var target := int(seconds * 60.0)
	while _frame < target:
		await process_frame
		_frame += 1


func _go() -> void:
	var packed := load("res://cutscenes/preview.tscn") as PackedScene
	var fake := packed.instantiate()
	root.add_child(fake)
	current_scene = fake
	for i in 5:
		await process_frame
	await _shot("managed_before")

	var cutscenes := root.get_node("Cutscenes")
	cutscenes.play(&"intro")
	for t in TIMES:
		await _wait_to(t)
		await _shot("managed_%04.1f" % t)

	# Пропуск: сразу видно «игру», ролик погас.
	cutscenes.skip()
	await _shot("managed_after_skip")
	await _wait_to(12.0)
	await _shot("managed_after_skip_later")
	print("MANAGED OK: playing=", cutscenes.is_playing)
	quit()
