extends Control
## Экранное управление с мультитачем: каждый палец (index) закрепляется за кнопкой под ним.
## Палец можно передвинуть с «влево» на «вправо», не отрывая. На ПК мышь эмулирует касание.

## Размер кнопок движения в долях высоты экрана (по правилам — не меньше 0.15).
const MOVE_SIZE := 0.24
const JUMP_SIZE := 0.28
const MARGIN := 0.05
## Насколько зона касания больше нарисованной кнопки — чтобы детский палец не «соскальзывал».
const HIT_GROW := 0.15

@onready var _left: TouchButton = $Left
@onready var _right: TouchButton = $Right
@onready var _jump: TouchButton = $Jump
@onready var _buttons: Array[TouchButton] = [_left, _right, _jump]

var _fingers: Dictionary = {}  # index пальца -> TouchButton или null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var h := size.y
	var m := h * MARGIN
	var ms := h * MOVE_SIZE
	var js := h * JUMP_SIZE
	_left.size = Vector2(ms, ms)
	_left.position = Vector2(m, h - m - ms)
	_right.size = Vector2(ms, ms)
	_right.position = Vector2(m + ms + m * 0.6, h - m - ms)
	_jump.size = Vector2(js, js)
	_jump.position = Vector2(size.x - m - js, h - m - js)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_fingers[touch.index] = _button_at(touch.position)
		else:
			_fingers.erase(touch.index)
		_refresh()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _fingers.has(drag.index):
			_fingers[drag.index] = _button_at(drag.position)
			_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		_fingers.clear()
		_refresh()


func _button_at(pos: Vector2) -> TouchButton:
	for b in _buttons:
		var rect := b.get_global_rect()
		if rect.grow(rect.size.x * HIT_GROW).has_point(pos):
			return b
	return null


func _refresh() -> void:
	var held := _fingers.values()
	for b in _buttons:
		b.set_pressed(held.has(b))
