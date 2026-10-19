class_name Berry
extends Area3D
## Ягодка: собирается, когда Август проходит сквозь неё, и улетает в банку. Уровень слушает сигнал collected.
## Разные виды (kind) — разные цвета и форма, чтобы собирать было интереснее.

signal collected(berry: Berry)

enum Kind { STRAWBERRY, BLUEBERRY, RASPBERRY, GRAPE, CHERRY }

const COLORS: Dictionary = {
	Kind.STRAWBERRY: Color(0.92, 0.15, 0.2),
	Kind.BLUEBERRY: Color(0.25, 0.35, 0.85),
	Kind.RASPBERRY: Color(0.88, 0.2, 0.45),
	Kind.GRAPE: Color(0.55, 0.28, 0.75),
	Kind.CHERRY: Color(0.7, 0.05, 0.12),
}
const LEAF := Color(0.3, 0.7, 0.25)

@export var kind: Kind = Kind.STRAWBERRY

@onready var _visual: Node3D = $Visual

var _time: float = randf() * TAU
var _taken: bool = false


func _ready() -> void:
	_build_visual()
	body_entered.connect(_on_body_entered)


## Цвет ягодки — им же окрашивается её полёт и место в банке.
func get_color() -> Color:
	return COLORS[kind]


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	_visual.position.y = sin(_time * 2.2) * 0.08
	_visual.rotate_y(delta * 1.5)


func _build_visual() -> void:
	var color := get_color()
	match kind:
		Kind.STRAWBERRY:
			_ball(Vector3.ZERO, 0.16, color, Vector3(1, 1.2, 1))
			_leaf(Vector3(0, 0.2, 0))
		Kind.BLUEBERRY:
			_ball(Vector3.ZERO, 0.16, color)
			_ball(Vector3(0, 0.15, 0), 0.04, color.darkened(0.5))
		Kind.RASPBERRY:
			for p: Vector3 in [Vector3(0, -0.1, 0), Vector3(0.1, -0.03, 0), Vector3(-0.1, -0.03, 0),
					Vector3(0.05, 0.06, 0.05), Vector3(-0.05, 0.06, -0.05), Vector3(0, 0.14, 0), Vector3(0, 0.0, 0.1)]:
				_ball(p, 0.08, color)
			_leaf(Vector3(0, 0.22, 0))
		Kind.GRAPE:
			for p: Vector3 in [Vector3(0, -0.12, 0), Vector3(0.1, 0.0, 0), Vector3(-0.1, 0.0, 0), Vector3(0, 0.1, 0.06), Vector3(0, 0.1, -0.06)]:
				_ball(p, 0.09, color)
			_leaf(Vector3(0, 0.24, 0))
		Kind.CHERRY:
			_ball(Vector3(-0.1, -0.06, 0), 0.12, color)
			_ball(Vector3(0.1, -0.06, 0), 0.12, color)
			_leaf(Vector3(0, 0.2, 0))


func _ball(pos: Vector3, radius: float, color: Color, stretch: Vector3 = Vector3.ONE) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	# Чуть собственного свечения, чтобы ягодки хорошо читались на фоне.
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.25
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = stretch
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(mi)


func _leaf(pos: Vector3) -> void:
	_ball(pos, 0.07, LEAF, Vector3(1.4, 0.35, 1.0))


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	collected.emit(self)
	set_deferred("monitoring", false)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_visual, "scale", Vector3.ONE * 1.5, 0.1)
	tw.tween_property(_visual, "scale", Vector3.ONE * 0.01, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
