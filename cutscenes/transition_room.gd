extends Cutscene
## transition — переход между комнатами (детская → ванная → кухня → гостиная).
## Астра оглядывается, убегает в дверь, камера едет за ней; дверь открывается,
## из проёма льётся свет следующей комнаты, затемнение.
##
## Комната задаётся параметром: Cutscenes.play(&"transition", {"room": &"bathroom"}).
## При самостоятельном запуске берётся default_room (меняется в инспекторе).
## Палитра — здесь, в ROOMS; тайминги и позиции — экспорт ниже и константы.

const DOOR_LEFT := 2.9
const DOOR_RIGHT := 4.0
const DOOR_X := 3.45
const DOOR_TOP := 2.25
const WALL_Z := -2.75
const WALL_TOP := 4.6
const FLOOR_Y := 0.012

const AVGUST_HOME := Vector3(-0.7, FLOOR_Y, 0.7)
const ASTRA_HOME := Vector3(0.8, FLOOR_Y, 0.7)

## Палитра комнат: пол, стена, акцент (дверь/мебель), свет из проёма.
const ROOMS: Dictionary = {
	"kids": {
		"floor": Color(0.62, 0.42, 0.26), "wall": Color(0.93, 0.85, 0.72),
		"accent": Color(0.83, 0.3, 0.28), "glow": Color(1.0, 0.86, 0.6),
	},
	"bathroom": {
		"floor": Color(0.36, 0.42, 0.46), "wall": Color(0.86, 0.55, 0.52),
		"accent": Color(0.96, 0.96, 0.95), "glow": Color(0.82, 0.94, 1.0),
	},
	"kitchen": {
		"floor": Color(0.55, 0.42, 0.32), "wall": Color(0.9, 0.86, 0.78),
		"accent": Color(0.72, 0.5, 0.3), "glow": Color(1.0, 0.9, 0.62),
	},
	"living": {
		"floor": Color(0.5, 0.35, 0.24), "wall": Color(0.78, 0.72, 0.62),
		"accent": Color(0.35, 0.5, 0.45), "glow": Color(1.0, 0.78, 0.45),
	},
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
	_room = StringName(params.get("room", default_room))
	if not ROOMS.has(String(_room)):
		push_warning("transition: неизвестная комната %s — беру bathroom" % _room)
		_room = &"bathroom"
	var palette: Dictionary = ROOMS[String(_room)]
	_build_room(palette)

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

func _build_room(palette: Dictionary) -> void:
	var floor_col: Color = palette["floor"]
	var wall_col: Color = palette["wall"]
	var accent_col: Color = palette["accent"]
	var glow_col: Color = palette["glow"]

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
		Vector3(DOOR_X, DOOR_TOP * 0.5, -2.66), CutSet.sky(glow_col, 0.7))

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

	_build_room_props(palette, glow_col)


