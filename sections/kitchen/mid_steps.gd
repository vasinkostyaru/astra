extends LevelSection
## Ступеньки из тумб: 0.6 / 1.2 / 0.6.

func _init() -> void:
	length = 11.0


func _build() -> void:
	counter(2.0, 1.8, 0.6)
	counter(3.8, 3.2, 1.2)
	counter(7.0, 1.8, 0.6)
	berry(2.9, 1.2)
	berry(5.4, 2.0)
	marker("Stop_Counter", 5.4, 1.2)
	marker("Run_Out", 10.0, 0.0)
