extends LevelSection
## Длинная столешница 1.2 со ступеньками-кастрюлями с обеих сторон.

func _init() -> void:
	length = 13.0


func _build() -> void:
	pot(2.0, 1.8, 0.6, Color(0.9, 0.55, 0.2))
	counter(3.8, 5.4, 1.2)
	pot(9.2, 1.8, 0.6, Color(0.9, 0.55, 0.2))
	berry(5.0, 2.0)
	berry(7.4, 2.0)
	marker("Stop_Counter", 6.5, 1.2)
	marker("Run_Out", 12.0, 0.0)
