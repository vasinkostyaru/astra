extends Cutscene
## transition — переход между комнатами (детская → ванная → кухня → гостиная).
## Астра оглядывается, убегает в дверь, камера едет за ней; дверь открывается,
## из проёма льётся свет следующей комнаты, затемнение.
##
## Комната задаётся параметром: Cutscenes.play(&"transition", {"room": &"bathroom"}) — это КУДА идём.
## Декорации показывают комнату, ИЗ которой уходят (SOURCE), так же, как она выглядит в игре
## (детская — обои со звёздами, ванная — коралловая плитка, кухня — тёмная фисташка и угольные шкафчики,
## гостиная — бело-голубые обои с птичками); за дверью — свет и цвет следующей комнаты (ROOMS).
## При самостоятельном запуске берётся default_room (меняется в инспекторе).

const DOOR_LEFT := 2.9
const DOOR_RIGHT := 4.0
const DOOR_X := 3.45
const DOOR_TOP := 2.25
const WALL_Z := -2.75
const WALL_TOP := 4.6
const FLOOR_Y := 0.012

const AVGUST_HOME := Vector3(-0.7, FLOOR_Y, 0.7)
const ASTRA_HOME := Vector3(0.8, FLOOR_Y, 0.7)

## Что за дверью (следующая комната): цвет стены в проёме и тёплый свет.
const ROOMS: Dictionary = {
	"kids": {"beyond": Color(0.78, 0.88, 0.98), "glow": Color(1.0, 0.86, 0.6)},
	"bathroom": {"beyond": Color(0.95, 0.5, 0.45), "glow": Color(1.0, 0.9, 0.85)},
	"kitchen": {"beyond": Color(0.4, 0.5, 0.3), "glow": Color(1.0, 0.9, 0.62)},
	"living": {"beyond": Color(0.88, 0.93, 0.98), "glow": Color(1.0, 0.78, 0.45)},
}

## Из какой комнаты уходим, если идём в room.
const SOURCE: Dictionary = {
	"bathroom": "kids",
	"kitchen": "bathroom",
	"living": "kitchen",
	"kids": "living",
}

## Вид покидаемой комнаты: пол, стена и дверь (как в игре).
const LOOK: Dictionary = {
	"kids": {"floor": Color(0.55, 0.38, 0.24), "wall": Color(0.76, 0.87, 0.97), "door": Color(0.95, 0.93, 0.88)},
	"bathroom": {"floor": Color(0.82, 0.3, 0.28), "wall": Color(0.95, 0.47, 0.42), "door": Color(0.97, 0.97, 0.98)},
	"kitchen": {"floor": Color(0.86, 0.8, 0.7), "wall": Color(0.36, 0.43, 0.27), "door": Color(0.72, 0.67, 0.6)},
	"living": {"floor": Color(0.74, 0.64, 0.52), "wall": Color(0.88, 0.93, 0.98), "door": Color(0.97, 0.95, 0.9)},
}

@export_group("Комната")
## Куда ведёт переход, если ролик запущен без параметра room.
@export var default_room: StringName = &"bathroom"

@export_group("Тайминги")
## Астра оглядывается на игрока (разворот 150° + пауза).
@export var t_look: float = 0.45
## Астра бежит к двери.
@export var t_run: float = 1.75
## Август идёт за ней.
@export var t_avgust: float = 2.1
## Дверь открывается.
@export var t_door: float = 2.7
## Астра шагает в проём (растворяется в свете).
@export var t_enter: float = 3.3
## Затемнение в следующую комнату.
@export var t_fade: float = 3.8

@export_group("Длительности")
@export var d_fade_in: float = 0.4
@export var d_fade_out: float = 0.9
@export var d_door_open: float = 0.55
@export var d_enter: float = 0.55

@export_group("Движение")
@export var astra_speed: float = 1.5
@export var astra_anim: float = 1.2
@export var astra_enter_anim: float = 0.6
@export var avgust_speed: float = 1.2
@export var avgust_anim: float = 1.0
@export var avgust_run_x: float = 3.1

