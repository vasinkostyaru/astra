class_name RoomCard
extends PictureButton
## Карточка комнаты: картинка-предмет и лампочка прогресса (горит — комната пройдена). Без текста.
## Комнаты, которых ещё нет в игре, приглушены и при касании только качаются.

const PAPER: Array[Color] = [
	Color(0.98, 0.84, 0.6), Color(0.66, 0.85, 0.95), Color(0.98, 0.78, 0.66), Color(0.82, 0.76, 0.95)]

## Картинки комнат (CC0, см. assets/rooms/SOURCES.txt); если файла нет — рисуем значок в коде.
const PICTURES: Dictionary = {
	0: "res://assets/rooms/room_0_kids_room.png",
	1: "res://assets/rooms/room_1_bathroom.png",
	2: "res://assets/rooms/room_2_kitchen.png",
	3: "res://assets/rooms/room_3_living_room.png",
}

@export var room: int = 0
var built: bool = false
var completed: bool = false
## Держим ссылку: текстура, загруженная прямо в _draw, освобождалась бы до отрисовки кадра.
var _picture: Texture2D


func _ready() -> void:
	super()
	if PICTURES.has(room):
		_picture = load(PICTURES[room])


func wobble() -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation", 0.06, 0.06)
	tw.tween_property(self, "rotation", -0.06, 0.12)
	tw.tween_property(self, "rotation", 0.0, 0.06)


func _draw_icon() -> void:
	var w := size.x
	var h := size.y
	var dim := 1.0 if built else 0.45
	var paper := PAPER[room % PAPER.size()]
	paper = paper.lerp(Color(0.75, 0.72, 0.7), 1.0 - dim)
	var card := Rect2(0, 0, w, h * 0.8)
	var sb := StyleBoxFlat.new()
	sb.bg_color = paper
	sb.set_corner_radius_all(int(w * 0.14))
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = int(w * 0.04)
	sb.shadow_offset = Vector2(0, w * 0.02)
	if completed:
		sb.border_color = Color(1.0, 0.85, 0.3)
		sb.set_border_width_all(int(w * 0.035))
	draw_style_box(sb, card)
	if _picture:
		var tint := Color.WHITE if built else Color(0.5, 0.5, 0.5, 1.0)
		draw_texture_rect(_picture, card, false, tint)
		if completed:
			var ring := StyleBoxFlat.new()
			ring.draw_center = false
			ring.border_color = Color(1.0, 0.85, 0.3)
			ring.set_border_width_all(int(w * 0.035))
			ring.set_corner_radius_all(int(w * 0.14))
			draw_style_box(ring, card)
		_bulb(Vector2(w * 0.5, h * 0.9), h * 0.09)
		return
	var c := card.get_center()
	var u := w * 0.1
	match room:
		0: _bricks(c, u, dim)
		1: _tub(c, u, dim)
		2: _pot(c, u, dim)
		_: _sofa(c, u, dim)
	_bulb(Vector2(w * 0.5, h * 0.9), h * 0.09)


func _col(c: Color, dim: float) -> Color:
	return c.lerp(Color(0.6, 0.58, 0.57), 1.0 - dim)


func _rr(r: Rect2, c: Color, radius: float, dim: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _col(c, dim)
	sb.set_corner_radius_all(int(radius))
	draw_style_box(sb, r)


func _bricks(c: Vector2, u: float, dim: float) -> void:
	var cols: Array[Color] = [Color(0.9, 0.25, 0.2), Color(0.2, 0.55, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.75, 0.35)]
	var k := 0
	for row in 3:
		var n := 3 - row
		for i in n:
			var x := c.x + (i - (n - 1) * 0.5) * u * 2.1 - u
			_rr(Rect2(x, c.y + u * 1.2 - row * u * 1.35, u * 2.0, u * 1.2), cols[k % 4], u * 0.3, dim)
			k += 1


func _tub(c: Vector2, u: float, dim: float) -> void:
	_rr(Rect2(c.x - u * 3.0, c.y - u * 0.2, u * 6.0, u * 2.6), Color(0.97, 0.97, 1.0), u * 1.0, dim)
	_rr(Rect2(c.x - u * 2.6, c.y + u * 0.1, u * 5.2, u * 1.2), Color(0.35, 0.7, 0.95), u * 0.5, dim)
	draw_circle(c + Vector2(u * 0.4, -u * 0.5), u * 0.9, _col(Color(1.0, 0.85, 0.2), dim))
	draw_circle(c + Vector2(u * 1.1, -u * 1.1), u * 0.55, _col(Color(1.0, 0.85, 0.2), dim))
	draw_colored_polygon(PackedVector2Array([c + Vector2(u * 1.6, -u * 1.1), c + Vector2(u * 2.2, -u * 0.9), c + Vector2(u * 1.6, -u * 0.8)]), _col(Color(1.0, 0.5, 0.15), dim))


func _pot(c: Vector2, u: float, dim: float) -> void:
	_rr(Rect2(c.x - u * 2.4, c.y - u * 0.4, u * 4.8, u * 2.6), Color(0.55, 0.6, 0.7), u * 0.7, dim)
	_rr(Rect2(c.x - u * 3.2, c.y + u * 0.1, u * 1.0, u * 0.6), Color(0.4, 0.45, 0.55), u * 0.3, dim)
	_rr(Rect2(c.x + u * 2.2, c.y + u * 0.1, u * 1.0, u * 0.6), Color(0.4, 0.45, 0.55), u * 0.3, dim)
	_rr(Rect2(c.x - u * 2.6, c.y - u * 1.0, u * 5.2, u * 0.8), Color(0.75, 0.8, 0.88), u * 0.4, dim)
	draw_circle(c + Vector2(0, -u * 1.25), u * 0.35, _col(Color(0.9, 0.35, 0.3), dim))


func _sofa(c: Vector2, u: float, dim: float) -> void:
	_rr(Rect2(c.x - u * 2.8, c.y - u * 1.2, u * 5.6, u * 2.2), Color(0.75, 0.35, 0.45), u * 0.9, dim)
	_rr(Rect2(c.x - u * 3.3, c.y - u * 0.2, u * 1.4, u * 2.2), Color(0.65, 0.28, 0.38), u * 0.6, dim)
	_rr(Rect2(c.x + u * 1.9, c.y - u * 0.2, u * 1.4, u * 2.2), Color(0.65, 0.28, 0.38), u * 0.6, dim)
	_rr(Rect2(c.x - u * 2.0, c.y, u * 4.0, u * 1.4), Color(0.85, 0.45, 0.55), u * 0.5, dim)
	for i in 5:
		draw_circle(Vector2(c.x + (i - 2) * u * 1.3, c.y - u * 1.9 + absf(i - 2) * u * 0.25), u * 0.22,
			_col([Color(1, 0.4, 0.4), Color(1, 0.85, 0.3), Color(0.4, 0.8, 0.5), Color(0.4, 0.7, 1), Color(1, 0.5, 0.8)][i], dim))


## Лампочка под карточкой: пройдена — горит, нет — тёмная.
func _bulb(c: Vector2, r: float) -> void:
	if completed:
		draw_circle(c, r * 1.7, Color(1.0, 0.85, 0.3, 0.3 + 0.1 * sin(_time * 3.0)))
	draw_circle(c, r, Color(1.0, 0.88, 0.35) if completed else Color(0.45, 0.4, 0.38, 0.8))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.28, Color(1, 1, 1, 0.7 if completed else 0.25))
