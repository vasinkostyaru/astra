extends LevelSection
## Игрушечный поезд: три вагона высотой 0.6, идти по крышам.

func _init() -> void:
	length = 11.5


func _build() -> void:
	box(2.0, 0.0, 6.4, 0.6, Color(0.4, 0.4, 0.45))
	decor(2.0, 0.0, 2.0, 0.62, 0.0, 2.02, Color(0.9, 0.22, 0.2))
	decor(4.2, 0.0, 2.0, 0.62, 0.0, 2.02, Color(1.0, 0.78, 0.15))
	decor(6.4, 0.0, 2.0, 0.62, 0.0, 2.02, Color(0.2, 0.5, 0.95))
	berry(3.0, 1.2)
	berry(7.4, 1.2)
	marker("Stop_Train", 5.0, 0.6)
	marker("Run_Out", 10.5, 0.0)
