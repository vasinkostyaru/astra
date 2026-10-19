extends LevelSection
## Камушки-кубики над пропастью: три островка по 1.2 с промежутками 1.6, внизу мягкие подушки.

func _init() -> void:
	length = 14.0


func _build() -> void:
	box(1.0, 0.0, 1.2, 0.6, Color(1.0, 0.78, 0.15))
	box(2.2, 0.0, 2.0, 1.2, Color(0.9, 0.22, 0.2))
	box(5.8, 0.0, 2.0, 1.2, Color(0.2, 0.5, 0.95))
	box(9.4, 0.0, 2.0, 1.2, Color(0.25, 0.75, 0.35))
	box(12.2, 0.0, 1.2, 0.6, Color(1.0, 0.78, 0.15))
	pillow_gap(4.2, 1.6)
	pillow_gap(7.8, 1.6)
	pillow_gap(11.4, 0.8)
	checkpoint(3.0, 1.2)
	checkpoint(6.6, 1.2)
	checkpoint(10.2, 1.2)
	berry(5.0, 2.6)
	berry(8.6, 2.6)
	marker("Stop_Stones", 3.2, 1.2)
	marker("Run_Stone2", 6.8, 1.2)
	marker("Run_Stone3", 10.4, 1.2)
	marker("Run_Out", 13.0, 0.0)
