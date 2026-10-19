class_name PictureButton
extends Control
## Крупная кнопка-картинка без текста для меню. Срабатывает сразу при касании (мышь на ПК эмулирует касание).
## Наследники рисуют содержимое в _draw_icon(); общий отклик — «вдавливание» и лёгкое дыхание.

signal pressed

enum Kind { PLAY, BACK }

@export var kind: Kind = Kind.PLAY
## Мягко «дышит», привлекая внимание (для главной кнопки).
@export var breathe: bool = false

var _press: float = 0.0
var _time: float = 0.0
var _holding: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	pivot_offset = size * 0.5


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_holding = mb.pressed
		if mb.pressed:
			Input.vibrate_handheld(15, 0.4)
			pressed.emit()


func _process(delta: float) -> void:
	_time += delta
	_press = move_toward(_press, 1.0 if _holding else 0.0, delta * 12.0)
	var s := 1.0 - 0.08 * _press
	if breathe:
		s *= 1.0 + 0.04 * sin(_time * 3.0)
	scale = Vector2.ONE * s
	queue_redraw()


func _draw() -> void:
	_draw_icon()


func _draw_icon() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	match kind:
		Kind.PLAY:
			draw_circle(c + Vector2(0, r * 0.06), r, Color(0.55, 0.25, 0.05, 0.35))
			draw_circle(c, r, Color(1.0, 0.62, 0.2))
			draw_circle(c, r * 0.88, Color(1.0, 0.74, 0.3))
			draw_arc(c, r * 0.94, 0.0, TAU, 64, Color(1.0, 0.95, 0.8), r * 0.07, true)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.28, -r * 0.42), c + Vector2(r * 0.46, 0.0), c + Vector2(-r * 0.28, r * 0.42)]),
				Color(1.0, 0.99, 0.94))
		Kind.BACK:
			draw_circle(c, r, Color(1.0, 0.9, 0.7, 0.35))
			draw_arc(c, r - 3.0, 0.0, TAU, 48, Color(1.0, 0.97, 0.9, 0.85), 4.0, true)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-r * 0.4, 0.0), c + Vector2(r * 0.25, -r * 0.4), c + Vector2(r * 0.25, r * 0.4)]),
				Color(1.0, 0.98, 0.92))
