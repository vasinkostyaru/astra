class_name DrainPlug
extends Area3D
## Раковина с водой и чёрной пробкой на цепочке. Август прошёл рядом — пробка выскакивает, вода с бульканьем
## уходит в слив; потом всё возвращается на место (можно повторить).
## Начало координат — центр дна раковины.

signal activated

const WATER_COLOR := Color(0.45, 0.75, 0.95, 0.7)

var _plug: Node3D
var _water: MeshInstance3D
var _busy: bool = false


func _ready() -> void:
	monitorable = false
	add_to_group(&"activities")
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.6, 2.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)
	_basin()
	_water = MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(1.5, 0.3, 1.1)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = WATER_COLOR
	mat.roughness = 0.1
	wm.material = mat
	_water.mesh = wm
	_water.position = Vector3(0, 0.17, 0)
	add_child(_water)
	_plug = Node3D.new()
	_plug.position = Vector3(0, 0.15, 0)
	add_child(_plug)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.28
	cyl.height = 0.2
	cyl.material = _flat(Color(0.07, 0.07, 0.08))
	var body := MeshInstance3D.new()
	body.mesh = cyl
	_plug.add_child(body)
	var knob := SphereMesh.new()
	knob.radius = 0.11
	knob.height = 0.22
	knob.material = _flat(Color(0.07, 0.07, 0.08))
	var knob_mi := MeshInstance3D.new()
	knob_mi.mesh = knob
	knob_mi.position = Vector3(0, 0.17, 0)
	_plug.add_child(knob_mi)
	# Цепочка к краю раковины.
	for i in 7:
		var link := SphereMesh.new()
		link.radius = 0.035
		link.height = 0.07
		link.material = _flat(Color(0.78, 0.8, 0.83))
		var mi := MeshInstance3D.new()
		mi.mesh = link
		mi.position = Vector3(0.1 + i * 0.1, 0.12 + i * 0.05, 0.0)
		_plug.add_child(mi)
	body_entered.connect(_on_body_entered)


func _basin() -> void:
	var white := Color(0.97, 0.97, 0.98)
	_box(Vector3(0, -0.05, 0), Vector3(1.9, 0.1, 1.3), white)
	# Передней стенки нет: камера видит пробку и воду, а Август не прячется за бортиком.
	_box(Vector3(0, 0.2, -0.62), Vector3(1.9, 0.5, 0.1), white)
	_box(Vector3(0.9, 0.2, 0), Vector3(0.1, 0.5, 1.3), white)
	_box(Vector3(-0.9, 0.2, 0), Vector3(0.1, 0.5, 1.3), white)


func _on_body_entered(body: Node3D) -> void:
	if _busy or not body is Player:
		return
	_busy = true
	activated.emit()
	Game.play_gurgle()
	# Пробка подпрыгивает и откатывается в сторону.
	var tw := create_tween()
	tw.tween_property(_plug, "position", Vector3(-0.2, 0.9, 0.2), 0.18).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_plug, "rotation", Vector3(0.6, 0, 1.2), 0.18)
	tw.tween_property(_plug, "position", Vector3(-0.65, 0.2, 0.35), 0.2).set_ease(Tween.EASE_IN)
	# Вода уходит воронкой: уровень падает, ширина сужается.
	var drain := create_tween()
	drain.tween_property(_water, "scale", Vector3(0.25, 0.02, 0.25), 1.8).set_ease(Tween.EASE_IN)
	drain.tween_interval(2.5)
	drain.tween_callback(_refill)
	_bubbles()


func _refill() -> void:
	_plug.position = Vector3(0, 0.15, 0)
	_plug.rotation = Vector3.ZERO
	var tw := create_tween()
	tw.tween_property(_water, "scale", Vector3.ONE, 1.2)
	tw.tween_callback(func() -> void: _busy = false)


func _bubbles() -> void:
	var drop := SphereMesh.new()
	drop.radius = 0.04
	drop.height = 0.08
	drop.material = _flat(Color(0.85, 0.95, 1.0))
	var p := CPUParticles3D.new()
	p.mesh = drop
	p.amount = 16
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 0.3
	p.direction = Vector3(0, 1, 0)
	p.spread = 35.0
	p.gravity = Vector3(0, -1.0, 0)
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.6
	p.position = Vector3(0, 0.3, 0)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _flat(color)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)


func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.4
	return m
