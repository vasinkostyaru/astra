"""Астра: мультяшная, но похожая на настоящую трёхцветную кошку. Покраска цветами вершин.

Запуск:
    blender -b --python tools/blender/build_astra.py -- <выход.blend>

Тело — модификатор Skin по анатомическому каркасу (astra_shape.py): плавные переходы груди,
талии, бёдер и лап без «трубочек». Голова — череп, широкие щёки, подушечки для усов, подбородок,
большие треугольные уши. Всё сливается вокселями в одну гладкую сетку.
Окраска по фото: белые грудка, низ морды, полоска на носу, живот и лапки; на спине, голове
и хвосте — пятна серого и рыжего.
"""
import os
import sys
import math
import bpy
import bmesh
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import astra_shape as A  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
DST = argv[0]

WHITE = (0.96, 0.95, 0.92)
GREY = (0.50, 0.51, 0.54)
GINGER = (0.92, 0.64, 0.40)
PINK = (0.97, 0.68, 0.70)
NOSE = (0.90, 0.52, 0.58)
EYE_IRIS = (0.63, 0.72, 0.30)
DARK = (0.06, 0.05, 0.05)

HEAD_C = Vector(A.HEAD_C)
TARGET_FACES = 18000
EARS = [HEAD_C + Vector((sx * A.EAR_X, A.EAR_DY, A.EAR_DZ)) * 1.18 for sx in (1, -1)]

bpy.ops.wm.read_factory_settings(use_empty=True)
parts = []

# --- Тело: каркас для модификатора Skin ---
verts, radii, edges = [], [], []


def add_chain(points, start_from=None):
    prev = start_from
    for p, rx, rz in points:
        verts.append(p)
        radii.append((rx, rz))
        i = len(verts) - 1
        if prev is not None:
            edges.append((prev, i))
        prev = i
    return prev


add_chain(list(reversed(A.SPINE)))                      # от шеи к крестцу
spine_idx = {k: len(A.SPINE) - 1 - k for k in range(len(A.SPINE))}
add_chain([(p, r, r) for p, r in A.TAIL], spine_idx[0])
for side in (1, -1):
    add_chain([((p[0] * side, p[1], p[2]), r, r) for p, r in A.FRONT_LEG], spine_idx[A.FRONT_ROOT])
    add_chain([((p[0] * side, p[1], p[2]), r, r) for p, r in A.HIND_LEG], spine_idx[A.HIND_ROOT])

me = bpy.data.meshes.new("skeleton")
me.from_pydata(verts, edges, [])
body = bpy.data.objects.new("Body", me)
bpy.context.scene.collection.objects.link(body)
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.modifier_add(type='SKIN')
for i, (rx, rz) in enumerate(radii):
    sv = me.skin_vertices[0].data[i]
    sv.radius = (rx, rz)
    sv.use_root = (i == 0)
sub = body.modifiers.new("sub", 'SUBSURF')
sub.levels = 2
bpy.ops.object.convert(target='MESH')
parts.append(body)


def ellipsoid(c, r, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1.0, location=c, rotation=rot)
    o = bpy.context.active_object
    o.scale = r
    parts.append(o)


# --- Голова ---
HEAD_SCALE = 1.18   # голова чуть крупнее реальной — мультяшность


def head_part(off, r):
    ellipsoid(HEAD_C + Vector(off) * HEAD_SCALE, tuple(x * HEAD_SCALE for x in r))


head_part((0, 0, 0), (0.074, 0.068, 0.063))                        # череп
head_part((0, 0.005, 0.030), (0.060, 0.055, 0.040))                # лоб (плоский сверху)
for sx in (1, -1):
    head_part((sx * 0.040, -0.023, -0.023), (0.046, 0.040, 0.036))  # щёки
    head_part((sx * 0.016, -0.055, -0.028), (0.021, 0.019, 0.017))  # подушечки для усов
head_part((0, -0.048, -0.046), (0.017, 0.016, 0.013))              # подбородок
head_part((0, -0.043, -0.003), (0.016, 0.030, 0.016))              # переносица
for ear, sx in zip(EARS, (1, -1)):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.047, radius2=0.003, depth=0.078, location=ear,
                                    rotation=(math.radians(-12), math.radians(sx * 24), 0))
    o = bpy.context.active_object
    o.scale = (1.0, 0.42, 1.0)
    parts.append(o)

bpy.ops.object.select_all(action='DESELECT')
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.join()
cat = bpy.context.active_object
cat.name = "Astra"

rem = cat.modifiers.new("remesh", 'REMESH')
rem.mode = 'VOXEL'
rem.voxel_size = 0.0035
bpy.ops.object.modifier_apply(modifier=rem.name)
sm = cat.modifiers.new("smooth", 'SMOOTH')
sm.factor = 0.6
sm.iterations = 8
bpy.ops.object.modifier_apply(modifier=sm.name)
dec = cat.modifiers.new("dec", 'DECIMATE')
dec.ratio = TARGET_FACES / max(len(cat.data.polygons), 1)
bpy.ops.object.modifier_apply(modifier=dec.name)
bpy.ops.object.shade_smooth()


# --- Окраска ---
def n3(p, scale, seed):
    return noise.noise(Vector((p.x * scale + seed, p.y * scale + seed * 2, p.z * scale - seed)))


