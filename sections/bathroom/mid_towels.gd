extends LevelSection
## Стопка полотенец: ступенька 0.45 и 0.9.

func _init() -> void:
	length = 10.0


func _build() -> void:
	box(2.0, 0.0, 5.2, 0.45, Color(0.95, 0.55, 0.25))
	box(3.0, 0.45, 3.2, 0.45, Color(0.55, 0.8, 0.9))
	berry(3.2, 1.5)
	berry(5.8, 1.5)
	marker("Stop_Towels", 4.6, 0.9)
	marker("Run_Out", 9.0, 0.0)
