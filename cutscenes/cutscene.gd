class_name Cutscene
extends Node3D
## Базовый ролик: общий таймлайн, пропуск и финальное состояние мира.
##
## Ролик — это сцена с этим скриптом (или его наследником) и одинаковым скелетом узлов:
##   CamRig/Camera3D   — камера на «рельсе»: цель взгляда — CamRig, расстояние — Camera3D.position.z
##   Set               — комната и мебель (её можно масштабировать для «уменьшения» героев)
##   Heroes            — Август и Астра (сюда их ставит ролик)
##   Props             — ягодки, вспышки, блёстки (в общем масштабе, не в Set)
##   Fade/Rect         — чёрная шторка для плавного входа и выхода
##   CutAudio          — синтезированные звуки
##
## Тайминги ролика — «реплики» на абсолютных временах: at(t, _bit). Пропуск в любой момент
## убивает твины, применяет _apply_final_state() и шлёт finished: мир остаётся в том же
## состоянии, что и после полного просмотра.

signal finished

const SPARKLES_SCENE := preload("res://cutscenes/props/sparkles.tscn")

## Имя для консоли; в игре нигде не показывается.
@export var cutscene_name: String = "cutscene"
## Полная длительность ролика, с (время последнего затемнения/кадра).
@export var duration: float = 15.0

## true — роликом управляет автолоад Cutscenes (SubViewport поверх игры).
var managed: bool = false
var running: bool = false
var done: bool = false

## Параметры ролика (например, комната для перехода). Автолоад ставит их до add_child,
## чтобы _prepare() уже их видел; при самостоятельном запуске словарь пуст.
var params: Dictionary = {}
var _cues: Array[Dictionary] = []
var _tweens: Array[Tween] = []
var _timeline: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_prepare()
	if not managed:
		finished.connect(_restart_when_standalone)
		start()


## Собрать декорации и героев (переопределяется роликом).
func _prepare() -> void:
	pass


## Построить таймлайн (переопределяется роликом): at(секунда, метод).
func _build() -> void:
	pass


## Привести мир к состоянию «ролик досмотрен» — контракт с пропуском.
func _apply_final_state() -> void:
	pass


func start(play_params: Dictionary = {}) -> void:
	if running or done:
		return
	params = play_params
	running = true
	_build()
	# Реплики могут быть добавлены в любом порядке — играем по времени.
	var cues := _cues.duplicate()
	cues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.t) < float(b.t))
	_timeline = new_tween()
	var time := 0.0
	for cue: Dictionary in cues:
		var beat := maxf(float(cue.t), time)
		if beat > time:
			_timeline.tween_interval(beat - time)
			time = beat
		_timeline.tween_callback(cue.c)
	var tail := maxf(duration, time)
	if tail > time:
		_timeline.tween_interval(tail - time)
	_timeline.tween_callback(_end)


## Любое касание (на ПК — клик, пробел или Enter) пропускает ролик.
func skip() -> void:
	if done or not running:
		return
	kill_tweens()
	_apply_final_state()
	_finish()


## Свой твин ролика: его убьёт skip().
func new_tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


func kill_tweens() -> void:
	for tw: Tween in _tweens:
		if tw.is_valid():
			tw.kill()
	_tweens.clear()
	_timeline = null


## Реплика ролика: выполнить action в секунду time.
func at(time: float, action: Callable) -> void:
	_cues.append({"t": time, "c": action})


# --- общие биты ------------------------------------------------------------

## Камера на «рельсе»: цель взгляда target, расстояние dist по оси Z.
func cam_to(target: Vector3, dist: float, sec: float) -> void:
	var rig := get_node_or_null("CamRig") as Node3D
	var cam := get_node_or_null("CamRig/Camera3D") as Camera3D
	if rig == null or cam == null:
		return
	if sec <= 0.0:
		rig.position = target
		cam.position = Vector3(0.0, 0.0, dist)
		return
	var tw := new_tween()
	tw.set_parallel(true)
	tw.tween_property(rig, "position", target, sec) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "position", Vector3(0.0, 0.0, dist), sec) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Шторка: 1 — чёрный экран, 0 — видно сцену.
func fade_to(alpha: float, sec: float) -> void:
	var rect := get_node_or_null("Fade/Rect") as ColorRect
	if rect == null:
		return
	if sec <= 0.0:
		rect.color.a = alpha
		return
	new_tween().tween_property(rect, "color:a", alpha, sec)


