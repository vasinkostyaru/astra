class_name BouncePad
extends Area3D
## Батут-подушка: наступил — подбросило высоко (до ягодок над ним). Идти вперёд он не мешает.

signal activated

@export var bounce_height: float = 3.4
## Вид: подушка-батут (по умолчанию) или крышка от кастрюли.
@export var lid: bool = false

var _pad: MeshInstance3D


func _ready() -> void:
	monitorable = false
	add_to_group(&"activities")
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 0.8, 2.2)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.4, 0)
	add_child(col)
	var mat := StandardMaterial3D.new()
	_pad = MeshInstance3D.new()
	if lid:
		# Крышка от кастрюли: блестящий металлический диск с ручкой.
		var disc := CylinderMesh.new()
		disc.top_radius = 0.9
		disc.bottom_radius = 0.95
		disc.height = 0.16
		mat.albedo_color = Color(0.78, 0.8, 0.84)
		mat.metallic = 0.7
		mat.roughness = 0.3
		disc.material = mat
		_pad.mesh = disc
		var knob := MeshInstance3D.new()
		var km := SphereMesh.new()
		km.radius = 0.14
		km.height = 0.28
		var kmat := StandardMaterial3D.new()
		kmat.albedo_color = Color(0.15, 0.15, 0.17)
		km.material = kmat
		knob.mesh = km
		knob.position = Vector3(0, 0.14, 0)
		_pad.add_child(knob)
		_pad.position = Vector3(0, 0.1, 0)
	else:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.8, 0.3, 2.0)
		mat.albedo_color = Color(1.0, 0.45, 0.6)
		mat.roughness = 0.9
		mesh.material = mat
		_pad.mesh = mesh
		_pad.position = Vector3(0, 0.15, 0)
	add_child(_pad)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	activated.emit()
	Game.play_boing()
	(body as Player).bounce(bounce_height)
	var tw := create_tween()
	tw.tween_property(_pad, "scale", Vector3(1.15, 0.4, 1.05), 0.06)
	tw.tween_property(_pad, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
