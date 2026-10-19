extends LevelSection
## Занятие: мыльные пузыри. Плавают в воздухе, лопаются от касания со звуком и появляются снова.

func _init() -> void:
	length = 11.0


func _build() -> void:
	var heights: Array[float] = [1.0, 2.0, 1.4, 2.4, 1.2, 2.2]
	for i in heights.size():
		var b := SoapBubble.new()
		b.position = Vector3(2.0 + i * 1.4, heights[i], 0.0)
		add_child(b)
	berry(4.0, 1.0)
	berry(8.0, 1.0)
	marker("Stop_Bubbles", 4.5, 0.0)
	marker("Run_Out", 10.0, 0.0)
