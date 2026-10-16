"""Headless rig preview, step 2: draws the figures from rigs.json (tools/rigpreview/export.luau)
as a contact sheet, front three-quarter view. Approximate (flat shading, no materials) but good
enough to judge proportions and silhouettes without opening Studio.

    pip install matplotlib numpy            (once, in any venv)
    python tools/rigpreview/render.py <dir-with-rigs.json> unit|enemy out.png [id,id,...]
"""
import json, sys, math
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

here = sys.argv[1]
which = sys.argv[2]  # unit | enemy
out = sys.argv[3]
ids = sys.argv[4].split(",") if len(sys.argv) > 4 else None
rigs = json.load(open(f"{here}/rigs.json"))

def box(sx, sy, sz):
    x, y, z = sx / 2, sy / 2, sz / 2
    v = np.array([[-x,-y,-z],[x,-y,-z],[x,y,-z],[-x,y,-z],[-x,-y,z],[x,-y,z],[x,y,z],[-x,y,z]])
    f = [[0,1,2,3],[4,5,6,7],[0,1,5,4],[2,3,7,6],[1,2,6,5],[0,3,7,4]]
    return [v[i] for i in f]

def sphere(sx, sy, sz, n=10):
    faces = []
    for i in range(n):
        t0, t1 = math.pi * i / n, math.pi * (i + 1) / n
        for j in range(2 * n):
            p0, p1 = 2 * math.pi * j / (2 * n), 2 * math.pi * (j + 1) / (2 * n)
            def pt(t, p):
                return [sx / 2 * math.sin(t) * math.cos(p), sy / 2 * math.cos(t), sz / 2 * math.sin(t) * math.sin(p)]
            faces.append(np.array([pt(t0, p0), pt(t0, p1), pt(t1, p1), pt(t1, p0)]))
    return faces

def cylinder(sx, sy, sz, n=14):
    r = min(sy, sz) / 2
    h = sx / 2
    faces = []
    ring = [(r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n)) for k in range(n)]
    for k in range(n):
        a, b = ring[k], ring[(k + 1) % n]
        faces.append(np.array([[-h, a[0], a[1]], [h, a[0], a[1]], [h, b[0], b[1]], [-h, b[0], b[1]]]))
    faces.append(np.array([[-h, p[0], p[1]] for p in ring]))
    faces.append(np.array([[h, p[0], p[1]] for p in ring]))
    return faces

def render(ax, parts, azim, zoom=1):
    polys, cols = [], []
    for p in parts:
        if p["transparency"] >= 0.99:
            continue
        sx, sy, sz = p["size"]
        shape = p["shape"]
        if shape == "Ball":
            d = min(sx, sy, sz)
            local = sphere(d, d, d)
        elif shape == "Cylinder":
            local = cylinder(sx, sy, sz)
        else:
            local = box(sx, sy, sz)
        r = np.array(p["rot"]).reshape(3, 3).T  # columns = X, Y, Z vectors
        pos = np.array(p["pos"])
        c = list(p["color"]) + [1 - p["transparency"] * 0.8]
        for f in local:
            w = (r @ f.T).T + pos
            polys.append(w[:, [0, 2, 1]] * np.array([1, -1, 1]))
            cols.append(c)
    pc = Poly3DCollection(polys, facecolors=cols, edgecolors=(0, 0, 0, 0.15), linewidths=0.2)
    ax.add_collection3d(pc)
    ax.set_xlim(-2.6 * zoom, 2.6 * zoom); ax.set_ylim(-2.6 * zoom, 2.6 * zoom); ax.set_zlim(0, 7.6 * zoom)
    ax.set_box_aspect((5.2, 5.2, 7.6))
    ax.view_init(elev=8, azim=azim)
    ax.set_axis_off()

names = [k for k, v in rigs.items() if v["kind"] == which and (ids is None or k in ids)]
names.sort()
cols_n = min(len(names), 6)
rows_n = math.ceil(len(names) / cols_n)
fig = plt.figure(figsize=(cols_n * 2.6, rows_n * 3.6), facecolor="#E9DFCB")
for i, n in enumerate(names):
    ax = fig.add_subplot(rows_n, cols_n, i + 1, projection="3d", computed_zorder=False)
    ax.set_facecolor("#E9DFCB")
    render(ax, rigs[n]["parts"], azim=112, zoom=1.0 if which == "unit" else 1.5)
    ax.set_title(n, fontsize=11, pad=-6)
plt.subplots_adjust(wspace=0, hspace=0.05, left=0, right=1, top=0.96, bottom=0)
plt.savefig(out, dpi=110, facecolor=fig.get_facecolor())
print("saved", out)
