"""Builds the procedural half of the hara kit (docs/STORY_PLAN.md §8.2, S1-M01) into
assets/blender/hara_kit.blend, from nothing, so the kit is reproducible from the repo.

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup -P tools/blender/kit_build.py

Conventions (the PropPlacements / Meshy-prop convention): 1 Blender unit = 1 stud, Z up, every
module's origin at its ground centre, its front facing -Y (it faces -Z after glTF/Roblox import).
Every face is coloured from one palette atlas (assets/blender/kit_atlas.png, 1024², 8×8 swatches of
128 px) through its UVs, and the same colour is stored as a vertex colour so a module still reads
if the texture is missing. Each module is one object in the "kit" collection; tools/blender/
export_kit.py writes one GLB per module. Budgets: ≤ 2,000 triangles per module (gates and the
warehouse ≤ 6,000), checked by export_kit.py.

The organic half (olive trees, sacks, jars, the press, nets: S1-M02) is scripted here too, as low-poly
stylised shapes, so the whole kit stays reproducible from the repo (D-054).
"""

import math
import random
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT_BLEND = ROOT / "assets" / "blender" / "hara_kit.blend"
OUT_ATLAS = ROOT / "assets" / "blender" / "kit_atlas.png"
ATLAS = 1024
GRID = 8  # 8×8 swatches

# Palette: the ART_BIBLE warm lane colours plus the cold colours of the gendarmerie and the rival lane.
PALETTE = [
    ("plaster", "#E9DCC2"), ("stone", "#D8CDB8"), ("basalt", "#3B3A3C"), ("wood", "#7A5132"),
    ("wood_dark", "#4A3020"), ("iron", "#2B2B2E"), ("brass", "#C9A13B"), ("terracotta", "#B5643C"),
    ("green", "#5E7A3A"), ("grass", "#6E8B3D"), ("dust", "#C8B48C"), ("cobble", "#9C9182"),
    ("cobble_dark", "#7B7266"), ("red", "#A4302A"), ("blue", "#2F3E6B"), ("sand", "#D9C49A"),
    ("water", "#5D8FA8"), ("sack", "#C2A878"), ("glow", "#F3D27A"), ("olive", "#5E6B3A"),
    ("canvas", "#D8CFB5"), ("khaki", "#8A7A52"), ("white", "#EFE6D2"), ("slate", "#5C6670"),
    ("plaster_shade", "#D6C6A8"), ("rival_wood", "#3E4A52"), ("fire", "#E07A2E"), ("cushion", "#7A3B5C"),
    ("leaf", "#4E6B34"), ("leaf_light", "#7E9467"), ("bark", "#6B5440"), ("net", "#B89E6A"),
]
SWATCH = {name: i for i, (name, _) in enumerate(PALETTE)}


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))


def swatch_uv(name):
    i = SWATCH[name]
    col, row = i % GRID, i // GRID
    s = 1 / GRID
    # centre of the swatch (V counted from the bottom in Blender)
    return Vector(((col + 0.5) * s, 1 - (row + 0.5) * s))


