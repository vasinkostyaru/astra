extends SceneTree
## Все ролики подряд без пропусков: проверяет цепочку play → finished → play.
## Запуск: godot --headless --path . --fixed-fps 60 -s cutscenes/tests/sequence.gd

var _done: Array[StringName] = []


func _initialize() -> void:
	_go.call_deferred()


func _fail(text: String) -> void:
	printerr("SEQUENCE FAIL: ", text)
	quit(1)


func _go() -> void:
	var cutscenes := root.get_node_or_null("Cutscenes")
	if cutscenes == null:
		_fail("нет автолоада Cutscenes")
		return
	var dummy := Node.new()
	dummy.name = "FakeGameScene"
	root.add_child(dummy)
	current_scene = dummy
	cutscenes.finished.connect(func(name: StringName) -> void: _done.append(name))

	var steps: Array = [
		[&"intro", {}],
		[&"transition", {"room": &"bathroom"}],
		[&"transition", {"room": &"kitchen"}],
		[&"transition", {"room": &"living"}],
	]
	for step: Array in steps:
		var before := _done.size()
		if not cutscenes.play(step[0], step[1]):
			_fail("не запустился %s" % step[0])
			return
		if _done.size() != before:
			_fail("finished пришёл сразу у %s" % step[0])
			return
		var frames := 0
		while cutscenes.is_playing and frames < 60 * 25:
			await process_frame
			frames += 1
		if cutscenes.is_playing:
			_fail("завис %s" % step[0])
			return
		if _done.size() != before + 1:
			_fail("нет finished у %s" % step[0])
			return
		print("SEQUENCE: ", step[0], " ", step[1], " ok (", frames, " кадров)")
	print("SEQUENCE OK")
	quit(0)
