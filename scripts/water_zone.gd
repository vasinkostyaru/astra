class_name WaterZone
extends FallZone
## Вода в поддоне: упал — всплеск, на Августа надевается надувной круг, и круг уносит его к чекпоинту.
## Проиграть нельзя: круг мягко выносит к краю. Зона лежит под уровнем пола, поверх игрушек её нет.

@export var width: float = 6.0
@export var top_y: float = -0.25
@export var bottom_y: float = -1.6
@export var surface_y: float = -0.45

var _ring: Node3D


func _ready() -> void:
	monitorable = false
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, top_y - bottom_y, 4.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, (top_y + bottom_y) * 0.5, 0.0)
	add_child(col)
	super._ready()


func _catch(player: Player) -> void:
	Game.play_splash()
	_splash_at(Vector3(player.global_position.x, surface_y, 0.4))
	_put_ring_on(player)
	player.catch_on(surface_y, 0.15, 0.2)


func _put_ring_on(player: Player) -> void:
	if is_instance_valid(_ring):
		_ring.queue_free()
	_ring = Node3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.75
	torus.rings = 20
	torus.ring_segments = 10
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	mat.roughness = 0.5
	torus.material = mat
	var body := MeshInstance3D.new()
	body.mesh = torus
	_ring.add_child(body)
	# Полоски на круге.
	for i in 4:
		var stripe := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.36, 0.2, 0.2)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.95, 0.3, 0.3)
		sm.material = smat
		stripe.mesh = sm
		var a := i * PI * 0.5
		stripe.position = Vector3(cos(a) * 0.585, 0.0, sin(a) * 0.585)
		stripe.rotation.y = -a
		_ring.add_child(stripe)
	_ring.position = Vector3(0, 0.55, 0)
	player.add_child(_ring)
	var tw := player.create_tween()
	_ring.scale = Vector3.ONE * 0.1
	tw.tween_property(_ring, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	player.respawned.connect(_take_ring_off, CONNECT_ONE_SHOT)


func _take_ring_off() -> void:
	if is_instance_valid(_ring):
		var ring := _ring
		var tw := ring.create_tween()
		tw.tween_property(ring, "scale", Vector3.ONE * 0.01, 0.25)
		tw.tween_callback(ring.queue_free)


func _splash_at(pos: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 0.9, 1.0)
	mesh.material = mat
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = 24
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 50.0
	p.gravity = Vector3(0, -9.0, 0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.0
	p.emitting = true
	get_parent().add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
