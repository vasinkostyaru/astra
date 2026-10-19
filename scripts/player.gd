class_name Player
extends CharacterBody3D
## Август: ходьба по X и прыжок, ось Z заблокирована.
## Внешний вид — дочерний узел Model: его можно заменить на импортированный GLB без правок кода.
## Анимации idle/walk/jump/fall/happy ищутся в AnimationPlayer внутри Model; если анимации нет — пропускаем.

signal respawned

@export var move_speed: float = 4.0
@export var acceleration: float = 30.0
@export var jump_height: float = 1.4
@export var gravity: float = 22.0
@export var max_fall_speed: float = 14.0
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15
## Ниже этой высоты — мягкое возвращение к чекпоинту (запасной вариант, если упал за пределы уровня).
@export var fall_limit_y: float = -6.0
## Возврат к чекпоинту: насколько выше самой высокой опоры на пути вершина дуги
## и «гравитация» полёта (меньше — дольше и плавнее парит).
@export var return_arc_height: float = 1.5
@export var return_gravity: float = 14.0

@onready var model: Node3D = $Model

var respawn_point: Vector3

var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
## 0 — смотрит вправо, 1 — влево; поворот идёт через «лицом к камере».
var _turn: float = 0.0
var _turn_target: float = 0.0
var _controls_locked: bool = false
var _celebrating: bool = false
var _model_scale: Vector3
var _anim_player: AnimationPlayer
var _stretch_tween: Tween
var _current_anim: StringName = &""
var _was_on_floor: bool = true
## Толчок (горка): пока _push_left > 0, едет со скоростью _push_speed, ввод не мешает.
var _push_left: float = 0.0
var _push_speed: float = 0.0
var _fall_speed: float = 0.0
var _dust_left: float = 0.0


func _ready() -> void:
	respawn_point = global_position
	_model_scale = model.scale
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim_player = players[0] as AnimationPlayer


func _physics_process(delta: float) -> void:
	if _controls_locked:
		return

	var dir := Input.get_axis(&"move_left", &"move_right")
	if _push_left > 0.0:
		_push_left -= delta
		velocity.x = _push_speed
	else:
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)

	if is_on_floor():
		_coyote_left = coyote_time
	else:
		_coyote_left -= delta
		velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)

	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_left = jump_buffer_time
	else:
		_jump_buffer_left -= delta

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = sqrt(2.0 * gravity * jump_height)
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
		_jump_stretch()

	velocity.z = 0.0
	move_and_slide()
	position.z = 0.0

	if global_position.y < fall_limit_y:
		return_to_checkpoint()
		return

	_update_facing(dir, delta)
	_update_animation()
	_update_juice(delta)


## Горка: «с ветерком» едет вперёд со скоростью speed в течение time секунд.
func push(speed: float, time: float) -> void:
	if _controls_locked:
		return
	_push_speed = speed
	_push_left = time


## Подбросило (батут): взлетает на height, как при прыжке, но выше.
func bounce(height: float) -> void:
	if _controls_locked:
		return
	velocity.y = sqrt(2.0 * gravity * height)
	_coyote_left = 0.0
	_jump_stretch()


func set_checkpoint(point: Vector3) -> void:
	respawn_point = point


## Падение без проигрыша: Август плавной дугой перелетает к последнему чекпоинту.
## Что его подбрасывает (подушка, круг, пузырь), решает уровень; полёт у всех один.
func return_to_checkpoint() -> void:
	if _controls_locked:
		return
	_controls_locked = true
	velocity = Vector3.ZERO
	_jump_buffer_left = 0.0
	_push_left = 0.0
	_launch_return()


## Мягкая поверхность поймала Августа: встал на неё, промялся вместе с ней — и полетел к чекпоинту.
func catch_on(surface_y: float, sink: float, sink_time: float) -> void:
	if _controls_locked:
		return
	_controls_locked = true
	velocity = Vector3.ZERO
	_jump_buffer_left = 0.0
	global_position.y = surface_y
	_play(&"idle")
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(self, "global_position:y", surface_y - sink, sink_time).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_launch_return)


func _launch_return() -> void:
	var from := global_position
	var to := respawn_point + Vector3.UP * 0.05
	var ground := _ground_profile(from.x, to.x)
	var top := maxf(from.y, to.y) + return_arc_height
	for x: float in ground:
		top = maxf(top, ground[x] + return_arc_height)
	# Баллистика, как у брошенного мяча: взлёт до вершины top и падение на чекпоинт.
	# Если дуга задевает мебель — поднимаем вершину.
	var arc := _make_arc(from, to, top)
	for i in 6:
		if _arc_clears(arc, ground):
			break
		top += 0.5
		arc = _make_arc(from, to, top)
	var duration: float = arc.duration
	_turn_target = 0.0 if to.x >= from.x else 1.0
	_play(&"jump")

	var fly := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	fly.tween_method(_fly_step.bind(arc), 0.0, duration, duration)
	# Лёгкое приседание при приземлении (модель не растягиваем — у живого персонажа это выглядит странно).
	fly.tween_property(model, "scale", _model_scale * Vector3(1.04, 0.95, 1.04), 0.07)
	fly.tween_property(model, "scale", _model_scale, 0.15).set_trans(Tween.TRANS_SINE)
	fly.tween_callback(_finish_return)


