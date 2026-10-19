class_name SoapBubble
extends Area3D
## Мыльный пузырь: плавает в воздухе; коснулся — лопается со звуком и брызгами, потом появляется снова.

signal activated

@export var radius: float = 0.5

var _mesh: MeshInstance3D
var _time: float = randf() * TAU
var _base_y: float = 0.0
var _popped: bool = false


func _ready() -> void:
	monitorable = false
	add_to_group(&"activities")
	_base_y = position.y
	var shape := SphereShape3D.new()
	shape.radius = radius
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.9, 1.0, 0.28)
	mat.rim_enabled = true
	mat.rim = 1.0
	mat.rim_tint = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.85, 1.0)
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.1
	sphere.material = mat
	_mesh = MeshInstance3D.new()
	_mesh.mesh = sphere
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 1.3) * 0.15
	if not _popped:
		_mesh.scale = Vector3.ONE * (1.0 + sin(_time * 3.0) * 0.03)


func _on_body_entered(body: Node3D) -> void:
	if _popped or not body is Player:
		return
	_popped = true
	activated.emit()
	Game.play_pop()
	_burst()
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3.ONE * 1.4, 0.06)
	tw.tween_property(_mesh, "scale", Vector3.ONE * 0.01, 0.05)
	tw.tween_interval(3.0)
	tw.tween_callback(_reappear)


func _reappear() -> void:
	_popped = false
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _burst() -> void:
	var drop := SphereMesh.new()
	drop.radius = 0.05
	drop.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.95, 1.0)
	drop.material = mat
	var p := CPUParticles3D.new()
	p.mesh = drop
	p.amount = 14
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector3(0, -2.0, 0)
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.4
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
