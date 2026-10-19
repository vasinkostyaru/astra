class_name KickBall
extends Node3D
## Мячик-пинашка: Август подошёл — мяч отскакивает вперёд, катится и сбивает кегли.
## Мяч и кегли с Августом не сталкиваются (он проходит сквозь них), поэтому путь они не загораживают.
## Невидимые стенки по краям держат мяч в пределах секции. Через несколько секунд всё встаёт на место.
## Начало координат — левый край занятия на полу; width — сколько места по X.

signal activated

@export var width: float = 11.0
@export var ball_x: float = 2.5
@export var color: Color = Color(0.95, 0.3, 0.3)

const LAYER := 8  # слой только для мяча, кеглей и их стенок
const RADIUS := 0.55
const RESET_TIME := 7.0

var _ball: RigidBody3D
var _pins: Array[RigidBody3D] = []
var _homes: Array[Transform3D] = []
var _reset_left: float = -1.0
var _cooldown: float = 0.0
var _knocked: Array[bool] = [false, false, false]


func _ready() -> void:
	add_to_group(&"activities")
	for x in [0.2, width - 0.2]:
		var wall := StaticBody3D.new()
		wall.collision_layer = LAYER
		wall.collision_mask = 0
		var ws := BoxShape3D.new()
		ws.size = Vector3(0.2, 4.0, 2.0)
		var wc := CollisionShape3D.new()
		wc.shape = ws
		wall.add_child(wc)
		wall.position = Vector3(x, 2.0, 0)
		add_child(wall)

	_ball = _make_body(SphereShape3D.new(), 1.0)
	(_ball.get_child(0) as CollisionShape3D).shape.radius = RADIUS
	_ball.position = Vector3(ball_x, RADIUS + 0.02, 0)
	_ball.angular_damp = 0.5
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.45
	mat.friction = 0.6
	_ball.physics_material_override = mat
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	_ball.add_child(_mesh(sphere, color))
	var band := TorusMesh.new()
	band.inner_radius = RADIUS * 0.93
	band.outer_radius = RADIUS * 1.03
	var band_mi := _mesh(band, Color(1, 1, 1))
	band_mi.rotation.x = PI * 0.5
	_ball.add_child(band_mi)
	var band2 := _mesh(band, Color(1.0, 0.85, 0.2))
	band2.rotation.z = PI * 0.5
	_ball.add_child(band2)
	var area := Area3D.new()
	area.monitorable = false
	var ts := SphereShape3D.new()
	ts.radius = RADIUS + 0.35
	var tc := CollisionShape3D.new()
	tc.shape = ts
	area.add_child(tc)
	area.body_entered.connect(_on_body_entered)
	_ball.add_child(area)
	add_child(_ball)

	for i in 3:
		var pin := _make_body(CylinderShape3D.new(), 0.12)
		var cs := (pin.get_child(0) as CollisionShape3D).shape as CylinderShape3D
		cs.radius = 0.15
		cs.height = 1.2
		pin.collision_mask = 1  # кегли друг друга не толкают
		pin.position = Vector3(width - 2.4 + i * 0.5, 0.62, 0)
		var grip := PhysicsMaterial.new()
		grip.friction = 1.0
		pin.physics_material_override = grip
		var body_mesh := CylinderMesh.new()
		body_mesh.top_radius = 0.1
		body_mesh.bottom_radius = 0.16
		body_mesh.height = 1.2
		pin.add_child(_mesh(body_mesh, Color(0.98, 0.97, 0.94)))
		var stripe := CylinderMesh.new()
		stripe.top_radius = 0.16
		stripe.bottom_radius = 0.17
		stripe.height = 0.12
		var stripe_mi := _mesh(stripe, Color(0.9, 0.2, 0.2))
		stripe_mi.position.y = 0.2
		pin.add_child(stripe_mi)
		add_child(pin)
		_pins.append(pin)
	_ignore_player.call_deferred()


func _make_body(shape: Shape3D, mass: float) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.collision_layer = LAYER
	b.collision_mask = 1 | LAYER
	b.mass = mass
	b.axis_lock_linear_z = true
	b.axis_lock_angular_x = true
	b.axis_lock_angular_y = true
	var c := CollisionShape3D.new()
	c.shape = shape
	b.add_child(c)
	return b


func _mesh(mesh: Mesh, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = LevelSection._soft_material(c, "grain")
	return mi


## Август и мяч друг друга не толкают (слой у него общий с полом, поэтому — исключение).
func _ignore_player() -> void:
	_homes.clear()
	_homes.append(_ball.transform)
	for p in _pins:
		_homes.append(p.transform)
	for node in get_tree().root.find_children("*", "CharacterBody3D", true, false):
		if node is Player:
			_ball.add_collision_exception_with(node)
			for p in _pins:
				p.add_collision_exception_with(node)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	# Мяч задел кеглю — все кегли по очереди валятся (анимацией: физика ставит их «на ребро»).
	if not _knocked[0]:
		for i in _pins.size():
			var d := _pins[i].global_position - _ball.global_position
			if absf(d.x) < RADIUS + 0.3 and _ball.linear_velocity.length() > 0.3:
				var dir := signf(_ball.linear_velocity.x) if _ball.linear_velocity.x != 0.0 else 1.0
				var order := range(_pins.size()) if dir > 0.0 else range(_pins.size() - 1, -1, -1)
				for k in order.size():
					_knocked[order[k]] = true
					get_tree().create_timer(0.09 * k, true, true).timeout.connect(_topple.bind(_pins[order[k]], dir, k))
				break
	if _reset_left > 0.0:
		_reset_left -= delta
		if _reset_left <= 0.0:
			_reset()


## Кегля валится набок и отъезжает чуть вперёд (анимация: физика ставит её «на ребро»).
func _topple(pin: RigidBody3D, dir: float, i: int) -> void:
	pin.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	pin.freeze = true
	var tw := create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(pin, "rotation:z", -PI * 0.5 * dir, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(pin, "position:y", 0.16, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(pin, "position:x", minf(pin.position.x + (0.7 + 0.2 * i) * dir, width - 0.9), 0.4)
	tw.chain().tween_callback(func() -> void: Fx.puff(self, pin.global_position, 5, 0.6))
	Game.play_note(330.0 + 110.0 * i)


func _reset() -> void:
	var bodies: Array[RigidBody3D] = [_ball]
	bodies.append_array(_pins)
	for i in bodies.size():
		var b := bodies[i]
		b.freeze = false
		b.linear_velocity = Vector3.ZERO
		b.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_state(b.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform * _homes[i])
		b.transform = _homes[i]
		Fx.sparkle(self, b.global_position, Color(1.0, 0.9, 0.5), 4)
	_knocked = [false, false, false]


func _on_body_entered(body: Node3D) -> void:
	if not body is Player or _cooldown > 0.0:
		return
	_cooldown = 0.6
	activated.emit()
	var dir := 1.0 if _ball.global_position.x >= body.global_position.x else -1.0
	_ball.apply_central_impulse(Vector3(8.0 * dir, 3.0, 0))
	Game.play_boing()
	_reset_left = RESET_TIME