@export_group("Камера")
@export var shot_open_target := Vector3(1.0, 1.1, 0.0)
@export var shot_open_dist: float = 6.2
@export var shot_run_target := Vector3(2.2, 1.2, 0.0)
@export var shot_run_dist: float = 5.6
@export var shot_door_target := Vector3(3.0, 1.2, 0.0)
@export var shot_door_dist: float = 4.8

var _room: StringName = &"bathroom"
var _source: StringName = &"kids"
var _set_root: Node3D
var _heroes: Node3D
var _props: Node3D
var _audio: CutAudio
var _avgust: Player
var _astra: Astra
var _door_pivot: Node3D
var _door_light: OmniLight3D
var _doorway: MeshInstance3D


func _prepare() -> void:
	_set_root = $Set as Node3D
	_heroes = $Heroes as Node3D
	_props = $Props as Node3D
	_audio = $CutAudio as CutAudio
	var requested := StringName(params.get("room", _cmdline_room()))
	if requested == &"":
		requested = default_room
	_room = requested
	if not ROOMS.has(String(_room)):
		push_warning("transition: неизвестная комната %s — беру bathroom" % _room)
		_room = &"bathroom"
	_source = StringName(SOURCE[String(_room)])
	_build_room(ROOMS[String(_room)], LOOK[String(_source)])

	_avgust = CutActors.spawn_avgust(_heroes)
	CutActors.matte(_avgust)
	_avgust.position = AVGUST_HOME
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	CutActors.play(_avgust, &"idle")

	_astra = CutActors.spawn_astra(_heroes)
	CutActors.matte(_astra)
	_astra.position = ASTRA_HOME
	CutActors.face_astra(_astra, CutActors.RIGHT)
	CutActors.play(_astra, &"idle")

	fade_to(1.0, 0.0)
	cam_to(shot_open_target, shot_open_dist, 0.0)
	print("[cutscene] transition room=", _room)


## Комната из командной строки: godot --path . cutscenes/transition_room.tscn -- room=kitchen
func _cmdline_room() -> StringName:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("room="):
			return StringName(arg.substr(5))
	return &""


func _build() -> void:
	at(0.0, _open)
	at(t_look, _look_back)
	at(t_run, _astra_runs)
	at(t_avgust, _avgust_follows)
	at(t_door, _door_opens)
	at(t_enter, _astra_enters)
	at(t_fade, _fade_out)


# --- биты ------------------------------------------------------------------

func _open() -> void:
	fade_to(0.0, d_fade_in)


func _look_back() -> void:
	# «Оглянуться»: разворот модели на ~150° за 0,3 с, пауза 0,5 с, возврат.
	astra_look_back(_astra, CutActors.RIGHT, 150.0, 0.3, 0.5)


func _astra_runs() -> void:
	var seconds := (DOOR_X - _astra.position.x) / astra_speed
	CutActors.face_astra(_astra, CutActors.RIGHT)
	walk_x(_astra, DOOR_X, seconds, &"run", astra_anim)
	cam_to(shot_run_target, shot_run_dist, seconds + 0.3)


func _avgust_follows() -> void:
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	walk_x(_avgust, AVGUST_HOME.x + avgust_run_x, avgust_run_x / avgust_speed, &"walk", avgust_anim)


func _door_opens() -> void:
	_audio.door_creak()
	var tw := new_tween()
	tw.tween_property(_door_pivot, "rotation:y", deg_to_rad(-100.0), d_door_open) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	new_tween().tween_property(_door_light, "light_energy", 1.1, d_door_open + 0.2)


func _astra_enters() -> void:
	# Шаг в проём: отворачивается от камеры, уходит вглубь и растворяется в свете двери.
	(_astra.get_node("Model") as Node3D).rotation.y = PI
	CutActors.play(_astra, &"run", astra_enter_anim)
	var tw := new_tween()
	tw.set_parallel(true)
	tw.tween_property(_astra, "position:x", DOOR_X, 0.3)
	tw.tween_property(_astra, "position:z", -2.35, d_enter).set_trans(Tween.TRANS_SINE)
	_audio.chime(6)
	cam_to(shot_door_target, shot_door_dist, 1.0)


