extends LevelSection
## Начало кухни: плитка, две кастрюли-ступеньки — учимся прыгать.

func _init() -> void:
	length = 12.0
	has_rug = false


func _build() -> void:
	pot(4.0, 1.8, 0.6, Color(0.78, 0.8, 0.84))
	pot(7.0, 1.8, 0.6, Color(0.85, 0.3, 0.25))
	berry_row(1.4, 0.6, 2)
	berry(4.9, 1.3)
	berry(7.9, 1.3)
	checkpoint(0.5, 0.0)
	marker("Stop_Start", 3.0, 0.0)
	marker("Run_Pot", 4.9, 0.6)
	marker("Stop_Pot2", 7.9, 0.6)
	marker("Run_Out", 11.0, 0.0)
