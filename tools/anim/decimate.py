"""Decimates a rigged Meshy GLB to a triangle budget, keeping UVs, the texture and the skin weights.

    blender -b --factory-startup -P tools/anim/decimate.py -- <in.glb> <out.glb> <max_tris>

A Collapse Decimate is put first in the mesh's modifier stack (before the Armature) and applied, so the
skinned vertices keep their group weights; the armature and its bind pose are untouched, which keeps
every clip baked by tools/anim/bake.py valid for the slimmer mesh. Prints the before/after counts.
"""

import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1 :]
src, out, budget = argv[0], argv[1], int(argv[2])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]


def tris(o) -> int:
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


before = sum(tris(o) for o in meshes)
ratio = min(1.0, budget / max(1, before) * 0.98)
for o in meshes:
    bpy.context.view_layer.objects.active = o
    mod = o.modifiers.new("Decimate", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = ratio
    mod.use_collapse_triangulate = True
    while o.modifiers[0] != mod:
        bpy.ops.object.modifier_move_up(modifier=mod.name)
    bpy.ops.object.modifier_apply(modifier=mod.name)
after = sum(tris(o) for o in meshes)

bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_skins=True, export_animations=True, export_yup=True)
print(f"DECIMATE {src}: {before} -> {after} tris (ratio {ratio:.3f})")
