extends Cutscene
## finale — финал игры после гостиной. Тёплая гостиная, на лежанке спит Астра клубком, Август тихо подходит;
## по очереди загорается гирлянда и торшер, над Астрой — сердечки и мурчание, камера плавно приближается.
## Потом затемнение и выбор комнаты. Никакого текста.

const FLOOR_Y := 0.012
const WALL_Z := -2.75
const WALL_TOP := 4.6

const BED := Vector3(1.2, FLOOR_Y, 0.4)
const AVGUST_START := Vector3(-3.4, FLOOR_Y, 0.8)
const AVGUST_END := Vector3(0.2, FLOOR_Y, 0.8)

const BULB_COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.3), Color(1.0, 0.8, 0.25), Color(0.4, 0.85, 0.45), Color(0.4, 0.65, 1.0), Color(0.85, 0.5, 0.95),
]

@export_group("Тайминги")
@export var t_open: float = 0.0
@export var t_walk: float = 0.8
@export var t_lights: float = 1.6
@export var t_arrive: float = 4.4
@export var t_purr: float = 4.6
@export var t_fade: float = 8.2

@export_group("Длительности")
@export var d_fade_in: float = 0.8
@export var d_fade_out: float = 1.0
@export var d_walk: float = 3.4
@export var d_zoom: float = 4.0

@export_group("Камера")
@export var shot_open_target := Vector3(0.0, 1.5, 0.0)
@export var shot_open_dist: float = 8.0
@export var shot_close_target := Vector3(0.7, 0.9, 0.0)
@export var shot_close_dist: float = 4.6

var _set_root: Node3D
var _heroes: Node3D
var _props: Node3D
var _audio: CutAudio
var _avgust: Player
var _astra: Astra
var _bulbs: Array[StandardMaterial3D] = []
var _lamp_shade: StandardMaterial3D
var _lamp_light: OmniLight3D
var _hearts: CPUParticles3D


func _prepare() -> void:
	_set_root = $Set as Node3D
	_heroes = $Heroes as Node3D
	_props = $Props as Node3D
	_audio = $CutAudio as CutAudio
	_build_room()

	_astra = CutActors.spawn_astra(_heroes)
	CutActors.matte(_astra)
	_astra.position = BED + Vector3(0, 0.2, 0)
	CutActors.face_astra(_astra, CutActors.CAMERA)
	CutActors.play(_astra, &"sleep")

	_avgust = CutActors.spawn_avgust(_heroes)
	CutActors.matte(_avgust)
	_avgust.position = AVGUST_START
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	CutActors.play(_avgust, &"idle")

	fade_to(1.0, 0.0)
	cam_to(shot_open_target, shot_open_dist, 0.0)


func _build() -> void:
	at(t_open, _open)
	at(t_walk, _avgust_walks)
	at(t_lights, _lights_on)
	at(t_arrive, _avgust_arrives)
	at(t_purr, _purr_and_hearts)
	at(t_fade, _fade_out)


# --- биты ------------------------------------------------------------------

func _open() -> void:
	fade_to(0.0, d_fade_in)


func _avgust_walks() -> void:
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	walk_x(_avgust, AVGUST_END.x, d_walk, &"walk", 0.8)
	cam_to(shot_close_target, shot_close_dist, d_zoom + 2.0)


func _lights_on() -> void:
	_audio.melody()
	var tw := new_tween()
	for mat in _bulbs:
		tw.tween_property(mat, "emission_energy_multiplier", 4.0, 0.07)
	var lamp := new_tween()
	lamp.set_parallel(true)
	lamp.tween_property(_lamp_light, "light_energy", 2.4, 2.0)
	lamp.tween_property(_lamp_shade, "emission_energy_multiplier", 3.0, 2.0)


func _avgust_arrives() -> void:
	CutActors.play(_avgust, &"idle")
	CutActors.face_avgust(_avgust, CutActors.RIGHT)


func _purr_and_hearts() -> void:
	_audio.purr()
	_hearts.emitting = true
	sparkles_at(BED + Vector3(0, 0.9, 0.3), Color(1.0, 0.82, 0.5), 30)


func _fade_out() -> void:
	_audio.shimmer()
	fade_to(1.0, d_fade_out)


# --- финальное состояние (после пропуска) -----------------------------------

func _apply_final_state() -> void:
	for mat in _bulbs:
		mat.emission_energy_multiplier = 4.0
	_lamp_light.light_energy = 2.4
	_lamp_shade.emission_energy_multiplier = 3.0
	_avgust.position = AVGUST_END
	CutActors.face_avgust(_avgust, CutActors.RIGHT)
	CutActors.play(_avgust, &"idle")
	CutActors.play(_astra, &"sleep")
	_hearts.emitting = true
	cam_to(shot_close_target, shot_close_dist, 0.0)
	fade_to(1.0, 0.0)


