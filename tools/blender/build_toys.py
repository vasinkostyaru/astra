"""Игрушки для ванной: лебедь, уточка, машинка, кораблик. Гладкие скруглённые формы.
Запуск: blender -b -P tools/blender/build_toys.py  -> assets/models/toys/*.glb
Оси как в floating_toy.gd (носом к +X, Y вверх в Godot)."""
import bpy, bmesh, math, os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "models", "toys")

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, rgb, rough=0.55, glow=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    if glow:  # лёгкое свечение, чтобы тёплый свет не желтил белое
        b.inputs["Emission Color"].default_value = (*rgb, 1)
        b.inputs["Emission Strength"].default_value = glow
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    return m

def ball(loc, r, m, name="b"):
    # Blender: X вперёд, Y вбок, Z вверх. r = (x, y, z) радиусы.
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=loc)
    o = bpy.context.object
    o.scale = r
    bpy.ops.object.shade_smooth()
    o.data.materials.append(m)
    return o

def rbox(loc, size, m, bevel=0.08):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object
    o.scale = (size[0]/2, size[1]/2, size[2]/2)
    bpy.ops.object.transform_apply(scale=True)
    bv = o.modifiers.new("bv", "BEVEL"); bv.width = bevel; bv.segments = 5
    ss = o.modifiers.new("ss", "SUBSURF"); ss.levels = 1
    bpy.ops.object.shade_smooth()
    o.data.materials.append(m)
    return o

def cyl(loc, r, depth, m, rot=(math.pi/2, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    bv = o.modifiers.new("bv", "BEVEL"); bv.width = r*0.2; bv.segments = 4
    bpy.ops.object.shade_smooth()
    o.data.materials.append(m)
    return o

def export(name):
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            bpy.context.view_layer.objects.active = o
            for mod in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", export_yup=True)

def swan():
    reset()
    w = mat("white", (1.0, 1.0, 1.0), 0.35, 0.45); o = mat("beak", (1, 0.6, 0.15)); k = mat("eye", (0.05, 0.05, 0.05))
    ball((0, 0, -0.1), (1.15, 0.62, 0.3), w)
    ball((0.35, 0, 0.08), (0.55, 0.52, 0.26), w)
    # шея изогнута: цепочка шаров
    for i, (x, z, r) in enumerate([(0.8, 0.15, 0.3), (0.95, 0.42, 0.25), (1.0, 0.72, 0.22), (1.0, 0.98, 0.2)]):
        ball((x, 0, z), (r, r, r*1.15), w)
    ball((1.08, 0, 1.12), (0.27, 0.22, 0.22), w)
    ball((1.32, 0, 1.08), (0.17, 0.08, 0.06), o)
    for s in (-1, 1):
        ball((1.2, s*0.17, 1.17), (0.05, 0.04, 0.05), k)
    ball((-1.0, 0, 0.1), (0.3, 0.25, 0.2), w)
    export("swan")

def duck():
    reset()
    y = mat("yellow", (1, 0.85, 0.15), 0.35); o = mat("beak", (1, 0.5, 0.1)); k = mat("eye", (0.05, 0.05, 0.05))
    ball((0, 0, -0.08), (1.05, 0.62, 0.3), y)
    ball((0.75, 0, 0.45), (0.4, 0.38, 0.4), y)
    ball((1.12, 0, 0.4), (0.2, 0.14, 0.08), o)
    for s in (-1, 1):
        ball((0.95, s*0.2, 0.58), (0.05, 0.05, 0.05), k)
    ball((-0.85, 0, 0.18), (0.32, 0.2, 0.28), y)
    ball((0.0, 0, 0.1), (0.5, 0.55, 0.22), y)
    export("duck")

def car():
    reset()
    r = mat("red", (0.88, 0.18, 0.18), 0.3); r2 = mat("red2", (0.95, 0.3, 0.3), 0.3)
    g = mat("glass", (0.7, 0.9, 1.0), 0.1); t = mat("tire", (0.1, 0.1, 0.1), 0.8); h = mat("hub", (0.85, 0.85, 0.88), 0.4)
    y = mat("lamp", (1, 0.9, 0.4), 0.3)
    rbox((0, 0, -0.1), (2.1, 1.4, 0.3), r, 0.12)
    rbox((-0.3, 0, 0.35), (1.0, 1.2, 0.45), r2, 0.15)
    rbox((-0.3, 0.605, 0.37), (0.75, 0.02, 0.3), g, 0.01)
    rbox((-0.3, -0.605, 0.37), (0.75, 0.02, 0.3), g, 0.01)
    for wx in (-0.65, 0.65):
        for s in (-1, 1):
            cyl((wx, s*0.72, -0.28), 0.3, 0.14, t)
            cyl((wx, s*0.8, -0.28), 0.12, 0.04, h)
    for s in (-1, 1):
        ball((1.05, s*0.45, -0.08), (0.06, 0.12, 0.1), y)
    export("car")

def boat():
    reset()
    b = mat("blue", (0.2, 0.5, 0.95), 0.35); d = mat("dark", (0.16, 0.4, 0.8), 0.4)
    wd = mat("wood", (0.6, 0.4, 0.2), 0.6); sail = mat("sail", (0.98, 0.95, 0.9), 0.7)
    rbox((0, 0, -0.1), (2.15, 1.2, 0.3), b, 0.12)
    rbox((0, 0, -0.22), (1.6, 1.0, 0.22), d, 0.1)
    cyl((-0.2, 0, 0.7), 0.04, 1.2, wd, (0, 0, 0))
    rbox((0.15, 0, 0.85), (0.7, 0.03, 0.8), sail, 0.02)
    export("boat")

os.makedirs(OUT, exist_ok=True)
swan(); duck(); car(); boat()