def color_at(p: Vector, n: Vector):
    wob = 0.02 * n3(p, 10, 3.1)
    d = p - HEAD_C
    if d.length < 0.12 and p.y < -0.22:
        for ear in EARS:
            if p.z > ear.z - 0.022 and (Vector((p.x - ear.x, p.y - ear.y, 0))).length < 0.035 and n.y < -0.25:
                return PINK
        dn = d.normalized()
        if dn.z < -0.05 + wob * 3 and dn.y < -0.3:
            return WHITE          # низ морды, подбородок
        if abs(p.x) < 0.014 + wob * 0.5 and dn.y < -0.5 and dn.z < 0.65:
            return WHITE          # полоска по носу
    else:
        if p.z < 0.145 + wob:
            return WHITE          # лапки и живот
        if p.y < -0.09 and n.y < -0.2 and p.z < 0.30 + wob:
            return WHITE          # грудка
        if n.z < -0.5:
            return WHITE          # живот снизу
    return GINGER if n3(p, 7.0, 0.7) + 0.35 * n3(p, 16.0, 5.3) > 0.12 else GREY


me = cat.data
attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
for poly in me.polygons:
    col = color_at(poly.center, poly.normal)
    for li in poly.loop_indices:
        attr.data[li].color = (*col, 1.0)

mat = bpy.data.materials.new("astra")
mat.use_nodes = True
nt = mat.node_tree
vc = nt.nodes.new("ShaderNodeVertexColor")
vc.layer_name = "Col"
nt.links.new(vc.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.85
me.materials.append(mat)

# --- Глаза, нос, усы ---
bm = bmesh.new()
bm.from_mesh(me)
bvh = BVHTree.FromBMesh(bm)
extra = []


def paint(o, color, group=None):
    bpy.ops.object.shade_smooth()
    a = o.data.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
    for dd in a.data:
        dd.color = (*color, 1.0)
    o.data.materials.append(mat)
    if group:
        o.vertex_groups.new(name=group).add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
    extra.append(o)


def add_part(center, size, normal, color, group=None):
    """Сфера размером size=(ширина, толщина по нормали, высота), развёрнутая по нормали лица."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0, location=center)
    o = bpy.context.active_object
    o.scale = size
    o.rotation_euler = normal.to_track_quat('-Y', 'Z').to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    paint(o, color, group)


def add_closed_eye(center, normal, group):
    """Закрытый глаз «‿»: нижняя половина тонкого тора; виден только во сне (кость глаза)."""
    bpy.ops.mesh.primitive_torus_add(major_radius=0.016, minor_radius=0.0032, major_segments=24, minor_segments=8,
                                     location=(0, 0, 0), rotation=(math.radians(90), 0, 0))
    o = bpy.context.active_object
    bpy.ops.object.transform_apply(rotation=True)
    bm2 = bmesh.new()
    bm2.from_mesh(o.data)
    bmesh.ops.delete(bm2, geom=[v for v in bm2.verts if v.co.z > 0.003], context='VERTS')
    bm2.to_mesh(o.data)
    bm2.free()
    o.rotation_euler = normal.to_track_quat('-Y', 'Z').to_euler()
    o.location = center
    bpy.ops.object.transform_apply(location=True, rotation=True)
    paint(o, DARK, group)


def add_whisker(a, b):
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.0012, depth=d.length, location=(a + b) / 2)
    o = bpy.context.active_object
    o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True)
    paint(o, (0.95, 0.94, 0.90))


EYE_R = 0.020
for sx in (1, -1):
    side = "L" if sx > 0 else "R"
    loc, nrm, _, _ = bvh.ray_cast(Vector((sx * A.EYE_X * 1.18, -1.0, HEAD_C.z + A.EYE_DZ * 1.18)), Vector((0, 1, 0)))
    nn = Vector((nrm.x * 0.5 + sx * 0.25, -1.0, nrm.z * 0.3)).normalized()
    g = f"mark_eye_open.{side}"
    # Миндалевидный глаз, почти весь — радужка, зрачок вертикальный.
    add_part(loc + nn * 0.001, (EYE_R * 1.25, EYE_R * 0.35, EYE_R * 0.95), nn, (0.96, 0.96, 0.92), g)
    add_part(loc + nn * 0.005, (EYE_R * 1.08, EYE_R * 0.28, EYE_R * 0.86), nn, EYE_IRIS, g)
    add_part(loc + nn * 0.008, (EYE_R * 0.32, EYE_R * 0.22, EYE_R * 0.78), nn, DARK, g)
    add_part(loc + nn * 0.011 + Vector((sx * 0.004, 0, 0.006)), (EYE_R * 0.22,) * 3, nn, (1, 1, 1), g)
    add_closed_eye(loc + nn * 0.003, nn, f"mark_eye_closed.{side}")
    # Усы: по три с каждой стороны от подушечек.
    for dz in (0.006, 0.0, -0.006):
        wz = HEAD_C.z - 0.032
        add_whisker((sx * 0.030, HEAD_C.y - 0.072, wz + dz), (sx * 0.110, HEAD_C.y - 0.088, wz + dz * 3.5))
loc, nrm, _, _ = bvh.ray_cast(Vector((0, -1.0, HEAD_C.z - 0.014)), Vector((0, 1, 0)))
add_part(loc + Vector((0, -0.002, 0)), (0.012, 0.007, 0.008), Vector((0, -1, 0.4)).normalized(), NOSE)

bpy.ops.object.select_all(action='DESELECT')
for o in extra:
    o.select_set(True)
cat.select_set(True)
bpy.context.view_layer.objects.active = cat
bpy.ops.object.join()

print("RESULT faces", len(cat.data.polygons), "verts", len(cat.data.vertices))
bpy.ops.wm.save_as_mainfile(filepath=DST)