func _fade_out() -> void:
	_audio.shimmer()
	fade_to(1.0, d_fade_out)


# --- финальное состояние (после пропуска) -----------------------------------

func _apply_final_state() -> void:
	_door_pivot.rotation.y = deg_to_rad(-100.0)
	_door_light.light_energy = 1.1
	(_astra.get_node("Model") as Node3D).rotation.y = PI
	_astra.position = Vector3(DOOR_X, FLOOR_Y, -2.35)
	CutActors.play(_astra, &"run", astra_enter_anim)
	_avgust.position = Vector3(AVGUST_HOME.x + avgust_run_x, FLOOR_Y, AVGUST_HOME.z)
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	CutActors.play(_avgust, &"walk", avgust_anim)
	cam_to(shot_door_target, shot_door_dist, 0.0)


# --- декорации --------------------------------------------------------------

func _build_room(beyond: Dictionary, look: Dictionary) -> void:
	var floor_col: Color = look["floor"]
	var wall_col: Color = look["wall"]
	var accent_col: Color = look["door"]
	var glow_col: Color = beyond["glow"]

	var floor_mat := CutSet.material(floor_col, 0.85)
	var wall_mat := CutSet.material(wall_col, 0.95)
	var accent_mat := CutSet.material(accent_col, 0.7)

	# Пол и стена с проёмом двери.
	CutSet.add_box(_set_root, "Floor", Vector3(16.0, 0.3, 4.6),
		Vector3(1.0, -0.15, -0.25), floor_mat)
	CutSet.add_box(_set_root, "WallLeft", Vector3(DOOR_LEFT + 7.0, WALL_TOP, 0.3),
		Vector3((-7.0 + DOOR_LEFT) * 0.5, WALL_TOP * 0.5, WALL_Z), wall_mat)
	CutSet.add_box(_set_root, "WallRight", Vector3(9.0 - DOOR_RIGHT, WALL_TOP, 0.3),
		Vector3((DOOR_RIGHT + 9.0) * 0.5, WALL_TOP * 0.5, WALL_Z), wall_mat)
	CutSet.add_box(_set_root, "WallTop", Vector3(DOOR_RIGHT - DOOR_LEFT, WALL_TOP - DOOR_TOP, 0.3),
		Vector3((DOOR_LEFT + DOOR_RIGHT) * 0.5, (DOOR_TOP + WALL_TOP) * 0.5, WALL_Z), wall_mat)
	CutSet.add_box(_set_root, "SkirtingL", Vector3(DOOR_LEFT + 7.0, 0.18, 0.08),
		Vector3((-7.0 + DOOR_LEFT) * 0.5, 0.09, -2.56), CutSet.material(wall_col.darkened(0.12), 0.9))

	# Свет из следующей комнаты в проёме.
	_doorway = CutSet.add_box(_set_root, "Doorway", Vector3(DOOR_RIGHT - DOOR_LEFT - 0.02, DOOR_TOP, 0.02),
		Vector3(DOOR_X, DOOR_TOP * 0.5, -2.66), CutSet.sky((beyond["beyond"] as Color).lerp(glow_col, 0.5), 0.8))

	# Дверная коробка и створка на петле слева.
	var frame := CutSet.material(Color(0.95, 0.93, 0.88), 0.8)
	CutSet.add_box(_set_root, "DoorFrameL", Vector3(0.08, DOOR_TOP + 0.08, 0.12),
		Vector3(DOOR_LEFT - 0.04, (DOOR_TOP + 0.08) * 0.5, -2.58), frame)
	CutSet.add_box(_set_root, "DoorFrameR", Vector3(0.08, DOOR_TOP + 0.08, 0.12),
		Vector3(DOOR_RIGHT + 0.04, (DOOR_TOP + 0.08) * 0.5, -2.58), frame)
	CutSet.add_box(_set_root, "DoorFrameTop", Vector3(DOOR_RIGHT - DOOR_LEFT + 0.16, 0.1, 0.12),
		Vector3(DOOR_X, DOOR_TOP + 0.05, -2.58), frame)

	_door_pivot = Node3D.new()
	_door_pivot.name = "DoorPivot"
	_door_pivot.position = Vector3(DOOR_LEFT + 0.03, 0.0, -2.56)
	_set_root.add_child(_door_pivot)
	var door_width := DOOR_RIGHT - DOOR_LEFT - 0.08
	CutSet.add_box(_door_pivot, "Door", Vector3(door_width, DOOR_TOP - 0.02, 0.06),
		Vector3(door_width * 0.5, (DOOR_TOP - 0.02) * 0.5, 0.0), accent_mat)
	CutSet.add_sphere(_door_pivot, "DoorKnob", 0.045,
		Vector3(door_width - 0.12, 1.05, 0.06), CutSet.glow(glow_col, 0.6), 12)

	_door_light = OmniLight3D.new()
	_door_light.name = "DoorLight"
	_door_light.position = Vector3(DOOR_X, 1.4, -2.1)
	_door_light.light_color = glow_col
	_door_light.light_energy = 0.0
	_door_light.omni_range = 3.4
	_set_root.add_child(_door_light)

	_build_source_props(String(_source), glow_col)


