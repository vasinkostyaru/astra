class_name CubePyramid
extends Node3D
## Пирамида из кубиков: Август подошёл или подпрыгнул — она с грохотом разваливается (кубики разлетаются
## и не мешают идти), через пару секунд сама собирается обратно.
## Начало координат — центр основания на полу.

signal activated

@export_range(2, 5) var base: int = 3
@export var cube_size: float = 0.6
@export var rebuild_delay: float = 2.2
@export var color_seed: int = 0

const PALETTE: Array[Color] = [
	Color(0.9, 0.22, 0.2), Color(1.0, 0.78, 0.15), Color(0.2, 0.5, 0.95),
	Color(0.25, 0.75, 0.35), Color(1.0, 0.5, 0.15), Color(0.65, 0.4, 0.85),
]

var _cubes: Array[MeshInstance3D] = []
var _home: Array[Vector3] = []
var _body: StaticBody3D
var _shape: CollisionShape3D
var _zone: Area3D
var _busy: bool = false


func _ready() -> void:
	add_to_group(&"activities")
	var rng := RandomNumberGenerator.new()
	rng.seed = color_seed + 5
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * (cube_size - 0.03)
	for row in base:
		var count := base - row
		for i in count:
			var cube := MeshInstance3D.new()
			cube.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = PALETTE[rng.randi() % PALETTE.size()]
			mat.roughness = 0.5
			cube.material_override = mat
			var home := Vector3((i - (count - 1) * 0.5) * cube_size, (row + 0.5) * cube_size, 0.0)
			cube.position = home
			add_child(cube)
			_cubes.append(cube)
			_home.append(home)
	# Коллизия: пока стоит — твёрдая (как кубики), при падении выключается.
	_body = StaticBody3D.new()
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(base * cube_size, base * cube_size, 1.4)
	_shape.shape = box
	_shape.position = Vector3(0, base * cube_size * 0.5, 0)
	_body.add_child(_shape)
	add_child(_body)
	# Зона срабатывания чуть шире пирамиды (на ширину пальца): разваливается, когда Август её коснулся
	# или приземлился сверху, а не заранее.
	_zone = Area3D.new()
	_zone.monitorable = false
	var zshape := CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(base * cube_size + 0.3, base * cube_size + 0.3, 1.8)
	zshape.shape = zbox
	zshape.position = Vector3(0, zbox.size.y * 0.5, 0)
	_zone.add_child(zshape)
	add_child(_zone)
	_zone.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _busy or not body is Player:
		return
	_busy = true
	activated.emit()
	_shape.set_deferred("disabled", true)
	Game.play_thud()
	var rng := RandomNumberGenerator.new()
	for i in _cubes.size():
		var cube := _cubes[i]
		var side := signf(_home[i].x + rng.randf_range(-0.3, 0.3))
		var away := Vector3(side * rng.randf_range(0.8, 2.0), cube_size * 0.5, rng.randf_range(-0.7, 0.7))
		var tw := create_tween()
		tw.tween_property(cube, "position", away + Vector3(0, 0.6, 0), 0.2).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(cube, "rotation", Vector3(rng.randf_range(-2, 2), rng.randf_range(-2, 2), rng.randf_range(-2, 2)), 0.3)
		tw.tween_property(cube, "position", away, 0.18).set_ease(Tween.EASE_IN)
	get_tree().create_timer(rebuild_delay).timeout.connect(_rebuild)


func _rebuild() -> void:
	for i in _cubes.size():
		var tw := create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_property(_cubes[i], "position", _home[i] + Vector3(0, 0.4, 0), 0.3).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(_cubes[i], "rotation", Vector3.ZERO, 0.3)
		tw.tween_property(_cubes[i], "position", _home[i], 0.1)
	await get_tree().create_timer(_cubes.size() * 0.06 + 0.5).timeout
	# Твёрдой пирамида становится, только когда рядом никого нет: иначе Августа вытолкнуло бы.
	while _zone.has_overlapping_bodies():
		await get_tree().create_timer(0.3).timeout
	_shape.disabled = false
	_busy = false
