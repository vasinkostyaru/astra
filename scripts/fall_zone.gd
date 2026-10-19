class_name FallZone
extends Area3D
## Место, откуда не выбраться (щель, яма): коснулся — Август возвращается к последнему чекпоинту.
## Наследники (подушка-батут, надувной круг, пузырь) переопределяют _catch() со своим эффектом.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_catch(body as Player)


func _catch(player: Player) -> void:
	player.return_to_checkpoint()
