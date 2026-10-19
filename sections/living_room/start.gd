extends LevelSection
## Начало гостиной: ковёр, два мягких пуфа-ступеньки.

func _init() -> void:
	length = 12.0


func _build() -> void:
	pouf(4.0, 1.8, 0.6, Color(0.3, 0.7, 0.75))
	pouf(7.0, 1.8, 0.6, Color(0.85, 0.45, 0.7))
	berry_row(1.4, 0.6, 2)
	berry(4.9, 1.3)
	berry(7.9, 1.3)
	checkpoint(0.5, 0.0)
	marker("Stop_Start", 3.0, 0.0)
	marker("Run_Pouf", 4.9, 0.6)
	marker("Stop_Pouf2", 7.9, 0.6)
	marker("Run_Out", 11.0, 0.0)
