class_name Astra
extends Node3D
## Астра. Внешний вид — дочерний узел Model (GLB можно заменить без правок кода).
## Анимации run/idle/sleep ищутся в AnimationPlayer внутри Model; если анимации нет — пропускаем.

@export var start_animation: StringName = &"idle"

@onready var model: Node3D = $Model

var _anim_player: AnimationPlayer


func _ready() -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim_player = players[0] as AnimationPlayer
	play(start_animation)


func play(anim: StringName) -> void:
	if _anim_player and _anim_player.has_animation(anim):
		_anim_player.play(anim, 0.25)
