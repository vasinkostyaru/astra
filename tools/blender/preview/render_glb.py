import bpy, sys, math, mathutils
argv = sys.argv[sys.argv.index("--")+1:]
src, out = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:
    bb = [o.matrix_world @ mathutils.Vector(c) for c in o.bound_box]
    mn = [min(v[i] for v in bb) for i in range(3)]; mx = [max(v[i] for v in bb) for i in range(3)]
    print("MESH", o.name, "verts", len(o.data.vertices), "faces", len(o.data.polygons), "min", [round(x,3) for x in mn], "max", [round(x,3) for x in mx], "mats", [m.name for m in o.data.materials if m])
scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = sys.argv[-1] if sys.argv[-1] in ('VERTEX','MATERIAL','OBJECT','TEXTURE') else 'OBJECT'
scene.display.shading.show_cavity = False
scene.render.resolution_x = 800; scene.render.resolution_y = 800
scene.world = bpy.data.worlds.new("w")
cam_data = bpy.data.cameras.new("cam"); cam_data.type = 'ORTHO'
cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
o = meshes[0]
bb = [o.matrix_world @ mathutils.Vector(c) for c in o.bound_box]
center = sum(bb, mathutils.Vector()) / 8
size = max((max(v[i] for v in bb) - min(v[i] for v in bb)) for i in range(3))
cam_data.ortho_scale = size * 1.15
views = {"front": (0,-1,0), "back": (0,1,0), "side": (1,0,0), "three_q": (0.7,-0.7,0.2)}
for name, d in views.items():
    d = mathutils.Vector(d).normalized()
    cam.location = center + d * size * 3
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = f"{out}_{name}.png"
    bpy.ops.render.render(write_still=True)
