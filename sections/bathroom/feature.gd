extends LevelSection
## «Фишка» ванной: переправа через глубокий поддон душевой кабины по плавающим игрушкам
## (лебедь, уточка, машинка, кораблик). Упал в воду — на Августа надевается круг и выносит к чекпоинту.
## На дне — чёрная пробка с цепочкой.


func _init() -> void:
	length = 25.0
	has_rug = false


func _build() -> void:
	water_pit(4.0, 16.0)
	var kinds: Array[int] = [FloatingToy.Kind.SWAN, FloatingToy.Kind.DUCK, FloatingToy.Kind.CAR, FloatingToy.Kind.BOAT]
	for i in 4:
		floating_toy(5.6 + i * 3.7, kinds[i])
	_plug(12.0)
	berry(6.7, 1.9)
	berry(8.4, 2.4)
	berry(11.2, 2.4)
	berry(14.9, 2.4)
	berry(18.6, 1.9)
	checkpoint(3.0, 0.0)
	checkpoint(14.1, 0.2)
	checkpoint(21.5, 0.0)
	marker("Stop_Edge", 2.6, 0.0)
	marker("Run_Swan", 6.7, 0.15)
	marker("Run_Duck", 10.4, 0.15)
	marker("Stop_Car", 14.1, 0.15)
	marker("Run_Boat", 17.8, 0.15)
	marker("Stop_Far", 21.6, 0.0)
	marker("Run_Out", 24.0, 0.0)


## Чёрная пробка на дне с цепочкой, уходящей к краю.
func _plug(x: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.38
	cyl.bottom_radius = 0.45
	cyl.height = 0.22
	cyl.material = _material(Color(0.08, 0.08, 0.09))
	var plug := MeshInstance3D.new()
	plug.mesh = cyl
	plug.position = Vector3(x, -1.5, 0.3)
	add_child(plug)
	var knob := SphereMesh.new()
	knob.radius = 0.14
	knob.height = 0.28
	knob.material = _material(Color(0.08, 0.08, 0.09))
	var knob_mi := MeshInstance3D.new()
	knob_mi.mesh = knob
	knob_mi.position = Vector3(x, -1.32, 0.3)
	add_child(knob_mi)
	for i in 12:
		var link := SphereMesh.new()
		link.radius = 0.05
		link.height = 0.1
		link.material = _material(Color(0.75, 0.77, 0.8))
		var mi := MeshInstance3D.new()
		mi.mesh = link
		mi.position = Vector3(x + 0.3 + i * 0.5, -1.55 + 0.04 * i, 0.3 + sin(i * 0.7) * 0.15)
		add_child(mi)
