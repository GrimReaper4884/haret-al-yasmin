# World Map

*Status: living document · Last updated 2026-10-15*

Coordinates are in studs. +Y is up, and ground level is Y = 0. The origin is the centre of the fountain
square. The lane runs along the Z axis from the gate (north, +Z) to Sitt Wardeh's house (south, −Z). The
authoritative layout is in code, in `src/server/Services/WorldService.luau`. Keep this table in sync with it.

```
                 N (+Z)
        ┌───────[ Jasmine Gate ]───────┐   z = 92
        │           Spawn (0,80)        │
        │                               │
 Bakery │◄ Abu Nadim (-11,60)           │
 z50-70 │        Jasmine Lane           │ Tailor stall  z48-64
        │          x −8..8   Khalil (11,56) ►│
        │                               │
        └──────┐                ┌───────┘   z = 24
               │  Fountain Sq.  │  r = 22, centre (0,0)
               │      ( ◎ )     │
               └──────┐  ┌──────┘          z = −24
                 ┌────┘  └────┐
                 │ Sitt Wardeh│  courtyard house x −16..16, z −26..−58
                 │   (4,−40)  │
                 └────────────┘                  S (−Z)
```

## Zones in the slice

| Zone ID | Name | Bounds | Key objects |
|---------|------|--------|-------------|
| `gate` | Jasmine Gate | x −8..8, z 84..94 | Basalt arch, SpawnLocation at (0, 0, 80) facing −Z |
| `lane` | Jasmine Lane | x −8..8, z 24..84 | Cobblestone floor, façades with jutting upper storeys, lanterns |
| `bakery` | Abu Nadim's bakery | x −22..−8, z 50..70 | Open counter at x −8.5, domed oven, bread racks, NPC `abu_nadim` |
| `tailor` | Khalil's stall | x 8..20, z 48..64 | Awning, cloth bolts, mannequin with tarboosh, NPC `khalil_tailor` |
| `square` | Fountain square | radius 22 around origin | Octagonal fountain, benches, citrus trees |
| `wardeh_house` | Sitt Wardeh's courtyard | x −16..16, z −58..−26 | Arched entrance at z −26, courtyard pool, jasmine tree, NPC `sitt_wardeh` |

The delivery route from Abu Nadim to Sitt Wardeh is about 100 studs, roughly 6 seconds of walking at the
default WalkSpeed. That is short enough for a first quest and long enough to show off the map.

## Set dressing (v2, 2026-10-15)

Built in `src/server/World/` (Kit → Props → Facade → Zones). Signature elements:

| Where | Elements |
|-------|----------|
| Lane | **Sabat** (covered room bridging the lane) at z 28–34; latticed mashrabiya bays on corbels; arched doors with ablaq voussoirs, iron bands and knockers; grilled windows with pots on sills; central basalt gutter; stone kerbs; grapevine trellises (z 46, 76); washing lines (z 59, 84); crates, cat, copper pot |
| Gate | Ablaq voussoir arch, banded pillars, iron-banded leaves, wicket door, twin lanterns |
| Bakery / tailor / spice shop | Bread racks and stacked ka'ak, domed oven with firewood and flour sacks, peel; hanging cloth lengths, tarboosh moulds, dressed dummy; heaped spice sacks, jars, brass scale |
| Square | Octagonal tiled fountain with falling streams; orange and pomegranate trees; cushioned benches; pigeons; copper jugs |
| Courtyard house | Striped ablaq paving, tiled pool with jet, lemon and orange trees, climbing jasmine, liwan with diwan, tray and birdcage |
| Skyline (no collision) | Neighbouring roofs, three domes, a banded minaret, cypresses, softened by the Atmosphere haze |

Part count: **1,267** (budget 6,000).

## Boundaries

The building blocks themselves enclose the play space. Two invisible walls (`Transparency = 1`,
`CanQuery = false`) close the gaps beside the gate, where the lane floor is wider than the buildings.
Rooftops are out of reach: awnings top out at 11 studs and roofs start at 20 or more.

## Future zones

| Zone | Location (planned) | Milestone |
|------|--------------------|-----------|
| Hammam | West of the square | Jobs |
| Khan (caravanserai) | Outside the gate, north | Businesses |
| Mosque courtyard (exterior only) | East of the square | World 2 |
| Player home plots (8) | Side alleys branching from the lane | Homes |
| Rooftops | Above the lane | Events |

Each future zone is a separate streaming region (`Model.ModelStreamingMode = Atomic` for buildings),
budgeted at 3,000 parts or fewer.
