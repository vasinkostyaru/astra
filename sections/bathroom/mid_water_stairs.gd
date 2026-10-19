extends LevelSection
## Лесенка из плавающих игрушек: каждая следующая чуть выше (0.15 → 0.55 → 0.95), потом вниз.

func _init() -> void:
	length = 24.0


func _build() -> void:
	var heights: Array[float] = [0.0, 0.4, 0.8, 0.4, 0.0]
	var end := water_crossing(2.0, 5, 0, heights)
	marker("Stop_Edge", 1.4, 0.0)
	marker("Run_T1", 5.7, 0.15)
	marker("Run_T2", 9.4, 0.55)
	marker("Run_T3", 13.1, 0.95)
	marker("Run_T4", 16.8, 0.55)
	marker("Stop_Far", end + 1.0, 0.0)
	marker("Run_Out", length - 1.0, 0.0)
