extends LevelAssembler
## Сборка «Детской»: начало и конец фиксированные, «фишка» — лестница из кирпичиков, середина — из пула.

func _setup() -> void:
	start_section = preload("res://sections/kids_room/start.gd")
	feature_section = preload("res://sections/kids_room/feature.gd")
	end_section = preload("res://sections/kids_room/end.gd")
	pool.append(preload("res://sections/kids_room/mid_blocks.gd"))
	pool.append(preload("res://sections/kids_room/mid_books.gd"))
	pool.append(preload("res://sections/kids_room/mid_mat.gd"))
	pool.append(preload("res://sections/kids_room/mid_toybox.gd"))
	pool.append(preload("res://sections/kids_room/mid_gap.gd"))
	pool.append(preload("res://sections/kids_room/mid_hill.gd"))
	pool.append(preload("res://sections/kids_room/mid_train.gd"))
	pool.append(preload("res://sections/kids_room/mid_stones.gd"))
	pool.append(preload("res://sections/kids_room/mid_shelf.gd"))
	pool.append(preload("res://sections/kids_room/mid_cabinets.gd"))
	pool.append(preload("res://sections/kids_room/mid_towers.gd"))
	activities.append(preload("res://sections/kids_room/act_piano.gd"))
	activities.append(preload("res://sections/kids_room/act_pyramid.gd"))
	activities.append(preload("res://sections/kids_room/act_trampoline.gd"))
