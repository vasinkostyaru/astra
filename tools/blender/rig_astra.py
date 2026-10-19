"""Скелет и анимации Астры: idle, run, sleep.

Запуск:
    blender -b --python tools/blender/rig_astra.py -- <astra.blend> <выход.glb>

Повороты в осях арматуры (градусы): X — вбок (кивок/взмах лапой вперёд-назад),
Y — вперёд (крен), Z — вверх (поворот влево-вправо). Морда смотрит в -Y.
"""
import os
import sys
import math
import bpy
from mathutils import Vector, Quaternion

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
FPS = 30

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import astra_shape as S  # noqa: E402

TAIL = [p for p, _ in S.TAIL]
SP = [p for p, _, _ in S.SPINE]          # крестец ... шея у головы, внутрь черепа
FL = [p for p, _ in S.FRONT_LEG]
HL = [p for p, _ in S.HIND_LEG]
HC = S.HEAD_C

BONES = {
    "hips": (SP[1], SP[2], None),
    "spine": (SP[2], SP[4], "hips"),
    "neck": (SP[4], SP[6], "spine"),
    "head": (SP[6], (HC[0], HC[1] - 0.03, HC[2] + 0.12), "neck"),
    "front_upper.L": (FL[0], FL[1], "spine"),
    "front_lower.L": (FL[1], FL[2], "front_upper.L"),
    "front_paw.L": (FL[2], (FL[3][0], FL[3][1] - 0.03, FL[3][2]), "front_lower.L"),
    "back_thigh.L": (HL[0], HL[1], "hips"),
    "back_shin.L": (HL[1], HL[2], "back_thigh.L"),
    "back_foot.L": (HL[2], HL[3], "back_shin.L"),
    "back_paw.L": (HL[3], (HL[4][0], HL[4][1] - 0.03, HL[4][2]), "back_foot.L"),
}
for i in range(len(TAIL) - 1):
    BONES[f"tail{i}"] = (TAIL[i], TAIL[i + 1], "hips" if i == 0 else f"tail{i - 1}")


def group_center(obj, name):
    gi = obj.vertex_groups[name].index
    pts = [v.co for v in obj.data.vertices if any(g.group == gi for g in v.groups)]
    return sum(pts, Vector()) / len(pts)


def mirror(name):
    return name.replace(".L", ".R")


bpy.ops.wm.open_mainfile(filepath=SRC)
scene = bpy.context.scene
scene.render.fps = FPS
cat = bpy.data.objects["Astra"]

EYE_GROUPS = ("eye_open.L", "eye_open.R", "eye_closed.L", "eye_closed.R")
for g in EYE_GROUPS:
    c = group_center(cat, "mark_" + g)
    BONES_EXTRA = BONES.setdefault("_eyes", {})
    BONES_EXTRA[g] = (tuple(c), tuple(c + Vector((0, -0.02, 0))), "head")
eye_bones = BONES.pop("_eyes")

