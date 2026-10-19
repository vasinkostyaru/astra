class_name MainLamp
extends Node3D
## Главный светильник уровня: выключен, пока не собраны ягодки; turn_on() — плавно загорается с салютом (праздник, не прогресс света).

@export var light: Light3D
@export var glow_mesh: MeshInstance3D
@export var particles: CPUParticles3D
@export var light_energy: float = 3.0
@export var glow_energy: float = 4.0

var _glow_material: StandardMaterial3D


func _ready() -> void:
	light.light_energy = 0.0
	_glow_material = glow_mesh.get_surface_override_material(0) as StandardMaterial3D
	if _glow_material:
		_glow_material.emission_energy_multiplier = 0.0


func turn_on() -> void:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(light, "light_energy", light_energy, 1.5)
	if _glow_material:
		tw.tween_property(_glow_material, "emission_energy_multiplier", glow_energy, 1.5)
	if particles:
		particles.restart()
