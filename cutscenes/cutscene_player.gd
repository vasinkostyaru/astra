extends Node
## Автолоад Cutscenes: общий проигрыватель роликов.
##
## play(name, params) — показать ролик поверх игры (отдельный SubViewport со своим миром,
## так что свет и камера уровня на ролик не влияют). Игра на это время «замораживается»
## (process_mode = DISABLED у текущей сцены), после конца или пропуска — сразу оживает.
## skip() — пропустить, finished(name) — ролик закончился (и после полного просмотра, и после пропуска).
##
## Точки интеграции описаны в cutscenes/README.md: вызывать play() и ждать finished.

signal finished(name: StringName)

const SCENES: Dictionary = {
	&"intro": "res://cutscenes/intro.tscn",
}

var is_playing: bool = false
var current_name: StringName = &""
var current_params: Dictionary = {}

var _layer: CanvasLayer
var _screen: TextureRect
var _black: ColorRect
var _viewport: SubViewport
var _cut: Cutscene
var _played: Dictionary = {}
var _frozen_scene: Node
var _frozen_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _finishing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.name = "CutsceneLayer"
	_layer.layer = 128
	add_child(_layer)

	_viewport = SubViewport.new()
	_viewport.name = "CutsceneWorld"
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.add_child(_viewport)

	_screen = TextureRect.new()
	_screen.name = "Screen"
	_screen.texture = _viewport.get_texture()
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_SCALE
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_screen)
	_screen.visible = false

	_black = ColorRect.new()
	_black.name = "Black"
	_black.color = Color(0.03, 0.02, 0.02, 0.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_black)
	_black.visible = false

	_update_viewport_size()
	get_viewport().size_changed.connect(_update_viewport_size)


## Показать ролик. params уходят в сам ролик (например, комната для перехода).
func play(name: StringName, params: Dictionary = {}) -> bool:
	if not SCENES.has(name):
		push_error("Cutscenes: неизвестный ролик %s" % name)
		return false
	if is_playing:
		skip()
	var packed := load(SCENES[name]) as PackedScene
	if packed == null:
		push_error("Cutscenes: не загрузилась сцена ролика %s" % SCENES[name])
		return false
	var cut := packed.instantiate() as Cutscene
	if cut == null:
		push_error("Cutscenes: сцена %s без скрипта Cutscene" % SCENES[name])
		return false

	_finishing = false
	is_playing = true
	current_name = name
	current_params = params
	_played[name] = true
	_cut = cut
	cut.managed = true
	_viewport.add_child(cut)
	cut.finished.connect(_on_cut_finished)

	_freeze_scene()
	_screen.visible = true
	_black.visible = true
	_black.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 0.0, 0.35)
	cut.start(params)
	return true


## Пропустить ролик: мир остаётся в том же состоянии, что после полного просмотра.
func skip() -> void:
	if not is_playing or _cut == null:
		return
	_cut.skip()


func was_played(name: StringName) -> bool:
	return _played.has(name)


func reset_played() -> void:
	_played.clear()


func _input(event: InputEvent) -> void:
	if not is_playing:
		return
	if Cutscene.is_skip_event(event):
		get_viewport().set_input_as_handled()
		skip()


func _on_cut_finished() -> void:
	if _finishing:
		return
	_finishing = true
	var name := current_name
	is_playing = false
	current_name = &""
	current_params = {}
	_resume_scene()
	_screen.visible = false
	_black.visible = false
	_black.color.a = 0.0
	if is_instance_valid(_cut):
		_cut.queue_free()
	_cut = null
	_finishing = false
	finished.emit(name)


func _freeze_scene() -> void:
	_frozen_scene = get_tree().current_scene
	if _frozen_scene == null:
		return
	_frozen_mode = _frozen_scene.process_mode
	_frozen_scene.process_mode = Node.PROCESS_MODE_DISABLED


func _resume_scene() -> void:
	if is_instance_valid(_frozen_scene):
		_frozen_scene.process_mode = _frozen_mode
	_frozen_scene = null
	_frozen_mode = Node.PROCESS_MODE_INHERIT


## Ролик рендерится в своё окно размером с экран — картинка резкая на телефоне.
func _update_viewport_size() -> void:
	if _viewport == null:
		return
	var size := get_window().size
	if size.x < 64 or size.y < 64:
		size = Vector2i(1280, 720)
	_viewport.size = size
