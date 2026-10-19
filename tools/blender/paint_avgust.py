"""Обработка сгенерированной модели Августа: облегчение, размер, покраска цветами вершин, глаза.

Запуск:
    blender -b --python tools/blender/paint_avgust.py -- <вход.glb> <выход.glb>

Модель из генератора: Z вверх, лицо смотрит в -Y. Зоны задаются в координатах исходной
модели (рост ~2 м, центр около нуля), поэтому их можно подстраивать по рендерам исходника.
"""
import sys
import math
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]

TARGET_FACES = 30000
TARGET_HEIGHT = 1.05

HAIR = (0.84, 0.68, 0.46)
SKIN = (1.00, 0.80, 0.68)
BLUSH = (1.00, 0.62, 0.58)
LIPS = (0.93, 0.58, 0.55)
SHIRT = (0.47, 0.70, 0.92)
BUTTON = (0.78, 0.64, 0.45)
SHORTS = (0.70, 0.62, 0.50)
SOCKS = (0.96, 0.95, 0.92)
SHOES = (0.55, 0.57, 0.61)
SOLE = (0.94, 0.92, 0.87)

# Ориентиры исходной модели (по рендерам): высоты по Z, полуширина рукава и т.п.
HEAD_CENTER = Vector((-0.01, 0.0, 0.55))
NECK_Z = 0.235          # выше — голова/шея (кожа или волосы)
SHIRT_BOTTOM_Z = -0.42
SHORTS_BOTTOM_Z = -0.62
SOCK_TOP_Z = -0.80
SHOE_TOP_Z = -0.835
SOLE_TOP_Z = -0.955
SLEEVE_X = 0.37         # дальше от центра по X в зоне футболки — голые руки
BODY_CX = -0.006


# Ось руки в A-позе (в плоскости XZ, для правой руки; для левой — зеркально по X).
ARM_SHOULDER = Vector((0.25, 0.17))
ARM_DIR = Vector((0.60, -0.80))
ARM_PERP = Vector((0.80, 0.60))
SLEEVE_HEM_T = 0.29     # дальше по оси руки — голая кожа
BUTTON_POS = Vector((BODY_CX, -0.21, 0.045))


# Линия волос по кругу головы: высота нижнего края «бугристой» зоны (вылепленных прядей)
# в каждом секторе азимута. Заполняется в build_hairline() по исходной плотной сетке.
SECTORS = 36
HAIRLINE = [0.7] * SECTORS
EAR_TOP_Z = 0.55        # верх уха (в координатах исходной модели)
TEMPLE_Z = 0.57         # на висках волосы до верха уха
NAPE_Z = 0.36           # сзади волосы опускаются до шеи (там прядей в форме нет)
HAIR_BUMP = 0.05        # порог бугристости прядей
HAIR_MARGIN = 0.015     # чуть ниже края прядей, чтобы покрыть их основание


def sector_of(p: Vector) -> float:
    a = math.atan2(p.y - HEAD_CENTER.y, p.x - HEAD_CENTER.x)
    return (a / (2 * math.pi) % 1.0) * SECTORS


def hairline_z(p: Vector) -> float:
    f = sector_of(p)
    i = int(f) % SECTORS
    t = f - int(f)
    return HAIRLINE[i] * (1 - t) + HAIRLINE[(i + 1) % SECTORS] * t


def build_hairline(bm) -> None:
    """Бугристость = отклонение вершины от среднего соседей по нормали (сглаженное)."""
    bm.verts.ensure_lookup_table()
    bm.normal_update()
    n = len(bm.verts)
    bump = [0.0] * n
    for v in bm.verts:
        if not v.link_edges:
            continue
        avg = sum((e.other_vert(v).co for e in v.link_edges), Vector()) / len(v.link_edges)
        el = sum(e.calc_length() for e in v.link_edges) / len(v.link_edges)
        bump[v.index] = abs((v.co - avg).dot(v.normal)) / max(el, 1e-6)
    nbrs = [[e.other_vert(v).index for e in v.link_edges] for v in bm.verts]
    for _ in range(12):
        bump = [(bump[i] + sum(bump[j] for j in nbrs[i]) / max(len(nbrs[i]), 1)) * 0.5 for i in range(n)]
    lows = [[] for _ in range(SECTORS)]
    for v in bm.verts:
        # Только верх головы (ниже — уши, они тоже «бугристые»).
        if v.co.z > 0.62 and bump[v.index] > HAIR_BUMP:
            lows[int(sector_of(v.co)) % SECTORS].append(v.co.z)
    raw = []
    for zs in lows:
        zs.sort()
        raw.append(zs[int(len(zs) * 0.1)] if len(zs) >= 5 else None)
    known = [z for z in raw if z is not None]
    fill = max(known) if known else 0.7
    raw = [z if z is not None else fill for z in raw]
    # Сглаживание по кругу.
    for _ in range(3):
        raw = [(raw[i - 1] + 2 * raw[i] + raw[(i + 1) % SECTORS]) / 4 for i in range(SECTORS)]
    for i in range(SECTORS):
        a = (i + 0.5) / SECTORS * 2 * math.pi
        fwd = -math.sin(a)  # +1 — лицо (-Y), -1 — затылок
        # Спереди — по вылепленной чёлке, по бокам — ровно по верху уха, сзади — до шеи.
        front_w = min(1.0, max(0.0, (fwd - 0.78) / 0.17))
        z = (raw[i] - HAIR_MARGIN) * front_w + TEMPLE_Z * (1.0 - front_w)
        back_w = min(1.0, max(0.0, (-fwd - 0.2) / 0.5))
        z = z + (NAPE_Z - z) * back_w
        HAIRLINE[i] = z
    print("HAIRLINE", [round(z, 2) for z in HAIRLINE])


