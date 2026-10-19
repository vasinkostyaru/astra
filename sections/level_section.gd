class_name LevelSection
extends Node3D
## Секция уровня — кусок комнаты, из которых собирается уровень (см. LevelAssembler).
## Правила (иначе стыки ломают проходимость):
##  - локальные координаты: вход в x = 0, выход в x = length, пол комнаты на y = 0;
##  - на входе и на выходе секции поверхность — пол (y = 0), все подъёмы и спуски внутри;
##  - ступени от 0.45 до 0.9 (подъём ровно 0.3 = радиус капсулы Августа — он упирается в ребро и застревает),
##    промежутки не шире ~2.0; под промежутком, из которого не вылезти, — подушка.
## Наследник переопределяет _build() и задаёт length.

const BERRY := preload("res://scenes/common/berry.tscn")
const CHECKPOINT := preload("res://scenes/common/checkpoint.tscn")
const PILLOW := preload("res://scenes/common/bounce_pillow.tscn")
const PILE := preload("res://scenes/common/brick_pile.tscn")
const BLOCK := preload("res://scenes/common/brick_block.tscn")

static var _materials: Dictionary = {}  # Color -> StandardMaterial3D

var length: float = 10.0
## Где в секции ставить главный светильник (только у финальной секции).
var lamp_anchor: Variant = null
## Маршрут Астры: Marker3D по порядку (имена — как в Astra: Stop_*, Run_*, Exit_*).
var markers: Array[Marker3D] = []
var berry_count: int = 0
## Ковёр-пятно на полу под секцией (у начала, «фишки» и конца свой пол).
var has_rug: bool = true

## Дыры в полу (поддон с водой): диапазоны x в координатах секции.
var pits: Array[Vector2] = []
## Тема фона: "kids" или "bath".
var theme: String = "kids"
## Материал задней стенки поддона (та же плитка, что на стене комнаты); пусто — светлая заглушка.
var liner_material: Material
var _berry_kind: int = 0
var _pillows: int = 0

const PILLOW_COLORS: Array[Color] = [Color(1.0, 0.55, 0.7), Color(1.0, 0.85, 0.3), Color(0.55, 0.85, 0.7), Color(0.75, 0.6, 0.95)]


func build(kind_offset: int, deco_seed: int) -> void:
	_berry_kind = kind_offset
	_build()
	_backdrop(deco_seed)


func _build() -> void:
	pass