func scale_to(node: Node3D, to: Vector3, sec: float, ease: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	var tw := new_tween()
	tw.tween_property(node, "scale", to, sec).set_trans(Tween.TRANS_CUBIC).set_ease(ease)
	return tw


## Пройти по X с анимацией (Астре для «ходьбы» — run со speed_scale 0.5).
func walk_x(who: Node3D, to_x: float, sec: float, state: StringName = &"walk", speed := 1.0) -> Tween:
	CutActors.play(who, state, speed)
	var tw := new_tween()
	tw.tween_property(who, "position:x", to_x, sec) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


## «Оглянуться» (Астра): разворот модели на ~150° за 0.3 с, пауза 0.5 с и возврат.
## Крутится только модель — позицию ролик продолжает вести сам.
func astra_look_back(who: Node3D, from_dir: float, turn_deg: float = 150.0,
		dur: float = 0.3, hold: float = 0.5) -> Tween:
	var model := who.get_node_or_null("Model") as Node3D
	if model == null:
		return null
	CutActors.play(who, &"idle")
	var start_angle := from_dir * PI * 0.5
	# Разворот в сторону камеры: от профиля к «лицом к экрану» и дальше.
	var mid := start_angle - signf(from_dir) * deg_to_rad(turn_deg)
	var tw := new_tween()
	tw.tween_property(model, "rotation:y", mid, dur).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(hold)
	tw.tween_property(model, "rotation:y", start_angle, dur).set_trans(Tween.TRANS_SINE)
	return tw


## Прыжок по дуге: «клип run + движение по дуге» для Астры, jump/fall для Августа.
func arc_move(who: Node3D, to: Vector3, sec: float, arc: float,
		state: StringName = &"jump", speed := 1.0) -> Tween:
	CutActors.play(who, state, speed)
	var from := who.position
	var tw := new_tween()
	tw.tween_method(func(t: float) -> void:
		who.position = from.lerp(to, t) + Vector3.UP * (arc * 4.0 * t * (1.0 - t)), 0.0, 1.0, sec)
	return tw


## Вспышка в точке: маленькая светящаяся сфера раздувается и гаснет.
func flash_at(pos: Vector3, color: Color, max_scale: float = 1.5) -> void:
	var props := get_node_or_null("Props") as Node3D
	if props == null:
		return
	var mi := CutSet.add_sphere(props, "Flash", 0.09, Vector3.ZERO, CutSet.glow(color, 3.0), 16)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.2
	var tw := new_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * max_scale, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3.ZERO, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)


## Залп блёсток в точке (частицы удаляются сами).
func sparkles_at(pos: Vector3, color := Color(1.0, 0.88, 0.55), amount := 36) -> void:
	var props := get_node_or_null("Props") as Node3D
	if props == null:
		return
	var sparks := SPARKLES_SCENE.instantiate() as CutSparkles
	sparks.color = color
	sparks.amount = amount
	props.add_child(sparks)
	sparks.global_position = pos
	sparks.burst()
	var tw := new_tween()
	tw.tween_interval(2.4)
	tw.tween_callback(sparks.queue_free)


# --- служебное -------------------------------------------------------------

func _end() -> void:
	if done:
		return
	_apply_final_state()
	_finish()


func _finish() -> void:
	if done:
		return
	done = true
	running = false
	print("[cutscene] %s finished" % cutscene_name)
	finished.emit()


## Самостоятельный запуск (godot cutscenes/intro.tscn): после конца играем заново,
## чтобы удобно было смотреть и подгонять. Под управлением Cutscenes не используется.
func _restart_when_standalone() -> void:
	if managed:
		return
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()


## Перед удалением снимаем временные материалы героев — чтобы сцена освобождалась чисто.
func _exit_tree() -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			mi.set_surface_override_material(surface, null)
		mi.material_override = null


func _input(event: InputEvent) -> void:
	if managed or not running:
		return
	if is_skip_event(event):
		get_viewport().set_input_as_handled()
		skip()


## Общее правило пропуска: касание в любом месте; на ПК ещё клик/пробел/Enter.
static func is_skip_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventKey:
		return event.pressed and not event.echo \
			and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)
	return false
