extends SceneTree

var level: Node
var frame := 0

func _initialize() -> void:
	level = load("res://levels/level_01_kids_room.tscn").instantiate()
	root.add_child(level)

func _touch(i: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i; e.position = root.get_final_transform() * pos; e.pressed = pressed
	root.push_input(e)

func _drag(i: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i; e.position = root.get_final_transform() * pos
	root.push_input(e)

func _state(tag: String) -> void:
	print(tag, " L=", Input.is_action_pressed(&"move_left"), " R=", Input.is_action_pressed(&"move_right"), " J=", Input.is_action_pressed(&"jump"))

func _process(_d: float) -> bool:
	frame += 1
	var tc: Control = level.get_node("HUD/Root/TouchControls")
	var c := func(n: String) -> Vector2: return (tc.get_node(n) as Control).get_global_rect().get_center()
	match frame:
		3:
			print("proc_input=", tc.is_processing_input(), " in_tree=", tc.is_inside_tree(), " fingers=", tc._fingers)
			print("viewport=", root.get_visible_rect().size, " left=", tc.get_node("Left").get_global_rect(), " jump=", tc.get_node("Jump").get_global_rect())
			_touch(0, c.call("Right"), true)
			_touch(1, c.call("Jump"), true)
		5:
			_state("right+jump:")
			print("fingers=", tc._fingers)
		6: _drag(0, c.call("Left"))
		8: _state("slide to left:")
		9: _touch(1, c.call("Jump"), false)
		11: _state("jump released:")
		12: _touch(0, c.call("Left"), false)
		14:
			_state("all released:")
			return true
	return false