arm_data = bpy.data.armatures.new("AstraRig")
rig = bpy.data.objects.new("AstraRig", arm_data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
all_bones = {}
for name, (h, t, parent) in BONES.items():
    all_bones[name] = (h, t, parent)
    if name.endswith(".L"):
        all_bones[mirror(name)] = ((-h[0], h[1], h[2]), (-t[0], t[1], t[2]),
                                   mirror(parent) if parent and parent.endswith(".L") else parent)
all_bones.update(eye_bones)
eb = arm_data.edit_bones
for name, (h, t, _) in all_bones.items():
    b = eb.new(name)
    b.head, b.tail, b.roll = h, t, 0.0
for name, (h, _, parent) in all_bones.items():
    if parent:
        eb[name].parent = eb[parent]
        eb[name].use_connect = (Vector(eb[parent].tail) - Vector(h)).length < 1e-4
bpy.ops.object.mode_set(mode='OBJECT')

bpy.ops.object.select_all(action='DESELECT')
cat.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
weighted = sum(1 for v in cat.data.vertices if any(g.weight > 0.01 for g in v.groups))
print("SKIN auto weighted", weighted, "of", len(cat.data.vertices))

segs = {n: (Vector(h), Vector(t)) for n, (h, t, _) in all_bones.items() if not n.startswith("eye_")}
vgs = {n: (cat.vertex_groups.get(n) or cat.vertex_groups.new(name=n)) for n in segs}
HEAD_C = Vector(S.HEAD_C)
# Детали глаз (метки mark_eye_* из build_astra.py) — целиком к своим костям глаз.
mark_to_bone = {cat.vertex_groups["mark_" + g].index: g for g in EYE_GROUPS}
for v in cat.data.vertices:
    p = v.co
    own = [mark_to_bone[g.group] for g in v.groups if g.group in mark_to_bone and g.weight > 0.5]
    if own:
        for g in list(v.groups):
            cat.vertex_groups[g.group].remove([v.index])
        vgs_eye = cat.vertex_groups.get(own[0]) or cat.vertex_groups.new(name=own[0])
        vgs_eye.add([v.index], 1.0, 'REPLACE')
        continue
    # Голова (с ушами, глазами, носом) — жёстко к кости head.
    if (p - HEAD_C).length < 0.10 or (p.z > HEAD_C.z + 0.05 and p.y < -0.22):
        for g in list(v.groups):
            cat.vertex_groups[g.group].remove([v.index])
        vgs["head"].add([v.index], 1.0, 'REPLACE')
        continue
    if any(g.weight > 0.01 for g in v.groups):
        continue
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
bpy.context.view_layer.objects.active = cat
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


def local_rot(name, rots):
    q = Quaternion()
    for ax, deg in rots.items():
        q = Quaternion(AXES[ax], math.radians(deg)) @ q
    m = rig.data.bones[name].matrix_local.to_3x3()
    return (m.inverted() @ q.to_matrix() @ m).to_quaternion()


def pose(frame, bones, lift=(0.0, 0.0, 0.0), asleep=False):
    for b in pb:
        if b.name.startswith("eye_"):
            visible = b.name.startswith("eye_closed") == asleep
            b.scale = (1, 1, 1) if visible else (0.001, 0.001, 0.001)
            b.keyframe_insert("scale", frame=frame)
        b.rotation_quaternion = local_rot(b.name, bones.get(b.name, {}))
        b.keyframe_insert("rotation_quaternion", frame=frame)
    # Сдвиг всего тела: в осях арматуры -> в локальные оси кости hips.
    m = rig.data.bones["hips"].matrix_local.to_3x3()
    pb["hips"].location = m.inverted() @ Vector(lift)
    pb["hips"].keyframe_insert("location", frame=frame)


def new_action(name):
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act


def tail(curl_x, sway_z):
    """Хвост: изгиб вверх/вниз (x) и покачивание вбок (z), нарастающие к кончику."""
    return {f"tail{i}": {"x": curl_x * (0.5 + 0.25 * i), "z": sway_z * (0.4 + 0.3 * i)} for i in range(len(TAIL) - 1)}


# idle: дыхание, хвост медленно покачивается, голова оглядывается. 3 с.
new_action("idle")
for f, k in ((0, 0.0), (22, 1.0), (45, 0.0), (67, -1.0), (90, 0.0)):
    b = abs(k)
    pose(f, {"spine": {"x": 1.5 * b}, "neck": {"x": -2 * b}, "head": {"z": 10 * k, "y": -4 * k},
             **tail(4 * b, 12 * k)}, lift=(0, 0, 0.004 * b))

# run: рысь — диагональные пары лап, тело покачивается, хвост развевается. 0.5 с.
new_action("run")
for ph in range(5):
    s = math.cos(ph * math.pi / 2)
    up = abs(math.sin(ph * math.pi / 2))
    pose(ph * 4, {
        "front_upper.L": {"x": -32 * s}, "front_upper.R": {"x": 32 * s},
        "front_lower.L": {"x": 30 * max(0, -s)}, "front_lower.R": {"x": 30 * max(0, s)},
        "back_thigh.L": {"x": 30 * s}, "back_thigh.R": {"x": -30 * s},
        "back_shin.L": {"x": -25 * max(0, s)}, "back_shin.R": {"x": -25 * max(0, -s)},
        "spine": {"x": 4 * s}, "neck": {"x": -6 * up}, "head": {"x": 5 * s},
        **tail(-10 + 6 * s, 8 * s),
    }, lift=(0, 0, 0.022 * up))

# Путь хвоста во сне: лежит на полу и обвивает правый бок к морде (точки в осях арматуры).
SLEEP_TAIL_PATH = [(0.0, 0.22), (0.07, 0.29), (0.16, 0.26), (0.21, 0.16), (0.22, 0.04), (0.19, -0.08), (0.13, -0.17)]


def lay_tail(frame, z=0.04):
    """Каждое звено хвоста направляем вдоль пути; Blender сам считает локальные повороты."""
    for i in range(len(TAIL) - 1):
        bpy.context.view_layer.update()
        b = pb[f"tail{i}"]
        a0, a1 = SLEEP_TAIL_PATH[i], SLEEP_TAIL_PATH[i + 1]
        want = Vector((a1[0] - a0[0], a1[1] - a0[1], -0.02 if i == 0 else 0.0)).normalized()
        cur = (b.matrix.to_3x3() @ Vector((0, 1, 0))).normalized()
        q = cur.rotation_difference(want)
        m = b.matrix.copy()
        loc = m.translation.copy()
        m = q.to_matrix().to_4x4() @ m
        m.translation = loc
        b.matrix = m
        bpy.context.view_layer.update()
        b.keyframe_insert("rotation_quaternion", frame=frame)


# sleep: лежит калачиком — лапки поджаты, голова на передних лапах, хвост обвивает бок, глаза закрыты.
new_action("sleep")
for f, k in ((0, 0.0), (45, 1.0), (90, 0.0)):
    pose(f, {
        "spine": {"z": 12, "x": 2 * k},
        "neck": {"x": 38, "z": 18},
        "head": {"x": 8, "z": 14, "y": 12},
        "front_upper.L": {"x": -85}, "front_upper.R": {"x": -80},
        "front_lower.L": {"x": 5}, "front_lower.R": {"x": 10},
        "front_paw.L": {"x": 10}, "front_paw.R": {"x": 10},
        "back_thigh.L": {"x": -55}, "back_thigh.R": {"x": -50},
        "back_shin.L": {"x": -75}, "back_shin.R": {"x": -70},
        "back_paw.L": {"x": 40}, "back_paw.R": {"x": 40},
    }, lift=(0, 0, -0.10 + 0.003 * k), asleep=True)
    bpy.context.scene.frame_set(f)
    lay_tail(f)

rig.animation_data.action = bpy.data.actions["idle"]
bpy.ops.object.mode_set(mode='OBJECT')
for a in bpy.data.actions:
    print("ACTION", a.name, tuple(round(x) for x in a.frame_range))

bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', export_vertex_color='ACTIVE',
                          export_animation_mode='ACTIONS', export_skins=True, export_def_bones=False)
bpy.ops.wm.save_as_mainfile(filepath=DST.rsplit('.', 1)[0] + ".blend")
print("RESULT exported", DST)