## Коробка-опора: x — левый край, y — низ, размеры w × h; по Z — depth по центру.
## Скруглённая, с зерном, затемнённым низом и мягкой тенью на полу.
func box(x: float, y: float, w: float, h: float, color: Color, depth: float = 2.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = Vector3(x + w * 0.5, y + h * 0.5, 0.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, h, depth)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = _rounded_mesh(shape.size, 0.12, y)
	mi.material_override = _soft_material(color, _surface())
	if y < 0.05 and depth < 4.0:
		_floor_shadow(x, w, depth)
	body.add_child(mi)
	add_child(body)
	return body


static var _rounded: Dictionary = {}  # "size|y" -> ArrayMesh
static var _soft: Dictionary = {}  # "цвет|поверхность" -> StandardMaterial3D
static var _grain: Texture2D
static var _shadow_tex: Texture2D
static var _shadow_mat: StandardMaterial3D


## Куб со скруглёнными рёбрами (радиус r); цвет вершин — «ненастоящая» AO: низ темнее.
## bottom_y — высота низа блока над полом (чем ниже, тем темнее у пола).
static func _rounded_mesh(size: Vector3, r: float, bottom_y: float) -> ArrayMesh:
	var key := "%s|%.2f" % [size, bottom_y]
	if _rounded.has(key):
		return _rounded[key]
	var half := size * 0.5
	r = minf(r, minf(half.x, minf(half.y, half.z)) * 0.9)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stops: Array[Array] = []
	for ax in 3:
		var h: float = half[ax]
		var f: Array[float] = [-h, -h + r * 0.29, -h + r * 0.71, -h + r, h - r, h - r * 0.71, h - r * 0.29, h]
		stops.append(f)
	for ax in 3:
		var u := (ax + 1) % 3
		var v := (ax + 2) % 3
		for sign in [-1.0, 1.0]:
			var grid: Array = []
			for iu in stops[u].size():
				var row: Array = []
				for iv in stops[v].size():
					var p := Vector3.ZERO
					p[ax] = half[ax] * sign
					p[u] = stops[u][iu]
					p[v] = stops[v][iv]
					var c := p.clamp(-half + Vector3.ONE * r, half - Vector3.ONE * r)
					var d := p - c
					var n := d.normalized()
					p = c + n * r
					var ao := lerpf(0.7, 1.0, clampf((bottom_y + p.y + half.y) / 0.7, 0.0, 1.0))
					row.append([p, n, Color(ao, ao, ao)])
				grid.append(row)
			for iu in stops[u].size() - 1:
				for iv in stops[v].size() - 1:
					var a: Array = grid[iu][iv]
					var b: Array = grid[iu + 1][iv]
					var c2: Array = grid[iu + 1][iv + 1]
					var d2: Array = grid[iu][iv + 1]
					var quad: Array = [a, b, c2, a, c2, d2]
					if sign > 0.0:
						quad = [a, c2, b, a, d2, c2]
					for q in quad:
						st.set_normal(q[1])
						st.set_color(q[2])
						st.add_vertex(q[0])
	var mesh := st.commit()
	_rounded[key] = mesh
	return mesh


const SURFACES := {
	"fabric": [preload("res://assets/textures/surfaces/fabric.png"), preload("res://assets/textures/surfaces/fabric_n.png"), 1.2],
	"wood": [preload("res://assets/textures/surfaces/wood.png"), preload("res://assets/textures/surfaces/wood_n.png"), 0.35],
	"carpet": [preload("res://assets/textures/surfaces/carpet.png"), preload("res://assets/textures/surfaces/carpet_n.png"), 0.8],
}


## Чем покрыты блоки в этой комнате: ткань (детская, гостиная), дерево (кухня), гладкое с зерном (ванная).
func _surface() -> String:
	match theme:
		"kitchen":
			return "wood"
		"bath":
			return "grain"
	return "fabric"


## Матовый материал с текстурой поверхности (трипланарная — без UV, одинаковый масштаб на всех блоках).
## Текстуры серые: цвет блока задаёт color.
static func _soft_material(color: Color, surface: String = "grain") -> StandardMaterial3D:
	var key := "%s|%s" % [color, surface]
	if not _soft.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.vertex_color_use_as_albedo = true
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.roughness = 0.9
		m.metallic_specular = 0.2
		if SURFACES.has(surface):
			var t: Array = SURFACES[surface]
			m.albedo_texture = t[0]
			m.normal_enabled = true
			m.normal_texture = t[1]
			m.normal_scale = 0.8
			m.uv1_scale = Vector3.ONE * float(t[2])
		else:
			m.albedo_texture = _grain_texture()
			m.uv1_scale = Vector3.ONE * 0.6
			m.roughness = 0.6
		_soft[key] = m
	return _soft[key]


static func _grain_texture() -> Texture2D:
	if _grain == null:
		var noise := FastNoiseLite.new()
		noise.frequency = 0.06
		noise.fractal_octaves = 3
		var img := noise.get_seamless_image(128, 128)
		for yy in 128:
			for xx in 128:
				var g := lerpf(0.86, 1.0, img.get_pixel(xx, yy).r)
				img.set_pixel(xx, yy, Color(g, g, g))
		_grain = ImageTexture.create_from_image(img)
	return _grain


## Мягкая тень у основания блока на полу.
func _floor_shadow(x: float, w: float, depth: float) -> void:
	if _shadow_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for yy in 64:
			for xx in 64:
				var d := Vector2(xx - 31.5, yy - 31.5).length() / 32.0
				img.set_pixel(xx, yy, Color(0, 0, 0, 0.5 * clampf(1.0 - d, 0.0, 1.0) ** 0.8))
		_shadow_tex = ImageTexture.create_from_image(img)
		_shadow_mat = StandardMaterial3D.new()
		_shadow_mat.albedo_texture = _shadow_tex
		_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var plane := PlaneMesh.new()
	plane.size = Vector2(w + 1.2, depth + 1.0)
	plane.material = _shadow_mat
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(x + w * 0.5, 0.045, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Только картинка, без коллизии (ковёр, рисунок на стене).
func decor(x: float, y: float, w: float, h: float, z: float, d: float, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(w, h, d)
	mesh.material = _material(color)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(x + w * 0.5, y + h * 0.5, z)
	add_child(mi)
	return mi


## Блок из кирпичиков конструктора (x — левый край, y — низ).
func bricks(x: float, y: float, columns: int, rows: int, seed_value: int, depth: float = 2.0, z: float = 0.0) -> BrickBlock:
	var b: BrickBlock = BLOCK.instantiate()
	b.columns = columns
	b.rows = rows
	b.depth = depth
	b.color_seed = seed_value
	b.position = Vector3(x, y, z)
	add_child(b)
	return b


func berry(x: float, y: float) -> Berry:
	var b: Berry = BERRY.instantiate()
	b.kind = _berry_kind % 5
	_berry_kind += 1
	b.position = Vector3(x, y, 0.0)
	add_child(b)
	berry_count += 1
	return b


## Ряд ягодок на одной высоте.
func berry_row(x: float, y: float, count: int, step: float = 0.9) -> void:
	for i in count:
		berry(x + i * step, y)


func checkpoint(x: float, y: float) -> void:
	var c: Checkpoint = CHECKPOINT.instantiate()
	c.position = Vector3(x, y, 0.0)
	add_child(c)


## Подушка поперёк промежутка [x, x + width] на полу: ловит упавшего и возвращает к чекпоинту.
func pillow_gap(x: float, width: float) -> void:
	var p: BouncePillow = PILLOW.instantiate()
	p.position = Vector3(x + width * 0.5, 0.0, 0.0)
	add_child(p)
	# Форма-триггер общая для всех подушек — делаем свою, по ширине промежутка.
	var col := p.get_node("CollisionShape3D") as CollisionShape3D
	var shape := (col.shape as BoxShape3D).duplicate() as BoxShape3D
	shape.size.x = width
	col.shape = shape
	var mesh_node := p.get_node("Pillow/Mesh") as MeshInstance3D
	mesh_node.scale.x = width / 1.2
	mesh_node.set_surface_override_material(0, _material(PILLOW_COLORS[_pillows % PILLOW_COLORS.size()]))
	_pillows += 1


## Поддон с водой на месте [x, x + width]: в полу дыра, внизу дно, по бокам белая облицовка, сверху вода.
## Упавшего ловит вода (круг выносит к чекпоинту). Игрушки (FloatingToy) ставит секция сама.
func water_pit(x: float, width: float, depth: float = 1.6) -> void:
	pits.append(Vector2(x, x + width))
	var bottom := box(x, -depth - 0.6, width, 0.6, Color(0.9, 0.9, 0.92), 6.0)
	bottom.collision_layer = 1
	decor(x - 0.04, -depth, 0.1, depth, 0.0, 6.0, WHITE)
	decor(x + width - 0.06, -depth, 0.1, depth, 0.0, 6.0, WHITE)
	var back := decor(x, -depth - 0.3, width, depth + 0.3, -3.0, 0.1, Color(0.9, 0.93, 0.97))
	if liner_material:
		back.material_override = liner_material
	var water := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(width, 0.02, 6.0)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://sections/water.gdshader")
	wm.material = mat
	water.mesh = wm
	water.position = Vector3(x + width * 0.5, -0.45, 0.0)
	add_child(water)
	var zone := WaterZone.new()
	zone.width = width
	zone.position = Vector3(x + width * 0.5, 0.0, 0.0)
	add_child(zone)


## Переправа через воду: count плавающих игрушек подряд (типы по кругу, начиная с first_kind), берега по 1.5 м,
## чекпоинт на берегу и на средней игрушке, ягодки над промежутками. Возвращает x конца поддона.
## heights — необязательные уровни игрушек (лесенка): по умолчанию все на воде.
func water_crossing(x: float, count: int, first_kind: int = 0, heights: Array[float] = []) -> float:
	var width := 1.6 + count * FloatingToy.WIDTH + (count - 1) * 1.5 + 1.3
	water_pit(x, width)
	checkpoint(x - 0.8, 0.0)
	for i in count:
		var left := x + 1.6 + i * (FloatingToy.WIDTH + 1.5)
		var t := floating_toy(left, (first_kind + i) % 4)
		var h := heights[i] if i < heights.size() else 0.0
		t.position.y = h
		var cx := left + FloatingToy.WIDTH * 0.5
		berry(cx + FloatingToy.WIDTH * 0.5 + 0.75, 2.0 + h)
		if i == count / 2:
			checkpoint(cx, h + 0.2)
	checkpoint(x + width + 0.8, 0.0)
	return x + width


func floating_toy(x: float, kind: int) -> FloatingToy:
	var t := FloatingToy.new()
	t.kind = kind as FloatingToy.Kind
	t.position = Vector3(x + FloatingToy.WIDTH * 0.5, 0.0, 0.0)
	add_child(t)
	return t


func marker(marker_name: String, x: float, y: float) -> void:
	var m := Marker3D.new()
	m.name = marker_name
	m.position = Vector3(x, y, -0.45)
	markers.append(m)


const RUGS: Array[Color] = [
	Color(0.85, 0.45, 0.45), Color(0.45, 0.65, 0.85), Color(0.95, 0.75, 0.35),
	Color(0.5, 0.75, 0.5), Color(0.75, 0.55, 0.8), Color(0.9, 0.6, 0.4),
]
const WALL_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.3), Color(0.3, 0.55, 0.9), Color(0.95, 0.8, 0.25),
	Color(0.35, 0.75, 0.45), Color(0.8, 0.5, 0.85), Color(0.95, 0.55, 0.25),
]


## Фон: ковёр на полу, постеры, шкафчики с книжками, воздушные шарики и кучки кубиков на заднем плане.
## Только картинка — на проходимость не влияет (всё глубже z = -1.2, выше пола).
func _backdrop(deco_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = deco_seed
	if theme == "bath":
		_backdrop_bath(rng)
		return
	if theme == "kitchen":
		_backdrop_kitchen(rng)
		return
	if theme == "living":
		_backdrop_living(rng)
		return
	if has_rug:
		_rug(0.6, length - 0.6, 3.4, RUGS[rng.randi() % RUGS.size()])
	var x := 0.6
	while x < length - 3.0:
		match rng.randi() % 6:
			0:
				bricks(x, 0.0, rng.randi_range(2, 3), rng.randi_range(2, 5), rng.randi(), 0.6, -2.3)
				x += 2.6
			1:
				_poster(x, rng)
				x += 2.8
			2:
				_bookshelf(x, rng)
				x += 3.8
			3:
				_balloons(x, rng)
				x += 2.4
			4:
				_teddy(x, rng)
				x += 2.4
			5:
				_toy_balls(x, rng)
				x += 2.6
		x += rng.randf_range(0.4, 1.4)


const WHITE := Color(0.97, 0.97, 0.98)
const BATH_COLORS: Array[Color] = [
	Color(0.3, 0.6, 0.9), Color(0.95, 0.8, 0.25), Color(0.35, 0.75, 0.55),
	Color(0.85, 0.45, 0.75), Color(0.95, 0.55, 0.25), Color(0.5, 0.85, 0.9),
]


## Фон ванной: раковина с зеркалом, полотенца, полка с флаконами, круглое зеркало, душевая стенка, надувной лебедь.
func _backdrop_bath(rng: RandomNumberGenerator) -> void:
	if has_rug:
		_rug(0.8, length - 0.8, 2.6, Color(0.97, 0.93, 0.88))  # коврик
	var x := 0.6
	while x < length - 3.0:
		if _over_pit(x, x + 3.4):
			x += 0.8
			continue
		match rng.randi() % 6:
			0:
				_sink(x)
				x += 3.0
			1:
				_towels(x, rng)
				x += 2.8
			2:
				_bottle_shelf(x, rng)
				x += 3.0
			3:
				_round_mirror(x)
				x += 2.6
			4:
				_shower_glass(x)
				x += 3.4
			5:
				var holder := Node3D.new()
				holder.position = Vector3(x + 1.1, 0.0, -2.1)
				holder.scale = Vector3.ONE * 0.9
				add_child(holder)
				FloatingToy.build_visual((rng.randi() % 2) as FloatingToy.Kind, holder)
				holder.position.y = 0.45
				x += 3.0
		x += rng.randf_range(0.4, 1.2)


## Ковёр на полу [x0, x1] без кусков над водой (иначе он «висит» над поддоном).
func _rug(x0: float, x1: float, depth: float, color: Color) -> void:
	var from := x0
	var cuts: Array[Vector2] = pits.duplicate()
	cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for p in cuts:
		if p.x - from > 0.3:
			decor(from, 0.0, p.x - from, 0.03, 0.0, depth, color).material_override = _soft_material(color, "carpet")
		from = maxf(from, p.y)
	if x1 - from > 0.3:
		decor(from, 0.0, x1 - from, 0.03, 0.0, depth, color).material_override = _soft_material(color, "carpet")


const CHARCOAL := Color(0.035, 0.037, 0.042)
const WOOD_TOP := Color(0.72, 0.67, 0.60)
const STEEL := Color(0.78, 0.8, 0.84)


## Опора-тумба: угольный фасад и деревянная столешница сверху. x — левый край, w × h.
func counter(x: float, w: float, h: float) -> void:
	box(x, 0.0, w, h, CHARCOAL)
	decor(x - 0.05, h - 0.09, w + 0.1, 0.1, 0.0, 2.2, WOOD_TOP)
	decor(x + w * 0.5 - 0.35, h * 0.55, 0.7, 0.05, 1.02, 0.06, WOOD_TOP)


## Стул лицом к экрану: сиденье на высоте h (коллизия — сплошной блок), спинка позади сиденья (z < 0),
## чтобы Август не проходил сквозь неё и она не мешала залезать.
func chair(x: float, h: float = 0.9, w: float = 1.8) -> void:
	box(x, 0.0, w, h, Color(0.66, 0.61, 0.54))
	decor(x + 0.05, h, w - 0.1, 1.3, -0.9, 0.18, Color(0.6, 0.55, 0.48))
	for i in 3:
		decor(x + 0.25 + i * (w - 0.5) / 2.0 - 0.06, h + 0.4, 0.12, 0.8, -0.78, 0.06, Color(0.56, 0.51, 0.44))
	decor(x + 0.1, h - 0.1, w - 0.2, 0.1, 1.02, 0.06, Color(0.76, 0.71, 0.64))


## Стол: деревянная столешница на высоте h.
func table(x: float, w: float, h: float) -> void:
	box(x, 0.0, w, h, Color(0.64, 0.59, 0.52))
	decor(x - 0.08, h - 0.14, w + 0.16, 0.16, 0.0, 2.3, WOOD_TOP)


## Кастрюля-платформа: блок высотой h с ручками по бокам (сверху плоская — по ней ходят).
func pot(x: float, w: float, h: float, color: Color) -> void:
	box(x, 0.0, w, h, color)
	decor(x - 0.12, h - 0.35, 0.16, 0.14, 0.0, 0.5, Color(0.12, 0.12, 0.14))
	decor(x + w - 0.04, h - 0.35, 0.16, 0.14, 0.0, 0.5, Color(0.12, 0.12, 0.14))
	decor(x + 0.1, h * 0.5, w - 0.2, 0.05, 1.02, 0.06, color.lightened(0.25))


## Фон кухни: сплошной ряд угольных тумб с деревянной столешницей, фартук, верхние шкафчики, холодильник,
## вытяжка, полка с банками и часы — обоев видно только сверху.
func _backdrop_kitchen(rng: RandomNumberGenerator) -> void:
	if has_rug:
		_rug(0.8, length - 0.8, 2.6, Color(0.55, 0.62, 0.5))
	var x := 0.0
	while x < length:
		var kind := rng.randi() % 4
		if x + 4.4 > length:
			kind = 0
		match kind:
			0, 1:
				_lower_run(x, 4.4)
				_upper_run(x, 4.4)
				x += 4.4
			2:
				_fridge(x)
				x += 2.4
			3:
				_lower_run(x, 4.4)
				_hood(x)
				x += 4.4
		if rng.randi() % 3 == 0 and x + 2.0 < length:
			_lower_run(x, 2.0)
			_wall_clock(x + 0.2)
			_jar_shelf(x, rng, 2.0)
			x += 2.0


## Нижние тумбы: фасады-дверцы с ручками, деревянная столешница, светлый фартук над ней.
func _lower_run(x: float, w: float) -> void:
	decor(x, 0.0, w, 1.7, -2.5, 1.0, CHARCOAL)
	decor(x - 0.02, 1.7, w + 0.04, 0.12, -2.45, 1.1, WOOD_TOP)
	var doors := maxi(1, int(round(w / 1.4)))
	var dw := w / doors
	for i in doors:
		decor(x + 0.08 + i * dw, 0.2, dw - 0.16, 1.4, -1.97, 0.04, Color(0.06, 0.063, 0.07))
		decor(x + dw * (i + 0.5) - 0.25, 1.35, 0.5, 0.05, -1.93, 0.04, STEEL)
	decor(x, 1.82, w, 1.2, -2.93, 0.05, WOOD_TOP)


func _upper_run(x: float, w: float) -> void:
	decor(x, 3.0, w, 2.0, -2.7, 0.7, CHARCOAL)
	var doors := maxi(1, int(round(w / 1.4)))
	var dw := w / doors
	for i in doors:
		decor(x + 0.08 + i * dw, 3.1, dw - 0.16, 1.8, -2.33, 0.04, Color(0.06, 0.063, 0.07))
		decor(x + dw * (i + 0.5) - 0.25, 3.2, 0.5, 0.05, -2.29, 0.04, STEEL)


func _fridge(x: float) -> void:
	decor(x, 0.0, 2.4, 5.0, -2.5, 1.2, Color(0.5, 0.52, 0.55))
	decor(x + 1.85, 1.2, 0.08, 1.2, -1.87, 0.08, STEEL)
	decor(x + 1.85, 3.3, 0.08, 0.8, -1.87, 0.08, STEEL)
	decor(x, 3.1, 2.4, 0.05, -1.88, 0.02, Color(0.3, 0.32, 0.35))


## Готовая модель (GLB) без коллизии: по центру x, низом на y, высотой height.
func prop(model: String, x: float, y: float, z: float, height: float) -> Node3D:
	var root := Node3D.new()
	var scene := load("res://assets/models/kenney/%s.glb" % model) as PackedScene
	if scene == null:
		return root
	var inst := scene.instantiate() as Node3D
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for n in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var bb := mi.transform * mi.get_aabb()
		lo = lo.min(bb.position)
		hi = hi.max(bb.end)
	inst.position = Vector3(-(lo.x + hi.x) * 0.5, -lo.y, -(lo.z + hi.z) * 0.5)
	root.add_child(inst)
	root.scale = Vector3.ONE * (height / maxf(hi.y - lo.y, 0.001))
	root.position = Vector3(x, y, z)
	add_child(root)
	return root


func _jar_shelf(x: float, rng: RandomNumberGenerator, w: float = 3.0) -> void:
	var y := 3.1
	decor(x, y, w, 0.1, -2.7, 0.7, WOOD_TOP)
	var items: Array[String] = ["bottle-oil", "honey", "can", "mug", "pepper-mill", "shaker-salt", "cup-tea", "bowl"]
	for i in int((w - 0.2) / 0.7):
		prop(items[rng.randi() % items.size()], x + 0.45 + i * 0.7, y + 0.1, -2.65, rng.randf_range(0.5, 0.85))


func _wall_clock(x: float) -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 0.7
	ring.bottom_radius = 0.7
	ring.height = 0.1
	ring.material = _material(CHARCOAL)
	var ri := MeshInstance3D.new()
	ri.mesh = ring
	ri.rotation.x = PI * 0.5
	ri.position = Vector3(x + 1.0, 5.7, -2.95)
	add_child(ri)
	var face := CylinderMesh.new()
	face.top_radius = 0.58
	face.bottom_radius = 0.58
	face.height = 0.1
	face.material = _material(Color(0.97, 0.96, 0.9))
	var fi := MeshInstance3D.new()
	fi.mesh = face
	fi.rotation.x = PI * 0.5
	fi.position = Vector3(x + 1.0, 5.7, -2.9)
	add_child(fi)
	decor(x + 0.97, 5.7, 0.06, 0.4, -2.84, 0.04, CHARCOAL)
	decor(x + 1.0, 5.67, 0.3, 0.06, -2.84, 0.04, CHARCOAL)


func _hood(x: float) -> void:
	decor(x, 3.0, 4.4, 0.6, -2.6, 1.2, CHARCOAL)
	decor(x + 1.6, 3.6, 1.2, 1.8, -2.8, 0.7, CHARCOAL)
	# Половник и сковородка на рейке под вытяжкой (на фартуке).
	decor(x + 0.4, 2.85, 3.6, 0.06, -2.8, 0.06, STEEL)
	decor(x + 0.9, 1.9, 0.06, 0.95, -2.8, 0.06, STEEL)
	decor(x + 0.7, 1.4, 0.5, 0.5, -2.8, 0.06, Color(0.08, 0.08, 0.09))
	decor(x + 2.8, 2.0, 0.06, 0.85, -2.8, 0.06, STEEL)
	decor(x + 2.68, 1.75, 0.3, 0.3, -2.8, 0.06, STEEL)


const SOFA := Color(0.78, 0.74, 0.68)
const ORANGE := Color(1.0, 0.4, 0.04)
const CURTAIN := Color(0.42, 0.57, 0.38)
const CUSHION_COLORS: Array[Color] = [
	Color(0.9, 0.3, 0.3), Color(0.25, 0.55, 0.85), Color(0.95, 0.78, 0.2), Color(0.35, 0.72, 0.45),
	Color(0.85, 0.45, 0.7), Color(0.95, 0.55, 0.2), Color(0.5, 0.4, 0.8), Color(0.3, 0.75, 0.75),
]


## Пуф: мягкий низкий блок-ступенька.
func pouf(x: float, w: float, h: float, color: Color) -> void:
	box(x, 0.0, w, h, color)
	decor(x + 0.1, h - 0.06, w - 0.2, 0.08, 1.02, 0.06, color.lightened(0.2))


## Диван (светлый серо-бежевый): сиденье высотой h — платформа, спинка позади, разноцветные подушки у спинки.
func sofa(x: float, w: float, h: float = 0.9) -> void:
	box(x, 0.0, w, h, SOFA)
	decor(x + 0.05, h, w - 0.1, 1.3, -0.9, 0.3, SOFA.darkened(0.06))
	decor(x + 0.12, h - 0.06, w - 0.24, 0.1, 1.02, 0.06, SOFA.lightened(0.12))
	_cushions(x, w, h)


func _cushions(x: float, w: float, y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 100.0)
	var n := maxi(3, int(w / 0.8))
	for i in n:
		var c := CUSHION_COLORS[rng.randi() % CUSHION_COLORS.size()]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.75, 0.75, 0.22)
		mesh.material = _material(c)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(x + 0.5 + i * (w - 1.0) / maxf(n - 1, 1), y + 0.45, -0.6)
		mi.rotation = Vector3(-0.25, 0.0, rng.randf_range(-0.35, 0.35))
		add_child(mi)


const WOOD_DARK := Color(0.28, 0.16, 0.09)


## Винтажное оранжевое кресло: тёмное дерево, четыре ножки, изогнутые подлокотники, две оранжевые подушки
## (сиденье и спинка). Сиденье на высоте h — платформа: коллизия сплошная, но не видна.
func armchair(x: float, w: float = 2.4, h: float = 0.9) -> void:
	var body := box(x, 0.0, w, h, ORANGE)
	body.get_child(1).visible = false
	_vintage_chair(x, w, h, 0.0)


## Только картинка винтажного кресла; z0 — на какой глубине стоит (0 — в плоскости Августа).
func _vintage_chair(x: float, w: float, h: float, z0: float) -> void:
	# Четыре ножки и рама под сиденьем.
	for lx in [x + 0.06, x + w - 0.2]:
		for lz in [z0 + 0.6, z0 - 0.7]:
			decor(lx, 0.0, 0.14, h - 0.3, lz, 0.14, WOOD_DARK)
	decor(x, h - 0.42, w, 0.14, z0, 1.5, WOOD_DARK)
	# Подушка сиденья.
	decor(x + 0.1, h - 0.3, w - 0.2, 0.32, z0, 1.35, ORANGE)
	# Спинка: деревянная рама и оранжевая подушка.
	decor(x + 0.08, h, 0.14, 1.35, z0 - 0.8, 0.14, WOOD_DARK)
	decor(x + w - 0.22, h, 0.14, 1.35, z0 - 0.8, 0.14, WOOD_DARK)
	decor(x + 0.08, h + 1.2, w - 0.16, 0.16, z0 - 0.8, 0.16, WOOD_DARK)
	decor(x + 0.3, h + 0.15, w - 0.6, 0.9, z0 - 0.62, 0.3, ORANGE)
	# Подлокотники сзади по бокам (не мешают Августу): стойка и закруглённая доска-«локоть».
	for ax in [x + 0.02, x + w - 0.18]:
		decor(ax, h, 0.16, 0.6, z0 - 0.55, 0.14, WOOD_DARK)
		var arm := CylinderMesh.new()
		arm.top_radius = 0.1
		arm.bottom_radius = 0.1
		arm.height = 0.9
		arm.material = _material(WOOD_DARK)
		var mi := MeshInstance3D.new()
		mi.mesh = arm
		mi.rotation.x = PI * 0.5
		mi.position = Vector3(ax + 0.08, h + 0.65, z0 - 0.75)
		add_child(mi)
		var knob := SphereMesh.new()
		knob.radius = 0.12
		knob.height = 0.24
		knob.material = _material(WOOD_DARK)
		var ki := MeshInstance3D.new()
		ki.mesh = knob
		ki.position = Vector3(ax + 0.08, h + 0.65, z0 - 0.3)
		add_child(ki)


## Фон гостиной: диван с подушками, телевизор, фисташковая штора, оранжевое кресло, торшер, растение, рамка с птичкой.
func _backdrop_living(rng: RandomNumberGenerator) -> void:
	if has_rug:
		_rug(0.6, length - 0.6, 3.2, Color(0.88, 0.82, 0.74))
	var x := 0.4
	while x < length - 3.0:
		# Диваны и кресла стоят в самом уровне (по ним прыгают), на заднем плане их нет — там растения и стена.
		match rng.randi() % 8:
			0:
				_tv(x)
				x += 3.6
			1:
				_curtain(x)
				x += 5.4
			2:
				_bird_frame(x, rng)
				x += 2.6
			3, 4:
				_plant_ficus(x, rng)
				x += 2.4
			5:
				_plant_monstera(x, rng)
				x += 2.6
			6:
				_plant_hanging(x, rng)
				x += 2.2
			7:
				_plant_shelf(x, rng)
				x += 3.0
		x += rng.randf_range(0.2, 0.8)


const LEAF_GREENS: Array[Color] = [
	Color(0.2, 0.55, 0.25), Color(0.28, 0.65, 0.3), Color(0.16, 0.45, 0.22), Color(0.4, 0.72, 0.32),
]


func _leaf(pos: Vector3, radii: Vector3, color: Color, roll: float = 0.0) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 14
	mesh.rings = 7
	mesh.material = _material(color)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = radii
	mi.rotation.z = roll
	add_child(mi)


func _pot(x: float, w: float, h: float, z: float) -> void:
	decor(x - w * 0.5, 0.0, w, h, z - w * 0.5, w, Color(0.78, 0.46, 0.3))
	decor(x - w * 0.55, h - 0.08, w * 1.1, 0.1, z - w * 0.55, w * 1.1, Color(0.7, 0.4, 0.26))


## Фикус: горшок, тонкий ствол и крона из зелёных «облачков».
func _plant_ficus(x: float, rng: RandomNumberGenerator) -> void:
	var cx := x + 0.9
	_pot(cx, 0.8, 0.7, -2.3)
	decor(cx - 0.05, 0.7, 0.1, 1.7, -2.3, 0.1, Color(0.45, 0.3, 0.18))
	for i in 9:
		var ang := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(0.2, 0.7)
		var py := 2.2 + rng.randf_range(-0.2, 1.5)
		_leaf(Vector3(cx + cos(ang) * r, py, -2.3 + sin(ang) * 0.3),
			Vector3(0.45, 0.28, 0.3) * rng.randf_range(0.8, 1.3), LEAF_GREENS[rng.randi() % LEAF_GREENS.size()], rng.randf_range(-0.5, 0.5))


## Монстера: большие продолговатые листья веером из горшка.
func _plant_monstera(x: float, rng: RandomNumberGenerator) -> void:
	var cx := x + 1.0
	_pot(cx, 0.9, 0.6, -2.3)
	for i in 7:
		var t := float(i) / 6.0 * 2.0 - 1.0
		var roll := -t * 1.0
		var len := rng.randf_range(0.8, 1.3)
		_leaf(Vector3(cx + t * 0.7, 0.9 + len * 0.9 - absf(t) * 0.3, -2.3 + rng.randf_range(-0.2, 0.2)),
			Vector3(0.22, len * 0.55, 0.12), LEAF_GREENS[i % LEAF_GREENS.size()], roll)


## Подвесное растение у стены: горшок на шнурах и свисающие листья.
func _plant_hanging(x: float, rng: RandomNumberGenerator) -> void:
	var cx := x + 0.8
	decor(cx - 0.01, 4.6, 0.02, 1.4, -2.85, 0.02, Color(0.85, 0.82, 0.75))
	decor(cx - 0.3, 4.1, 0.6, 0.5, -2.95, 0.5, Color(0.9, 0.88, 0.82))
	for i in 7:
		var ang := float(i) / 6.0 * 2.0 - 1.0
		_leaf(Vector3(cx + ang * 0.45, 3.8 - rng.randf_range(0.0, 0.7), -2.8),
			Vector3(0.12, 0.3 + rng.randf_range(0.0, 0.25), 0.1), LEAF_GREENS[i % LEAF_GREENS.size()], ang * 0.3)


## Полка со стопкой маленьких горшков с растениями.
func _plant_shelf(x: float, rng: RandomNumberGenerator) -> void:
	var y := rng.randf_range(2.3, 3.0)
	decor(x, y, 2.6, 0.1, -2.7, 0.7, Color(0.7, 0.66, 0.6))
	for i in 3:
		var px := x + 0.5 + i * 0.8
		decor(px - 0.2, y + 0.1, 0.4, 0.35, -2.7, 0.4, Color(0.78, 0.46, 0.3))
		for j in 4:
			_leaf(Vector3(px + (j - 1.5) * 0.12, y + 0.65 + (j % 2) * 0.12, -2.7),
				Vector3(0.12, 0.28, 0.1), LEAF_GREENS[(i + j) % LEAF_GREENS.size()], (j - 1.5) * 0.3)


func _tv(x: float) -> void:
	decor(x, 0.0, 3.2, 0.9, -2.5, 0.9, Color(0.66, 0.6, 0.52))
	decor(x + 0.3, 1.1, 2.6, 1.5, -2.6, 0.12, Color(0.04, 0.04, 0.05))
	decor(x + 0.4, 1.2, 2.4, 1.3, -2.53, 0.05, Color(0.1, 0.13, 0.2))
	decor(x + 1.45, 0.9, 0.3, 0.2, -2.6, 0.2, Color(0.04, 0.04, 0.05))


func _curtain(x: float) -> void:
	decor(x, 0.2, 5.2, 5.6, -2.9, 0.12, CURTAIN)
	for i in 10:
		decor(x + 0.05 + i * 0.52, 0.2, 0.26, 5.6, -2.8, 0.1, CURTAIN.darkened(0.12))
	decor(x - 0.2, 5.75, 5.6, 0.12, -2.8, 0.14, Color(0.7, 0.7, 0.72))


func _plant(x: float) -> void:
	decor(x + 0.2, 0.0, 0.8, 0.8, -2.3, 0.8, Color(0.75, 0.45, 0.3))
	for i in 5:
		var mesh := SphereMesh.new()
		mesh.radius = 0.4
		mesh.height = 0.8
		mesh.material = _material(Color(0.3 + 0.05 * i, 0.6, 0.3))
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(x + 0.6 + (i - 2) * 0.28, 1.3 + (i % 2) * 0.5, -2.3)
		add_child(mi)


func _bird_frame(x: float, rng: RandomNumberGenerator) -> void:
	var y := rng.randf_range(2.8, 4.0)
	decor(x, y, 1.8, 1.4, -2.95, 0.08, Color(0.97, 0.95, 0.9))
	decor(x + 0.15, y + 0.15, 1.5, 1.1, -2.9, 0.08, Color(0.62, 0.8, 0.95))
	_sphere(Vector3(x + 0.9, y + 0.7, -2.8), 0.18, Color(0.95, 0.75, 0.25))
	decor(x + 1.0, y + 0.66, 0.2, 0.06, -2.8, 0.06, Color(0.95, 0.5, 0.15))


func _over_pit(x0: float, x1: float) -> bool:
	for p in pits:
		if x1 > p.x and x0 < p.y:
			return true
	return false


func _sink(x: float) -> void:
	decor(x, 0.0, 2.2, 1.7, -2.5, 1.0, WHITE)
	decor(x + 0.2, 1.7, 1.8, 0.14, -2.5, 0.9, WHITE)
	decor(x + 1.0, 1.84, 0.12, 0.45, -2.85, 0.12, Color(0.8, 0.82, 0.85))
	decor(x + 0.9, 2.2, 0.35, 0.08, -2.75, 0.4, Color(0.8, 0.82, 0.85))
	decor(x + 0.2, 2.7, 1.8, 1.7, -2.95, 0.08, Color(0.97, 0.97, 0.97))
	decor(x + 0.3, 2.8, 1.6, 1.5, -2.9, 0.08, Color(0.72, 0.88, 0.95))


func _towels(x: float, rng: RandomNumberGenerator) -> void:
	decor(x, 3.4, 2.2, 0.08, -2.85, 0.12, WHITE)
	decor(x, 3.1, 0.08, 0.35, -2.85, 0.12, WHITE)
	decor(x + 2.12, 3.1, 0.08, 0.35, -2.85, 0.12, WHITE)
	for i in 2:
		var c := BATH_COLORS[rng.randi() % BATH_COLORS.size()]
		decor(x + 0.2 + i * 1.0, 2.0 - i * 0.15, 0.85, 1.45 + i * 0.15, -2.75, 0.1, c)
		decor(x + 0.2 + i * 1.0, 2.0 - i * 0.15, 0.85, 0.12, -2.7, 0.12, c.lightened(0.3))


func _bottle_shelf(x: float, rng: RandomNumberGenerator) -> void:
	var y := rng.randf_range(2.4, 3.2)
	decor(x, y, 2.6, 0.1, -2.7, 0.7, WHITE)
	var bx := x + 0.25
	while bx < x + 2.3:
		var w := rng.randf_range(0.22, 0.4)
		var h := rng.randf_range(0.5, 0.95)
		var c := BATH_COLORS[rng.randi() % BATH_COLORS.size()]
		decor(bx, y + 0.1, w, h, -2.65, 0.28, c)
		decor(bx + w * 0.25, y + 0.1 + h, w * 0.5, 0.12, -2.65, 0.2, WHITE)
		bx += w + 0.15


func _round_mirror(x: float) -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 1.0
	ring.bottom_radius = 1.0
	ring.height = 0.1
	ring.material = _material(WHITE)
	var ri := MeshInstance3D.new()
	ri.mesh = ring
	ri.rotation.x = PI * 0.5
	ri.position = Vector3(x + 1.0, 4.0, -2.95)
	add_child(ri)
	var glass := CylinderMesh.new()
	glass.top_radius = 0.85
	glass.bottom_radius = 0.85
	glass.height = 0.1
	glass.material = _material(Color(0.72, 0.88, 0.95))
	var gi := MeshInstance3D.new()
	gi.mesh = glass
	gi.rotation.x = PI * 0.5
	gi.position = Vector3(x + 1.0, 4.0, -2.9)
	add_child(gi)


func _shower_glass(x: float) -> void:
	var pane := BoxMesh.new()
	pane.size = Vector3(2.8, 5.2, 0.05)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.8, 0.92, 1.0, 0.22)
	pane.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = pane
	mi.position = Vector3(x + 1.4, 2.6, -2.3)
	add_child(mi)
	# Душевая лейка.
	decor(x + 2.2, 4.4, 0.08, 0.8, -2.8, 0.08, Color(0.8, 0.82, 0.85))
	decor(x + 1.8, 4.4, 0.5, 0.1, -2.8, 0.3, Color(0.8, 0.82, 0.85))


