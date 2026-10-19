extends Node
## Просмотрщик роликов на ПК (не часть игры).
## 1–4 — ролики, 5–7 — переходы в разные комнаты, 0 — все подряд,
## пробел/клик — пропуск, Esc — выход. Подсказки только в заголовке окна и консоли.

const NAMES: Array[StringName] = [
	&"intro",
	&"transition",
	&"finale",
	&"second_round_start",
]
## 5–7 — тот же переход, но в другую комнату (для подгонки палитры).
const ROOMS: Array[StringName] = [&"bathroom", &"kitchen", &"living"]

var _sequencing: bool = false
var _steps: Array[Dictionary] = []
var _step: int = 0


func _ready() -> void:
	DisplayServer.window_set_title(
		"1 intro | 2 transition | 3 finale | 4 second | 5-7 комнаты | 0 всё подряд | пробел — пропуск | Esc — выход")
	print("cutscenes preview: 1 intro | 2 transition | 3 finale | 4 second_round_start | 5-7 комнаты | 0 — всё по очереди")
	Cutscenes.finished.connect(_on_finished)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_4:
		_stop_sequence()
		_play(NAMES[key - KEY_1])
	elif key >= KEY_5 and key <= KEY_7:
		_stop_sequence()
		_play(&"transition", {"room": ROOMS[key - KEY_5]})
	elif key == KEY_0:
		_start_sequence()
	elif key == KEY_ESCAPE:
		get_tree().quit()


func _play(name: StringName, params: Dictionary = {}) -> void:
	if Cutscenes.play(name, params):
		print("cutscenes preview: играем ", name, " ", params)
	else:
		print("cutscenes preview: ролика ", name, " пока нет")


## Все ролики подряд, как они идут в игре: intro → переходы → финал → второй круг.
func _start_sequence() -> void:
	# Сначала гасим текущий ролик, не давая его finished запустить следующий шаг.
	_sequencing = false
	if Cutscenes.is_playing:
		Cutscenes.skip()
	_steps = []
	if Cutscenes.SCENES.has(&"intro"):
		_steps.append({"name": &"intro"})
	if Cutscenes.SCENES.has(&"transition"):
		for room in ROOMS:
			_steps.append({"name": &"transition", "params": {"room": room}})
	for name: StringName in [&"finale", &"second_round_start"]:
		if Cutscenes.SCENES.has(name):
			_steps.append({"name": name})
	if _steps.is_empty():
		return
	_sequencing = true
	_step = 0
	_play_next()


func _stop_sequence() -> void:
	_sequencing = false


func _play_next() -> void:
	if not _sequencing:
		return
	if _step >= _steps.size():
		_sequencing = false
		print("cutscenes preview: все ролики проиграны")
		return
	var step: Dictionary = _steps[_step]
	_step += 1
	_play(step["name"], step.get("params", {}))


func _on_finished(_name: StringName) -> void:
	if _sequencing:
		_play_next()
