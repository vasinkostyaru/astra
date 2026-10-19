extends SceneTree
## Кадры ролика intro для проверки глазами.
## Запуск: SHOT_DIR=<папка> godot --path . --fixed-fps 60 --resolution 1280x720 -s cutscenes/tests/shots.gd

const TIMES: Array[float] = [0.6, 1.5, 2.8, 3.7, 4.4, 5.2, 6.0, 6.9, 8.2, 9.2, 10.5, 12.5, 13.9]

var _frame: int = 0


func _initialize() -> void:
	_go.call_deferred()


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")


func _go() -> void:
	var packed := load("res://cutscenes/intro.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for t in TIMES:
		var target := int(t * 60.0)
		while _frame < target:
			await process_frame
			_frame += 1
		await _shot("intro_%04.1f" % t)
	quit()
