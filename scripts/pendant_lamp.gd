class_name PendantLamp
extends Node3D
## Лампа над столом на шнуре (главный светильник кухни). turn_on() — загорается с конфетти.
## Начало координат — центр абажура; шнур уходит вверх.

var _bulb: StandardMaterial3D
var _light: OmniLight3D
var _confetti: CPUParticles3D


func _ready() -> void:
	var cord := CylinderMesh.new()
	cord.top_radius = 0.025
	cord.bottom_radius = 0.025
	cord.height = 4.0
	cord.material = _flat(Color(0.15, 0.15, 0.17))
	var cord_mi := MeshInstance3D.new()
	cord_mi.mesh = cord
	cord_mi.position = Vector3(0, 2.2, 0)
	add_child(cord_mi)
	var shade := CylinderMesh.new()
	shade.top_radius = 0.12
	shade.bottom_radius = 0.75
	shade.height = 0.55
	shade.material = _flat(Color(0.035, 0.037, 0.042))
	var shade_mi := MeshInstance3D.new()
	shade_mi.mesh = shade
	add_child(shade_mi)
	var rim := CylinderMesh.new()
	rim.top_radius = 0.75
	rim.bottom_radius = 0.75
	rim.height = 0.05
	rim.material = _flat(Color(0.72, 0.5, 0.3))
	var rim_mi := MeshInstance3D.new()
	rim_mi.mesh = rim
	rim_mi.position = Vector3(0, -0.28, 0)
	add_child(rim_mi)
	_bulb = StandardMaterial3D.new()
	_bulb.albedo_color = Color(1.0, 0.95, 0.8)
	_bulb.emission_enabled = true
	_bulb.emission = Color(1.0, 0.8, 0.45)
	_bulb.emission_energy_multiplier = 0.4
	var bulb := SphereMesh.new()
	bulb.radius = 0.22
	bulb.height = 0.44
	bulb.material = _bulb
	var bulb_mi := MeshInstance3D.new()
	bulb_mi.mesh = bulb
	bulb_mi.position = Vector3(0, -0.35, 0)
	add_child(bulb_mi)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, -0.5, 0.5)
	_light.light_color = Color(1.0, 0.82, 0.55)
	_light.omni_range = 12.0
	_light.light_energy = 0.4
	add_child(_light)
	var spark := SphereMesh.new()
	spark.radius = 0.06
	spark.height = 0.12
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.85, 0.4)
	smat.vertex_color_use_as_albedo = true
	spark.material = smat
	_confetti = CPUParticles3D.new()
	_confetti.mesh = spark
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.amount = 48
	_confetti.lifetime = 1.8
	_confetti.explosiveness = 0.9
	_confetti.direction = Vector3(0, 1, 0)
	_confetti.spread = 70.0
	_confetti.gravity = Vector3(0, -2.5, 0)
	_confetti.initial_velocity_min = 2.5
	_confetti.initial_velocity_max = 4.5
	_confetti.position = Vector3(0, -0.4, 0.5)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1, 0.95, 0.6), Color(1, 0.55, 0.3)])
	_confetti.color_ramp = grad
	add_child(_confetti)


func turn_on() -> void:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(_light, "light_energy", 3.2, 1.5)
	tw.tween_property(_bulb, "emission_energy_multiplier", 5.0, 1.5)
	_confetti.restart()


func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.5
	return m
