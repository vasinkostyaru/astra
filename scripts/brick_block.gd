@tool
class_name BrickBlock
extends StaticBody3D
## Блок из кирпичиков конструктора: одна коробка-коллизия, кирпичики и пупырки — через MultiMesh.
## Начало координат — левый нижний угол блока, по Z блок центрирован.

const BRICK := Vector2(0.6, 0.3)
const GAP := 0.02
const STUD_STEP := 0.3
const PALETTE: Array[Color] = [
	Color(0.9, 0.22, 0.2), Color(1.0, 0.78, 0.15), Color(0.2, 0.5, 0.95),
	Color(0.25, 0.75, 0.35), Color(1.0, 0.5, 0.15), Color(0.65, 0.4, 0.85),
]

@export_range(1, 40) var columns: int = 2:
	set(v):
		columns = v
		_queue_rebuild()
@export_range(1, 40) var rows: int = 2:
	set(v):
		rows = v
		_queue_rebuild()
@export_range(0.3, 6.0, 0.1) var depth: float = 2.0:
	set(v):
		depth = v
		_queue_rebuild()
@export var color_seed: int = 0:
	set(v):
		color_seed = v
		_queue_rebuild()

static var _material: StandardMaterial3D

var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _queue_rebuild() -> void:
	if is_node_ready():
		_rebuild()


func _rebuild() -> void:
	for n in _generated:
		n.queue_free()
	_generated.clear()

	var block := Vector3(columns * BRICK.x, rows * BRICK.y, depth)
	var shape := BoxShape3D.new()
	shape.size = block
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = block * 0.5 * Vector3(1, 1, 0)
	_add(col)

	var brick_mesh := BoxMesh.new()
	brick_mesh.size = Vector3(BRICK.x - GAP, BRICK.y - GAP, depth - GAP)
	brick_mesh.material = _get_material()
	var bricks := _make_multimesh(brick_mesh, columns * rows)

	var studs_z := maxi(1, int(depth / STUD_STEP))
	var stud_mesh := CylinderMesh.new()
	stud_mesh.top_radius = 0.085
	stud_mesh.bottom_radius = 0.085
	stud_mesh.height = 0.08
	stud_mesh.radial_segments = 12
	stud_mesh.rings = 1
	stud_mesh.material = _get_material()
	var studs := _make_multimesh(stud_mesh, columns * 2 * studs_z)

	var i := 0
	var s := 0
	for r in rows:
		for c in columns:
			var color := _color_for(c, r)
			bricks.set_instance_transform(i, Transform3D(Basis(), Vector3((c + 0.5) * BRICK.x, (r + 0.5) * BRICK.y, 0.0)))
			bricks.set_instance_color(i, color)
			i += 1
			if r == rows - 1:
				for sx in 2:
					for sz in studs_z:
						var z := (sz + 0.5) * depth / studs_z - depth * 0.5
						var x := c * BRICK.x + (sx + 0.5) * BRICK.x * 0.5
						studs.set_instance_transform(s, Transform3D(Basis(), Vector3(x, block.y + 0.04, z)))
						studs.set_instance_color(s, color)
						s += 1


func _make_multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	_add(mmi)
	return mm


func _color_for(c: int, r: int) -> Color:
	return PALETTE[posmod(hash(Vector3i(c, r, color_seed)), PALETTE.size())]


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)


static func _get_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.45
	return _material
