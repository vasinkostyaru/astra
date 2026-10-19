extends LevelAssembler
## Сборка гостиной: короткая спокойная прогулка; в конце спящая Астра, по очереди загораются гирлянда и торшер.

func _setup() -> void:
	theme = "living"
	add_windows = false
	trim_color = Color(0.97, 0.95, 0.9)
	var wall := ShaderMaterial.new()
	wall.shader = preload("res://sections/living_wall.gdshader")
	wall_material = wall
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://sections/tile.gdshader")
	floor_mat.set_shader_parameter("floor_mode", true)
	floor_mat.set_shader_parameter("tile_a", Color(0.74, 0.64, 0.52))
	floor_mat.set_shader_parameter("tile_b", Color(0.70, 0.60, 0.48))
	floor_mat.set_shader_parameter("grout", Color(0.6, 0.5, 0.4))
	floor_mat.set_shader_parameter("tile_size", 1.6)
	floor_material = floor_mat
	start_section = preload("res://sections/living_room/start.gd")
	feature_section = preload("res://sections/living_room/feature.gd")
	end_section = preload("res://sections/living_room/end.gd")
	pool.append(preload("res://sections/living_room/mid_poufs.gd"))
	pool.append(preload("res://sections/living_room/mid_armchairs.gd"))
	pool.append(preload("res://sections/living_room/mid_table.gd"))
	pool.append(preload("res://sections/living_room/mid_flat.gd"))
	pool.append(preload("res://sections/living_room/mid_shelves.gd"))
	pool.append(preload("res://sections/living_room/mid_sofa_small.gd"))
	activities.append(preload("res://sections/living_room/act_cushion.gd"))
	activities.append(preload("res://sections/living_room/act_piano.gd"))
	activities.append(preload("res://sections/living_room/act_pyramid.gd"))
	activities.append(preload("res://sections/common/act_slide.gd"))
	activities.append(preload("res://sections/common/act_train.gd"))
	activities.append(preload("res://sections/common/act_ball.gd"))
