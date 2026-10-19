extends LevelAssembler
## Сборка кухни: начало и конец фиксированные, «фишка» — подъём по стульям на стол и высокие тумбы, середина — из пула.

func _setup() -> void:
	theme = "kitchen"
	add_windows = false
	trim_color = Color(0.035, 0.037, 0.042)
	var wall := ShaderMaterial.new()
	wall.shader = preload("res://sections/kitchen_wall.gdshader")
	wall_material = wall
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://sections/tile.gdshader")
	floor_mat.set_shader_parameter("floor_mode", true)
	floor_mat.set_shader_parameter("tile_a", Color(0.86, 0.80, 0.70))
	floor_mat.set_shader_parameter("tile_b", Color(0.81, 0.75, 0.65))
	floor_mat.set_shader_parameter("grout", Color(0.6, 0.55, 0.5))
	floor_mat.set_shader_parameter("tile_size", 1.2)
	floor_material = floor_mat
	start_section = preload("res://sections/kitchen/start.gd")
	feature_section = preload("res://sections/kitchen/feature.gd")
	end_section = preload("res://sections/kitchen/end.gd")
	pool.append(preload("res://sections/kitchen/mid_chairs.gd"))
	pool.append(preload("res://sections/kitchen/mid_steps.gd"))
	pool.append(preload("res://sections/kitchen/mid_pots.gd"))
	pool.append(preload("res://sections/kitchen/mid_crates.gd"))
	pool.append(preload("res://sections/kitchen/mid_table.gd"))
	pool.append(preload("res://sections/kitchen/mid_flat.gd"))
	pool.append(preload("res://sections/kitchen/mid_counter.gd"))
	activities.append(preload("res://sections/kitchen/act_lids.gd"))
	activities.append(preload("res://sections/kitchen/act_piano.gd"))
	activities.append(preload("res://sections/kitchen/act_pyramid.gd"))
