class_name Level
extends Node3D
## Общая логика уровня: свет как прогресс. Каждая искорка делает сцену светлее,
## собрал нужное количество — загорается главный светильник.

@export var player: Player
@export var hud: Hud
@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
## Светильники уровня (Light3D-дети), которые разгораются вместе с искорками.
@export var level_lights: Node3D
@export var main_lamp: MainLamp
## Сколько искорок нужно для главного светильника; 0 — все на уровне.
@export_range(0, 100) var sparks_needed: int = 0
@export var ambient_dark: float = 0.12
@export var ambient_lit: float = 0.7
@export var sun_dark: float = 0.1
@export var sun_lit: float = 0.7
## Доля яркости светильников уровня в начале.
@export_range(0.0, 1.0) var lights_dark_factor: float = 0.15
@export var fall_limit_y: float = -6.0

var _required: int = 0
var _collected: int = 0
var _light: float = 0.0
var _done: bool = false
var _light_bases: Dictionary = {}  # Light3D -> исходная энергия


func _ready() -> void:
	var total := 0
	for node in get_tree().get_nodes_in_group(&"sparks"):
		var spark := node as Spark
		if spark:
			spark.collected.connect(_on_spark_collected)
			total += 1
	_required = sparks_needed if sparks_needed > 0 else total
	_required = maxi(mini(_required, total), 1)
	hud.jar.total = _required

	if level_lights:
		for child in level_lights.get_children():
			if child is Light3D:
				_light_bases[child] = (child as Light3D).light_energy
	_apply_light(0.0)
	player.fall_limit_y = fall_limit_y


func _on_spark_collected(spark: Spark) -> void:
	_collected += 1
	Game.play_chime(_collected)
	var cam := get_viewport().get_camera_3d()
	if cam:
		hud.fly_spark_to_jar(cam.unproject_position(spark.global_position))
	var t := clampf(float(_collected) / _required, 0.0, 1.0)
	create_tween().tween_method(_apply_light, _light, t, 0.8).set_trans(Tween.TRANS_SINE)
	if _collected >= _required and not _done:
		_done = true
		# Ждём, пока последняя искорка долетит до банки.
		get_tree().create_timer(0.8).timeout.connect(_on_all_collected)


func _on_all_collected() -> void:
	main_lamp.turn_on()
	hud.jar.set_complete()
	player.celebrate()
	Game.play_fanfare()


func _apply_light(t: float) -> void:
	_light = t
	var env := world_environment.environment
	env.ambient_light_energy = lerpf(ambient_dark, ambient_lit, t)
	sun.light_energy = lerpf(sun_dark, sun_lit, t)
	for light: Light3D in _light_bases:
		light.light_energy = _light_bases[light] * lerpf(lights_dark_factor, 1.0, t)