func _poster(x: float, rng: RandomNumberGenerator) -> void:
	var y := rng.randf_range(3.0, 4.4)
	decor(x, y, 2.0, 1.5, -2.95, 0.08, Color(0.95, 0.92, 0.85))
	decor(x + 0.2, y + 0.2, 1.6, 1.1, -2.9, 0.08, WALL_COLORS[rng.randi() % WALL_COLORS.size()])
	decor(x + 0.7, y + 0.45, 0.6, 0.6, -2.85, 0.08, WALL_COLORS[rng.randi() % WALL_COLORS.size()])


func _bookshelf(x: float, rng: RandomNumberGenerator) -> void:
	decor(x, 0.0, 3.2, 4.4, -2.7, 0.4, Color(0.55, 0.36, 0.2))
	for row in 3:
		var y := 0.35 + row * 1.4
		decor(x + 0.15, y, 2.9, 1.2, -2.48, 0.05, Color(0.35, 0.22, 0.12))
		var bx := x + 0.25
		while bx < x + 2.8:
			var w := rng.randf_range(0.18, 0.34)
			var h := rng.randf_range(0.7, 1.1)
			decor(bx, y, w, h, -2.42, 0.2, WALL_COLORS[rng.randi() % WALL_COLORS.size()])
			bx += w + 0.02


