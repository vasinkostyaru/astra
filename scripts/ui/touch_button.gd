class_name TouchButton
extends Control
## Круглая экранная кнопка без текста. Нажатия приходят из TouchControls (мультитач).
## Отклик: вспышка тёплым светом, лёгкое «вдавливание» и короткая вибрация.

enum Icon { LEFT, RIGHT, JUMP }

const IDLE_FILL := Color(1.0, 0.9, 0.7, 0.28)
const PRESSED_FILL := Color(1.0, 0.78, 0.35, 0.85)

@export var action: StringName
@export var icon: Icon = Icon.LEFT
## Вибрация при нажатии: длительность (мс) и сила (0..1).
@export var vibrate_ms: int = 12
@export_range(0.0, 1.0) var vibrate_strength: float = 0.4

var is_pressed: bool = false

## 0 — отпущена, 1 — нажата; плавно анимируется для отрисовки.
var _press: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_pressed(pressed: bool) -> void:
	if pressed == is_pressed:
		return
	is_pressed = pressed
	if pressed:
		Input.action_press(action)
		Input.vibrate_handheld(vibrate_ms, vibrate_strength)
	else:
		Input.action_release(action)


func _process(delta: float) -> void:
	# Подсветка следует за действием — так кнопка откликается и на клавиатуру на ПК.
	var target := 1.0 if Input.is_action_pressed(action) else 0.0
	var speed := 25.0 if target > _press else 8.0
	var next := move_toward(_press, target, delta * speed)
	if next != _press:
		_press = next
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var base_r := minf(size.x, size.y) * 0.5
	var r := base_r * (1.0 - 0.08 * _press)

	if _press > 0.0:
		# Тёплое сияние вокруг нажатой кнопки.
		draw_circle(c, base_r * (1.0 + 0.12 * _press), Color(1.0, 0.75, 0.3, 0.3 * _press))
	draw_circle(c, r, IDLE_FILL.lerp(PRESSED_FILL, _press))
	draw_arc(c, r - 3.0, 0.0, TAU, 64, Color(1.0, 0.97, 0.9, 0.85 + 0.15 * _press), 5.0 + 3.0 * _press, true)

	var s := r * 0.45
	var col := Color(1.0, 0.98, 0.92, 0.95).lerp(Color(1.0, 1.0, 1.0, 1.0), _press)
	match icon:
		Icon.LEFT:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, 0.0), c + Vector2(s * 0.7, -s), c + Vector2(s * 0.7, s)]), col)
		Icon.RIGHT:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(s, 0.0), c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s)]), col)
		Icon.JUMP:
			# Две «галочки» вверх; при нажатии чуть подпрыгивают.
			var lift := -s * 0.15 * _press
			for k in 2:
				var y := c.y + s * 0.15 - k * s * 0.75 + lift
				draw_polyline(PackedVector2Array([
					Vector2(c.x - s * 0.8, y + s * 0.5), Vector2(c.x, y - s * 0.3),
					Vector2(c.x + s * 0.8, y + s * 0.5)]), col, r * 0.14, true)
