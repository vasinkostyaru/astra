extends LevelSection
## Занятие: паровозик. Встал на вагончик — гудок, паровозик везёт Августа вперёд; над путём ягодки.


func _init() -> void:
	length = 14.0


func _build() -> void:
	# Рельсы — картинка на полу.
	for z in [-0.7, 0.7]:
		decor(1.5, 0.0, 10.5, 0.05, z, 0.12, Color(0.55, 0.4, 0.28))
	for i in 15:
		decor(1.6 + i * 0.7, 0.0, 0.18, 0.035, 0.0, 1.8, Color(0.7, 0.5, 0.32))
	var train := ToyTrain.new()
	train.travel = 6.5
	train.position = Vector3(3.5, 0.0, 0.0)
	add_child(train)
	berry(6.0, 1.6)
	berry(7.6, 1.6)
	berry(9.2, 1.6)
	marker("Stop_Train", 1.5, 0.0)
	marker("Run_Out", 13.0, 0.0)
