# Склейка кадров в одну картинку на анимацию (через Blender-овский image API не нужно — PIL нет; используем bpy.data.images).
import bpy, sys, glob, os
argv = sys.argv[sys.argv.index("--")+1:]
src, dst = argv[0], argv[1]
names = sorted({os.path.basename(p).split('_')[0] for p in glob.glob(src + "/*.png")})
for name in names:
    tiles = []
    for vn in ("side", "tq"):
        for i in range(4):
            p = f"{src}/{name}_{vn}_{i}.png"
            tiles.append(bpy.data.images.load(p))
    w, h = tiles[0].size
    out = bpy.data.images.new(name, w * 4, h * 2)
    px = [0.0] * (w * 4 * h * 2 * 4)
    for t_i, im in enumerate(tiles):
        row = 1 - t_i // 4; col = t_i % 4
        data = list(im.pixels)
        for y in range(h):
            s0 = y * w * 4
            d0 = ((row * h + y) * w * 4 + col * w) * 4
            px[d0:d0 + w * 4] = data[s0:s0 + w * 4]
    out.pixels = px
    out.filepath_raw = f"{dst}/sheet_{name}.png"; out.file_format = 'PNG'; out.save()
