extends LevelSection
## «Фишка» кухни — подъём по стульям на стол, дальше по столешницам до самой высокой полки (3.6) и вниз.
## Два промежутка по 1.6 между шкафчиками, под ними подушки.


func _init() -> void:
	length = 29.0
	has_rug = false


func _build() -> void:
	chair(3.0, 0.9, 2.0)
	table(5.0, 3.0, 1.8)
	counter(8.0, 3.0, 2.7)
	pillow_gap(11.0, 1.6)
	counter(12.6, 4.4, 3.6)
	pillow_gap(17.0, 1.6)
	counter(18.6, 3.0, 2.7)
	table(21.6, 3.0, 1.8)
	chair(24.6, 0.9, 2.0)
	berry(4.0, 1.7)
	berry(6.5, 2.6)
	berry(9.5, 3.5)
	berry(14.8, 4.5)
	berry(20.1, 3.5)
	berry(23.1, 2.6)
	checkpoint(6.5, 1.8)
	checkpoint(9.5, 2.7)
	checkpoint(14.8, 3.6)
	checkpoint(20.1, 2.7)
	checkpoint(23.1, 1.8)
	marker("Stop_Chair", 2.4, 0.0)
	marker("Run_Table", 6.5, 1.8)
	marker("Stop_Counter", 9.5, 2.7)
	marker("Run_Shelf", 14.8, 3.6)
	marker("Stop_Top", 16.2, 3.6)
	marker("Run_Counter2", 20.1, 2.7)
	marker("Run_Table2", 23.1, 1.8)
	marker("Run_Out", 27.5, 0.0)
