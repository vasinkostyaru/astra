class_name BouncePillow
extends FallZone
## Подушка-батут: ловит Августа на своей верхней грани, проминается вместе с ним и подбрасывает к чекпоинту.

## Высота подушки (верхняя грань относительно её основания).
@export var surface_height: float = 0.5
## Насколько подушка проминается (доля высоты).
@export_range(0.1, 0.9) var squash: float = 0.55
@export var squash_time: float = 0.12

@onready var _pillow: Node3D = $Pillow


func _catch(player: Player) -> void:
	Game.play_boing()
	player.catch_on(global_position.y + surface_height, surface_height * squash, squash_time)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_pillow, "scale", Vector3(1.12, 1.0 - squash, 1.08), squash_time).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pillow, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
