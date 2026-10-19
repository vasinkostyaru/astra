class_name CutActors
extends RefCounted
## Герои для роликов: те же сцены, что в игре (Player и Astra), но физика выключена —
## позицию, поворот и анимацию задаёт ролик. Ничего в scripts/player.gd и scripts/astra.gd
## не меняется: модели подменяются как обычно через Model.

const AVGUST_SCENE := preload("res://scenes/player/player.tscn")
const ASTRA_SCENE := preload("res://scenes/astra/astra.tscn")

## Направление взгляда для face_avgust/face_astra.
const RIGHT := 1.0
const CAMERA := 0.0
const LEFT := -1.0


## Август на сцене: стоит там, куда его поставили (гравитация не тянет вниз).
static func spawn_avgust(parent: Node) -> Player:
	var p := AVGUST_SCENE.instantiate() as Player
	parent.add_child(p)
	p.set_physics_process(false)
	return p


## Астра на сцене: без маршрута и без физики, двигает её ролик.
static func spawn_astra(parent: Node) -> Astra:
	var a := ASTRA_SCENE.instantiate() as Astra
	parent.add_child(a)
	a.set_physics_process(false)
	return a


## Матовый материал героям ролика: убираем блик (модели выглядят «пластиково»),
## не трогая общий материал игры.
static func matte(who: Node, roughness: float = 1.0, specular: float = 0.0) -> void:
	for child in who.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var source: Material = mi.get_surface_override_material(surface)
			if source == null:
				source = mi.mesh.surface_get_material(surface)
			if source is StandardMaterial3D:
				var mat := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.roughness = roughness
				mat.metallic_specular = specular
				mi.set_surface_override_material(surface, mat)


static func anim_player(who: Node) -> AnimationPlayer:
	var players := who.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null


## Включить клип героя; speed_scale — чтобы шаги не «скользили» по полу.
static func play(who: Node, state: StringName, speed: float = 1.0) -> void:
	var ap := anim_player(who)
	if ap and ap.has_animation(state):
		ap.speed_scale = speed
		ap.play(state, 0.2)


## Поворот Августа: RIGHT, LEFT или CAMERA (лицом к экрану).
static func face_avgust(p: Node, dir: float) -> void:
	# У Player поворот 0 — вправо, -90° — к камере, -180° — влево.
	var model := p.get_node_or_null("Model") as Node3D
	if model:
		model.rotation.y = -PI * (1.0 - dir) * 0.5


## Поворот Астры: RIGHT, LEFT или CAMERA.
static func face_astra(a: Node, dir: float) -> void:
	var model := a.get_node_or_null("Model") as Node3D
	if model:
		model.rotation.y = dir * PI * 0.5


