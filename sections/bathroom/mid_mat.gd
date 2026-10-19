extends LevelSection
## Ровный коврик: ягодки повыше — подпрыгнуть и достать.

func _init() -> void:
	length = 9.0


func _build() -> void:
	berry(2.5, 1.6)
	berry(5.0, 0.7)
	berry(7.0, 1.6)
	marker("Stop_Mat", 4.5, 0.0)
	marker("Run_Out", 8.2, 0.0)
