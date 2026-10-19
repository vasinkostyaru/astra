extends LevelSection
## Занятие: горка. Три ступеньки вверх, площадка, скат — Август сам съезжает «с ветерком».

const SLIDE_COLORS := {"kids": Color(1.0, 0.78, 0.15), "bath": Color(0.35, 0.75, 0.95),
	"kitchen": Color(0.72, 0.67, 0.60), "living": Color(0.55, 0.8, 0.55)}


func _init() -> void:
	length = 15.0


func _build() -> void:
	var step := Color(0.3, 0.55, 0.85) if theme != "kitchen" else CHARCOAL
	box(2.0, 0.0, 1.2, 0.6, step)
	box(3.2, 0.0, 1.2, 1.2, step.lightened(0.1))
	box(4.4, 0.0, 1.8, 1.8, step.lightened(0.2))
	var slide := ToySlide.new()
	slide.height = 1.8
	slide.run = 3.6
	slide.color = SLIDE_COLORS.get(theme, Color(1.0, 0.78, 0.15))
	slide.position = Vector3(6.2, 0.0, 0.0)
	add_child(slide)
	berry(5.3, 2.7)
	berry(7.6, 1.9)
	berry(11.5, 0.8)
	marker("Stop_Slide", 5.3, 1.8)
	marker("Run_Out", 14.0, 0.0)
