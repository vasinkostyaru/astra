extends LevelSection
## Конец ванной: полотенца-ступени на тумбу с раковиной, над ней зеркало с лампочками, Астра у выхода.
## Единственная секция, которая заканчивается не на полу: за ней уровня нет.


func _init() -> void:
	length = 9.6
	has_rug = false


func _build() -> void:
	box(2.4, 0.0, 1.8, 0.6, Color(0.95, 0.75, 0.35))
	box(4.2, 0.0, 1.8, 1.2, Color(0.55, 0.78, 0.95))
	box(6.0, 0.0, 3.6, 1.8, Color(0.97, 0.97, 0.98))
	# Раковина с чёрной пробкой: Август проходит мимо — пробка выскакивает, вода уходит.
	var plug := DrainPlug.new()
	plug.position = Vector3(7.5, 1.85, 0.0)
	add_child(plug)
	decor(7.35, 2.0, 0.12, 0.45, -0.9, 0.12, Color(0.8, 0.82, 0.85))
	pillow_gap(9.6, 1.5)
	lamp_anchor = Vector3(7.8, 3.9, -2.8)
	berry(3.3, 1.2)
	berry(5.1, 1.8)
	berry(7.0, 2.8)
	checkpoint(6.8, 1.8)
	marker("Stop_Stairs", 2.0, 0.0)
	marker("Run_Step1", 3.3, 0.6)
	marker("Run_Step2", 5.1, 1.2)
	marker("Exit_hop", 9.0, 1.8)