# --- декорации --------------------------------------------------------------

func _build_room() -> void:
	var wood := CutSet.material(Color(0.74, 0.64, 0.52), 0.85)
	CutSet.add_box(_set_root, "Floor", Vector3(16.0, 0.3, 5.0), Vector3(0.0, -0.15, -0.2), wood)
	CutSet.add_box(_set_root, "Rug", Vector3(4.4, 0.008, 2.6), Vector3(0.6, 0.004, 0.4),
		CutSet.material(Color(0.9, 0.84, 0.76), 0.95))
	# Бело-голубые обои полосками.
	var stripe_a := CutSet.material(Color(0.88, 0.93, 0.98), 0.95)
	var stripe_b := CutSet.material(Color(0.8, 0.88, 0.96), 0.95)
	for i in 14:
		CutSet.add_box(_set_root, "Wall%d" % i, Vector3(1.2, WALL_TOP, 0.3),
			Vector3(-7.2 + i * 1.2, WALL_TOP * 0.5, WALL_Z), stripe_a if i % 2 == 0 else stripe_b)
	CutSet.add_box(_set_root, "Skirting", Vector3(16.0, 0.2, 0.08), Vector3(0.0, 0.1, WALL_Z + 0.2),
		CutSet.material(Color(0.97, 0.95, 0.9), 0.8))
	# Диван с разноцветными подушками (светлый серо-бежевый).
	var sofa := Color(0.78, 0.74, 0.68)
	CutSet.add_box(_set_root, "SofaBase", Vector3(2.8, 0.5, 0.95), Vector3(-3.0, 0.25, -1.9), CutSet.material(sofa, 0.9))
	CutSet.add_box(_set_root, "SofaBack", Vector3(2.8, 0.75, 0.3), Vector3(-3.0, 0.85, -2.25), CutSet.material(sofa.darkened(0.06), 0.9))
	var cushion_colors: Array[Color] = [Color(0.9, 0.3, 0.3), Color(0.25, 0.55, 0.85), Color(0.95, 0.78, 0.2), Color(0.35, 0.72, 0.45), Color(0.85, 0.45, 0.7)]
	for i in 5:
		var cushion := CutSet.add_box(_set_root, "Cushion%d" % i, Vector3(0.45, 0.45, 0.14),
			Vector3(-4.1 + i * 0.5, 0.82, -1.92), CutSet.material(cushion_colors[i], 0.9))
		cushion.rotation = Vector3(-0.2, 0.0, (i - 2) * 0.12)
	# Винтажное рыжее кресло: тёмное дерево, четыре ножки, изогнутые подлокотники, две подушки.
	var orange := Color(1.0, 0.4, 0.04)
	var dark := CutSet.material(Color(0.28, 0.16, 0.09), 0.7)
	var cushion_mat := CutSet.material(orange, 0.9)
	for lx in [3.4, 4.4]:
		for lz in [-1.4, -2.0]:
			CutSet.add_box(_set_root, "ChairLeg", Vector3(0.09, 0.4, 0.09), Vector3(lx, 0.2, lz), dark)
	CutSet.add_box(_set_root, "ChairFrame", Vector3(1.3, 0.1, 0.8), Vector3(3.9, 0.45, -1.7), dark)
	CutSet.add_box(_set_root, "ChairSeat", Vector3(1.15, 0.2, 0.75), Vector3(3.9, 0.6, -1.7), cushion_mat)
	CutSet.add_box(_set_root, "ChairBackFrame", Vector3(1.3, 0.95, 0.1), Vector3(3.9, 1.1, -2.1), dark)
	CutSet.add_box(_set_root, "ChairBackCushion", Vector3(1.0, 0.6, 0.2), Vector3(3.9, 1.0, -1.97), cushion_mat)
	for ax in [3.3, 4.5]:
		CutSet.add_box(_set_root, "ArmPost", Vector3(0.08, 0.4, 0.08), Vector3(ax, 0.8, -1.55), dark)
		var arm := CutSet.add_cylinder(_set_root, "Arm", 0.06, 0.06, 0.6, Vector3(ax, 1.02, -1.75), dark)
		arm.rotation.x = PI * 0.5
		CutSet.add_sphere(_set_root, "ArmKnob", 0.07, Vector3(ax, 1.02, -1.45), dark, 10)
	# Фисташковая штора на стене.
	var curtain := CutSet.material(Color(0.42, 0.57, 0.38), 0.95)
	CutSet.add_box(_set_root, "Curtain", Vector3(2.6, 3.7, 0.12), Vector3(-0.4, 2.0, WALL_Z + 0.2), curtain)
	for i in 6:
		CutSet.add_box(_set_root, "Fold%d" % i, Vector3(0.14, 3.7, 0.08),
			Vector3(-1.5 + i * 0.44, 2.0, WALL_Z + 0.3), CutSet.material(Color(0.34, 0.47, 0.31), 0.95))
	# Растения (у них в гостиной их много): фикус и монстера.
	var leaf_mats: Array[StandardMaterial3D] = [CutSet.material(Color(0.2, 0.55, 0.25), 0.9), CutSet.material(Color(0.3, 0.66, 0.3), 0.9), CutSet.material(Color(0.16, 0.45, 0.22), 0.9)]
	var pot_mat := CutSet.material(Color(0.78, 0.46, 0.3), 0.85)
	CutSet.add_cylinder(_set_root, "FicusPot", 0.28, 0.22, 0.45, Vector3(-0.2, 0.22, -2.0), pot_mat)
	CutSet.add_cylinder(_set_root, "FicusTrunk", 0.04, 0.05, 1.3, Vector3(-0.2, 1.0, -2.0), CutSet.material(Color(0.45, 0.3, 0.18), 0.9))
	for k in 8:
		var a := k * 0.8
		CutSet.add_sphere(_set_root, "FicusLeaf%d" % k, 0.3, Vector3(-0.2 + cos(a) * 0.4, 1.6 + (k % 4) * 0.28, -2.0 + sin(a) * 0.2), leaf_mats[k % 3], 12)
	CutSet.add_cylinder(_set_root, "MonsteraPot", 0.32, 0.26, 0.4, Vector3(6.0, 0.2, -1.7), pot_mat)
	for k in 6:
		var leaf := CutSet.add_sphere(_set_root, "MonsteraLeaf%d" % k, 0.3, Vector3(6.0 + (k - 2.5) * 0.28, 0.9 + (k % 2) * 0.2, -1.7), leaf_mats[k % 3], 12)
		leaf.scale = Vector3(0.45, 1.3, 0.3)
		leaf.rotation.z = -(k - 2.5) * 0.25
	# Лежанка Астры.
	var bed_mat := CutSet.material(Color(0.95, 0.72, 0.55), 0.95)
	CutSet.add_cylinder(_set_root, "Bed", 0.62, 0.7, 0.2, BED + Vector3(0, 0.1, 0), bed_mat)
	CutSet.add_cylinder(_set_root, "BedRim", 0.72, 0.74, 0.14, BED + Vector3(0, 0.07, 0), CutSet.material(Color(0.88, 0.6, 0.45), 0.95))
	# Торшер.
	CutSet.add_cylinder(_set_root, "LampPole", 0.03, 0.03, 2.0, Vector3(2.7, 1.0, -1.5), CutSet.material(Color(0.3, 0.3, 0.32), 0.7))
	CutSet.add_cylinder(_set_root, "LampBase", 0.28, 0.3, 0.05, Vector3(2.7, 0.03, -1.5), CutSet.material(Color(0.3, 0.3, 0.32), 0.7))
	_lamp_shade = CutSet.glow(Color(1.0, 0.95, 0.82), 0.1)
	CutSet.add_cylinder(_set_root, "LampShade", 0.22, 0.4, 0.5, Vector3(2.7, 2.1, -1.5), _lamp_shade)
	_lamp_light = OmniLight3D.new()
	_lamp_light.position = Vector3(2.7, 2.0, -0.6)
	_lamp_light.light_color = Color(1.0, 0.82, 0.55)
	_lamp_light.omni_range = 9.0
	_lamp_light.light_energy = 0.15
	_set_root.add_child(_lamp_light)
	# Гирлянда вдоль стены (тусклая, загорается по очереди).
	var x := -6.0
	var i := 0
	while x < 6.2:
		var mat := CutSet.glow(BULB_COLORS[i % BULB_COLORS.size()], 0.3)
		var y := 4.1 - sin(fmod(x + 6.0, 3.0) / 3.0 * PI) * 0.4
		var bulb := CutSet.add_sphere(_set_root, "Bulb%d" % i, 0.07, Vector3(x, y, WALL_Z + 0.35), mat, 8)
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_bulbs.append(mat)
		x += 0.55
		i += 1
	# Сердечки над Астрой.
	var quad := QuadMesh.new()
	quad.size = Vector2(0.28, 0.28)
	var hmat := StandardMaterial3D.new()
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.albedo_texture = Astra._heart_texture()
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	hmat.billboard_keep_scale = true
	quad.material = hmat
	_hearts = CPUParticles3D.new()
	_hearts.mesh = quad
	_hearts.amount = 12
	_hearts.lifetime = 2.2
	_hearts.direction = Vector3(0, 1, 0)
	_hearts.spread = 20.0
	_hearts.gravity = Vector3(0, 0.15, 0)
	_hearts.initial_velocity_min = 0.5
	_hearts.initial_velocity_max = 0.9
	_hearts.emitting = false
	_hearts.position = BED + Vector3(0, 0.7, 0.3)
	_props.add_child(_hearts)
