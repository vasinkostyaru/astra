class_name BrickPile
extends Node3D
## Кучка кирпичиков: Август подошёл — кирпичики сами перелетают и встают лестницей.
## Начало координат — центр кучки на полу. Лестница строится от stairs_origin (левый нижний угол первой ступени).
## Каждая ступень — столбик из step_rows[i] рядов шириной step_columns кирпичиков; коллизия ступени
## включается, когда на место встал её последний кирпичик.

signal built

@export var step_rows: PackedInt32Array = PackedInt32Array([2, 4, 6])
@export_range(1, 6) var step_columns: int = 2
@export_range(0.3, 6.0, 0.1) var depth: float = 2.0
@export var stairs_origin: Vector3 = Vector3(2.2, 0, 0)
## Зона, в которой Август запускает постройку (центр — кучка).
@export var trigger_size: Vector3 = Vector3(3.0, 3.0, 3.0)
@export var color_seed: int = 0
@export var flight_time: float = 0.55
@export var brick_delay: float = 0.04
@export var step_delay: float = 0.1
@export var arc_height: float = 1.2

const BRICK := BrickBlock.BRICK
const GAP := BrickBlock.GAP
const STUD_STEP := BrickBlock.STUD_STEP

static var _brick_mesh: ArrayMesh
static var _materials: Dictionary = {}  # Color -> StandardMaterial3D

var _triggered: bool = false
var _bricks: Array[MeshInstance3D] = []
var _targets: Array[Vector3] = []
var _step_of: Array[int] = []
var _step_left: Array[int] = []
var _step_bodies: Array[CollisionShape3D] = []


func _ready() -> void:
	_build_bricks()
	_build_trigger()


func _build_trigger() -> void:
	var area := Area3D.new()
	area.monitorable = false
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = trigger_size
	col.shape = shape
	col.position = Vector3(0, trigger_size.y * 0.5, 0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _build_bricks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(color_seed) + 17
	var heap_slot := 0
	for s in step_rows.size():
		var rows := step_rows[s]
		var step_x := stairs_origin.x + s * step_columns * BRICK.x
		# Невидимое тело ступени: коллизия появляется, когда ступень достроена.
		var body := StaticBody3D.new()
		body.position = Vector3(step_x, stairs_origin.y, stairs_origin.z)
		var shape := BoxShape3D.new()
		shape.size = Vector3(step_columns * BRICK.x, rows * BRICK.y, depth)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position = Vector3(shape.size.x * 0.5, shape.size.y * 0.5, 0)
		cs.disabled = true
		body.add_child(cs)
		add_child(body)
		_step_bodies.append(cs)
		_step_left.append(rows * step_columns)

		for r in rows:
			for c in step_columns:
				var brick := MeshInstance3D.new()
				brick.mesh = _get_brick_mesh()
				brick.material_override = _get_material(_color_for(s * step_columns + c, r))
				# Куча на полу: два слоя вразброс, повёрнутые кирпичики.
				var layer := heap_slot % 2
				var hx := rng.randf_range(-0.7, 0.7)
				var hz := rng.randf_range(-0.5, 0.5)
				brick.position = Vector3(hx, (layer + 0.5) * BRICK.y, hz)
				brick.rotation.y = rng.randf_range(-PI, PI)
				brick.scale = Vector3(1, 1, 0.3)
				heap_slot += 1
				add_child(brick)
				_bricks.append(brick)
				_targets.append(Vector3(
					step_x + (c + 0.5) * BRICK.x,
					stairs_origin.y + (r + 0.5) * BRICK.y,
					stairs_origin.z))
				_step_of.append(s)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	_build()


func _build() -> void:
	var order := 0
	for i in _bricks.size():
		var brick := _bricks[i]
		var from := brick.position
		var to := _targets[i]
		# Ряды нижние летят первыми — лестница растёт снизу вверх.
		var delay := _step_of[i] * step_delay + order * brick_delay
		order += 1
		var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_interval(delay)
		tw.tween_method(_fly_step.bind(brick, from, to), 0.0, 1.0, flight_time)
		tw.tween_callback(_landed.bind(i))


func _fly_step(t: float, brick: Node3D, from: Vector3, to: Vector3) -> void:
	var e := ease(t, -1.6) if t < 1.0 else 1.0
	var p := from.lerp(to, e)
	p.y += arc_height * 4.0 * t * (1.0 - t)
	brick.position = p
	brick.rotation.y = lerp_angle(brick.rotation.y, 0.0, minf(t * 1.5, 1.0))
	brick.scale.z = lerpf(0.3, 1.0, smoothstep(0.0, 1.0, t))


func _landed(i: int) -> void:
	var brick := _bricks[i]
	brick.rotation = Vector3.ZERO
	brick.scale = Vector3.ONE
	brick.position = _targets[i]
	# Короткий «клик» на месте: чуть сжался и вернулся.
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(brick, "scale", Vector3(1.0, 0.92, 1.0), 0.05)
	tw.tween_property(brick, "scale", Vector3.ONE, 0.1)
	var s := _step_of[i]
	_step_left[s] -= 1
	if _step_left[s] == 0:
		_step_bodies[s].set_deferred("disabled", false)
		Game.play_chime(s + 1)
		if _step_left.all(func(n: int) -> bool: return n == 0):
			built.emit()


func _color_for(c: int, r: int) -> Color:
	return BrickBlock.PALETTE[posmod(hash(Vector3i(c, r, color_seed)), BrickBlock.PALETTE.size())]


## Один общий меш кирпичика с пупырками (тело + 2×N цилиндров) — все кирпичики кучки делят его.
static func _get_brick_mesh() -> ArrayMesh:
	if _brick_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var body := BoxMesh.new()
		body.size = Vector3(BRICK.x - GAP, BRICK.y - GAP, 2.0 - GAP)
		st.append_from(body, 0, Transform3D())
		var stud := CylinderMesh.new()
		stud.top_radius = 0.085
		stud.bottom_radius = 0.085
		stud.height = 0.08
		stud.radial_segments = 12
		stud.rings = 1
		var studs_z := int(2.0 / STUD_STEP)
		for sx in 2:
			for sz in studs_z:
				var x := (sx - 0.5) * BRICK.x * 0.5
				var z := (sz + 0.5) * 2.0 / studs_z - 1.0
				st.append_from(stud, 0, Transform3D(Basis(), Vector3(x, (BRICK.y - GAP) * 0.5 + 0.04, z)))
		_brick_mesh = st.commit()
	return _brick_mesh


static func _get_material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.45
		_materials[color] = m
	return _materials[color]
