extends LevelAssembler
## Сборка ванной: начало и конец фиксированные, «фишка» — переправа по плавающим игрушкам, середина — из пула.

func _setup() -> void:
	theme = "bath"
	add_windows = false
	var wall := ShaderMaterial.new()
	wall.shader = preload("res://sections/tile.gdshader")
	wall.set_shader_parameter("tile_a", Color(0.95, 0.47, 0.42))
	wall.set_shader_parameter("tile_b", Color(0.91, 0.42, 0.38))
	wall_material = wall
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://sections/tile.gdshader")
	floor_mat.set_shader_parameter("floor_mode", true)
	floor_mat.set_shader_parameter("tile_a", Color(0.82, 0.3, 0.28))
	floor_mat.set_shader_parameter("tile_b", Color(0.76, 0.26, 0.25))
	floor_mat.set_shader_parameter("tile_size", 1.2)
	floor_material = floor_mat
	start_section = preload("res://sections/bathroom/start.gd")
	feature_section = preload("res://sections/bathroom/feature.gd")
	end_section = preload("res://sections/bathroom/end.gd")
	pool.append(preload("res://sections/bathroom/mid_washer.gd"))
	pool.append(preload("res://sections/bathroom/mid_baskets.gd"))
	pool.append(preload("res://sections/bathroom/mid_bench.gd"))
	pool.append(preload("res://sections/bathroom/mid_water_toys.gd"))
	pool.append(preload("res://sections/bathroom/mid_water_four.gd"))
	pool.append(preload("res://sections/bathroom/mid_water_stairs.gd"))
	pool.append(preload("res://sections/bathroom/mid_water_blocks.gd"))
	pool.append(preload("res://sections/bathroom/mid_puddle.gd"))
	activities.append(preload("res://sections/bathroom/act_bubbles.gd"))
	activities.append(preload("res://sections/bathroom/act_piano.gd"))
	activities.append(preload("res://sections/bathroom/act_trampoline.gd"))
	activities.append(preload("res://sections/common/act_slide.gd"))
	activities.append(preload("res://sections/common/act_train.gd"))
	activities.append(preload("res://sections/common/act_ball.gd"))
