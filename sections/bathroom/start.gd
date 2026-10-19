extends LevelSection
## Начало ванной: коврик у двери, табуретка и бельевая корзина — учимся прыгать.

const WICKER := Color(0.78, 0.6, 0.38)


func _init() -> void:
	length = 12.0
	has_rug = false


func _build() -> void:
	decor(0.6, 0.0, 4.0, 0.03, 0.0, 2.6, Color(0.97, 0.93, 0.88))
	box(5.0, 0.0, 1.8, 0.6, Color(0.55, 0.78, 0.95))
	box(6.8, 0.0, 2.2, 1.2, WICKER)
	box(9.0, 0.0, 1.8, 0.6, Color(0.55, 0.78, 0.95))
	berry_row(1.5, 0.6, 3)
	berry(7.9, 2.0)
	checkpoint(0.5, 0.0)
	marker("Stop_Start", 3.0, 0.0)
	marker("Run_Basket", 7.9, 1.2)
	marker("Stop_Out", 10.4, 0.0)
