extends LevelSection
## Два высоких шкафчика (1.8) с пропастью 2.0 между ними; ступеньки с обеих сторон, внизу подушка.

func _init() -> void:
	length = 17.0


func _build() -> void:
	var wood := Color(0.62, 0.4, 0.23)
	box(1.5, 0.0, 1.8, 0.6, Color(1.0, 0.78, 0.15))
	box(3.3, 0.0, 1.8, 1.2, Color(0.25, 0.75, 0.35))
	box(5.1, 0.0, 2.4, 1.8, wood)
	box(9.5, 0.0, 2.4, 1.8, wood)
	box(11.9, 0.0, 1.8, 1.2, Color(0.25, 0.75, 0.35))
	box(13.7, 0.0, 1.8, 0.6, Color(1.0, 0.78, 0.15))
	pillow_gap(7.5, 2.0)
	checkpoint(6.2, 1.8)
	checkpoint(10.6, 1.8)
	berry(4.2, 1.9)
	berry(8.5, 3.4)
	marker("Stop_CabinetA", 6.3, 1.8)
	marker("Run_CabinetB", 10.7, 1.8)
	marker("Run_Out", 16.0, 0.0)
