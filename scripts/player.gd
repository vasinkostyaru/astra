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
var _current_anim: StringName = &""


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

	velocity.z = 0.0
	move_and_slide()
	position.z = 0.0

	if global_position.y < fall_limit_y:
		soft_respawn()
		return

	_update_facing(dir, delta)
	_update_animation()


func set_checkpoint(point: Vector3) -> void:
	respawn_point = point


## Падение без проигрыша: Август «сдувается», переносится на чекпоинт и мягко появляется снова.
func soft_respawn() -> void:
	if _controls_locked:
		return
	_controls_locked = true
	velocity = Vector3.ZERO
	_jump_buffer_left = 0.0
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(model, "scale", _model_scale * 0.01, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(_teleport_to_checkpoint)
	tw.tween_property(model, "scale", _model_scale, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_finish_respawn)


## Радость: прыжки на месте (или анимация happy, если она есть у модели).
func celebrate() -> void:
	_celebrating = true
	_play(&"happy")
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for i in 3:
		tw.tween_property(model, "position:y", 0.35, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(model, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _celebrating = false)


func _teleport_to_checkpoint() -> void:
	global_position = respawn_point + Vector3.UP * 0.05
	reset_physics_interpolation()


func _finish_respawn() -> void:
	_controls_locked = false
	respawned.emit()


func _update_facing(dir: float, delta: float) -> void:
	if dir > 0.01:
		_turn_target = 0.0
	elif dir < -0.01:
		_turn_target = 1.0
	_turn = move_toward(_turn, _turn_target, delta * 6.0)
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
	if anim == _current_anim:
		return
	_current_anim = anim
	if _anim_player and _anim_player.has_animation(anim):
		_anim_player.play(anim, 0.15)
