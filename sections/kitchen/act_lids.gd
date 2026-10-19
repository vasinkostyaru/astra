extends LevelSection
## Занятие: крышка-трамплин. Наступил на блестящую крышку — подбросило, наверху ягодки; идти вперёд не мешает.

func _init() -> void:
	length = 11.0


func _build() -> void:
	var lid := BouncePad.new()
	lid.lid = true
	lid.position = Vector3(4.0, 0.0, 0.0)
	add_child(lid)
	var lid2 := BouncePad.new()
	lid2.lid = true
	lid2.position = Vector3(7.5, 0.0, 0.0)
	add_child(lid2)
	berry(4.0, 3.4)
	berry(5.8, 4.0)
	berry(7.5, 3.4)
	marker("Stop_Lids", 3.0, 0.0)
	marker("Run_Out", 10.0, 0.0)
