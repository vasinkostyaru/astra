extends LevelSection
## Переправа по кирпичикам конструктора: башенки стоят на дне и торчат из воды (верх на 0.5).

func _init() -> void:
	length = 19.0


func _build() -> void:
	var count := 4
	var width := 1.6 + count * 1.8 + (count - 1) * 1.5 + 1.3
	water_pit(2.0, width)
	checkpoint(1.2, 0.0)
	for i in count:
		var left := 3.6 + i * 3.3
		bricks(left, -1.6, 3, 7, 50 + i)
		berry(left + 2.55, 2.0)
		if i == 1:
			checkpoint(left + 0.9, 0.5)
	checkpoint(2.0 + width + 0.8, 0.0)
	marker("Stop_Edge", 1.4, 0.0)
	marker("Run_B1", 4.5, 0.5)
	marker("Run_B2", 7.8, 0.5)
	marker("Run_B3", 11.1, 0.5)
	marker("Stop_Far", 2.0 + width + 1.0, 0.0)
	marker("Run_Out", length - 1.0, 0.0)
