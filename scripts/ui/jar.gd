class_name Jar
extends Control
## Банка-счётчик без цифр: наполняется ягодками: каждая собранная ложится внутрь своим цветом.

var total: int = 1
var _count: int = 0
var _colors: Array[Color] = []
var _drop: float = 1.0  # 0..1 — «падение» последней ягодки на место
var _complete: bool = false
var _time: float = 0.0

var _glass := StyleBoxFlat.new()
var _lid := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass.bg_color = Color(0.8, 0.9, 1.0, 0.16)
	_glass.border_color = Color(1.0, 1.0, 1.0, 0.75)
	_glass.set_border_width_all(4)
	_lid.bg_color = Color(0.62, 0.4, 0.24)
	resized.connect(_update_corners)
	_update_corners()


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


func _update_corners() -> void:
	_glass.set_corner_radius_all(int(size.x * 0.18))
	_lid.set_corner_radius_all(int(size.x * 0.06))


func _draw() -> void:
	var w := size.x
	var h := size.y
	var body := Rect2(w * 0.08, h * 0.17, w * 0.84, h * 0.81)
	var inner := body.grow(-w * 0.07)

	# Сияние вокруг банки, когда она полная.
	if _complete:
		var pulse := 0.5 + 0.5 * sin(_time * 3.0)
		draw_circle(body.get_center(), w * (0.55 + 0.1 * pulse), Color(1.0, 0.8, 0.35, 0.2 + 0.15 * pulse))

	draw_style_box(_glass, body)
	# Ягодки укладываются на дно рядами по три.
	var cols := 3
	var cell := inner.size.x / cols
	var radius := minf(cell * 0.45, inner.size.y / (ceili(float(total) / cols) + 0.5) * 0.45)
	for i in _count:
		var row := i / cols
		var col := i % cols
		var x := inner.position.x + cell * (col + 0.5)
		var y := inner.end.y - radius * 1.05 - row * radius * 1.9
		if i == _count - 1:
			y -= (1.0 - _drop) * radius * 3.0
		draw_circle(Vector2(x, y), radius, _colors[i])
		draw_circle(Vector2(x - radius * 0.3, y - radius * 0.3), radius * 0.25, Color(1, 1, 1, 0.55))
	draw_style_box(_lid, Rect2(w * 0.16, h * 0.04, w * 0.68, h * 0.14))
	# Блик на стекле.
	draw_line(body.position + Vector2(w * 0.14, h * 0.12), body.position + Vector2(w * 0.14, h * 0.45),
		Color(1.0, 1.0, 1.0, 0.5), w * 0.05, true)
