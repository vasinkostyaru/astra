extends LevelSection
## Лужица в углу кабины: два плавающих игрушки (кораблик и лебедь), переправа короткая.


func _init() -> void:
	length = 13.5


func _build() -> void:
	water_pit(2.0, 8.8)
	floating_toy(3.6, FloatingToy.Kind.BOAT)
	floating_toy(7.3, FloatingToy.Kind.SWAN)
	checkpoint(1.2, 0.0)
	checkpoint(11.8, 0.0)
	berry(4.7, 1.9)
	berry(8.4, 1.9)
	marker("Stop_Edge", 1.2, 0.0)
	marker("Run_Boat", 4.7, 0.15)
	marker("Run_Swan", 8.4, 0.15)
	marker("Run_Out", 12.5, 0.0)
