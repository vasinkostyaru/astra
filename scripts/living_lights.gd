class_name LivingLights
extends Node3D
## Свет гостиной: торшер и гирлянда вдоль стены. Гирлянда тускло видна заранее; turn_on() — лампочки загораются
## по очереди слева направо, потом торшер. Начало координат — основание торшера на полу.

const COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.3), Color(1.0, 0.8, 0.25), Color(0.4, 0.85, 0.45), Color(0.4, 0.65, 1.0), Color(0.85, 0.5, 0.95),
]

var _bulbs: Array[StandardMaterial3D] = []
var _lamp_light: OmniLight3D
var _lamp_shade: StandardMaterial3D
var _glow_light: OmniLight3D


func _ready() -> void:
	# Торшер.
	var pole := CylinderMesh.new()
	pole.top_radius = 0.04
	pole.bottom_radius = 0.04
	pole.height = 3.4
	pole.material = _flat(Color(0.25, 0.25, 0.27))
	var pole_mi := MeshInstance3D.new()
	pole_mi.mesh = pole
	pole_mi.position = Vector3(0, 1.7, 0)
	add_child(pole_mi)
	var base := CylinderMesh.new()
	base.top_radius = 0.5
	base.bottom_radius = 0.55
	base.height = 0.1
	base.material = _flat(Color(0.25, 0.25, 0.27))
	var base_mi := MeshInstance3D.new()
	base_mi.mesh = base
	base_mi.position = Vector3(0, 0.05, 0)
	add_child(base_mi)
	_lamp_shade = StandardMaterial3D.new()
	_lamp_shade.albedo_color = Color(1.0, 0.95, 0.82)
	_lamp_shade.emission_enabled = true
	_lamp_shade.emission = Color(1.0, 0.8, 0.45)
	_lamp_shade.emission_energy_multiplier = 0.15
	var shade := CylinderMesh.new()
	shade.top_radius = 0.35
	shade.bottom_radius = 0.65
	shade.height = 0.8
	shade.material = _lamp_shade
	var shade_mi := MeshInstance3D.new()
	shade_mi.mesh = shade
	shade_mi.position = Vector3(0, 3.6, 0)
	add_child(shade_mi)
	_lamp_light = OmniLight3D.new()
	_lamp_light.position = Vector3(0, 3.4, 0.8)
	_lamp_light.light_color = Color(1.0, 0.82, 0.55)
	_lamp_light.omni_range = 14.0
	_lamp_light.light_energy = 0.3
	add_child(_lamp_light)
	_glow_light = OmniLight3D.new()
	_glow_light.position = Vector3(-3.0, 5.0, 1.5)
	_glow_light.light_color = Color(1.0, 0.85, 0.7)
	_glow_light.omni_range = 16.0
	_glow_light.light_energy = 0.0
	add_child(_glow_light)


## Гирлянда по всей длине уровня: провисающая нить с цветными лампочками на стене.
func setup(level_length: float) -> void:
	var x := 0.8
	var i := 0
	while x < level_length - 0.5:
		var sag := sin(fmod(x, 4.5) / 4.5 * PI)
		var y := 5.9 - sag * 0.7
		var mat := StandardMaterial3D.new()
		var c := COLORS[i % COLORS.size()]
		mat.albedo_color = c
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 0.35
		var mesh := SphereMesh.new()
		mesh.radius = 0.12
		mesh.height = 0.24
		mesh.radial_segments = 10
		mesh.rings = 6
		mesh.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(x - global_position.x, y, -2.85)
		add_child(mi)
		_bulbs.append(mat)
		x += 0.9
		i += 1
	# Сама нить.
	var wire := BoxMesh.new()
	wire.size = Vector3(level_length, 0.03, 0.03)
	wire.material = _flat(Color(0.2, 0.2, 0.22))
	var wire_mi := MeshInstance3D.new()
	wire_mi.mesh = wire
	wire_mi.position = Vector3(level_length * 0.5 - global_position.x, 5.55, -2.9)
	add_child(wire_mi)


func turn_on() -> void:
	var tw := create_tween()
	for mat in _bulbs:
		tw.tween_property(mat, "emission_energy_multiplier", 4.0, 0.06)
	tw.tween_callback(Game.play_fanfare)
	var lamp := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	lamp.tween_property(_lamp_light, "light_energy", 3.0, 2.0)
	lamp.tween_property(_lamp_shade, "emission_energy_multiplier", 3.0, 2.0)
	lamp.tween_property(_glow_light, "light_energy", 1.2, 3.0)


func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	return m
