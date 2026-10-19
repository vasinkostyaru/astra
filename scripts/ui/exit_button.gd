class_name ExitButton
extends PictureButton
## Кнопка выхода из уровня к выбору комнаты: маленький «домик» в углу. Чтобы ребёнок не вышел случайно,
## её нужно удерживать около секунды — по кругу заполняется кольцо; отпустил раньше — ничего не произошло.

signal held

const HOLD_TIME := 1.0

var _hold: float = 0.0
var _down: bool = false
var _done: bool = false


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_down = mb.pressed
		_holding = mb.pressed
		if mb.pressed:
			Input.vibrate_handheld(15, 0.4)
		accept_event()


func _process(delta: float) -> void:
	super._process(delta)
	if _down and not _done:
		_hold += delta
		if _hold >= HOLD_TIME:
			_done = true
			Input.vibrate_handheld(40, 0.6)
			held.emit()
	elif not _down:
		_hold = maxf(_hold - delta * 3.0, 0.0)


func _draw_icon() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c, r, Color(1.0, 0.9, 0.7, 0.35))
	draw_arc(c, r - 3.0, 0.0, TAU, 48, Color(1.0, 0.97, 0.9, 0.85), 4.0, true)
	# Домик: крыша-треугольник, стенки и дверь.
	var ink := Color(1.0, 0.98, 0.92)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-r * 0.55, -r * 0.02), c + Vector2(0.0, -r * 0.55), c + Vector2(r * 0.55, -r * 0.02)]), ink)
	draw_rect(Rect2(c + Vector2(-r * 0.38, -r * 0.05), Vector2(r * 0.76, r * 0.55)), ink)
	draw_rect(Rect2(c + Vector2(-r * 0.1, r * 0.2), Vector2(r * 0.2, r * 0.3)), Color(0.85, 0.55, 0.3))
	# Кольцо удержания.
	if _hold > 0.0:
		draw_arc(c, r - 3.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(_hold / HOLD_TIME, 0.0, 1.0), 48,
			Color(1.0, 0.7, 0.2), 7.0, true)
