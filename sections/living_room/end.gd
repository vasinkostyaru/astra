extends LevelSection
## Конец гостиной: ровный ковёр, торшер и гирлянда, на мягкой лежанке спит Астра. Спокойный финал без прыжков.


func _init() -> void:
	length = 14.0


func _build() -> void:
	# Лежанка Астры: круглая подушка.
	# Лежанка твёрдая (ступенька 0.45, Август может подойти вплотную и встать на неё); картинка ниже.
	box(9.0, 0.0, 2.0, 0.45, Color(0.95, 0.72, 0.55), 1.8).get_child(1).visible = false
	var bed := CylinderMesh.new()
	bed.top_radius = 1.0
	bed.bottom_radius = 1.1
	bed.height = 0.45
	bed.material = _material(Color(0.95, 0.72, 0.55))
	var bed_mi := MeshInstance3D.new()
	bed_mi.mesh = bed
	bed_mi.position = Vector3(10.0, 0.225, -0.1)
	add_child(bed_mi)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.75
	rim.outer_radius = 1.15
	rim.material = _material(Color(0.88, 0.6, 0.45))
	var rim_mi := MeshInstance3D.new()
	rim_mi.mesh = rim
	rim_mi.position = Vector3(10.0, 0.45, -0.1)
	rim_mi.scale = Vector3(1.0, 0.5, 1.0)
	add_child(rim_mi)
	lamp_anchor = Vector3(12.2, 0.0, -1.0)
	berry(3.0, 0.8)
	berry(5.0, 1.6)
	berry(7.0, 0.8)
	berry(8.5, 1.6)
	checkpoint(0.5, 0.0)
	marker("Stop_Rug", 4.0, 0.0)
	marker("Run_Rug2", 7.0, 0.0)
	marker("Exit_sleep", 10.0, 0.55)
