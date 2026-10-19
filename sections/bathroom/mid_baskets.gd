extends LevelSection
## Корзины и ящики ступенями 0.6 / 1.2 / 0.6.

func _init() -> void:
	length = 11.5


func _build() -> void:
	box(2.0, 0.0, 1.8, 0.6, Color(0.78, 0.6, 0.38))
	box(3.8, 0.0, 3.4, 1.2, Color(0.55, 0.78, 0.95))
	box(7.2, 0.0, 1.8, 0.6, Color(0.78, 0.6, 0.38))
	berry(2.9, 1.2)
	berry(5.5, 2.0)
	marker("Stop_Boxes", 5.5, 1.2)
	marker("Run_Out", 10.5, 0.0)
