extends LevelSection
## Кирпичные ступеньки вверх-вниз: 0.6 / 1.2 / 0.6.

func _init() -> void:
	length = 10.0


func _build() -> void:
	bricks(2.5, 0.0, 2, 2, 31)
	bricks(3.7, 0.0, 2, 4, 32)
	bricks(4.9, 0.0, 2, 4, 33)
	bricks(6.1, 0.0, 2, 2, 34)
	berry(4.3, 1.8)
	berry(5.5, 1.8)
	marker("Stop_Hill", 5.0, 1.2)
	marker("Run_Out", 9.0, 0.0)
