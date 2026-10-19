extends LevelSection
## Занятие: мячик-пинашка. Подошёл к мячу — он отскакивает вперёд и сбивает кегли.


func _init() -> void:
	length = 13.0


func _build() -> void:
	var ball := KickBall.new()
	ball.width = 12.0
	ball.ball_x = 3.0
	ball.position = Vector3(0.5, 0.0, 0.0)
	add_child(ball)
	berry(6.0, 1.4)
	berry(8.0, 1.4)
	marker("Stop_Ball", 2.0, 0.0)
	marker("Run_Out", 12.0, 0.0)
