extends LevelSection
## Холм из кубиков с буквами: ступени 0.45 / 0.9 и спуск.

func _init() -> void:
	length = 11.0


func _build() -> void:
	box(2.0, 0.0, 1.2, 0.45, Color(0.65, 0.4, 0.85))
	box(3.2, 0.0, 2.8, 0.9, Color(1.0, 0.5, 0.15))
	box(6.0, 0.0, 1.2, 0.45, Color(0.25, 0.75, 0.35))
	berry(4.0, 1.5)
	berry(6.6, 1.0)
	marker("Stop_Hill", 4.6, 0.9)
	marker("Run_Out", 10.0, 0.0)
