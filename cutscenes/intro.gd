extends Cutscene
## Ролик intro (~15 с, один раз за запуск, перед первым уровнем).
##
## Солнечный день. Август строит башню из конструктора, Астра на подоконнике рядом
## с горшком волшебного кустика. Она тянется к ягодке — «пиф», блёстки, герои
## уменьшаются, мебель становится огромной, ягодки разлетаются по квартире.
## Астра бежит по ним, Август за ней.
##
## Все тайминги, позиции и длительности — здесь (экспорт ниже и константы декораций).
## Пропуск: касание в любом месте экрана; _apply_final_state() ставит мир в конечную позу.

const BERRY_SCENE := preload("res://cutscenes/props/berry_stub.tscn")
const BUSH_SCENE := preload("res://cutscenes/props/bush_stub.tscn")

## Цвета ягодок — как в игре (клубника, черника, малина, виноград, вишня).
const BERRY_COLORS: Array[Color] = [
	Color(0.92, 0.15, 0.2), Color(0.25, 0.35, 0.85), Color(0.88, 0.2, 0.45),
	Color(0.55, 0.28, 0.75), Color(0.7, 0.05, 0.12),
]

# --- декорации (обычный, «человеческий» масштаб: Август 1.05 м) ---------------
const FLOOR_POS := Vector3(-0.3, -0.15, -0.2)
const FLOOR_SIZE := Vector3(11.5, 0.3, 4.8)
const WALL_POS := Vector3(-0.3, 2.1, -2.75)
const WALL_SIZE := Vector3(11.5, 4.2, 0.3)
const WINDOW_X := 2.35
const WINDOW_Y := 1.85
const WINDOW_W := 2.0
const WINDOW_H := 1.5
const BENCH_TOP := 0.6
const BENCH_Z := -2.28
const POT_X := 2.85
const POT_TOP := 0.9

## Август, Астра и башня из кирпичиков.
const AVGUST_HOME := Vector3(-1.05, 0.012, 0.35)
const ASTRA_HOME := Vector3(2.0, BENCH_TOP, -2.15)
const ASTRA_STEP_X := 2.4
const ASTRA_LAND := Vector3(0.9, 0.012, 0.3)
const BRICK_SIZE := Vector3(0.32, 0.16, 0.16)
## Башня: два кирпичика уже стоят, два прилетают во время ролика.
const TOWER_A := Vector3(-0.45, 0.08, -0.4)
const TOWER_B := Vector3(-0.45, 0.24, -0.4)
const TOWER_C := Vector3(-0.45, 0.4, -0.4)
const PILE_A := Vector3(0.3, 0.08, -0.3)
const PILE_B := Vector3(0.65, 0.08, -0.15)

# --- тайминги, с ----------------------------------------------------------
@export_group("Тайминги")
## Август достраивает башню.
@export var t_bricks: float = 0.9
## Астра подходит к ягодке на кусте.
@export var t_astra_steps: float = 2.5
## «Пиф»: ягодка вспыхивает, блёстки.
@export var t_pif: float = 3.5
## Астра спрыгивает с подоконника к Августу.
@export var t_astra_down: float = 4.0
## Уменьшение героев и рост комнаты.
@export var t_shrink: float = 4.8
## Ягодки разлетаются по квартире.
@export var t_scatter: float = 6.4
## Камера подъезжает к героям.
@export var t_close: float = 6.9
## Астра оглядывается на Августа.
@export var t_look: float = 8.9
## Астра убегает, Август за ней.
@export var t_run: float = 9.4
## Затемнение.
@export var t_fade_out: float = 13.2

# --- длительности, с -------------------------------------------------------
@export_group("Длительности")
@export var d_fade_in: float = 0.9
@export var d_astra_step: float = 0.85
@export var d_astra_hop: float = 0.7
@export var d_shrink: float = 1.3
@export var d_cam_close: float = 1.1
@export var d_fade_out: float = 1.4