func _sphere(pos: Vector3, radius: float, color: Color, squash: float = 1.0, surface: String = "") -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = _soft_material(color, surface) if surface != "" else _material(color)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = Vector3(1.0, squash, 1.0)
	add_child(mi)


## Плюшевый мишка на заднем плане: тело, голова, уши, мордочка.
func _teddy(x: float, rng: RandomNumberGenerator) -> void:
	var fur := Color(0.72, 0.5, 0.3) if rng.randi() % 2 == 0 else Color(0.9, 0.75, 0.55)
	var z := -2.2
	_sphere(Vector3(x + 0.8, 0.8, z), 0.8, fur, 1.05, "carpet")
	_sphere(Vector3(x + 0.8, 1.9, z), 0.55, fur, 1.0, "carpet")
	_sphere(Vector3(x + 0.35, 2.35, z), 0.2, fur, 1.0, "carpet")
	_sphere(Vector3(x + 1.25, 2.35, z), 0.2, fur, 1.0, "carpet")
	_sphere(Vector3(x + 0.8, 1.8, z + 0.45), 0.22, Color(0.95, 0.85, 0.7), 1.0, "carpet")
	_sphere(Vector3(x + 0.8, 1.88, z + 0.62), 0.07, Color(0.15, 0.1, 0.1))
	_sphere(Vector3(x + 0.6, 2.0, z + 0.48), 0.05, Color(0.1, 0.1, 0.1))
	_sphere(Vector3(x + 1.0, 2.0, z + 0.48), 0.05, Color(0.1, 0.1, 0.1))
	_sphere(Vector3(x + 0.1, 0.9, z), 0.28, fur, 1.0, "carpet")
	_sphere(Vector3(x + 1.5, 0.9, z), 0.28, fur, 1.0, "carpet")


func _toy_balls(x: float, rng: RandomNumberGenerator) -> void:
	for i in 3:
		var r := rng.randf_range(0.35, 0.7)
		_sphere(Vector3(x + i * 0.9, r, -2.1 - rng.randf_range(0.0, 0.5)), r, WALL_COLORS[rng.randi() % WALL_COLORS.size()])


func _balloons(x: float, rng: RandomNumberGenerator) -> void:
	for i in 3:
		var bx := x + i * 0.7 + rng.randf_range(-0.1, 0.1)
		var by := rng.randf_range(4.0, 5.8)
		var mesh := SphereMesh.new()
		mesh.radius = 0.4
		mesh.height = 0.85
		mesh.material = _material(WALL_COLORS[rng.randi() % WALL_COLORS.size()])
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(bx, by, -2.8)
		add_child(mi)
		decor(bx - 0.01, by - 2.0, 0.02, 1.6, -2.8, 0.02, Color(0.9, 0.9, 0.9))


static func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.7
		_materials[color] = m
	return _materials[color]
