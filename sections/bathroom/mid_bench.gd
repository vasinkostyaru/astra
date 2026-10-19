extends LevelSection
## Скамеечка 0.9 с низкой ступенькой с обеих сторон.

func _init() -> void:
	length = 12.0


func _build() -> void:
	box(2.0, 0.0, 1.8, 0.45, Color(0.97, 0.85, 0.45))
	box(3.8, 0.0, 4.2, 0.9, Color(0.97, 0.97, 0.98))
	box(8.0, 0.0, 1.8, 0.45, Color(0.97, 0.85, 0.45))
	berry(5.9, 1.9)
	berry(8.9, 1.2)
	marker("Stop_Bench", 5.9, 0.9)
	marker("Run_Out", 11.0, 0.0)
