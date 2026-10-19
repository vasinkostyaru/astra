class_name LevelAssembler
extends Node3D
## Собирает уровень из секций: начало → середина × N → «фишка» → середина × N → конец.
## Середина — случайно из пула, одна и та же секция два раза подряд не идёт.
## Должен стоять в сцене уровня ПЕРЕД Астрой, игроком и камерой: собирает всё в _ready().

## Сид сборки; 0 — случайный. Сид текущей сборки печатается в консоль (для воспроизведения сломанной сборки).
@export var seed_value: int = 0
@export_range(0, 12) var mids_before_feature: int = 6
@export_range(0, 12) var activities_per_level: int = 3
@export_range(0, 12) var mids_after_feature: int = 6
@export var astra_path: Node3D
@export var main_lamp: Node3D
@export var camera: SideCamera
@export var room: Node3D
## Тема фона секций ("kids" / "bath") и материалы пола и стены; пустые — как в «Детской».
@export var theme: String = "kids"
@export var add_windows: bool = true
var wall_material: Material
var trim_color := Color(0.97, 0.95, 0.9)
var floor_material: Material

## Заполняет наследник для конкретной комнаты.
var start_section: GDScript
var feature_section: GDScript
var end_section: GDScript
var pool: Array[GDScript] = []
## Занятия: встают вместо случайных середин; всего activities_per_level (3) на уровень, по одному каждого вида.
var activities: Array[GDScript] = []

var used_seed: int = 0
var total_length: float = 0.0
## Имена скриптов собранных секций по порядку (для отчёта бота).
var layout: Array[String] = []
var sections: Array[LevelSection] = []

const WALL_PAD := 1.5
const LEFT_EDGE := -4.5


func _ready() -> void:
	_setup()
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	used_seed = rng.seed
	print("СБОРКА seed=", used_seed)
	assemble(rng)


func _setup() -> void:
	pass


func assemble(rng: RandomNumberGenerator) -> void:
	var order: Array[GDScript] = [start_section]
	var last: GDScript = null
	for i in mids_before_feature:
		last = _pick(rng, last)
		order.append(last)
	order.append(feature_section)
	last = null
	for i in mids_after_feature:
		last = _pick(rng, last)
		order.append(last)
	order.append(end_section)
	_place_activities(order, rng)

	var x := 0.0
	var kind := 0
	var marker_index := 0
	for i in order.size():
		var sec: LevelSection = order[i].new()
		sec.name = "Section%d" % i
		sec.position = Vector3(x, 0.0, 0.0)
		sec.theme = theme
		sec.liner_material = wall_material
		add_child(sec)
		sec.build(kind, rng.randi())
		kind += sec.berry_count
		sections.append(sec)
		layout.append((order[i] as GDScript).resource_path.get_file().get_basename())
		# Маршрут Астры: точки секции — в общий AstraPath, с уникальным суффиксом имени.
		for m in sec.markers:
			m.name = "%s_s%d" % [m.name, i]
			m.position += Vector3(x, 0.0, 0.0)
			astra_path.add_child(m)
		if sec.lamp_anchor != null and main_lamp:
			main_lamp.position = Vector3(x, 0.0, 0.0) + (sec.lamp_anchor as Vector3)
		x += sec.length
	total_length = x
	if main_lamp and main_lamp.has_method("setup"):
		main_lamp.call("setup", total_length)
	_fit_room(x)
	_add_lights(x)


## Занятия вместо случайных середин; сами секции-середины остаются на других местах, соседи занятий — обычные.
func _place_activities(order: Array[GDScript], rng: RandomNumberGenerator) -> void:
	var feature_at := order.find(feature_section)
	var slots: Array[int] = []
	for i in range(1, order.size() - 1):
		if i != feature_at and i != feature_at - 1 and i != feature_at + 1:
			slots.append(i)
	var pending: Array[GDScript] = []
	while pending.size() < activities_per_level and not activities.is_empty():
		pending.append_array(activities)
	pending.shuffle()
	var count := mini(activities_per_level, mini(pending.size(), slots.size()))
	for k in count:
		var act: GDScript = pending.pop_back()
		# Занятия не стоят рядом друг с другом.
		for attempt in 20:
			var s := slots[rng.randi_range(0, slots.size() - 1)]
			if not (order[s - 1] in activities or order[s + 1] in activities):
				order[s] = act
				slots.erase(s)
				break


func _pick(rng: RandomNumberGenerator, last: GDScript) -> GDScript:
	var options := pool.filter(func(s: GDScript) -> bool: return s != last)
	return options[rng.randi_range(0, options.size() - 1)]


