extends LevelSection
## Занятие: пианино-коврик. Восемь цветных плиток на полу, каждая звучит своей нотой (идёшь — играет гамма).

const NOTES: Array[float] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.0, 987.77, 1046.5]
const COLORS: Array[Color] = [
	Color(0.9, 0.22, 0.2), Color(1.0, 0.5, 0.15), Color(1.0, 0.8, 0.15), Color(0.35, 0.75, 0.3),
	Color(0.2, 0.7, 0.75), Color(0.2, 0.5, 0.95), Color(0.5, 0.35, 0.85), Color(0.9, 0.4, 0.7),
]


func _init() -> void:
	length = 12.0


func _build() -> void:
	for i in 8:
		var tile := PianoTile.new()
		tile.frequency = NOTES[i]
		tile.color = COLORS[i]
		tile.position = Vector3(2.0 + i * 1.0, 0.0, 0.0)
		add_child(tile)
	berry(3.5, 1.5)
	berry(7.5, 1.5)
	marker("Stop_Piano", 5.0, 0.0)
	marker("Run_Out", 11.0, 0.0)
