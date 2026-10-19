extends LevelSection
## Маленький диванчик 0.9 с низкими пуфами с обеих сторон.

func _init() -> void:
	length = 12.0


func _build() -> void:
	pouf(1.8, 1.6, 0.45, Color(0.5, 0.4, 0.8))
	sofa(3.4, 4.4, 0.9)
	pouf(8.0, 1.6, 0.45, Color(0.5, 0.4, 0.8))
	berry(5.6, 2.0)
	berry(2.6, 1.0)
	marker("Stop_Sofa", 5.6, 0.9)
	marker("Run_Out", 11.0, 0.0)
