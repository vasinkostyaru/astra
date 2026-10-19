import bpy, sys, mathutils
argv = sys.argv[sys.argv.index("--")+1:]
out = argv[0]; scale = float(argv[1]) if len(argv) > 1 else 0.9; cz = float(argv[2]) if len(argv) > 2 else 0.3
scene = bpy.context.scene
scene.world = bpy.data.worlds.new("dark"); scene.world.color = (0.12, 0.12, 0.14)
scene.render.engine = 'BLENDER_WORKBENCH'; scene.display.shading.light = 'STUDIO'; scene.display.shading.color_type = 'VERTEX'
scene.render.resolution_x = 600; scene.render.resolution_y = 500
cam_data = bpy.data.cameras.new("cam"); cam_data.type = 'ORTHO'; cam_data.ortho_scale = scale
cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
c = mathutils.Vector((0, 0.05, cz))
for name, d in {"side": (1, 0, 0), "front": (0, -1, 0), "tq": (0.7, -0.7, 0.3), "back_tq": (-0.6, 0.7, 0.4)}.items():
    d = mathutils.Vector(d).normalized(); cam.location = c + d * 3; cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = f"{out}_{name}.png"; bpy.ops.render.render(write_still=True)
