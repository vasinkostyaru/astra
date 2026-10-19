class_name Astra
extends Node3D
## Астра-проводник. Внешний вид — дочерний узел Model (GLB можно заменить без правок кода).
## Анимации run/idle/sleep ищутся в AnimationPlayer внутри Model; если анимации нет — пропускаем.
##
## Маршрут — дети узла path (Marker3D) по порядку:
##   Stop_* — Астра ждёт здесь, пока Август не подойдёт;
##   Run_*  — пробегает без остановки;
##   Exit   — выход: ждёт, Август подошёл вплотную — уровень пройден.
## Между точками бежит; если есть перепад высоты или в имени точки есть «hop» — прыгает дугой.

signal reached_by_player

@export var path: Node3D
@export var player: Node3D
## Август ближе этого (по X) к точке ожидания — Астра убегает к следующей.
@export var trigger_distance: float = 2.2
## Август ближе этого к Астре на выходе — уровень пройден.
@export var exit_distance: float = 0.9
@export var run_speed: float = 4.5
@export var hop_height: float = 0.45
## Финал: у выхода Астра сворачивается клубком и спит (анимация sleep) вместо того, чтобы просто стоять.
@export var sleeps_at_exit: bool = false

@onready var model: Node3D = $Model

var _anim_player: AnimationPlayer
var _points: Array[Marker3D] = []
var _index: int = 0
var _moving: bool = false
var _done: bool = false
## Направление взгляда: -1 — влево (к Августу), +1 — вправо (бежит вперёд).
var _turn: float = -1.0
var _turn_target: float = -1.0


func _ready() -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim_player = players[0] as AnimationPlayer
	if path:
		for child in path.get_children():
			if child is Marker3D:
				_points.append(child)
	if not _points.is_empty():
		global_position = _points[0].global_position
	_apply_turn()
	play(&"idle")


func play(anim: StringName) -> void:
	if _anim_player and _anim_player.has_animation(anim):
		_anim_player.play(anim, 0.2)


func _physics_process(delta: float) -> void:
	_turn = move_toward(_turn, _turn_target, delta * 5.0)
	_apply_turn()
	if _moving or _done or player == null or _points.is_empty():
		return
	var waiting_at := _points[_index]
	if _is_exit(waiting_at):
		_turn_target = signf(player.global_position.x - global_position.x)
		# Засчитываем, если Август рядом по горизонтали и не выше прыжка (перепрыгнул — тоже нашёл).
		var gap := player.global_position - global_position
		if absf(gap.x) < exit_distance and absf(gap.y) < 1.8:
			_done = true
			play(&"sleep" if sleeps_at_exit else &"idle")
			_purr_with_hearts()
			reached_by_player.emit()
		return
	_turn_target = -1.0
	if player.global_position.x > global_position.x - trigger_distance:
		_run_to_next_stop()


## Астра мурчит, над ней поднимаются сердечки.
func _purr_with_hearts() -> void:
	Game.play_purr()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.3, 0.3)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _heart_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mesh.material = mat
	var hearts := CPUParticles3D.new()
	hearts.mesh = mesh
	hearts.amount = 14
	hearts.lifetime = 1.6
	hearts.one_shot = false
	hearts.explosiveness = 0.0
	hearts.direction = Vector3(0, 1, 0)
	hearts.spread = 25.0
	hearts.gravity = Vector3(0, 0.3, 0)
	hearts.initial_velocity_min = 0.8
	hearts.initial_velocity_max = 1.4
	hearts.scale_amount_min = 0.7
	hearts.scale_amount_max = 1.3
	hearts.position = Vector3(0, 0.8, 0.2)
	add_child(hearts)
	hearts.emitting = true
	# Твин привязан к Астре и пропадает вместе с ней при смене сцены.
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(hearts):
			hearts.emitting = false)


## Картинка сердечка, нарисованная в коде по формуле (розовое, с бликом).
static var _heart: ImageTexture


static func _heart_texture() -> ImageTexture:
	if _heart == null:
		var size := 64
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for py in size:
			for px in size:
				var x := (px + 0.5) / size * 3.0 - 1.5
				var y := 1.4 - (py + 0.5) / size * 3.0
				var v := pow(x * x + y * y - 1.0, 3.0) - x * x * y * y * y
				if v <= 0.0:
					var shade := clampf(0.5 + 0.5 * (y - 0.2), 0.0, 1.0)
					var col := Color(0.95, 0.25, 0.4).lerp(Color(1.0, 0.55, 0.65), shade * 0.6)
					if (x + 0.55) * (x + 0.55) + (y - 0.6) * (y - 0.6) < 0.05:
						col = Color(1.0, 0.85, 0.9)
					img.set_pixel(px, py, col)
				else:
					img.set_pixel(px, py, Color(0, 0, 0, 0))
		_heart = ImageTexture.create_from_image(img)
	return _heart


func _run_to_next_stop() -> void:
	_moving = true
	_turn_target = 1.0
	play(&"run")
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var from := global_position
	while _index < _points.size() - 1:
		_index += 1
		var marker := _points[_index]
		var to := marker.global_position
		var hop := absf(to.y - from.y) > 0.05 or marker.name.to_lower().contains("hop")
		var duration := maxf(absf(to.x - from.x) / run_speed, 0.3 if hop else 0.05)
		# Вершина дуги — на hop_height выше верхней из двух точек.
		var arc := absf(to.y - from.y) * 0.5 + hop_height if hop else 0.0
		tw.tween_method(_leg_step.bind(from, to, arc), 0.0, 1.0, duration)
		from = to
		if _is_stop(marker):
			break
	tw.tween_callback(_arrive)


func _leg_step(t: float, from: Vector3, to: Vector3, arc: float) -> void:
	var p := from.lerp(to, t)
	p.y += arc * 4.0 * t * (1.0 - t)
	global_position = p


func _arrive() -> void:
	_moving = false
	_turn_target = -1.0
	play(&"sleep" if sleeps_at_exit and _is_exit(_points[_index]) else &"idle")


func _is_stop(marker: Marker3D) -> bool:
	return marker.name.begins_with("Stop") or _is_exit(marker)


func _is_exit(marker: Marker3D) -> bool:
	return marker.name.begins_with("Exit")


func _apply_turn() -> void:
	# Модель смотрит на камеру (+Z); поворот на ±90° — вправо/влево, через «лицом к камере».
	model.rotation.y = _turn * PI * 0.5
