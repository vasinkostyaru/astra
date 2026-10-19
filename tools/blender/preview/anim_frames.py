import bpy, sys, mathutils
argv = sys.argv[sys.argv.index("--")+1:]
out = argv[0]
scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'VERTEX'
scene.render.resolution_x = 360; scene.render.resolution_y = 420
cam_data = bpy.data.cameras.new("cam"); cam_data.type = 'ORTHO'; cam_data.ortho_scale = float(__import__("os").environ.get("OSCALE", "1.45"))
cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
rig = bpy.data.objects[__import__("os").environ.get("RIG", "AvgustRig")]
views = {"side": (1, 0, 0), "tq": (0.75, -0.65, 0.35)}
for act in bpy.data.actions:
    rig.animation_data.action = act
    a, b = act.frame_range
    n = 4
    for i in range(n):
        f = round(a + (b - a) * i / n) if act.name != "jump" else round(a + (b - a) * i / (n - 1))
        scene.frame_set(f)
        for vn, d in views.items():
            d = mathutils.Vector(d).normalized()
            c = mathutils.Vector((0, 0.05, float(__import__("os").environ.get("CZ", "0.6"))))
            cam.location = c + d * 4
            cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
            scene.render.filepath = f"{out}/{act.name}_{vn}_{i}.png"
            bpy.ops.render.render(write_still=True)
