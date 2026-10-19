class_name CutBerry
extends Node3D
## Ягодка-заглушка для роликов: гладкая сфера с бликом и хвостиком.
## Модель подменяется подменой сцены props/berry_stub.tscn: снаружи важны только
## размер (radius), цвет (color) и позиция.

@export var color := Color(0.86, 0.16, 0.3)
@export var radius := 0.045
@export var shine := true


func _ready() -> void:
	_build()


func _build() -> void:
	var body := CutSet.add_sphere(self, "Body", radius, Vector3.ZERO,
		CutSet.material(color, 0.32), 20)
	body.scale = Vector3(1.0, 1.12, 1.0)
	if shine:
		CutSet.add_sphere(self, "Shine", radius * 0.26,
			Vector3(-radius * 0.34, radius * 0.52, radius * 0.8),
			CutSet.glow(Color(1.0, 0.97, 0.9), 0.7), 10)
	CutSet.add_box(self, "Leaf", Vector3(radius * 1.2, radius * 0.1, radius * 0.7),
		Vector3(0.0, radius * 1.12, 0.0), CutSet.material(Color(0.3, 0.68, 0.26), 0.8))
