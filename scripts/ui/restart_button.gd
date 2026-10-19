class_name RestartButton
extends ExitButton
## Кнопка «сначала» на выборе комнаты: круглая стрелка. Удержание ~1 с — прогресс обнуляется и снова идёт интро.


func _draw_icon() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c, r, Color(1.0, 0.9, 0.7, 0.35))
	draw_arc(c, r - 3.0, 0.0, TAU, 48, Color(1.0, 0.97, 0.9, 0.85), 4.0, true)
	# Круглая стрелка: дуга почти по кругу и наконечник на её конце.
	var ink := Color(1.0, 0.98, 0.92)
	var ar := r * 0.42
	var a0 := -PI * 0.35
	var a1 := a0 + TAU * 0.8
	draw_arc(c, ar, a0, a1, 32, ink, r * 0.13, true)
	var tip := c + Vector2(cos(a1), sin(a1)) * ar
	var along := Vector2(-sin(a1), cos(a1))
	var out := Vector2(cos(a1), sin(a1))
	draw_colored_polygon(PackedVector2Array([
		tip + along * r * 0.24, tip + out * r * 0.2 - along * r * 0.05, tip - out * r * 0.2 - along * r * 0.05]), ink)
	if _hold > 0.0:
		draw_arc(c, r - 3.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(_hold / HOLD_TIME, 0.0, 1.0), 48,
			Color(1.0, 0.7, 0.2), 7.0, true)
