extends Node
## Просмотрщик роликов на ПК (не часть игры): клавиши 1–4 запускают ролики,
## пробел/клик — пропустить, Esc — выйти. Подсказки только в заголовке окна и консоли.

const NAMES: Array[StringName] = [
	&"intro",
	&"transition",
	&"finale",
	&"second_round_start",
]


func _ready() -> void:
	DisplayServer.window_set_title(
		"cutscenes: 1 intro | 2 transition | 3 finale | 4 second_round_start | пробел — пропуск | Esc — выход")
	print("cutscenes preview: 1 intro | 2 transition | 3 finale | 4 second_round_start")


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_4:
		var name: StringName = NAMES[key - KEY_1]
		if Cutscenes.SCENES.has(name) and Cutscenes.play(name):
			print("cutscenes preview: играем ", name)
		else:
			print("cutscenes preview: ролика ", name, " пока нет")
	elif key == KEY_ESCAPE:
		get_tree().quit()
