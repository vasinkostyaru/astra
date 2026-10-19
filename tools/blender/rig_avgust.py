"""Скелет и анимации Августа: idle, walk, jump, fall, happy.

Запуск:
    blender -b --python tools/blender/rig_avgust.py -- <покрашенная.glb> <выход.glb>

Модель на входе (после paint_avgust.py): Z вверх, ноги в нуле, рост ~1.05, лицо в -Y, руки в A-позе.
Повороты в анимациях задаются в осях арматуры: X — вбок (наклон вперёд/назад), Y — вперёд-назад
(наклон вбок), Z — вверх (поворот). Положительный угол вокруг X отклоняет кость назад (+Y).
"""
import sys
import math
import bpy
from mathutils import Vector, Quaternion, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
FPS = 30

# Ориентиры (метры, модель ростом 1.05). Для левой стороны (+X); правая — зеркально.
BONES = {
    # имя: (голова, хвост, родитель)
    "hips": ((0, 0, 0.31), (0, 0, 0.40), None),
    "spine": ((0, 0, 0.40), (0, 0, 0.52), "hips"),
    "chest": ((0, 0, 0.52), (0, 0, 0.64), "spine"),
    "neck": ((0, 0, 0.64), (0, 0, 0.68), "chest"),
    "head": ((0, 0, 0.68), (0, 0, 1.00), "neck"),
    "upper_arm.L": ((0.115, 0, 0.62), (0.214, 0, 0.512), "chest"),
    "forearm.L": ((0.214, 0, 0.512), (0.294, 0, 0.404), "upper_arm.L"),
    "hand.L": ((0.294, 0, 0.404), (0.354, 0, 0.374), "forearm.L"),
    "thigh.L": ((0.083, 0, 0.31), (0.083, 0, 0.165), "hips"),
    "shin.L": ((0.083, 0, 0.165), (0.083, 0.0, 0.06), "thigh.L"),
    "foot.L": ((0.083, 0.0, 0.06), (0.083, -0.09, 0.02), "shin.L"),
}


def mirror(name: str) -> str:
    return name.replace(".L", ".R")


bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = FPS
bpy.ops.import_scene.gltf(filepath=SRC)
body = [o for o in scene.objects if o.type == 'MESH'][0]