## Радость: прыжки на месте (или анимация happy, если она есть у модели).
func celebrate() -> void:
	_celebrating = true
	_play(&"happy")
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# Четыре прыжка по 0.5 с — ровно два цикла анимации happy (1 с).
	for i in 4:
		tw.tween_property(model, "position:y", 0.3, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(model, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _celebrating = false)


func _fly_step(time: float, arc: Dictionary) -> void:
	global_position = _arc_point(arc, time)
	# «jump» короткая и не зациклена — после вершины дуги переходим на зацикленное «fall»,
	# иначе поза застывает на последнем кадре прыжка.
	_play(&"jump" if arc.vy - return_gravity * time > 0.0 else &"fall")
	_turn = move_toward(_turn, _turn_target, get_physics_process_delta_time() * 6.0)
	model.rotation.y = -PI * _turn


func _make_arc(from: Vector3, to: Vector3, top: float) -> Dictionary:
	var g := return_gravity
	var t_up := sqrt(2.0 * (top - from.y) / g)
	var t_down := sqrt(2.0 * (top - to.y) / g)
	var duration := t_up + t_down
	return {
		"from": from,
		"vx": (to.x - from.x) / duration,
		"vy": g * t_up,
		"duration": duration,
	}


func _arc_point(arc: Dictionary, time: float) -> Vector3:
	var from: Vector3 = arc.from
	return Vector3(
		from.x + arc.vx * time,
		from.y + arc.vy * time - 0.5 * return_gravity * time * time,
		0.0)


func _arc_clears(arc: Dictionary, ground: Dictionary) -> bool:
	var duration: float = arc.duration
	var steps := 30
	for i in steps + 1:
		var p := _arc_point(arc, duration * i / steps)
		for x: float in ground:
			if absf(x - p.x) < 0.35 and p.y < ground[x] + 0.05 and i > 0 and i < steps:
				return false
	return true


## Высота опоры по пути (x -> y) — лучами сверху вниз, чтобы дуга возврата не прошла сквозь мебель.
func _ground_profile(x1: float, x2: float) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var profile := {}
	var steps := maxi(2, int(absf(x2 - x1) / 0.25))
	for i in steps + 1:
		var x := lerpf(x1, x2, float(i) / steps)
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, 50.0, 0.0), Vector3(x, -50.0, 0.0))
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			profile[x] = (hit.position as Vector3).y
	return profile


func _finish_return() -> void:
	_controls_locked = false
	respawned.emit()


## Приземление: сплющился и выпрямился, облачко пыли; на бегу — маленькие облачка из-под ног.
func _update_juice(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 3.0:
		var k := clampf(_fall_speed / 10.0, 0.4, 1.0)
		_squash(Vector3(1.0 + 0.14 * k, 1.0 - 0.18 * k, 1.0 + 0.14 * k), 0.22)
		Fx.puff(get_parent(), global_position, int(10 + 8 * k), 0.8 + k)
	if not on_floor:
		_fall_speed = maxf(-velocity.y, 0.0)
	_was_on_floor = on_floor
	_dust_left -= delta
	if on_floor and absf(velocity.x) > move_speed * 0.6 and _dust_left <= 0.0:
		_dust_left = 0.28
		Fx.puff(get_parent(), global_position - Vector3(signf(velocity.x) * 0.15, 0, 0), 3, 0.5)


func _squash(amount: Vector3, time: float) -> void:
	if _stretch_tween:
		_stretch_tween.kill()
	model.scale = _model_scale * amount
	_stretch_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_stretch_tween.tween_property(model, "scale", _model_scale, time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Мгновенный отклик на прыжок: вытянулся вверх в первом же кадре и вернулся к обычной форме.
func _jump_stretch() -> void:
	if _stretch_tween:
		_stretch_tween.kill()
	model.scale = _model_scale * Vector3(0.9, 1.12, 0.9)
	_stretch_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_stretch_tween.tween_property(model, "scale", _model_scale, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _update_facing(dir: float, delta: float) -> void:
	if dir > 0.01:
		_turn_target = 0.0
	elif dir < -0.01:
		_turn_target = 1.0
	# Радуется лицом к экрану (0.5 — посередине между «вправо» и «влево»), потом возвращается к прежнему взгляду.
	var target := 0.5 if _celebrating else _turn_target
	_turn = move_toward(_turn, target, delta * 6.0)
	model.rotation.y = -PI * _turn


func _update_animation() -> void:
	var state: StringName
	if _celebrating:
		state = &"happy"
	elif not is_on_floor():
		state = &"jump" if velocity.y > 0.0 else &"fall"
	elif absf(velocity.x) > 0.1:
		state = &"walk"
	else:
		state = &"idle"
	_play(state)


func _play(anim: StringName) -> void:
	if _anim_player:
		# Шаги быстрее, когда Август бежит быстрее — меньше «скольжения» ног.
		_anim_player.speed_scale = lerpf(0.8, 2.0, absf(velocity.x) / move_speed) if anim == &"walk" else 1.0
	if anim == _current_anim:
		return
	_current_anim = anim
	if _anim_player and _anim_player.has_animation(anim):
		_anim_player.play(anim, 0.15)
