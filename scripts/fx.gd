class_name Fx
extends RefCounted
## Мелкие «сочные» эффекты: облачко пыли, искорки, цветокоррекция и виньетка уровня.
## Только картинка: на физику и проходимость не влияют.

static var _soft_mat: StandardMaterial3D
static var _vignette_shader: Shader


## Пыль у ног (приземление, бег): серо-бежевые клубки стелются по полу в стороны и тают.
static func puff(parent: Node, pos: Vector3, amount: int = 8, power: float = 1.0) -> void:
	var p := _burst(parent, pos + Vector3(0, 0.08, 0), amount, 0.5)
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.28
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = _soft()
	p.mesh = mesh
	p.direction = Vector3.RIGHT
	p.spread = 180.0
	p.flatness = 0.85  # разлёт в плоскости пола, а не вверх
	p.initial_velocity_min = 1.0 * power
	p.initial_velocity_max = 2.0 * power
	p.gravity = Vector3(0, 0.6, 0)
	p.damping_min = 4.0
	p.damping_max = 5.0
	p.scale_amount_curve = _fade_curve(0.6, 1.8)
	p.color = Color(0.92, 0.87, 0.8, 0.95)
	p.color_ramp = _alpha_ramp()


## Сбор ягодки: вспышка-кольцо её цвета и золотые звёздочки, которые крутятся и взлетают вверх.
static func sparkle(parent: Node, pos: Vector3, color: Color, amount: int = 12) -> void:
	_ring(parent, pos, color)
	var p := _burst(parent, pos, amount, 0.8)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.38, 0.38)
	mesh.material = _star_material()
	p.mesh = mesh
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -2.0, 0)
	p.damping_min = 2.5
	p.damping_max = 3.5
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_curve = _fade_curve(1.2, 0.2)
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.55, 1.0))
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = g


## Плоское кольцо, которое быстро расширяется и тает (лицом к камере).
static func _ring(parent: Node, pos: Vector3, color: Color) -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	var m := _ring_material().duplicate() as StandardMaterial3D
	m.albedo_color = color.lightened(0.35)
	mesh.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.3
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3.ONE * 2.2, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)


static var _star_mat: StandardMaterial3D
static var _ring_mat: StandardMaterial3D


static func _star_material() -> StandardMaterial3D:
	if _star_mat == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for yy in 64:
			for xx in 64:
				var d := Vector2(xx - 31.5, yy - 31.5) / 32.0
				var ang := atan2(d.y, d.x)
				var r := 0.45 + 0.55 * pow(absf(cos(ang * 2.5)), 6.0)  # пятиконечная звёздочка
				var a := clampf((r - d.length()) * 8.0, 0.0, 1.0)
				img.set_pixel(xx, yy, Color(1, 1, 1, a))
		_star_mat = _billboard(ImageTexture.create_from_image(img))
		_star_mat.vertex_color_use_as_albedo = true
	return _star_mat


static func _ring_material() -> StandardMaterial3D:
	if _ring_mat == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for yy in 64:
			for xx in 64:
				var d := Vector2(xx - 31.5, yy - 31.5).length() / 32.0
				var a := clampf(1.0 - absf(d - 0.8) * 8.0, 0.0, 1.0)
				img.set_pixel(xx, yy, Color(1, 1, 1, a))
		_ring_mat = _billboard(ImageTexture.create_from_image(img))
		_ring_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_ring_mat.billboard_keep_scale = true
	return _ring_mat


static func _billboard(tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Пар из трубы паровозика: белые клубки поднимаются вверх и растут.
static func steam(parent: Node, pos: Vector3) -> void:
	var p := _burst(parent, pos, 3, 0.9)
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = _soft()
	p.mesh = mesh
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(-0.6, 0.3, 0)
	p.scale_amount_curve = _fade_curve(0.6, 2.0)
	p.color = Color(1, 1, 1, 0.9)
	p.color_ramp = _alpha_ramp()


## Тёплая цветокоррекция и виньетка (мягкое затемнение по краям) для сцены уровня.
static func grade(level: Node) -> void:
	var we := level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.1
		env.adjustment_saturation = 1.15
		env.adjustment_brightness = 1.0
	if _vignette_shader == null:
		_vignette_shader = Shader.new()
		_vignette_shader.code = """
shader_type canvas_item;
uniform float strength = 0.35;
void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.6, 1.0);
	float v = smoothstep(0.45, 1.05, length(d));
	COLOR = vec4(0.18, 0.08, 0.02, v * strength);
}
"""
	var layer := CanvasLayer.new()
	layer.layer = -1  # над 3D, но под кнопками и банкой
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = _vignette_shader
	rect.material = sm
	layer.add_child(rect)
	level.add_child(layer)


static func _burst(parent: Node, pos: Vector3, amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func _soft() -> StandardMaterial3D:
	if _soft_mat == null:
		_soft_mat = StandardMaterial3D.new()
		_soft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_soft_mat.vertex_color_use_as_albedo = true
		_soft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _soft_mat


static func _fade_curve(from: float, to: float) -> Curve:
	var c := Curve.new()
	c.max_value = maxf(from, to)
	c.add_point(Vector2(0, from))
	c.add_point(Vector2(1, to))
	return c


static func _alpha_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	return g
