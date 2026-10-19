class_name Jar
extends Control
## Банка-счётчик без цифр: наполняется ягодками: каждая собранная ложится внутрь своим цветом.

var total: int = 1
var _count: int = 0
var _colors: Array[Color] = []
var _drop: float = 1.0  # 0..1 — «падение» последней ягодки на место
var _complete: bool = false
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Центр банки в координатах экрана — туда летят ягодки.
func target_point() -> Vector2:
	return get_global_rect().get_center()


func add_one(color: Color) -> void:
	_count = mini(_count + 1, total)
	_colors.append(color)
	_drop = 0.0
	create_tween().tween_property(self, "_drop", 1.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	pivot_offset = size * 0.5
	var bump := create_tween()
	bump.tween_property(self, "scale", Vector2.ONE * 1.15, 0.08)
	bump.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_complete() -> void:
	_complete = true


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Скруглённый прямоугольник как многоугольник (для стекла и крышки).
static func _rounded(r: Rect2, radius: float, steps: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	radius = minf(radius, minf(r.size.x, r.size.y) * 0.5)
	var centers := [r.position + Vector2(r.size.x - radius, radius), r.end - Vector2(radius, radius),
		Vector2(r.position.x + radius, r.end.y - radius), r.position + Vector2(radius, radius)]
	for c in 4:
		for i in steps + 1:
			var ang := -PI * 0.5 + (c + float(i) / steps) * PI * 0.5
			pts.append(centers[c] + Vector2(cos(ang), sin(ang)) * radius)
	return pts


func _draw() -> void:
	var w := size.x
	var h := size.y
	var body := Rect2(w * 0.06, h * 0.27, w * 0.88, h * 0.71)
	var neck := Rect2(w * 0.2, h * 0.17, w * 0.6, h * 0.14)
	var inner := body.grow(-w * 0.08)

	# Сияние вокруг банки, когда она полная, и искорки.
	if _complete:
		var pulse := 0.5 + 0.5 * sin(_time * 3.0)
		draw_circle(body.get_center(), w * (0.62 + 0.08 * pulse), Color(1.0, 0.8, 0.35, 0.18 + 0.12 * pulse))
		for i in 5:
			var ang := _time * 0.8 + i * TAU / 5.0
			var tw := 0.5 + 0.5 * sin(_time * 5.0 + i * 1.7)
			_star(body.get_center() + Vector2(cos(ang), sin(ang)) * w * 0.62, w * 0.07 * tw, Color(1.0, 0.92, 0.5))

	# Тень под банкой.
	draw_set_transform(Vector2(w * 0.5, h * 0.985), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, w * 0.42, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Стекло сзади: голубоватое, к низу чуть плотнее.
	var glass := _rounded(body, w * 0.24)
	draw_colored_polygon(glass, Color(0.85, 0.95, 1.0, 0.28))
	draw_colored_polygon(_rounded(neck, w * 0.06), Color(0.85, 0.95, 1.0, 0.28))
	draw_colored_polygon(_rounded(Rect2(body.position.x, body.end.y - body.size.y * 0.25, body.size.x, body.size.y * 0.25), w * 0.24),
		Color(0.7, 0.85, 0.95, 0.18))

	# Ягодки укладываются на дно рядами по три, с тёмным контуром, бликом и листиком.
	var cols := 3
	var cell := inner.size.x / cols
	var radius := minf(cell * 0.47, inner.size.y / (ceili(float(total) / cols) + 0.5) * 0.47)
	for i in _count:
		var row := i / cols
		var col := i % cols
		var x := inner.position.x + cell * (col + 0.5) + (radius * 0.25 if row % 2 == 1 else 0.0)
		var y := inner.end.y - radius * 1.05 - row * radius * 1.8
		if i == _count - 1:
			y -= (1.0 - _drop) * radius * 3.0
		var c := _colors[i]
		draw_circle(Vector2(x, y), radius * 1.08, c.darkened(0.45))
		draw_circle(Vector2(x, y), radius, c)
		draw_circle(Vector2(x + radius * 0.15, y + radius * 0.2), radius * 0.7, c.darkened(0.12))
		draw_circle(Vector2(x - radius * 0.3, y - radius * 0.32), radius * 0.26, Color(1, 1, 1, 0.75))
		draw_circle(Vector2(x - radius * 0.2, y - radius * 0.95), radius * 0.22, Color(0.3, 0.7, 0.25))
		draw_circle(Vector2(x + radius * 0.2, y - radius * 0.95), radius * 0.22, Color(0.25, 0.62, 0.2))

	# Стекло спереди: контур и блики.
	var outline := glass.duplicate()
	outline.append(glass[0])
	draw_polyline(outline, Color(1, 1, 1, 0.85), w * 0.035, true)
	var neck_pts := _rounded(neck, w * 0.06)
	neck_pts.append(neck_pts[0])
	draw_polyline(neck_pts, Color(1, 1, 1, 0.7), w * 0.025, true)
	draw_line(body.position + Vector2(w * 0.13, h * 0.1), body.position + Vector2(w * 0.13, h * 0.42),
		Color(1, 1, 1, 0.65), w * 0.06, true)
	draw_circle(body.position + Vector2(w * 0.13, h * 0.49), w * 0.03, Color(1, 1, 1, 0.65))
	draw_line(body.position + Vector2(body.size.x - w * 0.12, h * 0.38), body.position + Vector2(body.size.x - w * 0.12, h * 0.52),
		Color(1, 1, 1, 0.35), w * 0.035, true)

	# Крышка — клетчатая ткань с волнистым краем и верёвочкой.
	var cloth := Rect2(w * 0.1, h * 0.02, w * 0.8, h * 0.19)
	var cloth_poly := PackedVector2Array()
	cloth_poly.append(cloth.position + Vector2(w * 0.08, 0))
	cloth_poly.append(cloth.position + Vector2(cloth.size.x - w * 0.08, 0))
	var waves := 7
	for i in waves * 2 + 1:
		var t := float(i) / (waves * 2)
		var px := cloth.end.x - t * cloth.size.x
		var py := cloth.end.y + (h * 0.025 if i % 2 == 0 else -h * 0.005)
		cloth_poly.append(Vector2(px, py))
	draw_colored_polygon(cloth_poly, Color(0.9, 0.22, 0.22))
	# Клетка: светлые полосы.
	var stripe := Color(1, 1, 1, 0.45)
	for i in 4:
		var sx := cloth.position.x + cloth.size.x * (0.15 + i * 0.23)
		draw_line(Vector2(sx, cloth.position.y + h * 0.01), Vector2(sx, cloth.end.y), stripe, w * 0.06)
	for j in 2:
		var sy := cloth.position.y + cloth.size.y * (0.3 + j * 0.4)
		draw_line(Vector2(cloth.position.x + w * 0.02, sy), Vector2(cloth.end.x - w * 0.02, sy), stripe, h * 0.035)
	# Верёвочка с бантиком.
	var tie_y := neck.position.y + h * 0.03
	draw_line(Vector2(neck.position.x - w * 0.04, tie_y), Vector2(neck.end.x + w * 0.04, tie_y), Color(0.55, 0.38, 0.22), h * 0.025)
	draw_circle(Vector2(neck.end.x + w * 0.02, tie_y), w * 0.04, Color(0.55, 0.38, 0.22))
	draw_line(Vector2(neck.end.x + w * 0.03, tie_y), Vector2(neck.end.x + w * 0.1, tie_y + h * 0.07), Color(0.55, 0.38, 0.22), w * 0.025)


func _star(c: Vector2, r: float, color: Color) -> void:
	if r < 1.0:
		return
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI * 0.5 + i * PI / 5.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, color)
