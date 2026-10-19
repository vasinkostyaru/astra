class_name Checkpoint
extends Area3D
## Чекпоинт: мягкая подушечка. Коснулся — сюда Август вернётся после падения.

@onready var _cushion: MeshInstance3D = $Cushion

var _active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is Player:
		return
	(body as Player).set_checkpoint(global_position)
	if _active:
		return
	_active = true
	var mat := _cushion.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		create_tween().tween_property(mat, "emission_energy_multiplier", 0.8, 0.5)
