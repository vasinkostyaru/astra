extends SceneTree
## Бот на множестве случайных сборок уровня. Ходит вправо, прыгает у стенок и перед краями,
## за которыми есть опора. Считает: прошёл ли, за сколько, падения (возвраты к чекпоинту), где застрял.
## Запуск: godot --headless --path . --fixed-fps 60 -s $PWD/tools/tests/sections_bot.gd -- count=200 first=1 [level=res://...]
## Одна сборка: count=1 first=<сид>.

const MAX_TIME := 150.0
const STALL_TIME := 25.0
const PROBE_OFFSETS: Array[float] = [0.35, 0.7]

var level_path := "res://levels/level_01_kids_room.tscn"
var count := 200
var first := 1

var _index := 0
var _level: Node
var _player: CharacterBody3D
var _assembler: Node
var _frame := 0
var _done_flag := false
var _respawn_x: Array[float] = []
var _max_x := -100.0
var _last_progress_frame := 0
var _berries_total := 0
var _berries_left := 0
var _results: Array[Dictionary] = []
var _waiting := 0
var _acts_present: Dictionary = {}  # имя -> true (есть в сборке)
var _acts_touched: Dictionary = {}
var _act_stats: Dictionary = {}  # имя -> [есть в сборках, задето]
var _last_x := 0.0
var _still_frames := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		match kv[0]:
			"count": count = int(kv[1])
			"first": first = int(kv[1])
			"level": level_path = kv[1]
	print("Бот: %d сборок, сиды с %d" % [count, first])
	_start_run()


func _start_run() -> void:
	var packed: PackedScene = load(level_path)
	_level = packed.instantiate()
	_level.get_node("Assembler").seed_value = first + _index
	root.add_child(_level)
	_assembler = _level.get_node("Assembler")
	_player = _level.get_node("Player")
	_player.respawned.connect(func() -> void: _respawn_x.append(_player.global_position.x))
	_level.completed.connect(func() -> void: _done_flag = true)
	_frame = 0
	_done_flag = false
	_respawn_x = []
	_max_x = -100.0
	_last_progress_frame = 0
	Input.action_release(&"move_right")
	Input.action_release(&"jump")


func _physics_process(_delta: float) -> bool:
	if _waiting > 0:
		_waiting -= 1
		if _waiting == 0:
			_index += 1
			if _index >= count:
				_report()
				return true
			_start_run()
		return false
	_frame += 1
	var t := _frame / float(Engine.physics_ticks_per_second)
	if OS.get_cmdline_user_args().has("trace") and _frame % 10 == 0:
		print("t=%.1f x=%.2f y=%.2f floor=%s" % [t, _player.global_position.x, _player.global_position.y, _player.is_on_floor()])
	if _frame == 1:
		_berries_total = get_nodes_in_group(&"berries").size()
		var piles := _level.find_children("*", "Node3D", true, false).filter(func(n: Node) -> bool: return n.has_signal("built"))
		if OS.get_cmdline_user_args().has("trace"):
			print("кучек: ", piles.size(), " ", piles.map(func(n: Node) -> Vector3: return n.global_position))
		for pile in piles:
			pile.built.connect(func() -> void:
				if OS.get_cmdline_user_args().has("trace"):
					print("ЛЕСТНИЦА ГОТОВА t=%.1f, Август x=%.2f (кучка x=%.2f)" % [_frame / 120.0, _player.global_position.x, pile.global_position.x]))
		_acts_present = {}
		_acts_touched = {}
		for act in get_nodes_in_group(&"activities"):
			var act_name := _act_name(act)
			_acts_present[act_name] = true
			act.activated.connect(func() -> void: _acts_touched[act_name] = true)
		Input.action_press(&"move_right")
	_drive()
	if _player.global_position.x > _max_x + 0.05:
		_max_x = _player.global_position.x
		_last_progress_frame = _frame
	var stalled := (_frame - _last_progress_frame) / float(Engine.physics_ticks_per_second) > STALL_TIME
	if _done_flag or t > MAX_TIME or stalled:
		_finish_run(t, "ok" if _done_flag else ("застрял" if stalled else "таймаут"))
	return false


func _drive() -> void:
	var want_jump := false
	# Упёрлись и не двигаемся (низкая ступенька не всегда даёт is_on_wall) — тоже прыгаем.
	_still_frames = _still_frames + 1 if absf(_player.global_position.x - _last_x) < 0.004 else 0
	_last_x = _player.global_position.x
	if _player.is_on_floor():
		if _player.is_on_wall() or _still_frames > 6:
			want_jump = true
		else:
			want_jump = _edge_ahead()
	if want_jump and not Input.is_action_pressed(&"jump"):
		Input.action_press(&"jump")
	elif Input.is_action_pressed(&"jump"):
		Input.action_release(&"jump")


