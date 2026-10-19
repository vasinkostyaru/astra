extends LevelSection
## Стопка книг — «пирамидка» со ступеньками по 0.4 вверх и вниз.

func _init() -> void:
	length = 9.5


func _build() -> void:
	box(2.0, 0.0, 5.0, 0.4, Color(0.85, 0.3, 0.3))
	box(3.0, 0.4, 3.0, 0.4, Color(0.3, 0.55, 0.85))
	box(4.0, 0.8, 1.0, 0.4, Color(0.35, 0.75, 0.4))
	berry(3.5, 1.3)
	berry(5.5, 1.3)
	marker("Stop_Books", 4.5, 1.2)
	marker("Run_Out", 8.5, 0.0)
