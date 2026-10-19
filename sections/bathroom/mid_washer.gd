extends LevelSection
## Стиральная машина (1.2) с корзиной-ступенькой с обеих сторон.

func _init() -> void:
	length = 11.0


func _build() -> void:
	var wicker := Color(0.78, 0.6, 0.38)
	box(2.0, 0.0, 1.8, 0.6, wicker)
	box(3.8, 0.0, 3.0, 1.2, Color(0.97, 0.97, 0.98))
	decor(4.6, 0.3, 1.4, 0.6, 1.02, 0.06, Color(0.35, 0.45, 0.6))
	box(6.8, 0.0, 1.8, 0.6, wicker)
	berry(5.3, 2.0)
	berry(8.0, 1.4)
	marker("Stop_Washer", 5.3, 1.2)
	marker("Run_Out", 10.0, 0.0)