# ---------------------------------------------------------------------------------------- atlas
def build_atlas():
    img = bpy.data.images.new("kit_atlas", ATLAS, ATLAS, alpha=False)
    px = [0.0] * (ATLAS * ATLAS * 4)
    cell = ATLAS // GRID
    for i in range(GRID * GRID):
        r, g, b = hex_rgb(PALETTE[i][1]) if i < len(PALETTE) else (1.0, 0.0, 1.0)
        col, row = i % GRID, i // GRID
        y0 = ATLAS - (row + 1) * cell  # image rows start at the bottom
        for y in range(y0, y0 + cell):
            # a soft painted gradient, lighter at the top (no per-pixel grain: the atlas must stay a
            # small PNG, since every module's GLB embeds it)
            shade = 0.94 + 0.08 * ((y - y0) // 8 * 8 / cell)
            for x in range(col * cell, (col + 1) * cell):
                k = (y * ATLAS + x) * 4
                px[k] = min(1, r * shade)
                px[k + 1] = min(1, g * shade)
                px[k + 2] = min(1, b * shade)
                px[k + 3] = 1.0
    img.pixels = px
    img.filepath_raw = str(OUT_ATLAS)
    img.file_format = "PNG"
    img.save()
    return img


def atlas_material(img):
    mat = bpy.data.materials.new("kit_atlas")
    if hasattr(mat, "use_nodes"):
        mat.use_nodes = True  # always on from Blender 6.0
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    return mat


# ---------------------------------------------------------------------------------------- geometry
class Builder:
    """Accumulates coloured primitives into one bmesh, then becomes one object."""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.col = self.bm.loops.layers.color.new("Col")

    def _paint(self, faces, color):
        uv = swatch_uv(color)
        rgb = hex_rgb(dict(PALETTE)[color])
        for f in faces:
            for loop in f.loops:
                loop[self.uv].uv = uv
                loop[self.col] = (rgb[0], rgb[1], rgb[2], 1.0)

    def _new_faces(self, before):
        return [f for f in self.bm.faces if f.index == -1 or f not in before]

    def box(self, size, at, color, rot=(0, 0, 0)):
        """size (x, y, z) studs, `at` = centre of the box's bottom face, rot = degrees about x, y, z."""
        before = set(self.bm.faces)
        m = Matrix.Translation(Vector(at) + Vector((0, 0, size[2] / 2)))
        m = m @ (Matrix.Rotation(math.radians(rot[2]), 4, "Z") @ Matrix.Rotation(math.radians(rot[1]), 4, "Y") @ Matrix.Rotation(math.radians(rot[0]), 4, "X"))
        m = m @ Matrix.Diagonal(Vector((size[0], size[1], size[2], 1)))
        bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        self._paint([f for f in self.bm.faces if f not in before], color)

    def cyl(self, radius, height, at, color, segs=12, top_radius=None, rot=(0, 0, 0)):
        before = set(self.bm.faces)
        m = Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(rot[2]), 4, "Z") @ Matrix.Rotation(math.radians(rot[1]), 4, "Y") @ Matrix.Rotation(math.radians(rot[0]), 4, "X")
        m = m @ Matrix.Translation((0, 0, height / 2))
        bmesh.ops.create_cone(self.bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius if top_radius is None else top_radius, depth=height, matrix=m)
        self._paint([f for f in self.bm.faces if f not in before], color)

    def sphere(self, radius, at, color, segs=10, rings=6, scale=(1, 1, 1)):
        before = set(self.bm.faces)
        m = Matrix.Translation(Vector(at)) @ Matrix.Diagonal(Vector((scale[0], scale[1], scale[2], 1)))
        bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=radius, matrix=m)
        self._paint([f for f in self.bm.faces if f not in before], color)

    def to_object(self, name, coll, mat):
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        me.materials.append(mat)
        obj = bpy.data.objects.new(name, me)
        coll.objects.link(obj)
        return obj


# ---------------------------------------------------------------------------------------- pieces
WALL_H, WALL_D = 14, 2


