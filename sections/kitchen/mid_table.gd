extends LevelSection
## Стол (1.8) со стульями-ступеньками по бокам.

func _init() -> void:
	length = 12.0


func _build() -> void:
	chair(1.8, 0.9, 1.8)
	table(3.6, 4.2, 1.8)
	chair(7.8, 0.9, 1.8)
	berry(2.7, 1.7)
	berry(5.7, 2.8)
	marker("Stop_Table", 5.7, 1.8)
	marker("Run_Out", 11.0, 0.0)
