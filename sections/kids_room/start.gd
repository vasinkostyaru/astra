extends LevelSection
## Начало «Детской»: ковёр, кучки кирпичиков на заднем плане, первые низкие ступеньки (учимся прыгать).

func _init() -> void:
	has_rug = false
	length = 12.0


func _build() -> void:
	decor(0.5, 0.0, 9.0, 0.04, 0.0, 4.0, Color(0.22, 0.55, 0.58))
	bricks(2.0, 0.0, 2, 2, 3, 0.6, -2.2)
	bricks(4.6, 0.0, 3, 3, 7, 0.6, -2.2)
	bricks(6.0, 0.0, 2, 2, 11)
	bricks(8.5, 0.0, 2, 2, 12)
	berry_row(1.6, 0.6, 3)
	berry(6.6, 1.2)
	berry(9.1, 1.2)
	checkpoint(0.5, 0.0)
	marker("Stop_Start", 3.0, 0.0)
	marker("Run_Floor", 5.0, 0.0)
	marker("Stop_Block", 9.1, 0.6)
	marker("Run_Out", 11.5, 0.0)
