class_name PianoTile
extends Area3D
## Плитка пианино-коврика: наступил или приземлился — звучит своя нота и плитка вспыхивает.

signal activated

const GLOW := 1.6

var frequency: float = 523.25
var color: Color = Color.WHITE

var _mesh: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	monitorable = false
	add_to_group(&"activities")
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.95, 1.2, 2.4)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.6, 0)
	add_child(col)
	var box := BoxMesh.new()
	box.size = Vector3(0.95, 0.06, 2.4)
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.roughness = 0.6
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = 0.0
	box.material = _material
	_mesh = MeshInstance3D.new()
	_mesh.mesh = box
	_mesh.position = Vector3(0, 0.03, 0)
	add_child(_mesh)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	Game.play_note(frequency)
	activated.emit()
	var tw := create_tween()
	tw.tween_property(_material, "emission_energy_multiplier", GLOW, 0.05)
	tw.parallel().tween_property(_mesh, "scale:y", 0.4, 0.05)
	tw.tween_property(_material, "emission_energy_multiplier", 0.0, 0.6)
	tw.parallel().tween_property(_mesh, "scale:y", 1.0, 0.25)
