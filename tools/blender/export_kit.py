"""Exports the hara kit (docs/STORY_PLAN.md §8.2, S1-M01): one GLB per module object of the "kit"
collection in assets/blender/hara_kit.blend to assets/unapproved/kit/<name>.glb, a Workbench
thumbnail per module to docs/art/kit/<name>.png, and a triangle report (kit_report.json) that fails
on a module over budget (2,000 triangles; gates and the warehouse 6,000).

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b assets/blender/hara_kit.blend -P tools/blender/export_kit.py

The thumbnails are combined into docs/art/kit_sheet_<date>.png by tools/blender/kit_sheet.py
(system Python with Pillow).
"""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT_GLB = ROOT / "assets" / "unapproved" / "kit"
OUT_THUMB = ROOT / "docs" / "art" / "kit"
BUDGET = 2000
BIG_BUDGET = 6000
BIG = {"kit_gate_lane", "kit_gate_rival", "kit_warehouse_door", "kit_warehouse_block"}


def tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def thumbnail(obj, path):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = scene.render.resolution_y = 320
    scene.render.film_transparent = False
    scene.world = scene.world or bpy.data.worlds.new("w")
    for o in bpy.data.objects:
        o.hide_render = o is not obj and o.type == "MESH"
    bpy.context.view_layer.update()  # the export moved the module and back: refresh matrix_world
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    hi = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    centre = (lo + hi) / 2
    size = max((hi - lo).length, 1.0)
    cam = bpy.data.objects.get("kit_cam")
    if not cam:
        cam = bpy.data.objects.new("kit_cam", bpy.data.cameras.new("kit_cam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 50
    # from the front-left and a little above (the module's front faces -Y)
    direction = Vector((-0.55, -1.0, 0.55)).normalized()
    cam.location = centre + direction * size * 1.6
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def export(obj, path):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    keep = obj.location.copy()
    obj.location = (0, 0, 0)  # each GLB's origin is the module's ground centre
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_image_format="AUTO",
        export_vertex_color="ACTIVE",
    )
    obj.location = keep


def main():
    OUT_GLB.mkdir(parents=True, exist_ok=True)
    OUT_THUMB.mkdir(parents=True, exist_ok=True)
    coll = bpy.data.collections["kit"]
    report, over = {}, []
    for obj in sorted(coll.objects, key=lambda o: o.name):
        if obj.type != "MESH":
            continue
        n = tris(obj)
        limit = BIG_BUDGET if obj.name in BIG else BUDGET
        report[obj.name] = {"tris": n, "budget": limit}
        if n > limit:
            over.append(f"{obj.name} {n} > {limit}")
        export(obj, OUT_GLB / (obj.name + ".glb"))
        thumbnail(obj, OUT_THUMB / (obj.name + ".png"))
    (OUT_GLB / "kit_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("KIT_EXPORT", len(report), "modules;", "over budget: " + ", ".join(over) if over else "all within budget")
    if over:
        sys.exit(1)


main()
