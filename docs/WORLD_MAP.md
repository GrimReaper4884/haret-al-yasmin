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

## The bigger lane (LOOK_AND_PLAY_PLAN §4.1, LP-D00 scaffolding)

The slice's coordinates stay. New zones grow outward; each is a `Model` named `Zone_<id>` with
`ModelStreamingMode = Atomic`, built by `server/World/Zones/<module>.luau` once its task ships (the table is
`src/shared/Config/LaneZones.luau`; `tests/lanezones.spec.luau` checks no overlap and the budget). Lobby budget
**9,000 parts** (6,000 stream at once); baseline at LP-D00: **1,423 parts**, desktop Studio 60 FPS (16.6 ms
median, 17.8 ms p95).

| Zone ID | Bounds (x0, z0, x1, z1) | What | Budget | Task | Status |
|---------|------|------|--------|------|--------|
| `souq` | 24, 40, 64, 76 (+ passage 8..24, 64..72) | covered souq off the lane's east side, entered through a vaulted passage under EastA's south end (EastA now z 72..88): corridor A east (z 64..72) to the corner, corridor B south (x 52..60) to the khan door; niches for the potter (cat on a jar), the clog-maker, Abu Marzouk's greens and cart, Abu Brahim's cloth shop (bolts on the awning, the chest), a coppersmith; slatted roof at 13..14, 2 lights + 5 glowing lamps; Brahim (crowd look) by the cloth shop | 1,000 (254 built) | LP-D03 | built |
| `hammam` | −62, 0, −24, 40 (+ passage −24..−8, 27..32) | behind the square's north-west block: a low vaulted passage under WestB's south end (WestB now z 32..50, a stone pier at z 24..27) leads from the lane, beneath the sabat, into a court (x −60..−24, z 26..38); the bath-house (x −62..−40, z 2..26) faces it with banded stone, a curtained pointed arch, a dome with bottle-glass oculi and a steaming roof vent; bench with towels, a towel line, clogs and copper bowls, a basin; Abu Basim at the door | 700 (91 built) | LP-D04 | built |
| `diwan` | 24, −28, 54, −2 | the za'im's house behind SquareSE (now 6 deep, x 24..30): an ablaq portal at z −16..−11 with open leaves, stone benches and a tiled panel; a court with ablaq paving, a pool with a jet, two citrus trees; the liwan on the east side (cushions on three sides, the za'im's low table with coffee pot and cups, a brazier, a rug). Za'im Abu Faleh sits there; Al-'Akeed Abu Shehan walks liwan → portal → square → gate | 900 (115 built) | LP-D05 | built |
| `mosque_court` | 24, −2, 50, 26 | exterior only, behind SquareNE (now 6 deep): an ablaq arch at z 16..21 north of the Event arch; the court with the ablution fountain (taps, stools), a fig tree, a bench, the mosque's closed door under a canopy with a tiled band and grilled windows; the minaret in the north-east corner (moved from the skyline) | 500 (104 built) | LP-D05 | built |
| `post` | −44, 96, −16, 124 | outside the gate, west of the road: a walled yard open to the road, the stone post building (door at z 111, barred windows), the kit's sentry box at the mouth, a flag pole with a plain pennant, two straw dummies in kepis, the "wanted: Al-Adashari" poster, a bench; Abu Jawdan at the door, Corporal Houri in the yard | 600 (97 built) | LP-D06 | built |
| `orchard_road` | −16, 96, 44, 154 | the gate's outer wall opens (x −6..6) onto a packed-earth road to a vista wall at z 152 with the kit's rival-lane gate; east: olive (kit) and apricot orchards behind low kit walls, the well, a harvest net; west strip: the donkey cart of pickles (`Props.pickleCart`; its twin by the west wall inside the gate is the story cart, S1-A08, with Al-Adashari beside it after Episode 9), oil jars, the old olive with a rifle in its hollow; lights on the vista and east walls | 1,000 (79 built) | LP-D06 | built |
| `rooftop_view` | −24, 24, 24, 84 (overhead) | WestB's roof: Fawza seated on its lane edge on a mat, a washing line on poles, a basket of washing, a jar, pots; EastA's roof (Feryal's, model LP-D08): a washing line, a stool, a rolled mattress, pots. Nothing collides. Fawza calls a line every 90 s and waves her broom (RooftopController) | 150 (36 built) | LP-D07 | built |

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
| Square west (x -40..-24, z -26..0) | The coffee house (replaces SquareSW): open ground floor behind two columns, dikkeh benches, three low tables with tea and backgammon, samovar, cat; NPC `qahwaji` Abu Hatem at (-27, -13) |
| Lane east (x 8..24, z 24..48) | The barber shop (replaces EastB): chair, mirror, bottle shelves, basin, bench, latticed bay above; NPC `barber` Abu Issam at (14.5, 36) |
| Lane west | Notice board at (-8, 5, 74) with the launch codes |
| Coffee house back wall | Stair door to the Hakawati's room at (-37, -20.5) with a sign and a red mat (`AfkGate` tag); the back bench is shortened to z -16..-3 |
| Hakawati's room (off-map) | The AFK chamber at (-3000, 0, 0), `World/AfkRoom.luau`: closed room x ±18, z ±13, 15 high, painted ceiling, dais with the storyteller (NPC `hakawati`) at the north end, 12 stools + benches on three walls (34 seats), exit door in the south wall. Streams atomically; see docs/AFK_CHAMBER.md |
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