# --- уменьшение ------------------------------------------------------------
@export_group("Уменьшение")
## Во сколько раз вырастает комната (Set) — «мебель становится огромной».
@export var world_scale: float = 1.5
## Во сколько раз уменьшаются герои.
@export var hero_shrink: float = 3.0
@export var scatter_count: int = 14
## Сид разлёта ягодок: одинаковый — значит, каждый просмотр одинаковый.
@export var scatter_seed: int = 7

# --- камера ----------------------------------------------------------------
@export_group("Камера")
@export var shot_open_target := Vector3(0.6, 0.85, 0.0)
@export var shot_open_dist: float = 5.2
@export var shot_astra_target := Vector3(1.2, 0.9, 0.0)
@export var shot_astra_dist: float = 4.6
@export var shot_wide_target := Vector3(0.5, 1.1, 0.0)
@export var shot_wide_dist: float = 6.8
@export var shot_close_target := Vector3(-0.15, 0.3, 0.0)
@export var shot_close_dist: float = 3.0
@export var shot_run_target := Vector3(0.9, 0.3, 0.0)
@export var shot_run_dist: float = 3.8

# --- движение --------------------------------------------------------------
@export_group("Движение")
@export var astra_walk_anim: float = 0.5
@export var astra_tiny_anim: float = 0.6
@export var avgust_tiny_anim: float = 1.2
@export var astra_run_x: float = 2.2
@export var astra_run_speed: float = 0.75
@export var avgust_delay: float = 0.55
@export var avgust_run_x: float = 1.9
@export var avgust_walk_speed: float = 0.65

var _set_root: Node3D
var _heroes: Node3D
var _props: Node3D
var _audio: CutAudio
var _avgust: Player
var _astra: Astra
var _bush: CutBush
var _brick_1: MeshInstance3D
var _brick_2: MeshInstance3D


func _prepare() -> void:
	_set_root = $Set as Node3D
	_heroes = $Heroes as Node3D
	_props = $Props as Node3D
	_audio = $CutAudio as CutAudio
	_build_room()
	_build_bush()

	_avgust = CutActors.spawn_avgust(_heroes)
	CutActors.matte(_avgust)
	_avgust.position = AVGUST_HOME
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	CutActors.play(_avgust, &"idle")

	_astra = CutActors.spawn_astra(_heroes)
	CutActors.matte(_astra)
	_astra.position = ASTRA_HOME
	CutActors.face_astra(_astra, CutActors.LEFT)
	CutActors.play(_astra, &"idle")

	fade_to(1.0, 0.0)
	cam_to(shot_open_target, shot_open_dist, 0.0)


func _build() -> void:
	at(0.0, _open)
	at(t_bricks, _build_tower_1)
	at(t_bricks + 0.7, _build_tower_2)
	at(t_astra_steps, _astra_steps)
	at(t_pif, _pif)
	at(t_astra_down, _astra_down)
	at(t_shrink, _shrink)
	at(t_scatter, _scatter)
	at(t_close, _close_shot)
	at(t_look, _look)
	at(t_run, _run)
	at(t_fade_out, _fade_out)


# --- биты ------------------------------------------------------------------

func _open() -> void:
	fade_to(0.0, d_fade_in)
	_audio.melody()


func _build_tower_1() -> void:
	_fly_brick(_brick_1, TOWER_B, 0.5)


func _build_tower_2() -> void:
	_fly_brick(_brick_2, TOWER_C, 0.55)


func _astra_steps() -> void:
	# Кошка «идёт»: клип run со speed_scale 0.5 и медленное движение по подоконнику.
	CutActors.face_astra(_astra, CutActors.LEFT)
	walk_x(_astra, ASTRA_STEP_X, d_astra_step, &"run", astra_walk_anim)
	cam_to(shot_astra_target, shot_astra_dist, 1.2)


func _pif() -> void:
	var berry_pos := _bush.berry_world_position(0)
	if not _bush.berries.is_empty():
		_bush.berries[0].visible = false
	flash_at(berry_pos, Color(1.0, 0.45, 0.6), 1.0)
	sparkles_at(berry_pos, Color(1.0, 0.86, 0.6), 40)
	_audio.pif()
	_audio.sparkle()


