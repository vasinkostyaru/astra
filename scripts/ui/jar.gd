class_name Jar
extends Control
## Банка-счётчик без цифр: наполняется светом с каждой искоркой.

var total: int = 1
var _count: int = 0
var _fill: float = 0.0
var _complete: bool = false
var _time: float = 0.0

var _glass := StyleBoxFlat.new()
var _light := StyleBoxFlat.new()
var _lid := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass.bg_color = Color(0.8, 0.9, 1.0, 0.16)
	_glass.border_color = Color(1.0, 1.0, 1.0, 0.75)
	_glass.set_border_width_all(4)
	_light.bg_color = Color(1.0, 0.82, 0.35, 0.92)
	_lid.bg_color = Color(0.62, 0.4, 0.24)
	resized.connect(_update_corners)
	_update_corners()


## Центр банки в координатах экрана — туда летят искорки.
func target_point() -> Vector2:
	return get_global_rect().get_center()


func add_one() -> void:
	_count = mini(_count + 1, total)
	var tw := create_tween()
	tw.tween_property(self, "_fill", float(_count) / total, 0.35).set_trans(Tween.TRANS_SINE)
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
	_light.set_corner_radius_all(int(size.x * 0.14))
	_lid.set_corner_radius_all(int(size.x * 0.06))


func _draw() -> void:
	var w := size.x
	var h := size.y
	var body := Rect2(w * 0.08, h * 0.17, w * 0.84, h * 0.81)
	var inner := body.grow(-w * 0.07)

	# Сияние вокруг банки: растёт с наполнением, пульсирует, когда банка полная.
	var pulse := 0.5 + 0.5 * sin(_time * 3.0) if _complete else 0.0
	if _fill > 0.0:
		var glow := Color(1.0, 0.8, 0.35, 0.10 + 0.15 * _fill + 0.15 * pulse)
		draw_circle(body.get_center(), w * (0.55 + 0.1 * pulse), glow)

	draw_style_box(_glass, body)
	if _fill > 0.01:
		var fh := inner.size.y * _fill
		draw_style_box(_light, Rect2(inner.position.x, inner.end.y - fh, inner.size.x, fh))
		# Искорки внутри: по одной точке на собранную, слегка мерцают.
		for i in _count:
			var rx := fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
			var ry := fposmod(sin(i * 78.233) * 12345.6789, 1.0)
			var p := Vector2(inner.position.x + inner.size.x * (0.15 + 0.7 * rx),
				inner.end.y - fh * (0.15 + 0.7 * ry))
			var tw := 0.6 + 0.4 * sin(_time * 4.0 + i)
			draw_circle(p, w * 0.045 * tw, Color(1.0, 1.0, 0.9, 0.95))
	draw_style_box(_lid, Rect2(w * 0.16, h * 0.04, w * 0.68, h * 0.14))
	# Блик на стекле.
	draw_line(body.position + Vector2(w * 0.14, h * 0.12), body.position + Vector2(w * 0.14, h * 0.45),
		Color(1.0, 1.0, 1.0, 0.5), w * 0.05, true)
