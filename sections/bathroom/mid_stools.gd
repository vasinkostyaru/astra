extends LevelSection
## Две табуретки (0.9) с промежутком 1.6 и подушкой внизу.

func _init() -> void:
	length = 11.0


func _build() -> void:
	box(2.0, 0.0, 2.4, 0.9, Color(0.35, 0.75, 0.7))
	box(6.0, 0.0, 2.4, 0.9, Color(0.9, 0.45, 0.65))
	pillow_gap(4.4, 1.6)
	checkpoint(2.8, 0.9)
	berry(5.2, 2.4)
	marker("Stop_Stool", 3.2, 0.9)
	marker("Run_Out", 9.5, 0.0)
