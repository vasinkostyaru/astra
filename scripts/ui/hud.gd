class_name Hud
extends CanvasLayer
## Интерфейс уровня: банка-счётчик в углу и экранные кнопки. Без текста.

const JAR_HEIGHT := 0.2
const MARGIN := 0.04

@onready var jar: Jar = $Root/Jar
@onready var _root: Control = $Root

var _glow_texture: GradientTexture2D


func _ready() -> void:
	_root.resized.connect(_layout)
	_layout()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1.0, 1.0, 0.9, 1.0), Color(1.0, 0.8, 0.3, 0.8), Color(1.0, 0.6, 0.2, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	_glow_texture = GradientTexture2D.new()
	_glow_texture.gradient = g
	_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_glow_texture.fill_from = Vector2(0.5, 0.5)
	_glow_texture.fill_to = Vector2(0.5, 0.0)
	_glow_texture.width = 64
	_glow_texture.height = 64


func _layout() -> void:
	var h := _root.size.y
	var jh := h * JAR_HEIGHT
	jar.size = Vector2(jh * 0.72, jh)
	jar.position = Vector2(_root.size.x - h * MARGIN - jar.size.x, h * MARGIN)


## Искорка летит дугой из точки на экране в банку; по прилёту банка наполняется.
func fly_spark_to_jar(from: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _glow_texture
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	sprite.position = from
	_root.add_child(sprite)

	var to := jar.target_point()
	var control := from.lerp(to, 0.5) + Vector2(0.0, -_root.size.y * 0.25)
	var tw := create_tween()
	tw.tween_method(_move_spark.bind(sprite, from, control, to), 0.0, 1.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(sprite.queue_free)
	tw.tween_callback(jar.add_one)


func _move_spark(t: float, sprite: Sprite2D, from: Vector2, control: Vector2, to: Vector2) -> void:
	var a := from.lerp(control, t)
	var b := control.lerp(to, t)
	sprite.position = a.lerp(b, t)
	sprite.scale = Vector2.ONE * lerpf(1.4, 0.7, t)
