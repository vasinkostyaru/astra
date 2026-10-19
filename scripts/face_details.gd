extends Node3D
## Добрые детали лица Августа поверх модели: брови «домиком», улыбка и ресницы. Крепятся к кости головы
## (двигаются вместе с ней), ставятся на поверхность лица по вершинам меша. Если у модели нет скелета с костью
## «head» или меша — молча ничего не делаем (модель можно заменить без правок кода).

## Центры глаз и середина лица в системе модели при взгляде вправо (+X): из раскраски вершин.
@export var eye_y: float = 0.768
@export var eye_z_left: float = 0.0551
@export var eye_z_right: float = -0.0459
@export var eye_x: float = 0.157
@export var mouth_y: float = 0.705
@export var brow_color: Color = Color(0.62, 0.44, 0.24)
@export var lash_color: Color = Color(0.3, 0.18, 0.1)
@export var mouth_color: Color = Color(0.78, 0.42, 0.4)

var _surface: Dictionary = {}
const CELL := 0.006


func _ready() -> void:
	var skeleton := get_parent().find_children("*", "Skeleton3D", true, false)
	var meshes := get_parent().find_children("*", "MeshInstance3D", true, false)
	if skeleton.is_empty() or meshes.is_empty():
		return
	var sk := skeleton[0] as Skeleton3D
	var bone := sk.find_bone("head")
	if bone < 0:
		return
	_scan_surface(meshes[0] as MeshInstance3D)
	var attach := BoneAttachment3D.new()
	attach.bone_name = "head"
	sk.add_child(attach)
	# Преобразование «система модели → локальная система кости головы» в позе покоя.
	var bone_xf := sk.global_transform * sk.get_bone_global_pose(bone)
	var to_bone := bone_xf.affine_inverse()
	var z0 := (eye_z_left + eye_z_right) * 0.5
	for side in [1.0, -1.0]:
		var ez: float = eye_z_left if side > 0.0 else eye_z_right
		_brow(attach, to_bone, ez, side)
		_lashes(attach, to_bone, ez, side)
	_smile(attach, to_bone, z0)


## Карта «ячейка (y, z) → самый выдвинутый вперёд x» — поверхность лица.
func _scan_surface(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var xf := mi.global_transform
	for v in verts:
		var w := xf * v
		if w.y < 0.6 or w.y > 1.0 or absf(w.z) > 0.12 or w.x < 0.0:
			continue
		var key := Vector2i(roundi(w.y / CELL), roundi(w.z / CELL))
		if not _surface.has(key) or w.x > _surface[key]:
			_surface[key] = w.x


func _x_at(y: float, z: float) -> float:
	var best := -1.0
	var cy := roundi(y / CELL)
	var cz := roundi(z / CELL)
	for dy in range(-1, 2):
		for dz in range(-1, 2):
			var key := Vector2i(cy + dy, cz + dz)
			if _surface.has(key):
				best = maxf(best, _surface[key])
	return best if best > 0.0 else eye_x


func _brow(attach: BoneAttachment3D, to_bone: Transform3D, ez: float, side: float) -> void:
	var y := eye_y + 0.068
	var z := ez + side * 0.003
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.0048
	mesh.height = 0.052
	mesh.material = _mat(brow_color)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	attach.add_child(node)
	# Лежит вдоль Z, внутренний конец чуть выше (добрый, чуть удивлённый взгляд).
	var basis := Basis(Vector3.RIGHT, deg_to_rad(90.0 + side * 12.0))
	var pos := Vector3(_x_at(y, z) + 0.001, y, z)
	node.transform = to_bone * Transform3D(basis, pos)


func _lashes(attach: BoneAttachment3D, to_bone: Transform3D, ez: float, side: float) -> void:
	# Тонкая линия верхнего века: частые мелкие точки по дуге над глазом, по краям чуть толще.
	for i in 13:
		var a := deg_to_rad(25.0 + i * 11.0)
		var z := ez + cos(a) * 0.034 * side * -1.0
		var y := eye_y + sin(a) * 0.033 + 0.002
		var edge := absf(float(i) - 6.0) / 6.0
		var mesh := SphereMesh.new()
		mesh.radius = 0.0022 + edge * 0.0008
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = _mat(lash_color)
		var node := MeshInstance3D.new()
		node.mesh = mesh
		attach.add_child(node)
		node.transform = to_bone * Transform3D(Basis(), Vector3(_x_at(y, z) + 0.0012, y, z))


func _smile(attach: BoneAttachment3D, to_bone: Transform3D, z0: float) -> void:
	var count := 17
	for i in count:
		var t := float(i) / (count - 1) * 2.0 - 1.0  # -1 … 1
		var z := z0 + t * 0.03
		var y := mouth_y + t * t * 0.013
		var mesh := SphereMesh.new()
		mesh.radius = 0.0036
		mesh.height = 0.0072
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = _mat(mouth_color)
		var node := MeshInstance3D.new()
		node.mesh = mesh
		attach.add_child(node)
		node.transform = to_bone * Transform3D(Basis(), Vector3(_x_at(y, z) + 0.001, y, z))


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	m.metallic_specular = 0.0
	return m
