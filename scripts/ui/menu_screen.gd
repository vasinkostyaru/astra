class_name MenuScreen
extends Node
## База для экранов меню: тёплый фон, шторка затемнения и переход на другую сцену.

var ui: CanvasLayer
var fade: ColorRect
var backdrop: MenuBackdrop
var _busy: bool = false


## Слой интерфейса: фон на слое -1 (под 3D, если оно есть), шторка поверх всего.
func build_ui() -> void:
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	backdrop = MenuBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.add_child(backdrop)
	ui = CanvasLayer.new()
	add_child(ui)
	var top := CanvasLayer.new()
	top.layer = 10
	add_child(top)
	fade = ColorRect.new()
	fade.color = Color(0.03, 0.02, 0.02, 1.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.add_child(fade)
	create_tween().tween_property(fade, "color:a", 0.0, 0.5)


## Затемняет экран и вызывает действие; повторные касания во время перехода игнорируются.
func leave(action: Callable) -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	action.call()
