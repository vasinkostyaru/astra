class_name CutBush
extends Node3D
## Волшебный кустик-заглушка: зелёные сферы, блестящие ягодки-сферы.
## Для замены моделью достаточно подменить сцену props/bush_stub.tscn: снаружи нужны
## berries (список ягодок) и berry_world_position(i).

const BERRY_SCENE := preload("res://cutscenes/props/berry_stub.tscn")
const BERRY_RADIUS := 0.045
## Ягодки на кусте — точки на поверхности листвы (локальные координаты куста).
const BERRY_SPOTS: Array[Vector3] = [
	Vector3(0.1, 0.17, 0.14),
	Vector3(-0.13, 0.2, 0.1),
	Vector3(0.02, 0.3, 0.13),
	Vector3(0.15, 0.09, 0.05),
	Vector3(-0.05, 0.13, 0.17),
]

var berries: Array[CutBerry] = []


func _ready() -> void:
	_build()


func berry_world_position(index: int = 0) -> Vector3:
	if berries.is_empty():
		return global_position
	return berries[posmod(index, berries.size())].global_position


func _build() -> void:
	var leaf := CutSet.material(Color(0.27, 0.49, 0.24), 0.9)
	CutSet.add_sphere(self, "Leaf0", 0.17, Vector3(0.0, 0.16, 0.0), leaf, 20)
	CutSet.add_sphere(self, "Leaf1", 0.13, Vector3(0.09, 0.25, 0.02), leaf, 18)
	CutSet.add_sphere(self, "Leaf2", 0.12, Vector3(-0.1, 0.23, 0.03), leaf, 18)
	CutSet.add_sphere(self, "Leaf3", 0.11, Vector3(0.0, 0.3, 0.02), leaf, 18)
	for i in BERRY_SPOTS.size():
		var berry := BERRY_SCENE.instantiate() as CutBerry
		berry.radius = BERRY_RADIUS
		berry.color = [Color(0.92, 0.15, 0.2), Color(0.88, 0.2, 0.45), Color(0.55, 0.28, 0.75)][i % 3]
		berry.position = BERRY_SPOTS[i]
		add_child(berry)
		berries.append(berry)
