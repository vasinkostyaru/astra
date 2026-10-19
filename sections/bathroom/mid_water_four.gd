extends LevelSection
## Длинная переправа по четырём игрушкам.

func _init() -> void:
	length = 21.0


func _build() -> void:
	var end := water_crossing(2.0, 4, 1)
	marker("Stop_Edge", 1.4, 0.0)
	marker("Run_T1", 5.7, 0.15)
	marker("Run_T2", 9.4, 0.15)
	marker("Run_T3", 13.1, 0.15)
	marker("Stop_Far", end + 1.0, 0.0)
	marker("Run_Out", length - 1.0, 0.0)