# --- Арматура ---
arm_data = bpy.data.armatures.new("AvgustRig")
rig = bpy.data.objects.new("AvgustRig", arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
edit = arm_data.edit_bones
all_bones = {}
for name, (h, t, parent) in BONES.items():
    all_bones[name] = (h, t, parent)
    if name.endswith(".L"):
        all_bones[mirror(name)] = ((-h[0], h[1], h[2]), (-t[0], t[1], t[2]), mirror(parent) if parent and parent.endswith(".L") else parent)
for name, (h, t, parent) in all_bones.items():
    b = edit.new(name)
    b.head = h
    b.tail = t
    b.roll = 0.0
for name, (h, t, parent) in all_bones.items():
    if parent:
        edit[name].parent = edit[parent]
        edit[name].use_connect = (Vector(edit[parent].tail) - Vector(h)).length < 1e-4
bpy.ops.object.mode_set(mode='OBJECT')

# --- Привязка сетки ---
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
groups = {g.name for g in body.vertex_groups}
weighted = sum(1 for v in body.data.vertices if any(g.weight > 0.01 for g in v.groups))
print("SKIN auto groups", len(groups), "weighted verts", weighted, "of", len(body.data.vertices))


def distance_weights(only_unweighted: bool):
    """Веса по расстоянию до отрезков костей — для вершин, которые тепловые веса не покрыли
    (отдельные детали вроде глаз, несвязные кусочки сетки)."""
    segs = {n: (Vector(h), Vector(t)) for n, (h, t, _) in all_bones.items()}
    vgs = {n: (body.vertex_groups.get(n) or body.vertex_groups.new(name=n)) for n in segs}
    count = 0
    for v in body.data.vertices:
        if only_unweighted and any(g.weight > 0.01 for g in v.groups):
            continue
        p = v.co
        ds = []
        for n, (a, b) in segs.items():
            ab = b - a
            k = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
            ds.append(((p - (a + ab * k)).length + 1e-4, n))
        ds.sort()
        ws = [(1.0 / d ** 4, n) for d, n in ds[:3]]
        tot = sum(w for w, _ in ws)
        for w, n in ws:
            vgs[n].add([v.index], w / tot, 'REPLACE')
        count += 1
    print("SKIN distance weights for", count, "verts")


distance_weights(only_unweighted=weighted > len(body.data.vertices) * 0.5)

# Голова жёсткая: всё выше шеи (включая отдельные детали глаз) — целиком к кости head,
# иначе при наклоне головы радужка и белок разъезжаются.
for v in body.data.vertices:
    if v.co.z > 0.70:
        for g in list(v.groups):
            body.vertex_groups[g.group].remove([v.index])
        body.vertex_groups["head"].add([v.index], 1.0, 'REPLACE')

# Нормализация весов.
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_normalize_all(lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')

# --- Анимации ---
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = 'QUATERNION'

AXES = {"x": Vector((1, 0, 0)), "y": Vector((0, 1, 0)), "z": Vector((0, 0, 1))}


def local_rot(bone_name: str, rots: dict) -> Quaternion:
    """Поворот в осях арматуры (градусы) -> локальный кватернион кости."""
    q = Quaternion()
    for ax, deg in rots.items():
        q = Quaternion(AXES[ax], math.radians(deg)) @ q
    m = rig.data.bones[bone_name].matrix_local.to_3x3()
    return (m.inverted() @ q.to_matrix() @ m).to_quaternion()


# Руки из A-позы опускаем ближе к телу во всех анимациях (угол вокруг Y: +L / -R).
ARMS_DOWN = 38.0


def pose(frame: int, bones: dict, hips_z: float = 0.0):
    for b in pb:
        rots = dict(bones.get(b.name, {}))
        if b.name == "upper_arm.L":
            rots["y"] = rots.get("y", 0.0) + ARMS_DOWN
        elif b.name == "upper_arm.R":
            rots["y"] = rots.get("y", 0.0) - ARMS_DOWN
        b.rotation_quaternion = local_rot(b.name, rots)
        b.keyframe_insert("rotation_quaternion", frame=frame)
    pb["hips"].location = (0.0, 0.0, 0.0)
    # Сдвиг таза вверх-вниз (в локальных осях кости hips ось Y смотрит вверх).
    pb["hips"].location = (0.0, hips_z, 0.0)
    pb["hips"].keyframe_insert("location", frame=frame)


def arms(l: dict, r: dict) -> dict:
    return {"upper_arm.L": l, "upper_arm.R": r}


def new_action(name: str):
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act
    return act


def finish(act, loop: bool):
    for fc in _fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = 'BEZIER'
            kp.easing = 'AUTO'
        if loop:
            fc.modifiers.new('CYCLES')
    # Модификаторы CYCLES экспортёр не переносит; цикличность задаётся в Godot.
    for fc in _fcurves(act):
        for m in list(fc.modifiers):
            fc.modifiers.remove(m)


def _fcurves(act):
    # Blender 4.4+: анимация в слотах/слоях; fcurves доступны через channelbag.
    if hasattr(act, "layers") and len(act.layers) > 0:
        out = []
        for layer in act.layers:
            for strip in layer.strips:
                for cb in strip.channelbags:
                    out.extend(cb.fcurves)
        return out
    return list(act.fcurves)


# idle: дыхание и лёгкое покачивание, 2 с.
act = new_action("idle")
for f, k in ((0, 0.0), (30, 1.0), (60, 0.0)):
    pose(f, {
        "spine": {"x": -1.5 * k},
        "chest": {"x": 2.0 * k},
        "head": {"x": -2.0 * k, "y": 1.5 * k},
        **arms({"x": 3 * k, "y": -2 * k}, {"x": 3 * k, "y": 2 * k}),
        "forearm.L": {"x": -8 - 4 * k}, "forearm.R": {"x": -8 - 4 * k},
    }, hips_z=-0.004 * k)
finish(act, True)

# walk: два шага за 0.8 с.
act = new_action("walk")
for ph in range(5):
    s = math.cos(ph * math.pi / 2)        # +1, 0, -1, 0, +1 — фаза ног
    lift = abs(math.sin(ph * math.pi / 2))  # в середине шага таз выше
    pose(ph * 6, {
        "thigh.L": {"x": -28 * s}, "thigh.R": {"x": 28 * s},
        "shin.L": {"x": 30 * max(0.0, s) + 10}, "shin.R": {"x": 30 * max(0.0, -s) + 10},
        "foot.L": {"x": -10 * s}, "foot.R": {"x": 10 * s},
        "hips": {"z": 6 * s},
        "chest": {"z": -8 * s, "x": -4},
        "head": {"z": 4 * s, "x": 2},
        **arms({"x": 28 * s}, {"x": -28 * s}),
        "forearm.L": {"x": -15 - 10 * max(0.0, -s)}, "forearm.R": {"x": -15 - 10 * max(0.0, s)},
    }, hips_z=0.018 * lift - 0.01)
finish(act, True)

# jump: толчок (ноги выпрямлены, руки идут вверх) -> подъём с поджатыми по-разному ногами.
act = new_action("jump")
pose(0, {"thigh.L": {"x": 8}, "thigh.R": {"x": 12}, "shin.L": {"x": 5}, "shin.R": {"x": 8},
         "foot.L": {"x": 25}, "foot.R": {"x": 25}, "chest": {"x": -4},
         **arms({"x": 20}, {"x": 20}), "forearm.L": {"x": -10}, "forearm.R": {"x": -10}})
pose(5, {"thigh.L": {"x": -45}, "thigh.R": {"x": -5}, "shin.L": {"x": 60}, "shin.R": {"x": 45},
         "foot.L": {"x": 10}, "foot.R": {"x": 20}, "chest": {"x": -8}, "head": {"x": -4},
         **arms({"x": -70, "y": -15}, {"x": -50, "y": 15}),
         "forearm.L": {"x": -30}, "forearm.R": {"x": -20}}, hips_z=0.01)
pose(10, {"thigh.L": {"x": -58}, "thigh.R": {"x": -12}, "shin.L": {"x": 88}, "shin.R": {"x": 65},
          "foot.L": {"x": 5}, "foot.R": {"x": 15}, "chest": {"x": -10}, "head": {"x": -6},
          **arms({"x": -95, "y": -25}, {"x": -70, "y": 25}),
          "forearm.L": {"x": -35}, "forearm.R": {"x": -25}}, hips_z=0.02)
finish(act, False)

# fall: ноги тянутся вниз к приземлению (одна чуть впереди), руки в стороны, лёгкое «болтание».
act = new_action("fall")
for f, k in ((0, 0.0), (9, 1.0), (18, 0.0)):
    pose(f, {"thigh.L": {"x": -22 + 4 * k}, "thigh.R": {"x": 2 - 4 * k},
             "shin.L": {"x": 28 - 4 * k}, "shin.R": {"x": 14 + 4 * k},
             "foot.L": {"x": -8}, "foot.R": {"x": 6},
             "chest": {"x": 3}, "head": {"x": 4},
             **arms({"y": -62 - 10 * k, "x": -10}, {"y": 62 + 10 * k, "x": -10}),
             "forearm.L": {"x": -15, "y": -10 * k}, "forearm.R": {"x": -15, "y": 10 * k}})
finish(act, True)

# happy: подпрыгивает и машет руками над головой, 0.8 с.
act = new_action("happy")
for f, k in ((0, 0.0), (6, 1.0), (12, 0.0), (18, 1.0), (24, 0.0)):
    pose(f, {"thigh.L": {"x": -10 * (1 - k)}, "thigh.R": {"x": -10 * (1 - k)},
             "shin.L": {"x": 20 * (1 - k)}, "shin.R": {"x": 20 * (1 - k)},
             "chest": {"x": -5}, "head": {"x": -8, "y": 6 * (k - 0.5)},
             **arms({"y": -120 + 20 * k}, {"y": 120 - 20 * k}),
             "forearm.L": {"y": -30 * k}, "forearm.R": {"y": 30 * k}},
         hips_z=0.03 * k - 0.015 * (1 - k))
finish(act, True)

# Покой: без активного действия, поза покоя — исходная.
rig.animation_data.action = bpy.data.actions["idle"]
bpy.ops.object.mode_set(mode='OBJECT')

for a in bpy.data.actions:
    print("ACTION", a.name, "frames", tuple(round(x) for x in a.frame_range))

bpy.ops.export_scene.gltf(
    filepath=DST, export_format='GLB', export_vertex_color='ACTIVE',
    export_animation_mode='ACTIONS', export_skins=True, export_def_bones=False,
    export_optimize_animation_size=False)
bpy.ops.wm.save_as_mainfile(filepath=DST.rsplit('.', 1)[0] + ".blend")
print("RESULT exported", DST)