func _astra_down() -> void:
	# Прыжок без отдельного клипа: run и дуга.
	arc_move(_astra, ASTRA_LAND, d_astra_hop, 0.35, &"run", astra_walk_anim)


func _shrink() -> void:
	_audio.shimmer()
	sparkles_at(_avgust.global_position + Vector3.UP * 0.5, Color(1.0, 0.95, 0.75), 46)
	sparkles_at(_astra.global_position + Vector3.UP * 0.3, Color(1.0, 0.95, 0.75), 36)
	# Медленно, с замедлением в конце: мир растёт, герои сжимаются, камера отъезжает.
	scale_to(_set_root, Vector3.ONE * world_scale, d_shrink)
	scale_to(_avgust, Vector3.ONE / hero_shrink, d_shrink)
	scale_to(_astra, Vector3.ONE / hero_shrink, d_shrink)
	cam_to(shot_wide_target, shot_wide_dist, d_shrink + 0.4)


func _scatter() -> void:
	_audio.sparkle()
	sparkles_at(_bush.global_position + Vector3.UP * 0.45, Color(1.0, 0.78, 0.86), 30)
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var from := _bush.berry_world_position(1)
	for i in scatter_count:
		var berry := BERRY_SCENE.instantiate() as CutBerry
		berry.radius = 0.045
		berry.color = BERRY_COLORS[i % BERRY_COLORS.size()]
		_props.add_child(berry)
		berry.global_position = from
		var land := Vector3(
			rng.randf_range(-1.5, 1.5),
			berry.radius,
			rng.randf_range(-0.5, 1.4))
		_berry_fall(berry, from, land, rng.randf_range(0.55, 1.0),
			rng.randf_range(0.5, 1.3), rng.randf_range(0.0, 0.5), i)


func _close_shot() -> void:
	cam_to(shot_close_target, shot_close_dist, d_cam_close)


func _look() -> void:
	# Астра смотрит на Августа, потом разворачивается вперёд.
	CutActors.face_astra(_astra, CutActors.LEFT)
	CutActors.play(_astra, &"idle")


func _run() -> void:
	var astra_sec := astra_run_x / astra_run_speed
	CutActors.face_astra(_astra, CutActors.RIGHT)
	walk_x(_astra, _astra.position.x + astra_run_x, astra_sec, &"run", astra_tiny_anim)

	var tw := new_tween()
	tw.tween_interval(avgust_delay)
	tw.tween_callback(func() -> void:
		CutActors.face_avgust(_avgust, CutActors.RIGHT)
		CutActors.play(_avgust, &"walk", avgust_tiny_anim))
	tw.tween_property(_avgust, "position:x", _avgust.position.x + avgust_run_x,
		avgust_run_x / avgust_walk_speed)
	cam_to(shot_run_target, shot_run_dist, 3.0)


func _fade_out() -> void:
	fade_to(1.0, d_fade_out)


# --- финальное состояние (после пропуска) -----------------------------------

func _apply_final_state() -> void:
	_set_root.scale = Vector3.ONE * world_scale
	_avgust.scale = Vector3.ONE / hero_shrink
	_astra.scale = Vector3.ONE / hero_shrink
	_avgust.position = AVGUST_HOME + Vector3(avgust_run_x, 0.0, 0.0)
	_astra.position = ASTRA_LAND + Vector3(astra_run_x, 0.0, 0.0)
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	CutActors.face_astra(_astra, CutActors.RIGHT)
	CutActors.play(_avgust, &"walk", avgust_tiny_anim)
	CutActors.play(_astra, &"run", astra_tiny_anim)
	if _bush and not _bush.berries.is_empty():
		_bush.berries[0].visible = false
	# Башня достроена, чтобы кадр не отличался от досмотренного.
	_brick_1.position = TOWER_B
	_brick_2.position = TOWER_C
	cam_to(shot_run_target, shot_run_dist, 0.0)


# --- служебное --------------------------------------------------------------

