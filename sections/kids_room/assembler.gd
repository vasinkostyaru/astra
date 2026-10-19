extends LevelAssembler
## Сборка «Детской»: начало и конец фиксированные, «фишка» — лестница из кирпичиков, середина — из пула.

func _setup() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_texture = preload("res://assets/textures/surfaces/parquet.jpg")
	floor_mat.albedo_color = Color(0.85, 0.72, 0.6)
	floor_mat.normal_enabled = true
	floor_mat.normal_texture = preload("res://assets/textures/surfaces/parquet_n.png")
	floor_mat.roughness = 0.75
	floor_mat.uv1_triplanar = true
	floor_mat.uv1_world_triplanar = true
	floor_mat.uv1_scale = Vector3.ONE * 0.3
	floor_material = floor_mat
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
	activities.append(preload("res://sections/common/act_slide.gd"))
	activities.append(preload("res://sections/common/act_train.gd"))
	activities.append(preload("res://sections/common/act_ball.gd"))