## Перед нами обрыв, а дальше есть опора не ниже, чем мы стоим, — прыгаем с края.
func _edge_ahead() -> bool:
	var here := _ground(_player.global_position.x)
	if is_nan(here):
		return false
	var drop := false
	for off in PROBE_OFFSETS:
		var g := _ground(_player.global_position.x + off)
		if is_nan(g) or g < here - 0.5:
			drop = true
	if not drop or _ground(_player.global_position.x + 0.25) < here - 0.5:
		# Прыгаем в последний момент: край уже под носом.
		pass
	if not drop:
		return false
	if _ground(_player.global_position.x + 0.3) >= here - 0.5:
		return false
	var x := 0.8
	while x <= 2.8:
		var g := _ground(_player.global_position.x + x)
		if not is_nan(g) and g >= here - 1.0 and g >= -0.3 and g <= here + 1.2:
			return true
		x += 0.2
	return false


func _ground(x: float) -> float:
	var space := _player.get_world_3d().direct_space_state
	# Луч сверху (над головой): иначе он начинался бы внутри невысокой башенки и проходил бы сквозь неё.
	var from := Vector3(x, _player.global_position.y + 1.5, 0.0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 12.0)
	q.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(q)
	return NAN if hit.is_empty() else (hit.position as Vector3).y


func _act_name(act: Node) -> String:
	return str(act.get_script().resource_path.get_file().get_basename())


func _section_at(x: float) -> String:
	var name := "?"
	for i in _assembler.sections.size():
		if _assembler.sections[i].position.x <= x:
			name = "%d:%s" % [i, _assembler.layout[i]]
	return name


func _finish_run(t: float, status: String) -> void:
	var r := {
		"seed": _assembler.used_seed,
		"status": status,
		"time": t,
		"respawns": _respawn_x.duplicate(),
		"max_x": _max_x,
		"stuck_in": _section_at(_max_x) if status != "ok" else "",
		"layout": _assembler.layout.duplicate(),
		"length": _assembler.total_length,
		"respawn_sections": _respawn_x.map(_section_at),
		"berries": "%d/%d" % [_berries_total - get_nodes_in_group(&"berries").size(), _berries_total],
	}
	if status != "ok":
		print("    поза: pos=%s vel=%s floor=%s wall=%s" % [_player.global_position, _player.velocity, _player.is_on_floor(), _player.is_on_wall()])
	if status != "ok":
		print("    locked=%s slides=%d" % [_player._controls_locked, _player.get_slide_collision_count()])
		for i in _player.get_slide_collision_count():
			var c := _player.get_slide_collision(i)
			print("    hit %s normal=%s pos=%s" % [c.get_collider(), c.get_normal(), c.get_position()])
	if status != "ok" and _level.has_node("Astra"):
		var astra: Node3D = _level.get_node("Astra")
		print("    Астра: pos=%s точка=%d/%d идёт=%s" % [astra.global_position, astra._index, astra._points.size() - 1, astra._moving])
	if status != "ok":
		for motion: Vector3 in [Vector3(0, 0.2, 0), Vector3(0.2, 0, 0), Vector3(0, -0.05, 0)]:
			var col := KinematicCollision3D.new()
			var blocked := _player.test_move(_player.global_transform, motion, col)
			print("    test_move %s blocked=%s %s" % [motion, blocked, (str(col.get_normal()) + " at " + str(col.get_position()) + " depth " + str(col.get_depth())) if blocked else ""])
	for act_name: String in _acts_present:
		var st: Array = _act_stats.get(act_name, [0, 0])
		st[0] += 1
		if _acts_touched.has(act_name):
			st[1] += 1
		_act_stats[act_name] = st
	_results.append(r)
	if status != "ok" or not _respawn_x.is_empty():
		print("  сид %d: %s t=%.1f max_x=%.1f/%.1f застрял=%s падения=%s" % [r.seed, status, t, _max_x, r.length, r.stuck_in, r.respawn_sections])
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	_level.queue_free()
	_waiting = 3


func _report() -> void:
	var ok := 0
	var with_falls := 0
	var times: Array[float] = []
	var fail_sections := {}
	var fall_sections := {}
	for r in _results:
		if r.status == "ok":
			ok += 1
			times.append(r.time)
		else:
			fail_sections[r.stuck_in] = fail_sections.get(r.stuck_in, 0) + 1
		if not r.respawns.is_empty():
			with_falls += 1
			for s in r.respawn_sections:
				fall_sections[s] = fall_sections.get(s, 0) + 1
	times.sort()
	print("=== ИТОГ: прошли %d из %d; с падениями %d ===" % [ok, _results.size(), with_falls])
	if not times.is_empty():
		print("время прохождения бота, с: мин %.1f, медиана %.1f, макс %.1f" % [times[0], times[times.size() / 2], times[-1]])
	if not fail_sections.is_empty():
		print("не прошли, где застряли: ", fail_sections)
	if not fall_sections.is_empty():
		print("падения по секциям: ", fall_sections)
	for act_name: String in _act_stats:
		print("занятие %s: в %d сборках, задето в %d" % [act_name, _act_stats[act_name][0], _act_stats[act_name][1]])
