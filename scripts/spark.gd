class_name Spark
extends Area3D
## Искорка света: собирается, когда Август проходит сквозь неё. Уровень слушает сигнал collected.

signal collected(spark: Spark)

@onready var _visual: Node3D = $Visual

var _time: float = randf() * TAU
var _taken: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	_visual.position.y = sin(_time * 2.2) * 0.08
	_visual.rotate_y(delta * 1.5)


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body is Player:
		return
	_taken = true
	collected.emit(self)
	set_deferred("monitoring", false)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(_visual, "scale", Vector3.ONE * 1.8, 0.1)
	tw.tween_property(_visual, "scale", Vector3.ONE * 0.01, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
