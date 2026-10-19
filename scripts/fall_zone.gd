class_name FallZone
extends Area3D
## Место, откуда не выбраться (щель, яма): коснулся — мягко возвращаемся к последнему чекпоинту.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).soft_respawn()