## Обстановка покидаемой комнаты — как в игре, на примитивах.
func _build_source_props(src: String, glow_col: Color) -> void:
	match src:
		"kids": _props_kids()
		"bathroom": _props_bathroom()
		"kitchen": _props_kitchen()
		"living": _props_living(glow_col)


func _front(parent_name: String, size: Vector3, pos: Vector3, color: Color, rough := 0.85) -> MeshInstance3D:
	return CutSet.add_box(_set_root, parent_name, size, pos, CutSet.material(color, rough))


func _skirting(color: Color) -> void:
	_front("Skirting", Vector3(DOOR_LEFT + 7.0, 0.2, 0.06), Vector3((-7.0 + DOOR_LEFT) * 0.5, 0.1, -2.57), color)
	_front("SkirtingR", Vector3(9.0 - DOOR_RIGHT, 0.2, 0.06), Vector3((DOOR_RIGHT + 9.0) * 0.5, 0.1, -2.57), color)


func _props_kids() -> void:
	# Обои в голубую полоску со звёздочками, плинтус, ковёр, кирпичики, мишка и кровать с ночником.
	for i in 8:
		_front("Stripe%d" % i, Vector3(0.55, WALL_TOP, 0.01), Vector3(-6.4 + i * 1.1, WALL_TOP * 0.5, -2.585),
			Color(0.62, 0.78, 0.95) if i % 2 == 0 else Color(0.76, 0.87, 0.97))
	for i in 7:
		var star := _front("Star%d" % i, Vector3(0.12, 0.12, 0.01), Vector3(-6.0 + i * 1.0, 3.2 + (i % 3) * 0.5, -2.575), Color(1.0, 0.86, 0.4))
		star.rotation.z = PI * 0.25
	_skirting(Color(0.97, 0.95, 0.9))
	_front("Rug", Vector3(3.0, 0.008, 1.9), Vector3(-1.4, 0.004, 0.3), Color(0.22, 0.55, 0.58), 0.95)
	var brick_colors: Array[Color] = [Color(0.88, 0.22, 0.2), Color(0.2, 0.5, 0.95), Color(1.0, 0.78, 0.15), Color(0.25, 0.75, 0.35)]
	for i in 6:
		_front("Brick%d" % i, Vector3(0.34, 0.17, 0.17), Vector3(-2.2 + (i % 3) * 0.36, 0.09 + (i / 3) * 0.17, 0.0),
			brick_colors[i % brick_colors.size()], 0.55)
	# Мишка.
	var fur := CutSet.material(Color(0.78, 0.55, 0.32), 0.95)
	CutSet.add_sphere(_set_root, "BearBody", 0.34, Vector3(-4.2, 0.38, -1.8), fur)
	CutSet.add_sphere(_set_root, "BearHead", 0.24, Vector3(-4.2, 0.86, -1.8), fur)
	CutSet.add_sphere(_set_root, "BearEarL", 0.09, Vector3(-4.38, 1.08, -1.8), fur, 10)
	CutSet.add_sphere(_set_root, "BearEarR", 0.09, Vector3(-4.02, 1.08, -1.8), fur, 10)
	# Кровать с одеялом и ночник.
	_front("BedFrame", Vector3(1.8, 0.55, 1.0), Vector3(-5.6, 0.28, -1.9), Color(0.62, 0.4, 0.23), 0.7)
	_front("Blanket", Vector3(1.4, 0.12, 1.02), Vector3(-5.4, 0.6, -1.9), Color(0.95, 0.5, 0.4), 0.95)
	_front("Pillow", Vector3(0.5, 0.14, 0.4), Vector3(-6.2, 0.64, -1.9), Color(0.97, 0.95, 0.9), 0.95)


