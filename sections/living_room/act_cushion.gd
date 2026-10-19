extends LevelSection
## Занятие: диванная подушка-батут. Наступил — подбросило высоко, наверху ягодки; идти вперёд не мешает.

func _init() -> void:
	length = 11.0


func _build() -> void:
	var pad := BouncePad.new()
	pad.position = Vector3(4.0, 0.0, 0.0)
	add_child(pad)
	berry(4.0, 3.4)
	berry(5.2, 4.0)
	berry(6.4, 3.4)
	marker("Stop_Pad", 3.0, 0.0)
	marker("Run_Out", 10.0, 0.0)