def wall_body(b, width, x0=0.0, height=WALL_H, depth=WALL_D, ablaq=True):
    """A plastered lane wall from x0 - width/2 to x0 + width/2: stone plinth, a black-and-white
    ablaq course, coping on top."""
    b.box((width, depth + 0.4, 0.6), (x0, 0, 0), "stone")
    b.box((width, depth, height - 1.2), (x0, 0, 0.6), "plaster")
    b.box((width + 0.2, depth + 0.3, 0.6), (x0, 0, height - 0.6), "stone")
    if ablaq:
        n = max(2, int(width // 2))
        w = width / n
        for i in range(n):
            b.box((w, depth + 0.06, 1.0), (x0 - width / 2 + w * (i + 0.5), 0, 3.0), "basalt" if i % 2 == 0 else "stone")


def arch(b, cx, spring, radius, depth, y=0.0, blocks=9, thick=0.9):
    """A semicircular arch of alternating ablaq voussoirs."""
    for i in range(blocks):
        a = math.pi * (i + 0.5) / blocks
        x, z = cx + math.cos(a) * radius, spring + math.sin(a) * radius
        b.box((thick, depth, thick * 1.1), (x, y, z - thick * 0.55), "basalt" if i % 2 == 0 else "stone", rot=(0, -math.degrees(a) + 90, 0))


def lantern(b, at, scale=1.0):
    x, y, z = at
    s = scale
    b.box((0.7 * s, 0.7 * s, 0.15 * s), (x, y, z), "brass")
    b.box((0.55 * s, 0.55 * s, 0.8 * s), (x, y, z + 0.15 * s), "glow")
    b.cyl(0.45 * s, 0.3 * s, (x, y, z + 0.95 * s), "brass", segs=8, top_radius=0.05 * s)


# ---------------------------------------------------------------------------------------- modules
def wall_2m(b):
    wall_body(b, 8)


def wall_4m(b):
    wall_body(b, 16)


def wall_corner(b):
    wall_body(b, 8, x0=-3)
    # the return wall runs back along +Y from the corner
    b.box((WALL_D + 0.4, 8, 0.6), (1, 4, 0), "stone")
    b.box((WALL_D, 8, WALL_H - 1.2), (1, 4, 0.6), "plaster")
    b.box((WALL_D + 0.3, 8.2, 0.6), (1, 4, WALL_H - 0.6), "stone")
    for i in range(5):  # quoins at the corner
        b.box((WALL_D + 0.3, WALL_D + 0.3, 1.2), (1, 0, 1 + i * 2.6), "basalt" if i % 2 == 0 else "stone")


def wall_arch(b):
    # piers either side of a 6-stud passage, the arch, and the wall above it
    for side in (-1, 1):
        b.box((3, WALL_D + 0.4, 0.6), (side * 4.5, 0, 0), "stone")
        b.box((3, WALL_D, WALL_H - 1.2), (side * 4.5, 0, 0.6), "plaster")
    b.box((6, WALL_D, 3.4), (0, 0, WALL_H - 4.0), "plaster")
    b.box((12.2, WALL_D + 0.3, 0.6), (0, 0, WALL_H - 0.6), "stone")
    arch(b, 0, 7.0, 3.0, WALL_D + 0.2)
    for side in (-1, 1):  # spandrels between the arch and the wall above
        b.box((1.6, WALL_D, 2.2), (side * 2.3, 0, 8.0), "plaster_shade")


def wall_window_grille(b):
    # a wall with a barred window: build the wall around the opening
    b.box((8, WALL_D + 0.4, 0.6), (0, 0, 0), "stone")
    b.box((8, WALL_D, 5.4), (0, 0, 0.6), "plaster")
    for side in (-1, 1):
        b.box((2.5, WALL_D, 3.0), (side * 2.75, 0, 6.0), "plaster")
    b.box((8, WALL_D, 4.4), (0, 0, 9.0), "plaster")
    b.box((8.2, WALL_D + 0.3, 0.6), (0, 0, WALL_H - 0.6), "stone")
    b.box((3.4, WALL_D + 0.2, 0.4), (0, 0, 5.8), "stone")  # sill
    b.box((3.4, WALL_D + 0.2, 0.4), (0, 0, 9.0), "basalt")  # lintel
    for i in range(5):
        b.box((0.16, 0.16, 3.0), (-1.2 + i * 0.6, -WALL_D / 2 - 0.1, 6.0), "iron")
    for z in (6.9, 8.1):
        b.box((3.0, 0.16, 0.16), (0, -WALL_D / 2 - 0.1, z), "iron")


def mashrabiya_bay(b):
    # a wooden oriel that hangs on a wall face (its back at y = 0), floor 5 studs up
    y = -0.9
    b.box((5, 1.8, 0.4), (0, y, 5.0), "wood_dark")
    for side in (-1, 1):  # corbels
        b.box((0.5, 1.6, 1.4), (side * 2.0, y + 0.1, 3.6), "wood_dark", rot=(20, 0, 0))
    b.box((5, 1.8, 0.3), (0, y, 9.0), "wood_dark")
    b.box((5.6, 2.3, 0.3), (0, y - 0.1, 9.3), "terracotta", rot=(-8, 0, 0))
    for i in range(9):  # lattice: verticals and horizontals on the front
        b.box((0.12, 0.12, 3.6), (-2.2 + i * 0.55, y - 0.9, 5.4), "wood")
    for j in range(6):
        b.box((4.6, 0.12, 0.12), (0, y - 0.9, 5.7 + j * 0.6), "wood")
    for side in (-1, 1):
        b.box((0.15, 1.6, 3.6), (side * 2.45, y, 5.4), "wood")


def gate_frame(b, frame_color, leaf_color, stud_color):
    # stone frame: two piers and an arch, then two leaves with studs, a wicket and knockers
    for side in (-1, 1):
        b.box((2.4, 3, 12), (side * 4.6, 0, 0), frame_color)
    b.box((11.6, 3, 2.4), (0, 0, 12), frame_color)
    arch(b, 0, 9.0, 3.4, 3.2, blocks=11)
    for side in (-1, 1):
        x = side * 1.8
        b.box((3.5, 0.5, 9.0), (x, -0.6, 0), leaf_color)
        for row in range(5):
            for col in range(3):
                b.box((0.25, 0.25, 0.25), (x - 1.0 + col, -0.9, 1.2 + row * 1.7), stud_color)
        b.cyl(0.35, 0.12, (side * 0.6, -0.95, 5.0), stud_color, segs=10, rot=(90, 0, 0))  # knocker
        b.box((0.25, 0.6, 0.6), (side * 3.2, -1.0, 4.0), "iron")  # bar hook
    b.box((1.6, 0.06, 3.0), (-1.8, -0.88, 0.2), "wood_dark")  # wicket outline


def gate_lane(b):
    gate_frame(b, "stone", "wood", "brass")


def gate_rival(b):
    gate_frame(b, "basalt", "rival_wood", "iron")


def warehouse_door(b):
    b.box((12, 2.4, 0.5), (0, 0, 0), "stone")
    for side in (-1, 1):
        b.box((1.6, 2.4, 10), (side * 5.2, 0, 0.5), "stone")
        b.box((4.3, 0.5, 8.5), (side * 2.2, -0.4, 0.5), "wood")
        for z in (1.8, 4.6, 7.4):  # iron straps
            b.box((4.0, 0.12, 0.35), (side * 2.2, -0.7, z), "iron")
    b.box((12, 2.4, 1.6), (0, 0, 9.0), "wood_dark")
    for i, (x, y) in enumerate(((-7.6, -1.6), (-8.4, -0.2), (7.6, -1.4), (8.5, 0.0), (-7.9, -0.9))):
        b.sphere(0.95, (x, y, 0.95 + (1.4 if i == 4 else 0)), "sack", scale=(1.0, 0.8, 0.75))


def cobble_tile_4m(b):
    b.box((16, 16, 0.2), (0, 0, 0), "cobble_dark")
    rng = random.Random(4)
    for i in range(8):
        for j in range(8):
            h = 0.12 + rng.random() * 0.08
            b.box((1.75, 1.75, h), (-7 + i * 2, -7 + j * 2, 0.2), "cobble" if (i + j) % 3 else "cobble_dark", rot=(0, 0, rng.random() * 6 - 3))


def kerb_4m(b):
    b.box((16, 1.0, 0.6), (0, 0, 0), "stone")
    for i in range(4):
        b.box((0.06, 1.02, 0.62), (-6 + i * 4, 0, 0), "basalt")


def gutter_4m(b):
    for side in (-1, 1):
        b.box((16, 0.6, 0.35), (0, side * 0.7, 0), "stone")
    b.box((16, 0.8, 0.1), (0, 0, 0), "basalt")
    b.box((16, 0.7, 0.04), (0, 0, 0.1), "water")


def step_set(b):
    for i in range(3):
        b.box((6, 3 - i, 0.7), (0, -0.0 + i * 0.5, i * 0.7), "stone" if i % 2 == 0 else "plaster_shade")


def well(b):
    b.cyl(2.0, 2.4, (0, 0, 0), "stone", segs=14)
    b.cyl(1.6, 0.05, (0, 0, 2.38), "water", segs=14)
    for side in (-1, 1):
        b.box((0.4, 0.4, 5.0), (side * 1.8, 0, 2.4), "wood")
    b.box((4.0, 0.4, 0.4), (0, 0, 6.8), "wood")
    b.cyl(0.08, 2.0, (0, 0, 4.8), "iron", segs=6)
    b.cyl(0.45, 0.7, (0, 0, 4.1), "wood_dark", segs=10, top_radius=0.55)


def bench_dikkeh(b):
    b.box((6, 1.6, 1.2), (0, 0, 0), "stone")
    b.box((5.8, 1.5, 0.3), (0, 0, 1.2), "cushion")
    b.box((6, 0.5, 1.6), (0, 0.6, 1.2), "plaster_shade")
    for x in (-2.2, 0.0, 2.2):
        b.box((1.0, 0.4, 0.8), (x, 0.25, 1.5), "red", rot=(-15, 0, 0))


def lantern_wall(b):
    # bracket out of a wall face at y = 0, lantern hanging from it, 9 studs up
    b.box((0.4, 0.3, 1.0), (0, -0.15, 9.0), "iron")
    b.box((0.15, 1.6, 0.15), (0, -0.9, 9.8), "iron")
    b.box((0.08, 0.08, 0.5), (0, -1.6, 9.3), "iron")
    lantern(b, (0, -1.6, 8.0), 1.0)


def lantern_wire_span(b):
    # a wire 24 studs across, sagging, three lanterns hanging from it, hooks at 12 studs up
    for side in (-1, 1):
        b.box((0.3, 0.5, 0.3), (side * 12, 0, 12.0), "iron")
    n = 16
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        x0, x1 = -12 + 24 * t0, -12 + 24 * t1
        z0 = 12.15 - 1.6 * (1 - (2 * t0 - 1) ** 2)
        z1 = 12.15 - 1.6 * (1 - (2 * t1 - 1) ** 2)
        length = math.hypot(x1 - x0, z1 - z0)
        ang = math.degrees(math.atan2(z1 - z0, x1 - x0))
        b.box((length, 0.08, 0.08), ((x0 + x1) / 2, 0, (z0 + z1) / 2 - 0.04), "iron", rot=(0, -ang, 0))
    for x in (-6, 0, 6):
        sag = 12.15 - 1.6 * (1 - (x / 12) ** 2)
        b.box((0.06, 0.06, 0.7), (x, 0, sag - 0.7), "iron")
        lantern(b, (x, 0, sag - 1.9), 0.8)


def bakery_front(b):
    wall_body(b, 16, ablaq=False)
    b.box((7, 0.4, 5.0), (-3.5, -1.2, 0.6), "basalt")  # oven mouth surround
    arch(b, -3.5, 3.4, 1.6, 0.5, y=-1.3, blocks=7, thick=0.6)
    b.box((2.6, 0.3, 2.8), (-3.5, -1.4, 0.8), "fire")
    b.box((6, 1.6, 2.6), (3.5, -1.8, 0), "wood")  # counter
    for i in range(4):
        b.cyl(0.6, 0.12, (1.4 + i * 1.4, -1.8, 2.62), "sand", segs=10)  # loaves
    b.box((16.4, 3.0, 0.2), (0, -2.4, 6.8), "canvas", rot=(18, 0, 0))  # awning
    b.box((6, 0.2, 1.4), (0, -1.15, 8.5), "wood_dark")  # sign board
    b.box((5.4, 0.22, 0.9), (0, -1.2, 8.75), "white")


def warehouse_block(b):
    b.box((24, 16, 0.8), (0, 0, 0), "stone")
    b.box((24, 16, 14.0), (0, 0, 0.8), "plaster_shade")
    for k in range(2):  # two ablaq bands all round
        z = 4.0 + k * 6.0
        n = 12
        for i in range(n):
            c = "basalt" if i % 2 == 0 else "stone"
            b.box((2, 16.1, 1.0), (-11 + i * 2, 0, z), c)
            b.box((24.1, 2.0, 1.0), (0, -7 + i * (14 / (n - 1)), z), c) if i < 8 else None
    b.box((25, 17, 0.8), (0, 0, 14.8), "terracotta")
    b.box((22, 15, 1.4), (0, 0, 15.6), "terracotta", rot=(0, 0, 0))
    for side in (-1, 1):  # high windows on the front
        for x in (-8, 8):
            b.box((1.6, 0.3, 2.0), (x, -8.1, 9.5), "wood_dark")


def police_post(b):
    # a sentry box, a sandbag wall in front, barbed wire on posts (no flag)
    b.box((3.2, 3.2, 0.3), (5, 2, 0), "stone")
    b.box((3.0, 3.0, 6.0), (5, 2, 0.3), "khaki")
    b.box((1.6, 0.2, 3.6), (5, 0.45, 1.0), "iron")  # dark doorway
    b.box((3.8, 3.8, 0.4), (5, 2, 6.3), "slate", rot=(0, 0, 45))
    b.cyl(2.6, 1.0, (5, 2, 6.7), "slate", segs=4, top_radius=0.1)
    for row in range(3):
        n = 6 - row
        for i in range(n):
            b.sphere(0.75, (-5.0 + i * 1.35 + row * 0.67, -1.0, 0.45 + row * 0.75), "sack", segs=8, rings=5, scale=(1.0, 0.7, 0.55))
    for i in range(4):
        x = -6 + i * 3.4
        b.box((0.2, 0.2, 2.6), (x, -3.2, 0), "wood_dark")
        if i < 3:
            for k in range(4):  # zig-zag wire
                x0 = x + k * 0.85
                b.box((0.95, 0.06, 0.06), (x0 + 0.42, -3.2, 1.0 + (0.5 if k % 2 == 0 else 1.3)), "iron", rot=(0, 30 if k % 2 == 0 else -30, 0))


def rooftop_stair(b):
    for i in range(8):
        b.box((3, 1.2, 0.7 + i * 0.75), (0, -4.2 + i * 1.2, 0), "stone" if i % 2 == 0 else "plaster_shade")
    b.box((3.4, 2.6, 6.75), (0, 6.6, 0), "plaster")  # landing
    for i in range(5):
        b.box((0.15, 0.15, 1.6), (1.4, -4.2 + i * 2.4, 0.7 + i * 1.8), "wood_dark")
    # handrail over the post tops, from (y -4.2, z 2.3) to (y 5.4, z 9.5)
    run, rise = 9.6, 7.2
    b.box((0.12, math.hypot(run, rise), 0.12), (1.4, 0.6, 5.9 - 0.06), "wood_dark", rot=(math.degrees(math.atan2(rise, run)), 0, 0))


def skyline_dome(b):
    b.cyl(5.0, 6.0, (0, 0, 0), "plaster_shade", segs=16)
    b.box((11, 11, 1.0), (0, 0, 6.0), "stone")
    b.sphere(4.6, (0, 0, 7.0), "green", segs=16, rings=8, scale=(1, 1, 0.9))
    b.cyl(0.25, 2.2, (0, 0, 10.8), "brass", segs=6, top_radius=0.05)


def skyline_minaret(b):
    b.box((4, 4, 3), (0, 0, 0), "stone")
    b.cyl(1.4, 16, (0, 0, 3), "plaster", segs=8)
    b.cyl(2.0, 0.6, (0, 0, 15), "stone", segs=8)
    b.cyl(1.1, 3.0, (0, 0, 15.6), "plaster_shade", segs=8)
    b.cyl(1.3, 3.0, (0, 0, 18.6), "green", segs=8, top_radius=0.05)
    b.cyl(0.12, 1.2, (0, 0, 21.4), "brass", segs=6)


def patch(b, color, radius, tufts=None, seed=3):
    rng = random.Random(seed)
    for i in range(7):
        a = i / 7 * math.tau
        r = radius * (0.45 + rng.random() * 0.3)
        b.cyl(r, 0.08, (math.cos(a) * radius * 0.45, math.sin(a) * radius * 0.45, 0), color, segs=10)
    b.cyl(radius * 0.7, 0.1, (0, 0, 0), color, segs=12)
    if tufts:
        for _ in range(14):
            a, r = rng.random() * math.tau, rng.random() * radius * 0.9
            b.cyl(0.25, 0.6 + rng.random() * 0.4, (math.cos(a) * r, math.sin(a) * r, 0.05), tufts, segs=5, top_radius=0.02)


def grass_patch(b):
    patch(b, "grass", 4.0, tufts="green")


def dust_patch(b):
    patch(b, "dust", 4.0, seed=5)


def rubble(b):
    rng = random.Random(9)
    for _ in range(14):
        s = 0.6 + rng.random() * 1.0
        b.box((s, s * 0.8, s * 0.6), (rng.uniform(-2.5, 2.5), rng.uniform(-2.0, 2.0), 0), rng.choice(["stone", "basalt", "plaster_shade"]), rot=(rng.uniform(-15, 15), rng.uniform(-15, 15), rng.uniform(0, 90)))




# ---------------------------------------------------------------------------------------- organic (S1-M02)
def olive_tree(b, seed, height):
    """A stylised olive: a twisted trunk of tilted segments, two or three boughs, a silver-green
    canopy of squashed blobs, a few dark olives."""
    rng = random.Random(seed)
    x = y = 0.0
    z = 0.0
    seg = height * 0.45 / 3
    for i in range(3):  # the gnarled trunk leans a little each segment
        lean = (rng.uniform(-14, 14), rng.uniform(-14, 14))
        b.cyl(0.85 - i * 0.12, seg, (x, y, z), "bark", segs=7, top_radius=0.7 - i * 0.12, rot=(lean[0], lean[1], 0))
        x += math.sin(math.radians(lean[1])) * seg * 0.5
        y -= math.sin(math.radians(lean[0])) * seg * 0.5
        z += seg * 0.95
    top = Vector((x, y, z))
    for k in range(3):  # boughs
        a = k / 3 * math.tau + rng.random()
        b.cyl(0.22, height * 0.22, tuple(top), "bark", segs=5, top_radius=0.12, rot=(math.degrees(math.sin(a)) * 0.6 + 35 * math.sin(a), 35 * math.cos(a), 0))
    for k in range(8):  # canopy: low and wide, silver-green on top of dark green
        a = k / 8 * math.tau + rng.random() * 0.5
        r = rng.uniform(1.4, 2.6)
        c = top + Vector((math.cos(a) * r, math.sin(a) * r, rng.uniform(0.2, 1.2)))
        b.sphere(rng.uniform(1.4, 2.0), tuple(c), "leaf" if k % 2 else "leaf_light", segs=8, rings=5, scale=(1.25, 1.25, 0.55))
    for _ in range(6):
        a = rng.random() * math.tau
        c = top + Vector((math.cos(a) * 2.4, math.sin(a) * 2.4, rng.uniform(0.6, 1.6)))
        b.sphere(0.18, tuple(c), "basalt", segs=5, rings=3)
    # Built at a small size, then scaled to a real olive next to 14-stud lane walls (9–12 studs).
    bmesh.ops.scale(b.bm, vec=(2.0, 2.0, 2.0), verts=list(b.bm.verts))


def olive_tree_a(b):
    olive_tree(b, 11, 7.0)


def olive_tree_b(b):
    olive_tree(b, 23, 8.5)


def olive_tree_c(b):
    olive_tree(b, 37, 5.5)


def orchard_wall_low(b):
    # a dry-stone field wall 8 studs long, knee high, of irregular stones
    rng = random.Random(5)
    for row in range(3):
        x = -4.0 + (0.4 if row % 2 else 0.0)
        while x < 4.0:
            w = rng.uniform(0.8, 1.4)
            b.box((min(w, 4.0 - x), 1.4 - row * 0.15, 0.55), (x + min(w, 4.0 - x) / 2, 0, row * 0.55), rng.choice(["stone", "cobble", "plaster_shade"]), rot=(0, 0, rng.uniform(-3, 3)))
            x += w
    b.box((8.2, 1.2, 0.25), (0, 0, 1.65), "stone")


def terrace_step(b):
    # a step between two terraces: a retaining face of stones and an earth top, 8 wide
    b.box((8, 3, 1.6), (0, 0, 0), "dust")
    for i in range(6):
        b.box((1.3, 0.3, 1.6), (-3.3 + i * 1.32, -1.55, 0), "stone" if i % 2 else "cobble")
    b.box((8, 3, 0.1), (0, 0, 1.6), "grass")


def irrigation_channel_4m(b):
    for side in (-1, 1):
        b.box((16, 0.7, 0.6), (0, side * 0.9, 0), "stone")
    b.box((16, 1.1, 0.15), (0, 0, 0), "cobble_dark")
    b.box((16, 1.0, 0.05), (0, 0, 0.3), "water")


def olive_press(b):
    # the stone mill: a round basin, an upright millstone on a wooden axle, a beam to turn it, oil jars
    b.cyl(3.4, 1.4, (0, 0, 0), "stone", segs=16)
    b.cyl(2.9, 0.12, (0, 0, 1.4), "olive", segs=16)
    b.cyl(1.4, 0.9, (1.0, 0, 1.4), "plaster_shade", segs=14, rot=(90, 0, 0))  # the millstone on its edge
    b.cyl(0.35, 3.4, (0, 0, 1.4), "wood_dark", segs=8)  # central post
    b.box((7.6, 0.35, 0.35), (1.4, 0, 2.8), "wood")  # the beam
    b.cyl(0.6, 0.9, (4.6, 1.6, 0), "terracotta", segs=10, top_radius=0.35)
    b.cyl(0.55, 0.8, (4.4, -1.4, 0), "terracotta", segs=10, top_radius=0.3)
    b.box((1.4, 1.0, 0.5), (-4.0, 0, 0), "wood")  # trough
    b.box((1.2, 0.8, 0.1), (-4.0, 0, 0.45), "olive")


def sack_pile(b):
    rng = random.Random(8)
    spots = [(-1.0, 0, 0), (0.9, 0.2, 0), (0, -0.9, 0), (-0.2, 0.1, 1.1), (0.7, -0.4, 1.0)]
    for x, y, z in spots:
        b.sphere(0.95, (x, y, z + 0.6), "sack", segs=8, rings=5, scale=(1.0, 0.75, 0.62))
        b.cyl(0.22, 0.3, (x, y, z + 1.15), "net", segs=6, top_radius=0.1)
    b.box((0.06, 0.06, 0.06), (0, 0, 0), "net")  # keeps the origin on the ground


def oil_jar_cluster(b):
    for x, y, s in ((-0.9, 0.2, 1.0), (0.6, -0.3, 0.85), (0.2, 0.9, 0.7)):
        b.cyl(0.55 * s, 0.35 * s, (x, y, 0), "terracotta", segs=10, top_radius=0.75 * s)
        b.cyl(0.75 * s, 0.9 * s, (x, y, 0.35 * s), "terracotta", segs=10, top_radius=0.4 * s)
        b.cyl(0.3 * s, 0.3 * s, (x, y, 1.25 * s), "terracotta", segs=8, top_radius=0.38 * s)


def harvest_net(b):
    # a net spread under a tree to catch olives, 6 × 6, with olives on it
    rng = random.Random(3)
    b.box((6, 6, 0.04), (0, 0, 0), "net")
    for i in range(7):
        b.box((0.08, 6, 0.06), (-3 + i, 0, 0.04), "sack")
        b.box((6, 0.08, 0.06), (0, -3 + i, 0.04), "sack")
    for _ in range(18):
        b.sphere(0.13, (rng.uniform(-2.6, 2.6), rng.uniform(-2.6, 2.6), 0.12), "basalt", segs=5, rings=3)


def ladder(b):
    # a wooden ladder leaning back against a tree or wall (foot at the origin)
    for side in (-1, 1):
        b.box((0.18, 0.18, 7.0), (side * 0.6, 0, 0), "wood", rot=(-14, 0, 0))
    for i in range(8):
        z = 0.6 + i * 0.8
        b.box((1.25, 0.14, 0.14), (0, z * math.tan(math.radians(14)), z), "wood_dark")


MODULES = {
    # lane walls
    "wall_2m": wall_2m, "wall_4m": wall_4m, "wall_corner": wall_corner, "wall_arch": wall_arch,
    "wall_window_grille": wall_window_grille, "mashrabiya_bay": mashrabiya_bay,
    # gates (the match "gate" at the road's end)
    "gate_lane": gate_lane, "gate_rival": gate_rival, "warehouse_door": warehouse_door,
    # street
    "cobble_tile_4m": cobble_tile_4m, "kerb_4m": kerb_4m, "gutter_4m": gutter_4m, "step_set": step_set,
    "well": well, "bench_dikkeh": bench_dikkeh, "lantern_wall": lantern_wall, "lantern_wire_span": lantern_wire_span,
    # quarter
    "bakery_front": bakery_front, "warehouse_block": warehouse_block, "police_post": police_post,
    "rooftop_stair": rooftop_stair, "skyline_dome": skyline_dome, "skyline_minaret": skyline_minaret,
    # ground
    "grass_patch": grass_patch, "dust_patch": dust_patch, "rubble": rubble,
    # orchard (organic half, S1-M02): the Olive Press event map
    "olive_tree_a": olive_tree_a, "olive_tree_b": olive_tree_b, "olive_tree_c": olive_tree_c,
    "orchard_wall_low": orchard_wall_low, "terrace_step": terrace_step, "irrigation_channel_4m": irrigation_channel_4m,
    "olive_press": olive_press, "sack_pile": sack_pile, "oil_jar_cluster": oil_jar_cluster,
    "harvest_net": harvest_net, "ladder": ladder,
}


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    OUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    img = build_atlas()
    mat = atlas_material(img)
    coll = bpy.data.collections.new("kit")
    bpy.context.scene.collection.children.link(coll)
    spacing = 30
    for i, (name, fn) in enumerate(MODULES.items()):
        b = Builder()
        fn(b)
        obj = b.to_object("kit_" + name, coll, mat)
        # lay the modules out on a grid in the .blend so a person can look at them side by side
        obj.location = ((i % 6) * spacing, (i // 6) * spacing, 0)
    img.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND), compress=True)
    print("KIT_BUILD_OK", len(MODULES), "modules ->", OUT_BLEND)


main()