func _props_bathroom() -> void:
	# Коралловая плитка с белыми швами, пол из плитки, поддон душевой с водой и игрушками, раковина с зеркалом.
	var grout := CutSet.material(Color(0.97, 0.94, 0.92), 0.7)
	for i in 14:
		CutSet.add_box(_set_root, "GroutV%d" % i, Vector3(0.025, WALL_TOP, 0.01), Vector3(-6.5 + i * 1.0, WALL_TOP * 0.5, -2.585), grout)
	for j in 5:
		CutSet.add_box(_set_root, "GroutH%d" % j, Vector3(16.0, 0.025, 0.01), Vector3(0.0, 0.8 + j * 0.9, -2.585), grout)
	for i in 8:
		CutSet.add_box(_set_root, "FloorGroutV%d" % i, Vector3(0.025, 0.004, 4.6), Vector3(-6.0 + i * 1.7, 0.003, -0.25), grout)
	_skirting(Color(0.97, 0.94, 0.9))
	# Поддон: белые бортики и вода.
	var white := Color(0.97, 0.97, 0.98)
	_front("TrayBack", Vector3(3.2, 0.5, 0.12), Vector3(-3.0, 0.25, -1.8), white, 0.45)
	_front("TrayFront", Vector3(3.2, 0.5, 0.12), Vector3(-3.0, 0.25, -0.6), white, 0.45)
	_front("TrayL", Vector3(0.12, 0.5, 1.3), Vector3(-4.6, 0.25, -1.2), white, 0.45)
	_front("TrayR", Vector3(0.12, 0.5, 1.3), Vector3(-1.4, 0.25, -1.2), white, 0.45)
	var water := CutSet.glow(Color(0.45, 0.75, 0.95), 0.4)
	CutSet.add_box(_set_root, "Water", Vector3(3.0, 0.02, 1.1), Vector3(-3.0, 0.42, -1.2), water)
	# Игрушки: уточка, лебедь, чёрная пробка на цепочке.
	var yellow := CutSet.material(Color(1.0, 0.85, 0.15), 0.5)
	CutSet.add_sphere(_set_root, "Duck", 0.2, Vector3(-3.6, 0.55, -1.2), yellow)
	CutSet.add_sphere(_set_root, "DuckHead", 0.12, Vector3(-3.45, 0.78, -1.2), yellow, 12)
	var swan := CutSet.material(Color(0.97, 0.97, 0.98), 0.5)
	CutSet.add_sphere(_set_root, "Swan", 0.26, Vector3(-2.4, 0.56, -1.2), swan)
	CutSet.add_sphere(_set_root, "SwanNeck", 0.1, Vector3(-2.2, 0.85, -1.2), swan, 12)
	CutSet.add_cylinder(_set_root, "Plug", 0.1, 0.12, 0.05, Vector3(-3.0, 0.42, -1.4), CutSet.material(Color(0.07, 0.07, 0.08), 0.5))
	# Раковина с зеркалом в рамке.
	_front("SinkCabinet", Vector3(1.0, 0.85, 0.5), Vector3(0.3, 0.43, -2.2), white, 0.45)
	_front("MirrorFrame", Vector3(1.0, 0.9, 0.04), Vector3(0.3, 1.9, -2.57), Color(0.97, 0.97, 0.98), 0.5)
	CutSet.add_box(_set_root, "Mirror", Vector3(0.86, 0.76, 0.02), Vector3(0.3, 1.9, -2.55), CutSet.glow(Color(0.8, 0.92, 1.0), 0.35))
	# Полотенца на рейке.
	_front("TowelRail", Vector3(0.9, 0.04, 0.05), Vector3(-5.6, 2.3, -2.5), white)
	_front("Towel1", Vector3(0.34, 0.7, 0.03), Vector3(-5.85, 1.92, -2.5), Color(0.95, 0.55, 0.25), 0.95)
	_front("Towel2", Vector3(0.34, 0.7, 0.03), Vector3(-5.4, 1.92, -2.5), Color(0.55, 0.8, 0.9), 0.95)


