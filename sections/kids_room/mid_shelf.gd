extends LevelSection
## Широкая лестница на полку (1.8) и спуск с другой стороны.

func _init() -> void:
	length = 15.0


func _build() -> void:
	var wood := Color(0.78, 0.58, 0.38)
	box(2.0, 0.0, 1.8, 0.6, Color(0.95, 0.75, 0.35))
	box(3.8, 0.0, 1.8, 1.2, Color(0.9, 0.55, 0.4))
	box(5.6, 0.0, 3.8, 1.8, wood)
	decor(5.6, 1.8, 3.8, 0.06, 0.0, 2.1, Color(0.95, 0.93, 0.88))
	box(9.4, 0.0, 1.8, 1.2, Color(0.9, 0.55, 0.4))
	box(11.2, 0.0, 1.8, 0.6, Color(0.95, 0.75, 0.35))
	berry(4.7, 1.8)
	berry(7.5, 2.6)
	marker("Stop_Shelf", 7.5, 1.8)
	marker("Run_Out", 14.0, 0.0)
