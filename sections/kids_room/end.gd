extends LevelSection
## Конец «Детской»: лестница из кубиков на тумбочку, на ней ночник и Астра у выхода.
## Единственная секция, которая заканчивается не на полу: за ней уровня нет.

const WOOD_LIGHT := Color(0.78, 0.58, 0.38)


func _init() -> void:
	has_rug = false
	length = 10.0


func _build() -> void:
	bricks(3.0, 0.0, 2, 2, 21)
	bricks(4.2, 0.0, 2, 4, 22)
	bricks(5.4, 0.0, 2, 6, 23)
	box(6.6, 0.0, 3.4, 2.4, WOOD_LIGHT)
	decor(8.0, 1.5, 0.2, 0.2, 1.02, 0.1, Color(0.62, 0.4, 0.23))
	# Справа от тумбочки пол: подушка, чтобы не застрять под ней.
	pillow_gap(10.0, 1.5)
	lamp_anchor = Vector3(7.6, 2.4, -0.5)
	berry(4.8, 1.8)
	berry(6.0, 2.4)
	berry(7.6, 3.4)
	checkpoint(7.0, 2.4)
	marker("Stop_Stairs", 2.2, 0.0)
	marker("Run_Step1", 3.6, 0.6)
	marker("Run_Step2", 4.8, 1.2)
	marker("Run_Step3", 6.0, 1.8)
	marker("Exit_hop", 9.2, 2.4)