def classify(p: Vector, n: Vector) -> tuple:
    x = p.x - BODY_CX
    if p.z > NECK_Z:
        d = (p - HEAD_CENTER).normalized()
        is_ear = abs(x) > 0.2 and 0.33 < p.z < EAR_TOP_Z and d.y > -0.35 and d.y < 0.35
        if not is_ear and p.z > hairline_z(p):
            return HAIR
        return SKIN
    if p.z > SHIRT_BOTTOM_Z:
        a = Vector((abs(x), p.z)) - ARM_SHOULDER
        if abs(a.dot(ARM_PERP)) < 0.12 and a.dot(ARM_DIR) > SLEEVE_HEM_T:
            return SKIN
        if (p - BUTTON_POS).length < 0.022:
            return BUTTON
        return SHIRT
    if p.z > SHORTS_BOTTOM_Z:
        return SHORTS
    if p.z > SOCK_TOP_Z:
        return SKIN
    if p.z > SHOE_TOP_Z:
        return SOCKS
    if p.z > SOLE_TOP_Z:
        return SHOES
    return SOLE


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
body = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Дерево для поиска поверхности (глаза) — по исходной, плотной сетке.
bm_src = bmesh.new()
bm_src.from_mesh(body.data)
bvh = BVHTree.FromBMesh(bm_src)
build_hairline(bm_src)

# 1. Облегчение.
dec = body.modifiers.new("dec", 'DECIMATE')
dec.ratio = TARGET_FACES / max(len(body.data.polygons), 1)
bpy.ops.object.modifier_apply(modifier=dec.name)
bpy.ops.object.shade_smooth()

# 2. Покраска: цвет на грань (чёткие границы), румянец и губы — мягко по углам граней.
me = body.data
attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
cheek_l = Vector((BODY_CX - 0.13, -0.27, 0.43))
cheek_r = Vector((BODY_CX + 0.11, -0.27, 0.43))
lips = Vector((BODY_CX - 0.005, -0.30, 0.375))
for poly in me.polygons:
    base = classify(poly.center, poly.normal)
    for li in poly.loop_indices:
        col = base
        if base == SKIN and poly.center.z > NECK_Z:
            v = me.vertices[me.loops[li].vertex_index].co
            for ch in (cheek_l, cheek_r):
                t = max(0.0, 1.0 - (v - ch).length / 0.09)
                col = mix(col, BLUSH, t * 0.7)
            dl = Vector(((v.x - lips.x) / 0.05, (v.y - lips.y) / 0.05, (v.z - lips.z) / 0.022)).length
            if dl < 1.0:
                col = mix(col, LIPS, min(1.0, (1.0 - dl) * 2.0) * 0.8)
        attr.data[li].color = (*col, 1.0)

mat = bpy.data.materials.new("avgust")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
vc = nt.nodes.new("ShaderNodeVertexColor")
vc.layer_name = "Col"
nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.75
me.materials.append(mat)

# 3. Глаза: белок, радужка, зрачок, блик — сплющенные сферы на поверхности лица.
EYES = [Vector((BODY_CX - 0.103, 0.0, 0.515)), Vector((BODY_CX + 0.088, 0.0, 0.515))]
EYE_R = 0.052


def add_sphere(name, center, radius, flat, color, normal):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0, location=center)
    o = bpy.context.active_object
    o.name = name
    o.scale = (radius, radius * flat, radius)
    # Повернуть так, чтобы «плоская» ось смотрела по нормали лица.
    o.rotation_euler = normal.to_track_quat('-Y', 'Z').to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.shade_smooth()
    m = o.data
    a = m.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
    for d in a.data:
        d.color = (*color, 1.0)
    m.materials.append(mat)
    return o


parts = [body]
for e in EYES:
    loc, nrm, _, _ = bvh.ray_cast(Vector((e.x, -2.0, e.z)), Vector((0, 1, 0)))
    surf = loc
    n = Vector((nrm.x * 0.5, -1.0, nrm.z * 0.3)).normalized()
    parts.append(add_sphere("sclera", surf + n * 0.002, EYE_R, 0.30, (0.97, 0.97, 0.97), n))
    parts.append(add_sphere("iris", surf + n * 0.012, EYE_R * 0.82, 0.22, (0.56, 0.64, 0.70), n))
    parts.append(add_sphere("pupil", surf + n * 0.017, EYE_R * 0.36, 0.18, (0.05, 0.05, 0.07), n))
    hl = surf + n * 0.022 + Vector((0.018, 0, 0.020))
    parts.append(add_sphere("highlight", hl, EYE_R * 0.20, 0.4, (1.0, 1.0, 1.0), n))

bpy.ops.object.select_all(action='DESELECT')
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
body.name = "Avgust"

# 4. Размер и положение: ноги в нуле, рост TARGET_HEIGHT.
zs = [v.co.z for v in body.data.vertices]
xs = [v.co.x for v in body.data.vertices]
ys = [v.co.y for v in body.data.vertices]
h = max(zs) - min(zs)
s = TARGET_HEIGHT / h
off = Vector((-(max(xs) + min(xs)) / 2, -(max(ys) + min(ys)) / 2, -min(zs)))
for v in body.data.vertices:
    v.co = (v.co + off) * s

print("RESULT faces", len(body.data.polygons), "verts", len(body.data.vertices), "height", round(TARGET_HEIGHT, 3))
bpy.ops.export_scene.gltf(filepath=DST, export_format='GLB', use_selection=False, export_vertex_color='ACTIVE')
bpy.ops.wm.save_as_mainfile(filepath=DST.rsplit('.', 1)[0] + ".blend")
