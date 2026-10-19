class_name Level
extends Node3D
## Общая логика уровня: собираем ягодки в банку. Собрал нужное количество — загорается главный светильник
## (праздник), а выход ждёт у Астры. Свет в комнате с самого начала включён.

signal completed

@export var player: Player
@export var hud: Hud
@export var main_lamp: MainLamp
## Астра-проводник; подошёл к ней на выходе — уровень пройден.
@export var astra: Astra
## Сколько ягодок нужно для праздника; 0 — все на уровне.
@export_range(0, 100) var berries_needed: int = 0
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
	_required = berries_needed if berries_needed > 0 else total
	_required = maxi(mini(_required, total), 1)
	hud.jar.total = _required
	player.fall_limit_y = fall_limit_y
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
	main_lamp.turn_on()
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
	Game.go_to_next_level()
