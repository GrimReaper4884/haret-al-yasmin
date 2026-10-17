"""Renders a contact sheet of an animated GLB (Meshy clip) with Blender, to judge a clip by eye
before baking it (docs/CHARACTER_PIPELINE.md, "Signature animations").

    blender -b --factory-startup -P tools/anim/preview.py -- <clip.glb> <out.png> [frames=8] [view=front|side|threequarter]

Workbench engine, flat texture lighting, orthographic camera framed on the whole clip.
"""

import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1 :]
src, out = argv[0], argv[1]
count = int(argv[2]) if len(argv) > 2 else 8
view = argv[3] if len(argv) > 3 else "threequarter"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
scene = bpy.context.scene

arm = next((o for o in scene.objects if o.type == "ARMATURE"), None)
meshes = [o for o in scene.objects if o.type == "MESH"]
action = arm.animation_data.action if arm and arm.animation_data else None
f0, f1 = (int(action.frame_range[0]), int(action.frame_range[1])) if action else (1, 1)

# Bounds over the whole clip so every cell shares one framing.
lo, hi = Vector((1e9, 1e9, 1e9)), Vector((-1e9, -1e9, -1e9))
frames = [round(f0 + (f1 - f0) * i / max(1, count - 1)) for i in range(count)]
dg = bpy.context.evaluated_depsgraph_get()
for f in frames:
    scene.frame_set(f)
    dg = bpy.context.evaluated_depsgraph_get()
    for m in meshes:
        ev = m.evaluated_get(dg)
        me = ev.to_mesh()
        step = max(1, len(me.vertices) // 400)
        for vi in range(0, len(me.vertices), step):
            v = me.vertices[vi]
            w = ev.matrix_world @ v.co
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
        ev.to_mesh_clear()
center = (lo + hi) / 2
size = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)

cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = size * 1.15
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
yaw = {"front": 0, "side": 90, "threequarter": 35}[view]
# glTF -Z forward imports as Blender +Y forward... characters face Blender -Y after import.
d = Vector((math.sin(math.radians(yaw)), -math.cos(math.radians(yaw)), 0.25)).normalized()
cam.location = center + d * size * 3
cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()

scene.render.engine = "BLENDER_WORKBENCH"
shading = scene.display.shading
shading.light = "STUDIO"
shading.color_type = "TEXTURE"
shading.show_shadows = False
scene.render.resolution_x = 320
scene.render.resolution_y = 400
scene.render.film_transparent = False
world = bpy.data.worlds.new("w")
scene.world = world
world.color = (0.18, 0.18, 0.2)

import os
import tempfile

tmp = tempfile.mkdtemp()
paths = []
for i, f in enumerate(frames):
    scene.frame_set(f)
    p = os.path.join(tmp, f"f{i:02d}.png")
    scene.render.filepath = p
    bpy.ops.render.render(write_still=True)
    paths.append(p)

# Stitch into one strip (Blender image API, no PIL needed).
cols = min(count, 8)
rows = math.ceil(count / cols)
W, H = 320, 400
sheet = bpy.data.images.new("sheet", W * cols, H * rows, alpha=False)
px = [0.0] * (W * cols * H * rows * 4)
for i, p in enumerate(paths):
    img = bpy.data.images.load(p)
    src_px = list(img.pixels)
    c, r = i % cols, rows - 1 - i // cols
    for y in range(H):
        row = src_px[y * W * 4 : (y + 1) * W * 4]
        start = ((r * H + y) * W * cols + c * W) * 4
        px[start : start + W * 4] = row
sheet.pixels = px
sheet.filepath_raw = out
sheet.file_format = "PNG"
sheet.save()
print(f"frames {f0}-{f1} ({action.name if action else 'none'}) -> {out}")
