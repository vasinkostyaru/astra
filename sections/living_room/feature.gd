extends LevelSection
## «Фишка» гостиной: через диван с разноцветными подушками и два оранжевых кресла (промежутки 1.6 с подушками внизу).


func _init() -> void:
	length = 23.0


func _build() -> void:
	pouf(2.0, 1.8, 0.45, Color(0.5, 0.4, 0.8))
	sofa(3.8, 6.0, 0.9)
	pillow_gap(9.8, 1.6)
	armchair(11.4, 2.4, 0.9)
	pillow_gap(13.8, 1.6)
	armchair(15.4, 2.4, 0.9)
	pouf(17.8, 1.8, 0.45, Color(0.95, 0.78, 0.2))
	berry(2.9, 1.2)
	berry(5.0, 2.0)
	berry(7.6, 2.0)
	berry(10.6, 3.0)
	berry(12.6, 2.2)
	berry(16.6, 2.2)
	checkpoint(6.8, 0.9)
	checkpoint(12.6, 0.9)
	checkpoint(16.6, 0.9)
	marker("Stop_Pouf", 2.9, 0.45)
	marker("Run_Sofa", 6.8, 0.9)
	marker("Stop_Armchair", 12.6, 0.9)
	marker("Run_Armchair2", 16.6, 0.9)
	marker("Run_Out", 21.5, 0.0)
