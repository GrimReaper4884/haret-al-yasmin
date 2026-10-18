"""Authors an arena from the hara kit (docs/STORY_PLAN.md §8.3, S1-M03/M04) into
assets/blender/arenas/<id>.blend, from tools/blender/arena_defs.py: kit modules as linked duplicates,
each road as a curve (`Path`, `Path_2`), the `Bounds` plane, empties `PlayerSpawn`, `Spawn_1`, `Gate`
(and `AllySpot` when the arena has one). tools/blender/export_layout.py turns it into config.

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/blender/arena_build.py -- <id>

Axis mapping both ways (arena local ↔ Blender): x_blender = -x, y_blender = z, yaw = rotation about
Blender Z in degrees (0 = the module's front faces -Z in the arena), matching the glTF import.
"""

import math
import random
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from arena_defs import ARENAS  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / "assets" / "blender" / "hara_kit.blend"
HALF = 3.2  # TD.PATH_HALF_WIDTH: dressing keeps clear of the roads


def to_b(x, z):
    return (-x, z)


def seg_dist(px, pz, a, b):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    l2 = dx * dx + dz * dz
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / l2)) if l2 > 0 else 0.0
    return math.hypot(px - (ax + dx * t), pz - (az + dz * t))


def build(aid):
    d = ARENAS[aid]
    roads = d["roads"]

    def road_dist(x, z):
        return min(seg_dist(x, z, r[i], r[i + 1]) for r in roads for i in range(len(r) - 1))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    with bpy.data.libraries.load(str(KIT), link=True) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("kit_")]
    kit = {o.name.removeprefix("kit_"): o for o in dst.objects if o}
    scene = bpy.context.scene
    coll = bpy.data.collections.new("layout")
    scene.collection.children.link(coll)
    placed = []

    def put(module, x, z, yaw=0.0, scale=1.0):
        o = bpy.data.objects.new(f"{module}.{len(placed):03d}", kit[module].data)  # linked mesh data
        bx, by = to_b(x, z)
        o.location = (bx, by, 0)
        o.rotation_euler = (0, 0, math.radians(yaw))
        o.scale = (scale, scale, scale)
        o["module"] = module
        coll.objects.link(o)
        placed.append((x, z))

    for module, x, z, yaw in d["modules"]:
        put(module, x, z, yaw)
    x0, z0, x1, z1 = d["bounds"]
    party = d["party"]
    for module, count, seed, (smin, smax), r in d.get("scatter", []):
        rng = random.Random(seed)
        n = tries = 0
        while n < count and tries < 5000:
            tries += 1
            x, z = rng.uniform(x0 + 4, x1 - 4), rng.uniform(z0 + 4, z1 - 4)
            # r: the piece's footprint (a canopy for trees), so nothing overhangs a road
            if road_dist(x, z) < HALF + r or math.hypot(x - party[0], z - party[1]) < 10:
                continue
            if any(math.hypot(x - px, z - pz) < r + 2.5 for px, pz in placed):
                continue
            name = ("olive_tree_a", "olive_tree_b", "olive_tree_c")[n % 3] if module == "olive_tree" else module
            put(name, x, z, yaw=rng.uniform(0, 360), scale=rng.uniform(smin, smax))
            n += 1

    for i, r in enumerate(roads):
        curve = bpy.data.curves.new("Path" if i == 0 else f"Path_{i + 1}", "CURVE")
        curve.dimensions = "3D"
        sp = curve.splines.new("POLY")
        sp.points.add(len(r) - 1)
        for p, (x, z) in zip(sp.points, r):
            bx, by = to_b(x, z)
            p.co = (bx, by, 0.2, 1)
        scene.collection.objects.link(bpy.data.objects.new(curve.name, curve))
    bpy.ops.mesh.primitive_plane_add(size=1)
    bounds = bpy.context.active_object
    bounds.name = "Bounds"
    bx0, by0 = to_b(x0, z0)
    bx1, by1 = to_b(x1, z1)
    bounds.location = ((bx0 + bx1) / 2, (by0 + by1) / 2, -0.05)
    bounds.scale = (abs(bx1 - bx0), abs(by1 - by0), 1)
    marks = [("PlayerSpawn", party), ("Spawn_1", roads[0][0]), ("Gate", roads[0][-1])]
    if d.get("ally"):
        marks.append(("AllySpot", d["ally"]))
    for name, (x, z) in marks:
        e = bpy.data.objects.new(name, None)
        e.location = (*to_b(x, z), 0)
        scene.collection.objects.link(e)
    scene["arena_id"] = aid
    scene["arena_name_key"] = d["name_key"]
    scene["arena_seed"] = aid
    scene["arena_theme"] = d["theme"]
    out = ROOT / "assets" / "blender" / "arenas" / f"{aid}.blend"
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out), relative_remap=True, compress=True)
    print("ARENA_OK", aid, len(placed), "modules,", len(roads), "road(s) ->", out)


build(sys.argv[sys.argv.index("--") + 1])