func _props_kitchen() -> void:
	# Тёмная фисташка, угольные шкафчики со светлой серо-деревянной столешницей, серый холодильник, лампа над столом.
	var charcoal := Color(0.04, 0.04, 0.045)
	var wood := Color(0.72, 0.67, 0.6)
	_front("Backsplash", Vector3(5.4, 1.0, 0.01), Vector3(-3.3, 1.45, -2.58), wood, 0.7)
	_front("Cabinets", Vector3(5.4, 0.9, 0.7), Vector3(-3.3, 0.45, -2.2), charcoal, 0.6)
	_front("Countertop", Vector3(5.5, 0.08, 0.76), Vector3(-3.3, 0.94, -2.2), wood, 0.6)
	for i in 4:
		CutSet.add_box(_set_root, "Handle%d" % i, Vector3(0.28, 0.03, 0.02), Vector3(-5.4 + i * 1.4, 0.7, -1.83), CutSet.material(Color(0.78, 0.8, 0.84), 0.3, 0.6))
	_front("Upper", Vector3(5.4, 1.0, 0.45), Vector3(-3.3, 3.3, -2.35), charcoal, 0.6)
	_front("Fridge", Vector3(1.0, 2.5, 0.8), Vector3(-6.4, 1.25, -2.15), Color(0.5, 0.52, 0.55), 0.55)
	_skirting(charcoal)
	# Стол со стулом и лампой над ним.
	_front("TableTop", Vector3(1.5, 0.08, 1.0), Vector3(-0.2, 0.74, -0.5), wood, 0.7)
	_front("TableLeg", Vector3(0.12, 0.7, 0.12), Vector3(-0.2, 0.37, -0.5), Color(0.62, 0.57, 0.5), 0.8)
	_front("ChairSeat", Vector3(0.5, 0.08, 0.5), Vector3(-1.2, 0.44, -0.6), wood, 0.7)
	_front("ChairBack", Vector3(0.5, 0.5, 0.08), Vector3(-1.2, 0.7, -0.88), wood, 0.7)
	CutSet.add_cylinder(_set_root, "LampCord", 0.01, 0.01, 1.4, Vector3(-0.2, 3.3, -0.5), CutSet.material(Color(0.1, 0.1, 0.1), 0.7))
	CutSet.add_cylinder(_set_root, "LampShade", 0.05, 0.3, 0.3, Vector3(-0.2, 2.45, -0.5), CutSet.material(charcoal, 0.5))
	CutSet.add_sphere(_set_root, "LampBulb", 0.09, Vector3(-0.2, 2.28, -0.5), CutSet.glow(Color(1.0, 0.9, 0.65), 0.6), 10)


