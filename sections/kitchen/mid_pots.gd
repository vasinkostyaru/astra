extends LevelSection
## Три кастрюли по 0.9 с промежутками 1.0 между ними (можно спрыгнуть и выпрыгнуть обратно).

func _init() -> void:
	length = 12.5


func _build() -> void:
	pot(2.0, 2.0, 0.9, Color(0.78, 0.8, 0.84))
	pot(5.0, 2.0, 0.9, Color(0.85, 0.3, 0.25))
	pot(8.0, 2.0, 0.9, Color(0.78, 0.8, 0.84))
	berry(3.0, 1.9)
	berry(6.0, 1.9)
	berry(9.0, 1.9)
	marker("Stop_Pot", 6.0, 0.9)
	marker("Run_Out", 11.5, 0.0)
