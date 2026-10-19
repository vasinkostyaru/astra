class_name MenuBackdrop
extends Control
## Тёплый вечерний фон меню: градиент и медленно плывущие разноцветные ягодки.

const COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.25), Color(0.3, 0.3, 0.75), Color(0.85, 0.2, 0.45), Color(0.6, 0.35, 0.8), Color(0.8, 0.1, 0.2)]

## Область (в долях экрана), которую ягодки обходят — там стоит персонаж.
@export var avoid: Rect2 = Rect2()

var _time: float = 0.0
var _gradient := GradientTexture2D.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 0.82, 0.55), Color(0.95, 0.55, 0.4), Color(0.45, 0.3, 0.45)])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	_gradient.gradient = g
	_gradient.fill_from = Vector2(0.5, 0.0)
	_gradient.fill_to = Vector2(0.5, 1.0)
	_gradient.width = 4
	_gradient.height = 128


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_gradient, Rect2(Vector2.ZERO, size), false)
	for i in 14:
		var x := fposmod(size.x * (0.07 * i + 0.03) + _time * (6.0 + i % 4 * 3.0), size.x + 80.0) - 40.0
		var y := size.y * (0.12 + 0.8 * fposmod(i * 0.37, 1.0)) + sin(_time * 0.8 + i) * size.y * 0.02
		var r := size.y * (0.025 + 0.012 * (i % 3))
		if avoid.has_point(Vector2(x, y) / size):
			continue
		var c := COLORS[i % COLORS.size()]
		c.a = 0.55
		draw_circle(Vector2(x, y), r, c)
		draw_circle(Vector2(x - r * 0.3, y - r * 0.3), r * 0.25, Color(1, 1, 1, 0.4))
