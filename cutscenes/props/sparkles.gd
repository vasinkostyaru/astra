class_name CutSparkles
extends Node3D
## Блёстки-заглушка: штатные частицы Godot (мягкие светящиеся точки).
## burst() — один залп; узел удаляет сам ролик. Модель/текстура частиц меняется здесь.

@export var color := Color(1.0, 0.88, 0.55)
@export var amount := 36
@export var size := 0.06
@export var speed_min := 0.5
@export var speed_max := 1.7
@export var lifetime := 1.1

var _particles: GPUParticles3D


func _ready() -> void:
	_build()


## Один залп из текущей точки.
func burst() -> void:
	if _particles == null:
		return
	_particles.emitting = true
	_particles.restart()


func _build() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "Sparkles"
	_particles.amount = amount
	_particles.lifetime = lifetime
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.emitting = false
	_particles.local_coords = false
	_particles.visibility_aabb = AABB(Vector3(-6.0, -6.0, -6.0), Vector3(12.0, 12.0, 12.0))
	_particles.process_material = _process_material()
	_particles.draw_pass_1 = _quad()
	add_child(_particles)


func _process_material() -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = speed_min
	pm.initial_velocity_max = speed_max
	pm.gravity = Vector3(0.0, -1.2, 0.0)
	pm.damping_min = 0.3
	pm.damping_max = 0.9
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	pm.color = color
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.06
	return pm


func _quad() -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = _dot_texture()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.disable_receive_shadows = true
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	return mesh


## Мягкая точка: белый центр, прозрачный край.
func _dot_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex
