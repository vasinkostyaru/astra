extends LevelSection
## Занятие: пирамида из кубиков. Подошёл или подпрыгнул — рассыпается с грохотом и сама собирается обратно.


func _init() -> void:
	length = 10.0


func _build() -> void:
	var pyramid := CubePyramid.new()
	pyramid.base = 3
	pyramid.color_seed = 9
	pyramid.position = Vector3(5.0, 0.0, 0.0)
	add_child(pyramid)
	berry(3.0, 1.2)
	berry(5.0, 2.4)
	marker("Stop_Pyramid", 3.0, 0.0)
	marker("Run_Out", 9.0, 0.0)
