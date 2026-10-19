extends LevelSection
## Пуфы ступенями 0.6 / 1.2 / 0.6.

func _init() -> void:
	length = 11.0


func _build() -> void:
	pouf(2.0, 1.8, 0.6, Color(0.3, 0.7, 0.75))
	pouf(3.8, 3.2, 1.2, Color(0.85, 0.45, 0.7))
	pouf(7.0, 1.8, 0.6, Color(0.3, 0.7, 0.75))
	berry(2.9, 1.2)
	berry(5.4, 2.0)
	marker("Stop_Poufs", 5.4, 1.2)
	marker("Run_Out", 10.0, 0.0)
