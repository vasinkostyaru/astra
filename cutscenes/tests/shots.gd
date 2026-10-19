extends SceneTree
## Кадры ролика для проверки глазами.
## Запуск: SHOT_DIR=<папка> CUT_SCENE=res://cutscenes/intro.tscn CUT_TIMES=1.5,5.2 \
##         godot --path . --fixed-fps 60 --resolution 1280x720 -s cutscenes/tests/shots.gd

const DEFAULT_SCENE := "res://cutscenes/intro.tscn"
const DEFAULT_TIMES := "0.6,1.5,2.8,3.7,4.4,5.2,6.0,6.9,8.2,9.2,10.5,12.5,13.9"

var _frame: int = 0


func _initialize() -> void:
	_go.call_deferred()


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")


func _go() -> void:
	var path := OS.get_environment("CUT_SCENE")
	if path.is_empty():
		path = DEFAULT_SCENE
	var times_text := OS.get_environment("CUT_TIMES")
	if times_text.is_empty():
		times_text = DEFAULT_TIMES
	var times: Array[float] = []
	for part in times_text.split(","):
		times.append(float(part))
	var packed := load(path) as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	var prefix := path.get_file().get_basename()
	for t in times:
		var target := int(t * 60.0)
		while _frame < target:
			await process_frame
			_frame += 1
		await _shot("%s_%04.1f" % [prefix, t])
	quit()
