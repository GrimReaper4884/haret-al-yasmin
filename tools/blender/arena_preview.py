"""Renders a top-down picture of an arena .blend (the kit layout over its road and bounds) for the record.

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b assets/blender/arenas/<id>.blend -P tools/blender/arena_preview.py -- docs/art/arena_<id>_layout_<date>.png
"""

import sys

import bpy

out = sys.argv[sys.argv.index("--") + 1]
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE"
scene.render.resolution_x, scene.render.resolution_y = 1600, 800
b = bpy.data.objects["Bounds"]
# the road as a visible tube
path = bpy.data.objects["Path"]
path.data.bevel_depth = 1.6
path.data.bevel_resolution = 2
mat = bpy.data.materials.new("road")
mat.diffuse_color = (0.55, 0.45, 0.32, 1)
path.data.materials.append(mat)
bmat = bpy.data.materials.new("ground")
bmat.diffuse_color = (0.80, 0.72, 0.55, 1)
b.data.materials.append(bmat)
cam = bpy.data.objects.new("top", bpy.data.cameras.new("top"))
scene.collection.objects.link(cam)
cam.data.type = "ORTHO"
cam.data.ortho_scale = max(b.scale.x, b.scale.y) * 1.05
cam.location = (b.location.x, b.location.y, 120)
cam.rotation_euler = (0, 0, 0)
scene.camera = cam
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
# Blender x is the arena's -x: mirror so the picture reads with +x to the right and +z up.
img = bpy.data.images.load(out)
w, h = img.size
px = list(img.pixels)
row = w * 4
flipped = []
for y in range(h):
    r = px[y * row : (y + 1) * row]
    for x in range(w - 1, -1, -1):
        flipped.extend(r[x * 4 : x * 4 + 4])
img.pixels = flipped
img.save()
print("PREVIEW_OK", out)