## Пол, задняя стена и правая стена по длине уровня.
func _fit_room(length: float) -> void:
	var right := length + WALL_PAD
	var width := right - LEFT_EDGE
	var mid := (right + LEFT_EDGE) * 0.5
	_build_floor(LEFT_EDGE, right)
	var wall := room.get_node("BackWall") as MeshInstance3D
	wall.position.x = mid
	var wm := (wall.mesh as BoxMesh).duplicate() as BoxMesh
	wm.size.x = width
	wall.mesh = wm
	(room.get_node("RightWall") as Node3D).position.x = right + 0.5
	(room.get_node("LeftWall") as Node3D).position.x = LEFT_EDGE - 0.5
	if wall_material == null:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://sections/wallpaper.gdshader")
		wall_material = mat
	wall.set_surface_override_material(0, wall_material)
	for side in ["LeftWall", "RightWall"]:
		(room.get_node(side + "/Mesh") as MeshInstance3D).set_surface_override_material(0, wall_material)
	_add_trim_and_windows(length)
	if camera:
		camera.limit_left = 1.5
		camera.limit_right = length - 2.5


## Пол сегментами между дырами (поддонами с водой), все секции собраны.
func _build_floor(left: float, right: float) -> void:
	var original := room.get_node("Floor") as StaticBody3D
	if floor_material == null:
		floor_material = (original.get_node("Mesh") as MeshInstance3D).get_surface_override_material(0)
	original.queue_free()
	var from := left
	for p in _pits_world():
		_floor_segment(from, p.x)
		from = p.y
	_floor_segment(from, right)


func _floor_segment(x0: float, x1: float) -> void:
	if x1 - x0 < 0.01:
		return
	var body := StaticBody3D.new()
	body.position = Vector3((x0 + x1) * 0.5, -2.0, 0.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(x1 - x0, 4.0, 8.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	mesh.material = floor_material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	body.add_child(mi)
	room.add_child(body)


## Плинтус по всей длине и окна с шторами и луной через каждые ~25 м.
func _add_trim_and_windows(length: float) -> void:
	# Плинтус кусками между поддонами: над водой его нет.
	var from := LEFT_EDGE
	for p in _pits_world():
		_add_trim(from, p.x)
		from = p.y
	_add_trim(from, length + WALL_PAD)
	var x := 12.0
	while add_windows and x < length - 6.0:
		_add_window(x)
		x += 25.0


func _add_trim(x0: float, x1: float) -> void:
	if x1 - x0 < 0.05:
		return
	var trim := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(x1 - x0, 0.45, 0.1)
	tm.material = _flat(trim_color)
	trim.mesh = tm
	trim.position = Vector3((x0 + x1) * 0.5, 0.22, -2.95)
	add_child(trim)


func _pits_world() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for sec in sections:
		for p in sec.pits:
			result.append(p + Vector2(sec.position.x, sec.position.x))
	result.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return result


func _add_window(x: float) -> void:
	_deco_box(Vector3(x, 5.0, -2.96), Vector3(3.4, 3.8, 0.08), Color(0.97, 0.95, 0.9))
	_deco_box(Vector3(x, 5.0, -2.9), Vector3(3.0, 3.4, 0.08), Color(0.08, 0.1, 0.25))
	_deco_box(Vector3(x, 5.0, -2.86), Vector3(0.06, 3.4, 0.05), Color(0.97, 0.95, 0.9))
	_deco_box(Vector3(x - 1.9, 5.0, -2.8), Vector3(0.9, 4.4, 0.25), Color(0.95, 0.5, 0.4))
	_deco_box(Vector3(x + 1.9, 5.0, -2.8), Vector3(0.9, 4.4, 0.25), Color(0.95, 0.5, 0.4))
	var moon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.8
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(1, 0.95, 0.75)
	sm.material = mm
	moon.mesh = sm
	moon.position = Vector3(x + 0.6, 5.6, -2.84)
	add_child(moon)


func _deco_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _flat(color)
	mi.mesh = bm
	mi.position = pos
	add_child(mi)


func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m


## Тёплые «пятна света» через каждые ~7 м вдоль уровня.
func _add_lights(length: float) -> void:
	var x := 1.0
	while x < length:
		var l := OmniLight3D.new()
		l.position = Vector3(x, 4.5, 2.5)
		l.light_color = Color(1, 0.75, 0.45)
		l.light_energy = 0.6
		l.omni_range = 8.0
		add_child(l)
		x += 7.0