func _build_room_props(palette: Dictionary, glow_col: Color) -> void:
	match String(_room):
		"kids":
			CutSet.add_box(_set_root, "Rug", Vector3(2.6, 0.006, 1.7),
				Vector3(-1.3, -0.002, 0.3), CutSet.material(Color(0.42, 0.58, 0.66), 0.95))
			for i in 3:
				CutSet.add_box(_set_root, "Brick%d" % i, Vector3(0.32, 0.16, 0.16),
					Vector3(-1.7 + i * 0.36, 0.08, 0.15), CutSet.material(
						[Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.95, 0.75, 0.2)][i], 0.55))
			CutSet.add_box(_set_root, "ToyChest", Vector3(0.9, 0.46, 0.5),
				Vector3(-3.4, 0.23, -1.9), CutSet.material(Color(0.75, 0.5, 0.28), 0.9))
		"bathroom":
			# Коралловая плитка и белая сантехника (решение пользователя).
			CutSet.add_box(_set_root, "TileBand", Vector3(3.4, 1.5, 0.03),
				Vector3(-2.3, 1.35, -2.58), CutSet.material(palette["wall"].lightened(0.18), 0.5))
			var grout := CutSet.material(Color(0.96, 0.93, 0.9), 0.7)
			for i in 4:
				CutSet.add_box(_set_root, "TileV%d" % i, Vector3(0.02, 1.5, 0.01),
					Vector3(-3.15 + i * 0.56, 1.35, -2.56), grout)
			for j in 2:
				CutSet.add_box(_set_root, "TileH%d" % j, Vector3(3.4, 0.02, 0.01),
					Vector3(-2.3, 0.85 + j * 0.5, -2.56), grout)
			CutSet.add_box(_set_root, "ShowerTray", Vector3(2.0, 0.5, 0.95),
				Vector3(-2.5, 0.25, -1.55), CutSet.material(Color(0.88, 0.88, 0.87), 0.45))
			CutSet.add_box(_set_root, "ShowerRim", Vector3(2.1, 0.08, 1.05),
				Vector3(-2.5, 0.54, -1.55), CutSet.material(Color(0.9, 0.9, 0.89), 0.4))
			CutSet.add_box(_set_root, "Sink", Vector3(0.5, 0.85, 0.4),
				Vector3(-4.4, 0.43, -2.1), CutSet.material(Color(0.89, 0.89, 0.88), 0.4))
			CutSet.add_box(_set_root, "Mirror", Vector3(0.6, 0.7, 0.03),
				Vector3(-4.4, 1.7, -2.58), CutSet.glow(Color(0.9, 0.96, 1.0), 0.35))
		"kitchen":
			CutSet.add_box(_set_root, "Cabinets", Vector3(3.0, 0.9, 0.6),
				Vector3(-2.6, 0.45, -1.85), CutSet.material(palette["accent"], 0.75))
			CutSet.add_box(_set_root, "Countertop", Vector3(3.1, 0.08, 0.66),
				Vector3(-2.6, 0.94, -1.85), CutSet.material(Color(0.93, 0.9, 0.84), 0.5))
			CutSet.add_box(_set_root, "TableTop", Vector3(0.95, 0.07, 0.9),
				Vector3(-1.2, 0.72, -0.5), CutSet.material(Color(0.85, 0.68, 0.45), 0.8))
			CutSet.add_box(_set_root, "TableLeg", Vector3(0.12, 0.7, 0.12),
				Vector3(-1.2, 0.35, -0.5), CutSet.material(Color(0.72, 0.55, 0.36), 0.85))
			CutSet.add_box(_set_root, "ChairSeat", Vector3(0.5, 0.08, 0.5),
				Vector3(-2.1, 0.44, -0.6), CutSet.material(palette["accent"], 0.75))
			CutSet.add_box(_set_root, "ChairBack", Vector3(0.08, 0.5, 0.5),
				Vector3(-2.33, 0.7, -0.6), CutSet.material(palette["accent"], 0.75))
		"living":
			CutSet.add_box(_set_root, "Rug", Vector3(3.0, 0.006, 2.0),
				Vector3(-1.6, -0.002, 0.3), CutSet.material(Color(0.55, 0.4, 0.45), 0.95))
			CutSet.add_box(_set_root, "SofaBase", Vector3(2.2, 0.45, 0.85),
				Vector3(-2.6, 0.23, -1.5), CutSet.material(palette["accent"], 0.9))
			CutSet.add_box(_set_root, "SofaBack", Vector3(2.2, 0.7, 0.25),
				Vector3(-2.6, 0.75, -1.85), CutSet.material(palette["accent"].darkened(0.12), 0.9))
			CutSet.add_box(_set_root, "Cushion1", Vector3(0.55, 0.4, 0.16),
				Vector3(-3.0, 0.72, -1.7), CutSet.material(Color(0.95, 0.8, 0.45), 0.9))
			CutSet.add_box(_set_root, "Cushion2", Vector3(0.55, 0.4, 0.16),
				Vector3(-2.3, 0.72, -1.7), CutSet.material(Color(0.95, 0.8, 0.45), 0.9))
			CutSet.add_box(_set_root, "FloorLampPole", Vector3(0.05, 1.5, 0.05),
				Vector3(0.4, 0.75, -2.0), CutSet.material(Color(0.5, 0.45, 0.4), 0.8))
			CutSet.add_box(_set_root, "FloorLampShade", Vector3(0.38, 0.3, 0.38),
				Vector3(0.4, 1.62, -2.0), CutSet.glow(glow_col, 0.8))
