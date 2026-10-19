class_name TouchButton
extends Control
## Круглая экранная кнопка без текста. Нажатия приходят из TouchControls (мультитач).

enum Icon { LEFT, RIGHT, JUMP }

@export var action: StringName
@export var icon: Icon = Icon.LEFT

var is_pressed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_pressed(pressed: bool) -> void:
	if pressed == is_pressed:
		return
	is_pressed = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 * (0.92 if is_pressed else 1.0)
	draw_circle(c, r, Color(1.0, 0.9, 0.7, 0.55 if is_pressed else 0.28))
	draw_arc(c, r - 3.0, 0.0, TAU, 64, Color(1.0, 0.97, 0.9, 0.85), 5.0, true)

	var s := r * 0.45
	var col := Color(1.0, 0.98, 0.92, 0.95)
	match icon:
		Icon.LEFT:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, 0.0), c + Vector2(s * 0.7, -s), c + Vector2(s * 0.7, s)]), col)
		Icon.RIGHT:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(s, 0.0), c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s)]), col)
		Icon.JUMP:
			# Две «галочки» вверх.
			for k in 2:
				var y := c.y + s * 0.15 - k * s * 0.75
				draw_polyline(PackedVector2Array([
					Vector2(c.x - s * 0.8, y + s * 0.5), Vector2(c.x, y - s * 0.3),
					Vector2(c.x + s * 0.8, y + s * 0.5)]), col, r * 0.14, true)