func _fly_brick(brick: MeshInstance3D, to: Vector3, sec: float) -> void:
	if brick == null:
		return
	var from := brick.position
	var tw := new_tween()
	tw.tween_method(func(t: float) -> void:
		brick.position = from.lerp(to, t) + Vector3.UP * (0.35 * 4.0 * t * (1.0 - t)),
		0.0, 1.0, sec)
	tw.tween_callback(_audio.tap)


func _berry_fall(berry: CutBerry, from: Vector3, to: Vector3, sec: float, arc: float,
		delay: float, index: int) -> void:
	var tw := new_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_method(func(t: float) -> void:
		berry.position = from.lerp(to, t) + Vector3.UP * (arc * 4.0 * t * (1.0 - t)),
		0.0, 1.0, sec)
	if index % 4 == 0:
		tw.tween_callback(_audio.chime.bind(index + 1))


# --- декорации --------------------------------------------------------------

func _build_room() -> void:
	var wood := CutSet.material(Color(0.62, 0.42, 0.26), 0.85)
	var cream := CutSet.material(Color(0.94, 0.87, 0.75), 0.95)
	var white := CutSet.material(Color(0.95, 0.94, 0.9), 0.7)
	var baseboard := CutSet.material(Color(0.87, 0.8, 0.68), 0.9)

	CutSet.add_box(_set_root, "Floor", FLOOR_SIZE, FLOOR_POS, wood)
	CutSet.add_box(_set_root, "Wall", WALL_SIZE, WALL_POS, cream)
	CutSet.add_box(_set_root, "Baseboard", Vector3(11.5, 0.18, 0.08),
		Vector3(-0.3, 0.09, -2.56), baseboard)
	CutSet.add_box(_set_root, "Rug", Vector3(2.8, 0.006, 1.9),
		Vector3(-0.5, -0.002, 0.25), CutSet.material(Color(0.42, 0.58, 0.66), 0.95))

	# Окно: светящееся стекло, белая рама и переплёт.
	var glass_z := -2.6
	CutSet.add_box(_set_root, "WindowGlass", Vector3(WINDOW_W, WINDOW_H, 0.04),
		Vector3(WINDOW_X, WINDOW_Y, glass_z), CutSet.sky(Color(0.72, 0.87, 1.0), 0.8))
	CutSet.add_box(_set_root, "WindowFrameTop", Vector3(WINDOW_W + 0.16, 0.1, 0.12),
		Vector3(WINDOW_X, WINDOW_Y + WINDOW_H * 0.5 + 0.05, -2.56), white)
	CutSet.add_box(_set_root, "WindowFrameBottom", Vector3(WINDOW_W + 0.16, 0.1, 0.12),
		Vector3(WINDOW_X, WINDOW_Y - WINDOW_H * 0.5 - 0.05, -2.56), white)
	CutSet.add_box(_set_root, "WindowFrameLeft", Vector3(0.1, WINDOW_H + 0.2, 0.12),
		Vector3(WINDOW_X - WINDOW_W * 0.5 - 0.05, WINDOW_Y, -2.56), white)
	CutSet.add_box(_set_root, "WindowFrameRight", Vector3(0.1, WINDOW_H + 0.2, 0.12),
		Vector3(WINDOW_X + WINDOW_W * 0.5 + 0.05, WINDOW_Y, -2.56), white)
	CutSet.add_box(_set_root, "MullionV", Vector3(0.05, WINDOW_H, 0.06),
		Vector3(WINDOW_X, WINDOW_Y, -2.58), white)
	CutSet.add_box(_set_root, "MullionH", Vector3(WINDOW_W, 0.05, 0.06),
		Vector3(WINDOW_X, WINDOW_Y - 0.05, -2.58), white)

	# Подоконник-скамейка.
	CutSet.add_box(_set_root, "BenchTop", Vector3(WINDOW_W + 0.4, 0.1, 0.62),
		Vector3(WINDOW_X, BENCH_TOP - 0.05, BENCH_Z), white)
	CutSet.add_box(_set_root, "BenchLegL", Vector3(0.14, BENCH_TOP - 0.1, 0.14),
		Vector3(WINDOW_X - WINDOW_W * 0.5 + 0.1, (BENCH_TOP - 0.1) * 0.5, BENCH_Z), baseboard)
	CutSet.add_box(_set_root, "BenchLegR", Vector3(0.14, BENCH_TOP - 0.1, 0.14),
		Vector3(WINDOW_X + WINDOW_W * 0.5 - 0.1, (BENCH_TOP - 0.1) * 0.5, BENCH_Z), baseboard)

	# Горшок (куст сажается отдельно, в _build_bush).
	CutSet.add_cylinder(_set_root, "Pot", 0.16, 0.12, 0.3,
		Vector3(POT_X, POT_TOP - 0.15, -2.25), CutSet.material(Color(0.72, 0.42, 0.3), 0.95))
	CutSet.add_cylinder(_set_root, "PotRim", 0.175, 0.175, 0.05,
		Vector3(POT_X, POT_TOP - 0.04, -2.25), CutSet.material(Color(0.78, 0.48, 0.35), 0.95))

	# Комод у левой стены, сундук с игрушками, картинка на стене.
	CutSet.add_box(_set_root, "Dresser", Vector3(1.4, 1.0, 0.55),
		Vector3(-4.3, 0.5, -2.1), CutSet.material(Color(0.5, 0.35, 0.28), 0.9))
	CutSet.add_box(_set_root, "DresserTop", Vector3(1.5, 0.06, 0.6),
		Vector3(-4.3, 1.03, -2.1), CutSet.material(Color(0.62, 0.44, 0.34), 0.85))
	for row in 2:
		CutSet.add_box(_set_root, "Drawer%d" % row, Vector3(1.18, 0.34, 0.03),
			Vector3(-4.3, 0.32 + row * 0.4, -1.81), CutSet.material(Color(0.57, 0.4, 0.31), 0.9))
		CutSet.add_sphere(_set_root, "Knob%d" % row, 0.035,
			Vector3(-4.3, 0.32 + row * 0.4, -1.78), CutSet.glow(Color(1.0, 0.9, 0.7), 0.3), 10)
	CutSet.add_box(_set_root, "ToyChest", Vector3(0.9, 0.46, 0.5),
		Vector3(-2.9, 0.23, -2.05), CutSet.material(Color(0.75, 0.5, 0.28), 0.9))
	CutSet.add_box(_set_root, "ToyChestLid", Vector3(0.96, 0.07, 0.54),
		Vector3(-2.9, 0.5, -2.05), CutSet.material(Color(0.82, 0.58, 0.34), 0.85))
	CutSet.add_box(_set_root, "Picture", Vector3(0.56, 0.44, 0.05),
		Vector3(-0.6, 2.45, -2.59), CutSet.material(Color(0.55, 0.4, 0.24), 0.8))
	CutSet.add_box(_set_root, "PictureArt", Vector3(0.46, 0.34, 0.02),
		Vector3(-0.6, 2.45, -2.56), CutSet.material(Color(0.55, 0.72, 0.6), 0.9))

	# Кирпичики: башня из двух и кучка рядом. Два верхних прилетают по ходу ролика.
	var red := CutSet.material(Color(0.85, 0.2, 0.2), 0.55)
	var blue := CutSet.material(Color(0.2, 0.45, 0.85), 0.55)
	var yellow := CutSet.material(Color(0.95, 0.75, 0.2), 0.55)
	var green := CutSet.material(Color(0.3, 0.68, 0.35), 0.55)
	CutSet.add_box(_set_root, "BrickBase", BRICK_SIZE, TOWER_A, red)
	CutSet.add_box(_set_root, "BrickBase2", BRICK_SIZE, TOWER_A + Vector3(0.35, 0.0, 0.0), blue)
	_brick_1 = CutSet.add_box(_set_root, "BrickTop1", BRICK_SIZE, PILE_A, yellow)
	_brick_2 = CutSet.add_box(_set_root, "BrickTop2", BRICK_SIZE, PILE_B, green)


func _build_bush() -> void:
	_bush = BUSH_SCENE.instantiate() as CutBush
	_bush.position = Vector3(POT_X, POT_TOP, -2.25)
	_set_root.add_child(_bush)
