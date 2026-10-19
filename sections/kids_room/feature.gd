extends LevelSection
## «Фишка» «Детской»: кучка кирпичиков сама строит лестницу к кровати (срабатывает от прихода Августа),
## дальше кровать и спуск обратно на пол.

const WOOD := Color(0.62, 0.4, 0.23)
const LINEN := Color(0.95, 0.93, 0.88)
const BLANKET := Color(0.95, 0.5, 0.4)
const WOOD_LIGHT := Color(0.78, 0.58, 0.38)


func _init() -> void:
	has_rug = false
	length = 23.0


func _build() -> void:
	var pile: BrickPile = PILE.instantiate()
	pile.position = Vector3(3.0, 0.0, 0.0)
	pile.stairs_origin = Vector3(2.0, 0.0, 0.0)  # ступени с x = 5.0 в координатах секции
	pile.step_columns = 3  # ступень 1.8 м
	# Четвёртая ступень — продолжение верхней: полный прыжок Августа летит ~2.5 м, на узкой площадке он бы перелетел.
	pile.step_rows = PackedInt32Array([2, 4, 6, 6])
	pile.trigger_size = Vector3(3.0, 3.0, 3.0)  # зона x = 1.5…4.5: строится, когда Август в 3–4 м от лестницы
	pile.flight_time = 0.4
	pile.brick_delay = 0.012
	pile.step_delay = 0.08
	pile.color_seed = 1
	add_child(pile)
	# Лестница 0.6 / 1.2 / 1.8 (x 5.0–12.2, верх 3.6 м), дальше промежуток 1.8 (под ним подушка) и кровать 2.4.
	pillow_gap(12.2, 1.8)
	box(14.0, 0.0, 6.0, 2.0, WOOD)
	box(14.0, 2.0, 6.0, 0.4, LINEN, 2.4)
	decor(15.9, 2.4, 3.6, 0.08, 0.0, 2.5, BLANKET)
	decor(14.2, 2.4, 1.4, 0.3, -0.3, 1.0, LINEN)
	# Спуск: тумбочка-ступень 1.2, потом пол.
	box(20.0, 0.0, 1.4, 1.2, WOOD_LIGHT)

	berry(5.9, 1.2)
	berry(9.5, 2.4)
	berry(15.1, 3.0)
	berry(17.1, 3.5)
	berry(20.7, 1.9)
	checkpoint(11.6, 1.8)
	checkpoint(17.0, 2.4)
	marker("Stop_Pile", 4.0, 0.0)
	marker("Run_Step1", 5.9, 0.6)
	marker("Run_Step2", 7.7, 1.2)
	marker("Stop_Top", 10.4, 1.8)
	marker("Run_Bed", 14.8, 2.4)
	marker("Stop_Bed", 17.1, 2.4)
	marker("Run_BedEnd", 19.4, 2.4)
	marker("Run_Down", 20.7, 1.2)
	marker("Run_Floor", 22.1, 0.0)
