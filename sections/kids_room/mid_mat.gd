extends LevelSection
## Ровный игровой коврик: ягодки повыше — подпрыгнуть и достать.

func _init() -> void:
	length = 9.0


func _build() -> void:
	decor(1.0, 0.0, 7.0, 0.04, 0.0, 3.5, Color(0.95, 0.75, 0.3))
	berry(2.5, 1.6)
	berry(5.5, 1.6)
	marker("Stop_Mat", 4.5, 0.0)
	marker("Run_Out", 8.2, 0.0)
