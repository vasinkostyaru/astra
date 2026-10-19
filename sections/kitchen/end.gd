extends LevelSection
## Конец кухни: стул, потом большой стол, над ним лампа на шнуре, на столе Астра у выхода и миска с фруктами.
## Единственная секция, которая заканчивается не на полу: за ней уровня нет.


func _init() -> void:
	length = 10.0
	has_rug = false


func _build() -> void:
	chair(2.4, 0.9, 2.0)
	table(4.4, 5.6, 1.8)
	# Миска с фруктами на столе.
	decor(5.4, 1.8, 1.0, 0.25, -0.3, 0.9, Color(0.035, 0.037, 0.042))
	for i in 3:
		var fruit := SphereMesh.new()
		fruit.radius = 0.2
		fruit.height = 0.4
		fruit.material = _material([Color(0.9, 0.3, 0.2), Color(1.0, 0.8, 0.2), Color(0.5, 0.75, 0.3)][i])
		var mi := MeshInstance3D.new()
		mi.mesh = fruit
		mi.position = Vector3(5.65 + i * 0.3, 2.15, -0.3)
		add_child(mi)
	pillow_gap(10.0, 1.5)
	lamp_anchor = Vector3(7.2, 4.1, -0.9)
	berry(3.4, 1.7)
	berry(6.0, 2.8)
	berry(8.0, 2.8)
	checkpoint(6.5, 1.8)
	marker("Stop_Chair", 1.8, 0.0)
	marker("Run_Table", 5.0, 1.8)
	marker("Exit_hop", 9.3, 1.8)
