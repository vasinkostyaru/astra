class_name ToySlide
extends Node3D
## Горка: скат от (0, height) вниз до (run, 0). Въехал на скат — Август сам «с ветерком» съезжает вниз.
## Поднимаются к горке по ступенькам, которые строит секция.

signal activated

@export var height: float = 1.8
@export var run: float = 3.6
@export var color: Color = Color(1.0, 0.78, 0.15)
@export var rail_color: Color = Color(0.9, 0.25, 0.25)

const SPEED := 9.0
const THICK := 0.3

var _angle: float
var _cooldown: float = 0.0


func _ready() -> void:
	add_to_group(&"activities")
	_angle = atan2(height, run)
	var hyp := sqrt(height * height + run * run)
	var normal := Vector3(sin(_angle), cos(_angle), 0.0)
	var center := Vector3(run * 0.5, height * 0.5, 0.0) - normal * THICK * 0.5

	var body := StaticBody3D.new()
	body.position = center
	body.rotation.z = -_angle
	var shape := BoxShape3D.new()
	shape.size = Vector3(hyp, THICK, 2.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = LevelSection._rounded_mesh(shape.size, 0.1, 1.0)
	mi.material_override = LevelSection._soft_material(color, "grain")
	body.add_child(mi)
	# Бортики по краям ската — только картинка.
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.mesh = LevelSection._rounded_mesh(Vector3(hyp, 0.25, 0.16), 0.07, 1.0)
		rail.material_override = LevelSection._soft_material(rail_color, "grain")
		rail.position = Vector3(0.0, THICK * 0.5 + 0.1, side * 1.05)
		body.add_child(rail)
	add_child(body)

	var area := Area3D.new()
	area.monitorable = false
	area.position = center + normal * 0.7
	area.rotation.z = -_angle
	var trigger := BoxShape3D.new()
	trigger.size = Vector3(hyp * 0.9, 1.0, 2.0)
	var tcol := CollisionShape3D.new()
	tcol.shape = trigger
	area.add_child(tcol)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func _process(delta: float) -> void:
	_cooldown -= delta


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or _cooldown > 0.0:
		return
	# Только сверху вниз: если идёт вверх по скату (влево) — пусть идёт.
	if player.velocity.x < -0.1:
		return
	_cooldown = 1.0
	activated.emit()
	var left := (run - (player.global_position.x - global_position.x)) / SPEED
	player.push(SPEED, maxf(left, 0.0) + 0.35)
	player.velocity.y = -SPEED * tan(_angle)
	Game.play_note(660.0)
	get_tree().create_timer(0.12).timeout.connect(func() -> void: Game.play_note(880.0))
	# «Ветерок» — облачка вдоль ската.
	for i in 4:
		var t := float(i) / 3.0
		get_tree().create_timer(t * run / SPEED).timeout.connect(func() -> void:
			if is_instance_valid(player):
				Fx.puff(get_parent(), player.global_position, 4, 0.6))
