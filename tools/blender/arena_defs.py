"""Arena definitions for tools/blender/arena_build.py (docs/STORY_PLAN.md §8.3–8.5): roads, bounds,
spawns and the kit modules each arena is dressed with, in arena-local Roblox studs (x right, z toward
the back). `scatter` places trees (or any module) on free ground with a fixed seed, keeping their
footprint clear of every road. Edit here, rebuild the .blend, re-export the layout.
"""

ARENAS = {
    # The Olive Harvest event map (§8.4).
    "olive_press": {
        "name_key": "arena.olive_press.name",
        "theme": "orchard_kit",
        "roads": [[(-70, 30), (-30, 30), (-30, -10), (12, -10), (12, 24), (48, 24), (48, -20)]],
        "bounds": (-80, -40, 80, 36),
        "party": (30, -32),
        "modules": [
            ("gate_rival", -76, 30, -90), ("warehouse_door", 48, -24, 180), ("olive_press", -9, 9, 0),
            ("oil_jar_cluster", -2, 3, 40), ("oil_jar_cluster", -15, 15, 120), ("oil_jar_cluster", 5, -30, 200),
            ("oil_jar_cluster", 36, -30, 80), ("oil_jar_cluster", 24, 30, 300),
            ("sack_pile", -16, 2, 10), ("sack_pile", 0, 16, 90), ("sack_pile", 40, -14, 180), ("sack_pile", 56, -14, 270),
            ("sack_pile", -50, 20, 45), ("sack_pile", 20, 4, 135), ("well", -48, -24, 0),
            ("lantern_wire_span", -30, -10, 45), ("lantern_wire_span", 12, -10, -45), ("lantern_wire_span", 12, 24, 45),
            ("harvest_net", -56, -6, 84), ("harvest_net", 30, 8, 58), ("harvest_net", -12, -28, 41),
            ("ladder", -52, -2, 20), ("ladder", 33, 12, 200),
        ]
        + [("orchard_wall_low", -72 + i * 8.2, -39, 0) for i in range(7)]
        + [("orchard_wall_low", -18 + i * 8.2, 35, 180) for i in range(7)]
        + [("terrace_step", x, -30 + i * 8.5, 90) for i in range(4) for x in (64, 72)],
        "scatter": [("olive_tree", 22, 2026, (0.75, 0.9), 5.5)],
    },
    # The fountain square (Episodes 4 and 6, §8.5): the lobby's saha rebuilt as an arena. Pickpockets
    # come down the rooftop stair (road 1) and through the side alley (road 2); the roads merge before
    # the square and end at the lane mouth.
    "saha": {
        "name_key": "arena.saha.name",
        "theme": "rival",
        "roads": [
            [(-62, 30), (-34, 30), (-34, 6), (-6, 6), (22, 6), (22, 28), (54, 28), (54, -30)],
            [(-62, -30), (-40, -30), (-40, -14), (-6, -14), (-6, 6), (22, 6), (22, 28), (54, 28), (54, -30)],
        ],
        "bounds": (-72, -40, 70, 36),
        "party": (40, -34),
        "ally": (48, -26),
        "modules": [
            ("rooftop_stair", -66, 30, -90), ("wall_arch", -66, -30, -90), ("gate_lane", 54, -36, 180),
            ("well", 6, 18, 0), ("bench_dikkeh", -2, 20, 90), ("bench_dikkeh", 14, 20, -90),
            ("lantern_wire_span", -34, 6, 45), ("lantern_wire_span", 22, 28, -45), ("lantern_wall", -20, 34, 180),
            ("bakery_front", -40, 37, 180), ("wall_4m", -18, 37, 180), ("wall_window_grille", -4, 37, 180),
            ("mashrabiya_bay", -4, 36, 180), ("wall_4m", 12, 37, 180), ("mashrabiya_bay", 12, 36, 180),
            ("wall_4m", -40, -41, 0), ("wall_window_grille", -24, -41, 0), ("wall_4m", -12, -41, 0),
            ("mashrabiya_bay", -12, -40, 0), ("wall_4m", 4, -41, 0), ("wall_corner", 20, -41, 0),
            ("skyline_dome", 30, 60, 0), ("skyline_minaret", -50, 62, 0),
        ]
        + [("cobble_tile_4m", x, z, 0) for x in (-2, 14) for z in (-30, 18)],
        "scatter": [("rubble", 3, 11, (0.8, 1.0), 4.0), ("sack_pile", 4, 12, (1.0, 1.0), 2.5)],
    },
    # The warehouse yard (Episode 5, §8.5): an orchard road with two tight bends under lantern wires,
    # ending at the 'akeed's warehouse door. The last leg runs past the z = 14 leg so the gate wall
    # (40 studs either side of the end) stands clear of the road (player report 2026-10-18).
    "warehouse": {
        "name_key": "arena.warehouse.name",
        "theme": "orchard",
        "roads": [[(-70, -30), (-70, 20), (-40, 20), (-40, -14), (-6, -14), (-6, 14), (20, 14), (20, -24), (44, -24), (44, 26)]],
        "bounds": (-80, -36, 66, 32),
        "party": (58, -28),
        "modules": [
            ("gate_rival", -70, -35, 0), ("warehouse_door", 44, 28, 0), ("warehouse_block", 44, 36, 0),
            ("lantern_wire_span", -6, -14, 45), ("lantern_wire_span", 20, 14, -45),
            ("sack_pile", 34, 20, 30), ("sack_pile", 54, 20, 300), ("oil_jar_cluster", 30, 24, 0),
            ("oil_jar_cluster", 58, 22, 90), ("well", -56, -6, 0), ("ladder", -28, 4, 10),
        ]
        + [("orchard_wall_low", -76 + i * 8.2, 31, 180) for i in range(9)]
        + [("orchard_wall_low", -40 + i * 8.2, -35, 0) for i in range(6)],
        "scatter": [("olive_tree", 16, 55, (0.75, 0.9), 5.5), ("sack_pile", 3, 56, (1.0, 1.0), 2.5)],
    },
    # The police-post road (Episode 7, §8.5): three long straights past the gendarmerie post, the road
    # narrowed by sandbag chicanes (sack piles at the bends; dressing only, PATH_HALF_WIDTH unchanged).
    "post_road": {
        "name_key": "arena.post_road.name",
        "theme": "orchard",
        "roads": [[(-70, -24), (30, -24), (30, 4), (-30, 4), (-30, 26), (66, 26)]],
        "bounds": (-80, -36, 76, 36),
        "party": (52, -20),
        "ally": (44, 12),
        "modules": [
            ("gate_rival", -74, -24, -90), ("gate_lane", 70, 26, 90), ("police_post", -58, 10, 90),
            ("lantern_wall", -46, 4, 90), ("lantern_wall", 40, -14, -90),
            ("lantern_wire_span", 30, -24, 45), ("lantern_wire_span", -30, 4, -45), ("lantern_wire_span", 30, 26, 0),
            ("sack_pile", 22, -31, 0), ("sack_pile", 37, -16, 90), ("sack_pile", 22, 11, 180),
            ("sack_pile", -22, -3, 0), ("sack_pile", -37, 12, 90), ("sack_pile", -22, 33, 180),
            ("sack_pile", 0, -31, 0), ("sack_pile", 6, 33, 180), ("wall_corner", -64, 30, 90),
            ("skyline_minaret", 20, 60, 0),
        ]
        + [("orchard_wall_low", -76 + i * 8.2, -35, 0) for i in range(6)],
        "scatter": [("olive_tree", 10, 71, (0.75, 0.9), 5.5), ("rubble", 4, 72, (0.8, 1.0), 4.0)],
    },
    # Twin gates (Episodes 8 and 9, §8.5): two rival gates 40 studs apart at the west wall; the roads
    # merge at a small square and run on together to the lane gate. Both roads end at the same gate.
    "twin_gates": {
        "name_key": "arena.twin_gates.name",
        "theme": "rival",
        "roads": [
            [(-74, 20), (-30, 20), (-30, 0), (0, 0), (30, 0), (30, 24), (64, 24), (64, -30)],
            [(-74, -20), (-40, -20), (-40, -32), (0, -32), (0, 0), (30, 0), (30, 24), (64, 24), (64, -30)],
        ],
        "bounds": (-80, -40, 72, 36),
        "party": (46, -12),
        "ally": (14, 10),
        "modules": [
            ("gate_rival", -78, 20, -90), ("gate_rival", -78, -20, -90), ("gate_lane", 64, -36, 180),
            ("well", 14, -14, 0), ("bench_dikkeh", 8, -20, 90), ("bench_dikkeh", 20, -20, -90),
            ("lantern_wire_span", -30, 0, 45), ("lantern_wire_span", 0, -32, -45), ("lantern_wire_span", 30, 24, -45),
            ("lantern_wall", -12, 7, 180),
            ("wall_4m", -40, 37, 180), ("wall_window_grille", -24, 37, 180), ("mashrabiya_bay", -24, 36, 180),
            ("wall_4m", -8, 37, 180), ("wall_arch", 8, 37, 180), ("wall_4m", 24, 37, 180),
            ("wall_4m", -24, -41, 0), ("wall_window_grille", -8, -41, 0), ("wall_corner", 8, -41, 0),
            ("skyline_dome", 26, 62, 0), ("skyline_minaret", -46, 64, 0), ("skyline_minaret", 60, 58, 0),
        ]
        + [("cobble_tile_4m", x, z, 0) for x in (6, 22) for z in (-14,)],
        "scatter": [("rubble", 3, 81, (0.8, 1.0), 4.0), ("sack_pile", 4, 82, (1.0, 1.0), 2.5)],
    },
}
