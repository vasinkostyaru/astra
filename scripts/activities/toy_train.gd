class_name ToyTrain
extends AnimatableBody3D
## Паровозик: Август встал на вагончик — гудок, и паровозик сам везёт его вперёд на travel метров, пуская пар.
## Ехать можно один раз; дальше стоит на месте (на него можно залезть, он низкий).
## Начало координат — на полу посередине вагончика.

signal activated

@export var travel: float = 6.0
@export var color: Color = Color(0.9, 0.25, 0.25)

const SPEED := 2.2
const BASE := Vector3(2.6, 0.5, 2.0)

var _moved: bool = false
var _moving: bool = false
var _target_x: float
var _steam_left: float = 0.0
var _chimney: Node3D


func _ready() -> void:
	add_to_group(&"activities")
	sync_to_physics = true
	var shape := BoxShape3D.new()
	shape.size = BASE
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, BASE.y * 0.5, 0)
	add_child(col)
	_build_visual()

	var area := Area3D.new()
	area.monitorable = false
	var trigger := BoxShape3D.new()
	trigger.size = Vector3(BASE.x - 0.2, 0.6, BASE.z)
	var tcol := CollisionShape3D.new()
	tcol.shape = trigger
	tcol.position = Vector3(0, BASE.y + 0.3, 0)
	area.add_child(tcol)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _build_visual() -> void:
	var base := MeshInstance3D.new()
	base.mesh = LevelSection._rounded_mesh(BASE - Vector3(0, 0.1, 0), 0.1, 0.1)
	base.material_override = LevelSection._soft_material(color, "grain")
	base.position = Vector3(0, BASE.y * 0.5 + 0.05, 0)
	add_child(base)
	# Кабина и труба — позади платформы (z < 0), чтобы не мешать стоять и идти.
	var cab := MeshInstance3D.new()
	cab.mesh = LevelSection._rounded_mesh(Vector3(1.0, 1.1, 0.7), 0.12, 0.5)
	cab.material_override = LevelSection._soft_material(Color(0.25, 0.45, 0.9), "grain")
	cab.position = Vector3(-0.6, BASE.y + 0.55, -1.25)
	add_child(cab)
	var roof := MeshInstance3D.new()
	roof.mesh = LevelSection._rounded_mesh(Vector3(1.3, 0.16, 0.9), 0.06, 1.6)
	roof.material_override = LevelSection._soft_material(Color(1.0, 0.8, 0.2), "grain")
	roof.position = Vector3(-0.6, BASE.y + 1.18, -1.25)
	add_child(roof)
	var boiler := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.35
	bm.bottom_radius = 0.35
	bm.height = 1.1
	boiler.mesh = bm
	boiler.material_override = LevelSection._soft_material(Color(0.2, 0.7, 0.4), "grain")
	boiler.rotation.z = PI * 0.5
	boiler.position = Vector3(0.55, BASE.y + 0.35, -1.25)
	add_child(boiler)
	var chimney := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16
	cm.bottom_radius = 0.11
	cm.height = 0.5
	chimney.mesh = cm
	chimney.material_override = LevelSection._soft_material(Color(0.15, 0.15, 0.17), "grain")
	chimney.position = Vector3(0.85, BASE.y + 0.9, -1.25)
	add_child(chimney)
	_chimney = chimney
	for wx in [-0.85, 0.0, 0.85]:
		for wz in [-1.0, 1.0]:
			var wheel := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.24
			wm.bottom_radius = 0.24
			wm.height = 0.12
			wheel.mesh = wm
			wheel.material_override = LevelSection._soft_material(Color(0.12, 0.12, 0.14), "grain")
			wheel.rotation.x = PI * 0.5
			wheel.position = Vector3(wx, 0.24, wz)
			add_child(wheel)


func _physics_process(delta: float) -> void:
	if not _moving:
		return
	position.x = move_toward(position.x, _target_x, SPEED * delta)
	_steam_left -= delta
	if _steam_left <= 0.0:
		_steam_left = 0.35
		Fx.steam(get_parent(), _chimney.global_position + Vector3(0, 0.3, 0))
	if is_equal_approx(position.x, _target_x):
		_moving = false


func _on_body_entered(body: Node3D) -> void:
	if _moved or not body is Player:
		return
	_moved = true
	activated.emit()
	_target_x = position.x + travel
	Game.play_note(392.0)
	get_tree().create_timer(0.25).timeout.connect(func() -> void: Game.play_note(523.0))
	get_tree().create_timer(0.4).timeout.connect(func() -> void: _moving = true)
