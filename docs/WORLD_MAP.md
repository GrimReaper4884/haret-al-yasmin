# World Map

*Status: living document · Last updated 2026-10-16*

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

## Tower-defense update (v3, 2026-10-16)

| Where | Elements (`World/Zones/Extras.luau`, `World/Props2.luau`) |
|-------|----------|
| Gate | Rebuilt leaves (`Props2.gate`, open, swinging inward), wicket, knockers, bar hooks, the bar leaning by the east jamb; nameplates "حارة الياسمين" on both faces; the watchman Abu Fares (NPC `natour`) with stool and lantern at (5.5, 84) |
| Square | Four mode portals: pads at (-19, 2) Ep1, (-19, -8) Ep2, (19, 2) Ep3, (19, -8) Endless, each with a banded arch, lantern and Arabic board; billboards are client-side |
| Square west (x -40..-24, z -26..0) | The coffee house (replaces SquareSW): open ground floor behind two columns, dikkeh benches, three low tables with tea and backgammon, samovar, cat; NPC `qahwaji` Abu Hamed at (-27, -13) |
| Lane east (x 8..24, z 24..48) | The barber shop (replaces EastB): chair, mirror, bottle shelves, basin, bench, latticed bay above; NPC `barber` Abu Nidal at (14.5, 36) |
| Lane west | Notice board at (-8, 5, 74) with the launch codes |
| Shops | Painted signs over the bakery, tailor and spice shop |
| Crowd | 8 ambient walkers (`CrowdService`) between gate, shops and square |

### Arenas (`Config/Arenas.luau`, `World/Arena.luau`)

Built on demand at x = 3000 + 600 * (slot - 1) (up to 6). Local coordinates:

| Arena | Road | Bounds | Party spawn |
|-------|------|--------|-------------|
| `orchard` (Ep1, Ep2) | (-64,-34) -> (-64,12) -> (-28,12) -> (-28,-18) -> (12,-18) -> (12,20) -> (50,20) -> (50,-26) = gate; 274 studs | x -74..74, z -42..32 | (30, -32) |
| `siege` (Ep3, Endless) | (-70,24) -> (-40,24) -> (-40,-22) -> (0,-22) -> (0,22) -> (36,22) -> (36,-10) -> (64,-10) = gate; 262 studs | x -80..80, z -36..36 | (60, 20) |

Each arena: grass field with garden plots (trees, low walls, crates, a well) kept 9 studs off the road and 12
off the spawn pad, a cobbled road with kerbs and a milestone at the start, the quarter wall with the closed,
barred gate and nameplate at the end, an invisible fence at the bounds. Part count ~600 per arena. Matches
open in the overhead "watchtower" camera (`MatchCameraController`), with a Walk toggle.
