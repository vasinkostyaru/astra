extends MenuScreen
## Стартовый экран: большая кнопка «играть». Через весь экран туда-сюда с паузами бегает
## Астра, а Август бежит за ней.

const CAT_SPEED := 2.6     # м/с
## На сколько Астра впереди Августа, м: каждый раз случайно в этих пределах.
const GAP_MIN := 0.8
const GAP_MAX := 3.2
const ASTRA_ANIM_SCALE := 1.0
const AVGUST_ANIM_SCALE := 1.4
const PAUSE := 2.5        # пауза между пробежками, с

@onready var _camera: Camera3D = $Camera3D
@onready var _avgust: Node3D = $Avgust
@onready var _astra: Node3D = $Astra

var _play: PictureButton


func _ready() -> void:
	build_ui()
	_play = PictureButton.new()
	_play.breathe = true
	_play.pressed.connect(func() -> void: leave(Game.go_to_rooms))
	ui.add_child(_play)
	ui.get_viewport().size_changed.connect(_layout)
	_layout()
	_astra.add_child(($Avgust/Shadow as Node3D).duplicate())
	(_astra.get_child(-1) as Node3D).scale = Vector3.ONE * 0.5
	_avgust.hide()
	_astra.hide()
	_run_loop.call_deferred()


func _layout() -> void:
	var vs := ui.get_viewport().get_visible_rect().size
	var d := vs.y * 0.42
	_play.size = Vector2(d, d)
	_play.position = Vector2(vs.x * 0.66 - d * 0.5, vs.y * 0.5 - d * 0.5)


## Точка на земле в нужной доле ширины экрана (за краем — меньше 0 или больше 1).
func _ground_at(fraction: float) -> Vector3:
	var vs := ui.get_viewport().get_visible_rect().size
	return _camera.project_position(Vector2(vs.x * fraction, vs.y * 0.88), 2.7)


## Туда-сюда без конца: пробежка в одну сторону, пауза, разворот и пробежка обратно.
func _run_loop() -> void:
	var direction := 1.0
	await get_tree().create_timer(0.6).timeout
	while is_inside_tree():
		await _run_across(direction)
		direction = -direction
		await get_tree().create_timer(PAUSE).timeout


## Астра бежит первой, Август стартует позже, чтобы между ними оставался случайный промежуток.
## direction: 1 — слева направо, -1 — справа налево. Возвращается, когда Август скрылся за краем.
func _run_across(direction: float) -> void:
	var gap := randf_range(GAP_MIN, GAP_MAX)
	var start := _ground_at(-0.12 if direction > 0.0 else 1.12)
	var finish_x := _ground_at(1.12 if direction > 0.0 else -0.12).x + direction * gap
	var duration := absf(finish_x - start.x) / CAT_SPEED
	_start_runner(_astra, &"run", ASTRA_ANIM_SCALE, start, finish_x, duration, 0.0, direction)
	var tw := _start_runner(_avgust, &"walk", AVGUST_ANIM_SCALE, start, finish_x, duration, gap / CAT_SPEED, direction)
	await tw.finished


func _start_runner(who: Node3D, anim: StringName, anim_scale: float, from: Vector3, to_x: float,
		duration: float, delay: float, direction: float) -> Tween:
	var players := who.find_children("*", "AnimationPlayer", true, false)
	var ap: AnimationPlayer = players[0] as AnimationPlayer if not players.is_empty() else null
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		who.global_position = from
		# Модели смотрят вправо при повороте на +90°, влево — на -90°.
		(who.get_node_or_null("Model") as Node3D if who == _astra else who).rotation.y = direction * PI * 0.5
		who.show()
		if ap and ap.has_animation(anim):
			ap.speed_scale = anim_scale
			ap.play(anim))
	tw.tween_property(who, "global_position:x", to_x, duration)
	tw.tween_callback(who.hide)
	return tw
