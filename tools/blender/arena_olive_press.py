"""Authors the Olive Press event arena (docs/STORY_PLAN.md §8.4, S1-M03) from the hara kit, into
assets/blender/arenas/olive_press.blend: kit modules as linked duplicates, the enemy road as a `Path`
curve, the `Bounds` plane, empties `PlayerSpawn`, `Spawn_1` and `Gate`. Re-runnable; the layout is
data below (arena-local Roblox studs: x right, z toward the back of the arena), placed with a fixed
random seed. tools/blender/export_layout.py turns the .blend back into config.

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/blender/arena_olive_press.py

Axis mapping used both ways (arena local ↔ Blender): x_blender = -x, y_blender = z, yaw = rotation
about Blender Z in degrees (0 = the module's front faces -Z in the arena). It follows the glTF
import, where a module whose front faces -Y in Blender faces -Z in Roblox.
"""

import math
import random
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / "assets" / "blender" / "hara_kit.blend"
OUT = ROOT / "assets" / "blender" / "arenas" / "olive_press.blend"

ROAD = [(-70, 30), (-30, 30), (-30, -10), (12, -10), (12, 24), (48, 24), (48, -20)]
BOUNDS = (-80, -40, 80, 36)
PARTY = (30, -32)
HALF = 3.2  # TD.PATH_HALF_WIDTH: dressing keeps clear of the road


def to_b(x, z):
    return (-x, z)


def seg_dist(px, pz, a, b):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    l2 = dx * dx + dz * dz
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / l2)) if l2 > 0 else 0.0
    return math.hypot(px - (ax + dx * t), pz - (az + dz * t))


def road_dist(x, z):
    return min(seg_dist(x, z, ROAD[i], ROAD[i + 1]) for i in range(len(ROAD) - 1))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    with bpy.data.libraries.load(str(KIT), link=True) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("kit_")]
    kit = {o.name.removeprefix("kit_"): o for o in dst.objects if o}
    scene = bpy.context.scene
    coll = bpy.data.collections.new("layout")
    scene.collection.children.link(coll)
    placed = []

    def put(module, x, z, yaw=0.0, scale=1.0):
        src = kit[module]
        o = bpy.data.objects.new(f"{module}.{len(placed):03d}", src.data)  # linked mesh data
        bx, by = to_b(x, z)
        o.location = (bx, by, 0)
        o.rotation_euler = (0, 0, math.radians(yaw))
        o.scale = (scale, scale, scale)
        o["module"] = module
        coll.objects.link(o)
        placed.append((x, z))
        return o

    def clear(x, z, r):
        # r: the piece's footprint radius (a canopy for trees), so nothing overhangs the road
        if road_dist(x, z) < HALF + r:
            return False
        return all(math.hypot(x - px, z - pz) >= r + 2.5 for px, pz in placed)

    # The gates: the rival lane's gate at the spawn, the warehouse door at the end of the road.
    put("gate_rival", -76, 30, yaw=-90)
    put("warehouse_door", 48, -24, yaw=180)
    # The press inside the first loop; jars, sacks and a well around it.
    put("olive_press", -9, 9)
    for x, z in ((-2, 3), (-15, 15), (5, -30), (36, -30), (24, 30)):
        put("oil_jar_cluster", x, z, yaw=random.Random(x).uniform(0, 360))
    for x, z in ((-16, 2), (0, 16), (40, -14), (56, -14), (-50, 20), (20, 4)):
        put("sack_pile", x, z, yaw=random.Random(z).uniform(0, 360))
    put("well", -48, -24)
    # Lantern wires across the road at three bends.
    for (x, z), yaw in (((-30, -10), 45), ((12, -10), -45), ((12, 24), 45)):
        put("lantern_wire_span", x, z, yaw=yaw)
    # The irrigation channel along the first road, 6 studs north of it.
    for i in range(3):
        put("irrigation_channel_4m", -62 + i * 16, 38.5 - 2.5, yaw=0)
    for i in range(3):
        put("irrigation_channel_4m", -38.0 + 0.0, 18 - i * 16, yaw=90)
    # Field walls along the edges of the bounds (low, so towers behind them still see the road).
    for i in range(7):
        put("orchard_wall_low", -72 + i * 8.2, -39, yaw=0)
    for i in range(7):
        put("orchard_wall_low", 22 + i * 8.2 - 40, 35, yaw=180)
    # Terraces on the east side.
    for i in range(4):
        put("terrace_step", 64, -30 + i * 8.5, yaw=90)
        put("terrace_step", 72, -30 + i * 8.5, yaw=90)
    # Harvest nets and ladders under trees; 22 olive trees on free ground.
    for x, z in ((-56, -6), (30, 8), (-12, -28)):
        put("harvest_net", x, z, yaw=random.Random(x + z).uniform(0, 90))
    rng = random.Random(2026)
    trees = 0
    tries = 0
    while trees < 22 and tries < 4000:
        tries += 1
        x = rng.uniform(BOUNDS[0] + 4, BOUNDS[2] - 4)
        z = rng.uniform(BOUNDS[1] + 4, BOUNDS[3] - 4)
        if clear(x, z, 6.5) and math.hypot(x - PARTY[0], z - PARTY[1]) > 10:
            put(("olive_tree_a", "olive_tree_b", "olive_tree_c")[trees % 3], x, z, yaw=rng.uniform(0, 360), scale=rng.uniform(0.6, 0.75))
            trees += 1
    for x, z in ((-52, -2), (33, 12)):
        put("ladder", x, z, yaw=rng.uniform(0, 360))

    # The road, the bounds and the markers.
    curve = bpy.data.curves.new("Path", "CURVE")
    curve.dimensions = "3D"
    sp = curve.splines.new("POLY")
    sp.points.add(len(ROAD) - 1)
    for p, (x, z) in zip(sp.points, ROAD):
        bx, by = to_b(x, z)
        p.co = (bx, by, 0.2, 1)
    path = bpy.data.objects.new("Path", curve)
    scene.collection.objects.link(path)
    bpy.ops.mesh.primitive_plane_add(size=1)
    bounds = bpy.context.active_object
    bounds.name = "Bounds"
    x0, z0, x1, z1 = BOUNDS
    bx0, by0 = to_b(x0, z0)
    bx1, by1 = to_b(x1, z1)
    bounds.location = ((bx0 + bx1) / 2, (by0 + by1) / 2, -0.05)
    bounds.scale = (abs(bx1 - bx0), abs(by1 - by0), 1)
    for name, (x, z) in (("PlayerSpawn", PARTY), ("Spawn_1", ROAD[0]), ("Gate", ROAD[-1])):
        e = bpy.data.objects.new(name, None)
        e.location = (*to_b(x, z), 0)
        scene.collection.objects.link(e)
    scene["arena_id"] = "olive_press"
    scene["arena_name_key"] = "arena.olive_press.name"
    scene["arena_seed"] = "olive_press"
    scene["arena_theme"] = "orchard"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT), relative_remap=True, compress=True)
    print("ARENA_OK olive_press", len(placed), "modules ->", OUT)


main()
