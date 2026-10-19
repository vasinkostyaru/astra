extends LevelSection
## Два стула (0.9) с промежутком 1.6 и подушкой внизу.

func _init() -> void:
	length = 11.0


func _build() -> void:
	chair(2.0, 0.9, 2.0)
	chair(5.6, 0.9, 2.0)
	pillow_gap(4.0, 1.6)
	checkpoint(2.8, 0.9)
	berry(4.8, 2.4)
	marker("Stop_Chair", 3.0, 0.9)
	marker("Run_Out", 9.5, 0.0)