func _props_living(glow_col: Color) -> void:
	# Бело-голубые обои с птичками, серо-бежевый диван с разноцветными подушками, рыжее винтажное кресло,
	# фисташковая штора, телевизор, торшер.
	for i in 8:
		_front("Stripe%d" % i, Vector3(0.9, WALL_TOP, 0.01), Vector3(-6.3 + i * 1.8, WALL_TOP * 0.5, -2.585), Color(0.8, 0.88, 0.96))
	var bird := CutSet.material(Color(0.5, 0.76, 0.97), 0.8)
	for i in 8:
		var x := -6.0 + i * 1.5
		var y := 3.0 + (i % 3) * 0.55
		var w1 := CutSet.add_box(_set_root, "BirdL%d" % i, Vector3(0.2, 0.04, 0.01), Vector3(x - 0.09, y + 0.04, -2.575), bird)
		w1.rotation.z = 0.5
		var w2 := CutSet.add_box(_set_root, "BirdR%d" % i, Vector3(0.2, 0.04, 0.01), Vector3(x + 0.09, y + 0.04, -2.575), bird)
		w2.rotation.z = -0.5
	_skirting(Color(0.97, 0.95, 0.9))
	var sofa := Color(0.78, 0.74, 0.68)
	_front("SofaBase", Vector3(2.8, 0.5, 0.95), Vector3(-3.3, 0.25, -1.9), sofa, 0.9)
	_front("SofaBack", Vector3(2.8, 0.75, 0.3), Vector3(-3.3, 0.85, -2.25), sofa.darkened(0.06), 0.9)
	var cushion_colors: Array[Color] = [Color(0.9, 0.3, 0.3), Color(0.25, 0.55, 0.85), Color(0.95, 0.78, 0.2), Color(0.35, 0.72, 0.45), Color(0.85, 0.45, 0.7)]
	for i in 5:
		var c := _front("Cushion%d" % i, Vector3(0.45, 0.45, 0.14), Vector3(-4.4 + i * 0.5, 0.82, -1.92), cushion_colors[i], 0.9)
		c.rotation = Vector3(-0.2, 0.0, (i - 2) * 0.12)
	# Винтажное кресло: тёмное дерево, ножки, подлокотники, две оранжевые подушки.
	var orange := Color(1.0, 0.4, 0.04)
	var dark := CutSet.material(Color(0.28, 0.16, 0.09), 0.7)
	for lx in [-0.75, 0.25]:
		for lz in [-1.4, -2.0]:
			CutSet.add_box(_set_root, "ChairLeg", Vector3(0.09, 0.4, 0.09), Vector3(lx, 0.2, lz), dark)
	CutSet.add_box(_set_root, "ChairFrame", Vector3(1.3, 0.1, 0.8), Vector3(-0.25, 0.45, -1.7), dark)
	_front("ChairSeat", Vector3(1.15, 0.2, 0.75), Vector3(-0.25, 0.6, -1.7), orange, 0.9)
	CutSet.add_box(_set_root, "ChairBackFrame", Vector3(1.3, 0.95, 0.1), Vector3(-0.25, 1.1, -2.1), dark)
	_front("ChairBackCushion", Vector3(1.0, 0.6, 0.2), Vector3(-0.25, 1.0, -1.97), orange, 0.9)
	# Штора, телевизор, торшер.
	_front("Curtain", Vector3(1.7, 3.6, 0.1), Vector3(-6.5, 2.0, -2.5), Color(0.42, 0.57, 0.38), 0.95)
	_front("TV", Vector3(1.6, 0.95, 0.06), Vector3(5.3, 1.45, -2.5), Color(0.04, 0.04, 0.05), 0.4)
	_front("TVStand", Vector3(1.9, 0.6, 0.5), Vector3(5.3, 0.3, -2.3), Color(0.66, 0.6, 0.52), 0.8)
	CutSet.add_cylinder(_set_root, "FloorLampPole", 0.025, 0.025, 1.6, Vector3(1.6, 0.8, -2.1), CutSet.material(Color(0.3, 0.3, 0.32), 0.7))
	CutSet.add_cylinder(_set_root, "FloorLampShade", 0.16, 0.28, 0.4, Vector3(1.6, 1.75, -2.1), CutSet.glow(glow_col, 0.7))
