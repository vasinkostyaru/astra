extends SceneTree
## Проверка проигрывателя роликов: полный просмотр, пропуск, повторный запуск.
## Запуск: godot --headless --path . --fixed-fps 60 -s cutscenes/tests/smoke.gd

var _dummy: Node


func _initialize() -> void:
	_go.call_deferred()


func _fail(text: String) -> void:
	printerr("SMOKE FAIL: ", text)
	quit(1)


func _go() -> void:
	var cutscenes := root.get_node_or_null("Cutscenes")
	if cutscenes == null:
		_fail("нет автолоада Cutscenes")
		return
	_dummy = Node.new()
	_dummy.name = "FakeGameScene"
	root.add_child(_dummy)
	current_scene = _dummy
	var finished: Array[StringName] = []
	cutscenes.finished.connect(func(name: StringName) -> void: finished.append(name))

	# 1. Полный просмотр: ролик доходит до конца, игра заморожена и оживает.
	cutscenes.play(&"intro")
	await process_frame
	if not cutscenes.is_playing:
		_fail("play не начался")
		return
	if _dummy.process_mode != Node.PROCESS_MODE_DISABLED:
		_fail("игра не заморожена на время ролика")
		return
	var frames := 0
	while cutscenes.is_playing and frames < 60 * 25:
		await process_frame
		frames += 1
	if cutscenes.is_playing:
		_fail("ролик завис")
		return
	if finished.size() != 1 or finished[0] != &"intro":
		_fail("нет сигнала finished(intro): %s" % str(finished))
		return
	if _dummy.process_mode == Node.PROCESS_MODE_DISABLED:
		_fail("игра осталась замороженной")
		return
	print("SMOKE: полный просмотр ok (", frames, " кадров)")

	# 2. Пропуск: сразу finished и управление возвращается.
	finished.clear()
	cutscenes.play(&"intro")
	await process_frame
	await process_frame
	cutscenes.skip()
	if cutscenes.is_playing:
		_fail("после skip ролик всё ещё идёт")
		return
	if finished.size() != 1 or finished[0] != &"intro":
		_fail("skip не дал finished(intro): %s" % str(finished))
		return
	if _dummy.process_mode == Node.PROCESS_MODE_DISABLED:
		_fail("после skip игра заморожена")
		return
	print("SMOKE: пропуск ok")

	# 3. Повторный запуск и was_played.
	if not cutscenes.was_played(&"intro"):
		_fail("was_played(intro) = false")
		return
	finished.clear()
	cutscenes.play(&"intro")
	await process_frame
	cutscenes.play(&"intro")
	await process_frame
	cutscenes.skip()
	if cutscenes.is_playing:
		_fail("повторный play сломал проигрыватель")
		return
	if finished.size() != 2:
		_fail("повторный play: ожидалось 2 finished, получено %d" % finished.size())
		return
	print("SMOKE: повторный play ok")

	if paused:
		_fail("дерево осталось на паузе")
		return
	print("SMOKE OK")
	quit(0)
