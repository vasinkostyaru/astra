extends LevelSection
## Журнальный столик 0.9 с пуфами-ступеньками по бокам.

func _init() -> void:
	length = 11.5


func _build() -> void:
	pouf(1.8, 1.6, 0.45, Color(0.95, 0.78, 0.2))
	box(3.4, 0.0, 4.0, 0.9, Color(0.66, 0.6, 0.52))
	decor(3.3, 0.85, 4.2, 0.1, 0.0, 2.2, Color(0.75, 0.7, 0.62))
	pouf(7.4, 1.6, 0.45, Color(0.95, 0.78, 0.2))
	berry(5.4, 2.0)
	berry(2.6, 1.0)
	marker("Stop_Table", 5.4, 0.9)
	marker("Run_Out", 10.5, 0.0)
