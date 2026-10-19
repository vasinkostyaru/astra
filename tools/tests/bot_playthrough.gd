extends SceneTree

var level: Node
var player: CharacterBody3D
var frame := 0
var respawns := 0
var max_x := -100.0
var log_every := 60

func _initialize() -> void:
	level = load("res://levels/level_01_kids_room.tscn").instantiate()
	root.add_child(level)
	player = level.get_node("Player")
	player.respawned.connect(func() -> void: respawns += 1)
	level.completed.connect(func() -> void: print("LEVEL COMPLETED at t=%.1f x=%.2f" % [frame / 60.0, player.global_position.x]))

func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		Input.action_press(&"move_right")
	# прыгаем, когда стоим на полу (зажатая кнопка не повторяет прыжок — отпускаем/жмём)
	var x := player.global_position.x
	var want_jump := player.is_on_floor() and (player.is_on_wall() or (x > 7.4 and x < 7.8) or (x > 16.4 and x < 16.8))
	if want_jump and not Input.is_action_pressed(&"jump"):
		Input.action_press(&"jump")
	elif Input.is_action_pressed(&"jump"):
		Input.action_release(&"jump")
	max_x = maxf(max_x, player.global_position.x)
	if frame % log_every == 0:
		var left := get_nodes_in_group(&"berries").size()
		var a: Node3D = level.get_node("Astra")
		print("t=%.1f x=%.2f y=%.2f berries_left=%d respawns=%d astra=(%.2f, %.2f)" % [frame / 60.0, player.global_position.x, player.global_position.y, left, respawns, a.global_position.x, a.global_position.y])
	if frame >= 60 * 20:
		var lamp := level.get_node("NightLamp/Light") as OmniLight3D
		print("DONE max_x=%.2f lamp_energy=%.2f jar=%d respawns=%d" % [max_x, lamp.light_energy, level.get_node("HUD/Root/Jar")._count, respawns])
		for s in get_nodes_in_group(&"berries"):
			print("  missed berry at ", s.global_position)
		return true
	return false
