extends SceneTree
## Рендер иконки: SHOT_DIR=<папка> godot --path . --resolution 1024x1024 -s $PWD/tools/tests/icon_render.gd
## Крупные планы голов Августа и Астры на тёплом фоне; fg — без фона для адаптивной иконки.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var out := OS.get_environment("SHOT_DIR")
	for who in ["avgust", "astra"]:
		for transparent in [false, true]:
			var vp := SubViewport.new()
			vp.size = Vector2i(1024, 1024)
			vp.transparent_bg = transparent
			vp.msaa_3d = Viewport.MSAA_4X
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(vp)
			var env := Environment.new()
			env.background_mode = Environment.BG_COLOR if not transparent else Environment.BG_CLEAR_COLOR
			env.background_color = Color(0.6, 0.8, 0.95)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(1, 0.88, 0.75)
			env.ambient_light_energy = 0.7
			var we := WorldEnvironment.new(); we.environment = env; vp.add_child(we)
			var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-30, 25, 0); sun.light_energy = 0.9; vp.add_child(sun)
			var m: Node3D = load("res://assets/models/%s/%s.glb" % [who, who]).instantiate()
			vp.add_child(m)
			if who == "astra":
				m.rotation_degrees.y = -90 if false else 0
			var cam := Camera3D.new(); cam.fov = 30; vp.add_child(cam)
			var cfg: Array = {"avgust": [Vector3(0, 0.93, 1.5), Vector3(0, 0.88, 0)], "astra": [Vector3(0, 0.36, 1.05), Vector3(0, 0.33, 0)]}[who]
			cam.position = cfg[0]
			cam.look_at(cfg[1])
			for i in 20: await process_frame
			vp.get_texture().get_image().save_png("%s/icon_%s_%s.png" % [out, who, "fg" if transparent else "bg"])
			vp.queue_free()
	quit()
