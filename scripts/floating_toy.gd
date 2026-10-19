class_name FloatingToy
extends AnimatableBody3D
## Плавающая игрушка в поддоне: мягко покачивается на воде, по ней можно переходить. Верх плоский (y = 0.15).
## Внешний вид — примитивы (лебедь, уточка, машинка, кораблик); решает kind.

enum Kind { SWAN, DUCK, CAR, BOAT }

const WIDTH := 2.2
const TOP := 0.15

@export var kind: Kind = Kind.SWAN
@export var bob_height: float = 0.07
@export var bob_speed: float = 1.5

var _time: float = randf() * TAU
var _base_y: float = 0.0
var _visual: Node3D


func _ready() -> void:
	sync_to_physics = true
	_base_y = position.y
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH, 0.5, 1.6)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, TOP - 0.25, 0)
	add_child(col)
	_visual = Node3D.new()
	add_child(_visual)
	build_visual(kind, _visual)


func _physics_process(delta: float) -> void:
	_time += delta * bob_speed
	position.y = _base_y + sin(_time) * bob_height
	# Покачивание только у картинки: коллизия не наклоняется, Август не скользит.
	_visual.rotation.z = sin(_time * 0.7) * 0.025


const MODELS := {Kind.SWAN: "swan", Kind.DUCK: "duck", Kind.CAR: "car", Kind.BOAT: "boat"}


static func build_visual(k: Kind, parent: Node3D) -> void:
	var scene := load("res://assets/models/toys/%s.glb" % MODELS[k]) as PackedScene
	if scene != null:
		parent.add_child(scene.instantiate())
		return
	_build_primitives(k, parent)


## Запасной вариант, если модели нет: примитивы.
static func _build_primitives(k: Kind, parent: Node3D) -> void:
	match k:
		Kind.SWAN:
			var white := Color(0.97, 0.97, 0.98)
			_ball(parent, Vector3(0, -0.1, 0), Vector3(1.15, 0.27, 0.62), white)
			_ball(parent, Vector3(0.35, 0.05, 0), Vector3(0.55, 0.22, 0.5), white.darkened(0.04))  # крыло
			_ball(parent, Vector3(0.85, 0.2, 0), Vector3(0.25, 0.4, 0.25), white)
			_ball(parent, Vector3(1.0, 0.65, 0), Vector3(0.22, 0.4, 0.22), white)
			_ball(parent, Vector3(1.05, 1.0, 0), Vector3(0.27, 0.22, 0.22), white)
			_ball(parent, Vector3(1.28, 0.97, 0), Vector3(0.13, 0.06, 0.08), Color(1.0, 0.6, 0.15))
			_ball(parent, Vector3(1.15, 1.07, 0.15), Vector3(0.04, 0.04, 0.04), Color(0.05, 0.05, 0.05))
		Kind.DUCK:
			var yellow := Color(1.0, 0.85, 0.15)
			_ball(parent, Vector3(0, -0.08, 0), Vector3(1.05, 0.26, 0.62), yellow)
			_ball(parent, Vector3(0.75, 0.45, 0), Vector3(0.38, 0.38, 0.38), yellow)
			_ball(parent, Vector3(1.1, 0.4, 0), Vector3(0.18, 0.07, 0.12), Color(1.0, 0.5, 0.1))
			_ball(parent, Vector3(0.9, 0.58, 0.28), Vector3(0.05, 0.05, 0.05), Color(0.05, 0.05, 0.05))
			_ball(parent, Vector3(-0.8, 0.15, 0), Vector3(0.3, 0.3, 0.2), yellow)  # хвостик
		Kind.CAR:
			var red := Color(0.88, 0.18, 0.18)
			_box(parent, Vector3(0, -0.1, 0), Vector3(2.1, 0.3, 1.4), red)
			_box(parent, Vector3(-0.35, 0.35, 0), Vector3(0.9, 0.4, 1.2), red.lightened(0.1))
			_box(parent, Vector3(-0.35, 0.37, 0.61), Vector3(0.7, 0.28, 0.02), Color(0.7, 0.9, 1.0))
			for wx in [-0.65, 0.65]:
				_ball(parent, Vector3(wx, -0.28, 0.72), Vector3(0.3, 0.3, 0.12), Color(0.1, 0.1, 0.1))
		Kind.BOAT:
			var blue := Color(0.2, 0.5, 0.95)
			_box(parent, Vector3(0, -0.1, 0), Vector3(2.15, 0.3, 1.2), blue)
			_box(parent, Vector3(0, -0.2, 0), Vector3(1.6, 0.2, 1.0), blue.darkened(0.2))
			_box(parent, Vector3(-0.2, 0.7, 0), Vector3(0.06, 1.2, 0.06), Color(0.6, 0.4, 0.2))
			_box(parent, Vector3(0.15, 0.85, 0), Vector3(0.7, 0.8, 0.02), Color(0.98, 0.95, 0.9))


static func _ball(parent: Node3D, pos: Vector3, radii: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.45
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = radii
	parent.add_child(mi)


static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
