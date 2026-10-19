class_name CutSet
extends RefCounted
## Декорации-заглушки для роликов: гладкие коробки, сферы, цилиндры и общие материалы.
## Ролики строят комнаты этими функциями — подмена на настоящие модели делается
## внутри своего ролика, тайминги и камера при этом не меняются.


## Матовый материал предмета (дерево, ткань, пластик).
static func material(color: Color, roughness := 0.85, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


## Светящийся материал: блики, ягодки, окно, вспышки.
static func glow(color: Color, energy := 1.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.5
	return m


## Мягкий светящийся материал без бликов — окно, небо в проёме.
static func sky(color: Color, energy := 1.0) -> StandardMaterial3D:
	var m := glow(color, energy)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func add_box(parent: Node3D, name: String, size: Vector3, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, name, mesh, pos, mat)


static func add_sphere(parent: Node3D, name: String, radius: float, pos: Vector3,
		mat: Material, rings := 24) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = rings
	return _add(parent, name, mesh, pos, mat)


static func add_cylinder(parent: Node3D, name: String, top_radius: float, bottom_radius: float,
		height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 28
	return _add(parent, name, mesh, pos, mat)


static func _add(parent: Node3D, name: String, mesh: Mesh, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi
