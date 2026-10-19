extends LevelSection
## Два оранжевых кресла (0.9) с промежутком 1.6 и подушкой внизу.

func _init() -> void:
	length = 11.0


func _build() -> void:
	armchair(2.0, 2.2, 0.9)
	armchair(5.8, 2.2, 0.9)
	pillow_gap(4.2, 1.6)
	checkpoint(3.1, 0.9)
	berry(5.0, 2.4)
	marker("Stop_Chair", 3.1, 0.9)
	marker("Run_Out", 9.5, 0.0)
