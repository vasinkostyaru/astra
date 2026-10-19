extends LevelSection
## Башня из кирпичиков: ступени 0.6 / 1.2 и широкая крыша на 1.8, спуск такой же.

func _init() -> void:
	length = 14.5


func _build() -> void:
	bricks(2.0, 0.0, 3, 2, 41)
	bricks(3.8, 0.0, 3, 4, 42)
	bricks(5.6, 0.0, 5, 6, 43)
	bricks(8.6, 0.0, 3, 4, 44)
	bricks(10.4, 0.0, 3, 2, 45)
	berry(4.7, 1.8)
	berry(7.1, 2.6)
	marker("Stop_Tower", 7.1, 1.8)
	marker("Run_Out", 13.5, 0.0)
