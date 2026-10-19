class_name MirrorLights
extends Node3D
## Зеркало с лампочками (главный светильник ванной). Лампочки загораются по очереди — праздник.
## Начало координат — центр зеркала на стене.

var _bulbs: Array[StandardMaterial3D] = []
var _light: OmniLight3D


func _ready() -> void:
	_box(Vector3(0, 0, 0), Vector3(3.4, 2.4, 0.1), Color(0.97, 0.97, 0.97))
	_box(Vector3(0, 0, 0.06), Vector3(3.0, 2.0, 0.04), Color(0.72, 0.88, 0.95))
	# Лампочки по рамке сверху и по бокам.
	var spots: Array[Vector3] = []
	for i in 7:
		spots.append(Vector3(-1.5 + i * 0.5, 1.4, 0.12))
	for i in 3:
		spots.append(Vector3(-1.95, 0.8 - i * 0.8, 0.12))
		spots.append(Vector3(1.95, 0.8 - i * 0.8, 0.12))
	spots.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)
	for s in spots:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.45)
		mat.emission_energy_multiplier = 0.5
		var mesh := SphereMesh.new()
		mesh.radius = 0.14
		mesh.height = 0.28
		mesh.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = s
		add_child(mi)
		_bulbs.append(mat)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 0.3, 1.5)
	_light.light_color = Color(1.0, 0.85, 0.6)
	_light.omni_range = 12.0
	_light.light_energy = 0.4
	add_child(_light)


func turn_on() -> void:
	var tw := create_tween()
	for mat in _bulbs:
		tw.tween_property(mat, "emission_energy_multiplier", 4.0, 0.18)
	tw.parallel().tween_property(_light, "light_energy", 3.0, 0.18 * _bulbs.size())
	# Блеск зеркала, пока горят лампочки.
	tw.tween_callback(Game.play_fanfare)


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.35
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)
