class_name SideCamera
extends Camera3D
## Камера сбоку: плавно следует за целью с опережением в сторону движения.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 1.3, 6.5)
@export var look_ahead: float = 1.6
@export var follow_speed: float = 4.0
@export var look_ahead_speed: float = 1.5
@export var limit_left: float = -1000.0
@export var limit_right: float = 1000.0
@export var min_y: float = 1.5

var _look: float = 0.0


func _ready() -> void:
	# Двигаемся в _process по интерполированной позиции цели — без дрожания на 90/120 Гц экранах.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target:
		global_position = _desired_position(target.global_position)


func _process(delta: float) -> void:
	if target == null:
		return
	var body := target as CharacterBody3D
	if body and absf(body.velocity.x) > 0.5:
		var look_target := signf(body.velocity.x) * look_ahead
		_look = lerpf(_look, look_target, 1.0 - exp(-look_ahead_speed * delta))
	var goal := _desired_position(target.get_global_transform_interpolated().origin)
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))


func _desired_position(target_pos: Vector3) -> Vector3:
	var p := target_pos + offset
	p.x = clampf(p.x + _look, limit_left, limit_right)
	p.y = maxf(p.y, min_y)
	return p
