class_name Level
extends Node3D
## Общая логика уровня: собираем ягодки в банку. Собрал нужное количество — загорается главный светильник
## (праздник), а выход ждёт у Астры. Свет в комнате с самого начала включён.

signal completed

@export var player: Player
@export var hud: Hud
@export var main_lamp: Node3D  ## MainLamp, MirrorLights и т.п.: что умеет turn_on()
## Астра-проводник; подошёл к ней на выходе — уровень пройден.
@export var astra: Astra
## Сколько ягодок нужно для праздника; 0 — все на уровне.
@export_range(0, 100) var berries_needed: int = 0
## Если berries_needed = 0: доля ягодок уровня для праздника (не все — часть можно пропустить).
@export_range(0.1, 1.0) var needed_share: float = 0.8
@export var fall_limit_y: float = -6.0

var _required: int = 0
var _collected: int = 0
var _done: bool = false
var _completed: bool = false


func _ready() -> void:
	var total := 0
	for node in get_tree().get_nodes_in_group(&"berries"):
		var berry := node as Berry
		if berry:
			berry.collected.connect(_on_berry_collected)
			total += 1
	_required = berries_needed if berries_needed > 0 else int(ceil(total * needed_share))
	_required = maxi(mini(_required, total), 1)
	hud.jar.total = _required
	player.fall_limit_y = fall_limit_y
	Fx.grade(self)
	Game.play_level_music()
	if astra:
		astra.reached_by_player.connect(_on_level_completed)


func _on_berry_collected(berry: Berry) -> void:
	_collected += 1
	Game.play_chime(_collected)
	var cam := get_viewport().get_camera_3d()
	if cam:
		hud.fly_berry_to_jar(cam.unproject_position(berry.global_position), berry.get_color())
	if _collected >= _required and not _done:
		_done = true
		# Ждём, пока последняя ягодка долетит до банки.
		get_tree().create_timer(0.8).timeout.connect(_on_all_collected)


func _on_all_collected() -> void:
	main_lamp.call(&"turn_on")
	hud.jar.set_complete()
	player.celebrate()
	Game.play_fanfare()


func _on_level_completed() -> void:
	if _completed:
		return
	_completed = true
	completed.emit()
	player.celebrate()
	Game.play_fanfare()
	Game.complete_level()
	await get_tree().create_timer(1.6).timeout
	await hud.fade_out()
	# Ролик-переход в следующую комнату (уровень уже затемнён, ролик начинается с чёрного).
	# 0 детская → ванная, 1 ванная → кухня, 2 кухня → гостиная; после гостиной перехода пока нет.
	var next_rooms: Array[StringName] = [&"bathroom", &"kitchen", &"living"]
	if Game.current_level + 1 >= Game.LEVELS.size():
		# Последняя комната: финальный ролик, потом выбор комнаты (Game.go_to_next_level ведёт туда).
		Cutscenes.play(&"finale")
		await Cutscenes.finished
	elif Game.current_level < next_rooms.size():
		Cutscenes.play(&"transition", {"room": next_rooms[Game.current_level]})
		await Cutscenes.finished
	Game.go_to_next_level()
