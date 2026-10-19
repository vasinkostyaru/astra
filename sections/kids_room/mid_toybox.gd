extends LevelSection
## Сундук с игрушками: ступенька 0.6, сундук 1.2, потом вниз по ступенькам.

func _init() -> void:
	length = 10.5


func _build() -> void:
	box(2.0, 0.0, 1.2, 0.6, Color(1.0, 0.78, 0.15))
	box(3.2, 0.0, 3.6, 1.2, Color(0.62, 0.4, 0.23))
	decor(3.1, 1.2, 3.8, 0.1, 0.0, 2.2, Color(0.85, 0.3, 0.3))
	box(6.8, 0.0, 1.2, 0.6, Color(0.25, 0.75, 0.35))
	berry(4.2, 2.1)
	berry(5.8, 2.1)
	marker("Stop_Chest", 5.0, 1.3)
	marker("Run_Out", 9.5, 0.0)
