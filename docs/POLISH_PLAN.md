# Look-and-feel plan: "Perfectize" pass (Phase V)

*Written 2026-10-17 by the planning session after a live audit of the TEST place (Studio Play Solo through the
Studio MCP, computer use to launch Studio and Blender). Executor: Opus 5.5 in Claude Code on the owner's
Windows machine. Owner: approves looks, uploads images, publishes.*

This document is the whole work queue for the visual pass: real Meshy enemies instead of the blocky
primitives, animation and effects, a hand-made icon set for the game's own objects (lira, qirsh, trait stones,
bread, tea glass…), the experience icon, covers and thumbnails, an animated logo and loading screen, and the
lobby/arena dressing that makes the lane feel alive. Everything below is a task with an **Accept** line. Do
the tasks in order inside each workstream; workstreams A, B, C can run in parallel sessions as long as the
file-ownership rule in §2 holds.

---

## 0. Kickoff prompt (paste this into Opus 5.5)

> Read `CLAUDE.md`, `docs/TOOLS.md`, `docs/DECISIONS.md`, `docs/ART_BIBLE.md`, `docs/CHARACTER_PIPELINE.md` and
> `docs/POLISH_PLAN.md`. Work through `docs/POLISH_PLAN.md` workstream by workstream, starting with PV-A01.
> For every task: follow the CLAUDE.md verify loop (code + Lune spec, `tools/check.ps1` green, `script_grep`
> sync check, Studio playtest through the MCP with `screen_capture` evidence), commit one task per commit on
> branch `phase/polish` (cut it from `phase/0`), tick the task in `docs/POLISH_PLAN.md` §9 with the commit hash,
> and log TUNE changes or deviations in `docs/DECISIONS.md`. Every generated asset gets a
> `docs/COPYRIGHT_REGISTER.md` row. Stop and ask for anything on the "STOP" lines (Meshy spend above the stated
> budget, image uploads to Roblox, publishing, anything that needs a human click such as Rojo Connect or the
> Studio importer). Never put a TV series title, actor or real person in any prompt. When all tasks of a
> workstream are ticked, post the before/after screenshots and wait.

---

## 1. What the audit found (2026-10-17, place version 95, Episode 1 Normal, Play Solo)

Screenshots are in `docs/art/polish_audit_*_2026-10-17.jpg`.

| Area | Seen | Verdict |
|---|---|---|
| Defenders | 16 Meshy cast members with baked signature clips; cards show the posed idle; hand props back in hands | Good. Keep. |
| Attackers | Thief, gendarme, Al-Nims, Al-Idaashari, Abu al-Nar are Meshy. **Thug, bandit, rider, sapper, the Sergeant and the Commandant are still the primitive block figures (34–38 parts each)**: cube heads, grey block hatta, no face. In the wave-19 crowd (`polish_audit_wave19_primitive_crowd`) they stand next to the Meshy cast and look like a different game | **Worst problem. Workstream A.** |
| Enemy feedback | Hit = thin neon streak + small spark; death = petal poof; no hit flash on the figure, no death animation, no damage numbers, plain cyan health bars (`BillboardGui` 44×6 px) | Workstream B |
| Defender attacks | Thrown props exist (tea glass, bread, chickpeas, stone, shibriyeh) and are good; melee hits have no impact frame; abilities = gold beam + name banner | Workstream B |
| Match atmosphere | Night sky + moon, lanterns glow; `[Fx] live` peaks at 18 of 80; no particles anywhere in the project (`ParticleEmitter` is never created), no fog layering, no dust, no jasmine, no laundry, no life | Workstream E |
| Currency and rewards | Lira = flat purple disc, qirsh = flat gold ring; Lane Diary rewards are **text only** ("+25 lira"); summon buttons text only; store products have no icons; **not one image asset is used in the UI** (`Icons.luau` draws rectangles) | **Workstream C** |
| Menu rail | Primitive-drawn icons (units, summon, pass…) are readable but generic | Workstream C (replace with painted icons) |
| Experience page | No custom icon, no thumbnails, no video (`RELEASE_CHECKLIST` §B) | Workstream D |
| Loading / first impression | Default Roblox loading screen; no title card; no logo anywhere | Workstream D |
| Console | `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` ×6 on every join. The id is **not in this repo** (grep of `src`, `assets/*.rbxm`, `default.project.json`); it comes from Studio itself or an installed plugin. Confirm once with a published-client log; if it is ours, fix; if not, note in DECISIONS and ignore | PV-B00 |
| Tooling state | Studio MCP works after `open_application("Roblox Studio")` + clicking the TEST tile; **Rojo Connect needs the owner's click** (the automation classifier refuses it); Blender 5.2 up and connected to the Lab MCP (empty file); `blender` is **not on PATH** (use `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`); Meshy balance **1,304 credits**; Higgsfield (image/video MCP) **710 credits** on the max plan; `matplotlib` missing, so `tools/rigpreview/render.py` is dead until `pip install matplotlib` in a venv | §2 |

---

## 2. Rules for this pass

- Everything in `CLAUDE.md` still applies: server-authoritative, pure `Logic/*`, numbers in `Config`, Lune specs,
  no MCP script writes, Rojo + git own the scripts, one task per commit, STOP list.
- **Effects never change play.** Every effect is client-side, drawn from `UI/Fx` pools under `Config/Vfx` caps
  and gated by the Effects setting (`full` / `reduced` / `off`). New caps go in `Config/Vfx` with a spec in
  `tests/vfx.spec.luau`.
- **Phone first.** Every new effect is judged at 844×390 and through the Device Emulator. Particle budget:
  ≤ 24 live `ParticleEmitter`s in a match, `Rate` ≤ 20 on continuous emitters, one-shot `Emit(n)` for hits,
  textures ≤ 256² with alpha. `Highlight` only for bosses and the selected tower (Roblox caps 31 at once).
- **Images are assets with ids.** `Icons.luau` keeps the primitive drawers as the **fallback when an id is 0**
  (the same pattern as `CharacterLooks[id].model`). Ids live in a new `src/shared/Config/Icons.luau`. Nothing
  references `assets/unapproved`.
- **Uploading is the owner's click** unless PV-C01 (the Open Cloud uploader, BUILD_PLAN P3-02) is built and the
  owner says to use it. Either way the agent prepares the files and a one-line upload list.
- **Generated art is logged.** Each Meshy or Higgsfield asset gets a register row (tool, prompt, date, status).
  Meshy spend per task is capped below; ask before going over. Higgsfield: preflight with `get_cost: true`,
  keep ≥ 250 credits in reserve for the trailer (PV-D04).
- **Style lock (ART_BIBLE §2, §5, §6).** Chibi toy proportions, hand-painted flat colours, warm limestone
  palette, copper for money, dignity in faces. Enemies are hostile but never grotesque or ethnic caricature:
  colder palette (indigo, basalt, olive), red accents, scowls and sneers, heavier silhouettes than the cast.
- **File ownership when sessions run in parallel.** A = `tools/meshy/*`, `tools/anim/*`, `assets/*`,
  `Config/CharacterLooks`, `Config/Enemies` visual fields, `Anim/*`. B = `Controllers/EnemyRenderController`,
  `Controllers/MatchFxController`, `Controllers/ThrowFx`, `Controllers/RigAnimController`, `UI/Fx`,
  `Config/Vfx`, `Logic/VfxBudget`. C = `UI/Icons`, `UI/Theme`, `Config/Icons`, the screen controllers' icon
  slots. D = `assets/marketing`, `src/first/*`, `Controllers/TitleController`. E = `server/World/*`,
  `Config/PropPlacements`, `default.project.json` lighting. Two sessions never edit the same file; message
  first (`ListAgents` / `SendMessage`).

---

## 3. Workstream A: the remaining enemies through Meshy (no more block figures)

Budget: **≈ 420 Meshy credits** (6 characters × ≈ 47 + hit/death clips + two concept rerolls each). STOP if
the running total passes 500. Pipeline exactly as `docs/CHARACTER_PIPELINE.md` ("Making an imported
character" + "Signature animations"); the Studio importer and Clip Editor are owner clicks, so batch all six
GLBs into one "please import" request.

### PV-A01 Prompts and concept sheets (≈ 36 credits)
Add the six entries below to `tools/meshy/characters.json → characters` (keys = enemy ids), then run
`python tools/meshy/meshy.py make <id> --until concept` for each and build one contact sheet with
`tools/meshy/contact_sheet.py` → `docs/art/enemy_concepts_2026-10-xx.png`. Judge every concept against the
style lock before spending on meshes; reroll (delete the concept task id from `manifest.json`) until the
silhouette reads from the match camera (chibi, big head, one strong prop).

Prompts (the shared `style` and `texture_style` strings are prepended automatically; do not repeat them):

| id | height | prompt | texture |
|---|---|---|---|
| `thug` | 1.75 | Rival-lane street thug of 1930s Damascus, stocky young man with stubble and a sneer, black tarboosh pushed back, olive-green striped qumbaz with the sleeves rolled, wide black sash, baggy dark trousers, leather slippers, holding a short wooden cudgel in his right hand, swaggering stance | Olive and black stripes, black sash and tarboosh, dark wood cudgel, tan skin |
| `bandit` | 1.9 | Orchard bandit of the 1930s Syrian countryside, broad bearded man with a grey-and-white checkered head cloth (keffiyeh) under a black cord, long dusty brown robe, crossed leather bandoliers over the chest, dark cloak, tall boots, holding a curved sword in his right hand, grim menacing face | Dusty brown robe, grey-white checkered head cloth, dark brown cloak, worn leather bandoliers, steel sword, tan weathered skin |
| `rider` | 1.85 | Colonial-era mounted gendarmerie officer of the 1930s **on foot**, lean man with a thin handlebar moustache, dark blue kepi with a gold band, dark blue riding jacket with gold buttons and epaulettes, tan riding breeches, tall black riding boots with spurs, holding a sabre in his right hand and a riding crop tucked in his belt, arrogant upright pose | Navy jacket with gold braid, tan breeches, black boots and spurs, steel sabre, light skin |
| `sapper` | 1.8 | Military sapper of a 1930s colonial garrison, stocky man with a short beard, round steel helmet, dark grey work tunic with rolled sleeves, heavy canvas apron, leather gloves, a coil of fuse rope over the shoulder, holding a pickaxe in his right hand and a small powder keg under the left arm, dogged determined face | Dark grey tunic, steel helmet, tan canvas apron, brown rope, black-and-red powder keg, light skin |
| `sergeant` | 1.95 | The Sergeant (shawish), a burly 1930s colonial gendarmerie sergeant, thick black moustache and a scar on the cheek, dark blue kepi with a red band, dark blue uniform with gold chevrons on the sleeves, brass buttons, wide belt with a holster, tall black boots, holding a heavy cavalry sabre in his right hand, barking furious face | Navy uniform, gold chevrons and buttons, red kepi band, black boots, steel sabre, light skin |
| `colonel` | 2.1 | The Commandant, the towering commander of a 1930s colonial garrison, tall man with a grey goatee and monocle, black kepi with heavy gold braid, long black greatcoat with gold epaulettes and a red sash across the chest, white gloves, polished black boots, holding an ornate officer's sabre in his right hand, cold imperious face | Black greatcoat, gold braid and epaulettes, crimson sash, white gloves, steel sabre with a gold hilt, pale skin |

Notes: the "rider" is built **on foot** (see DECISIONS entry you will add: the biped auto-rig and the
humanoid clip library are the reliable path; Meshy's quadruped rig has almost no horse clips). His speed stays
in Config; the run clip (PV-A03) sells "mounted" speed. If the owner wants a real horse later, that is a
separate task (horse mesh with `"rig": false`, rider welded, a bob animation in `BoneAnim`).

**Accept:** six concept images approved by the owner (one Discord/chat message with the contact sheet); the
register has six "Proposed" rows (C-204…); credits logged in each `manifest.json`.

### PV-A02 Meshes, rigs and import (≈ 210 credits)
`make <id>` to the end for each approved concept (mesh ≈ 8k tris remeshed, rig, the free walk). Check tri
counts (`python tools/anim/islands.py list <glb>` also shows loose islands: drop fused props the way
`qahwaji_clean.glb` was made). Preview each rig with
`"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P tools/anim/preview.py -- <glb> <png> 8 front`.
STOP: ask the owner to import the six GLBs (Rig Type Custom, Upload on, Keep Zero Influence Bones) and save
them to `assets/production/CharacterModels/{Thug,Bandit,Rider,Sapper,Sergeant,Commandant}.rbxm`.
Then set `model = "<Name>"` in `CharacterLooks.luau` for the six ids and drop the `anims` publishing step: baked
clips only (PV-A03).

**Accept:** ≤ 12k tris each (bosses) / ≤ 6k (others); `search_game_tree ReplicatedStorage.CharacterModels`
lists 27 models; a Studio match at Episode 1 wave 12+ shows thugs and bandits as Meshy figures; a screenshot in
`docs/TEST_REPORT_SLICE.md`; `RigBuilder` still falls back cleanly when a model is missing (existing spec).

### PV-A03 Walk, run, hit and death clips for every attacker (≈ 110 credits)
`tools/anim/clips.json`: give each of the 11 attackers a `walk` (or `run` for `rider` and `thief`), a `hit`
and a new `death` slot; bosses also get an `intro` (a taunt) and a `stagger`. Choose from the library
(`python tools/meshy/meshy.py library --search <word>`): walks seen today: `Casual Walk` 30, `Walk Fight
Forward` 21, `Slow Orc Walk` 119 (bandit), `Injured Walk` 111 (sapper), `Red Carpet Walk` 117 / `Stage Walk`
55 (colonel), `Quick Walk` 115, runs `Run Fast` 16, `Run 2` 14 (rider), hits `Hit Reaction` 178 / 179, `BeHit
FlyUp` 7 or 608 for deaths (search also `die`, `dying`, `knock`, `fall`, `defeat`, `collapse` and pick one
per silhouette). Fetch (`tools/anim/fetch.py`), bake (`bake.py`; keep the walk's measured speed so the stride
matches `Enemies[id].speed`), and extend `RigAnimController` to play `death` (hold the last frame while the
model fades, PV-B03) and `intro` on boss spawn (PV-B06). Clip picks are judged first with `preview.py`.

**Accept:** every attacker id has walk/hit/death in `src/shared/Anim/Clips/<id>.luau`; a Studio wave shows
walks at the right stride (no sliding: `EnemyRenderController.speedOf` vs the clip's root speed logged within
10 %); deaths play before the petal poof; `lune run tests/run` green (the clip tables have a shape spec).

### PV-A04 Enemy read-at-a-glance (0 credits)
Make hostiles obvious from the overhead camera without reading names: a thin dark-red `UIStroke` ring under
each enemy health bar, a red ground disc (pooled `Fx` part, `reduced` keeps it) that follows bosses, and the
armour/stealth markers as small icons from PV-C03 on the health bar (shield for `armor`, eye for `stealth`).
Boss health bars become a top-of-screen bar with the boss's name and a 64 px portrait (PV-C05).

**Accept:** phone-emulator screenshot where thug, bandit, boss and a stealth thief are told apart in one glance;
no new per-frame work (`stats` in the debug overlay unchanged ± 1 part).

### PV-A05 Refresh the five older enemies (optional, ≈ 60 credits)
Al-Nims, Al-Idaashari, Abu al-Nar, thief, gendarme keep their meshes but get hit/death clips (covered by A03)
and, if the owner wants, a texture pass with `generate_texture` in Studio for stronger red accents. STOP before
re-texturing production models.

---

## 4. Workstream B: animation and effects ("juice")

Everything here is pooled, budgeted (`Config/Vfx`), setting-gated and tested with `tests/vfx.spec.luau`
(the budget maths and the per-event tables are pure). Timings follow `docs/research/ROBLOX_TD_UI_PATTERNS.md`
§Juice. Before starting, read `UI/Fx.luau`, `EnemyRenderController.luau`, `ThrowFx.luau`,
`MatchFxController.luau`, `RigAnimController.luau` end to end.

### PV-B00 Console hygiene
Track down `rbxassetid://203785492` (see §1). Also silence nothing of ours: the `[Fx]` overlay stays.
**Accept:** either a fix or a DECISIONS line "external, ignored", and a clean join log otherwise.

### PV-B01 Particle sprite kit (owner upload)
Author 8 sprite textures at 256² PNG with alpha, hand-painted look: soft spark, dust puff, jasmine petal,
smoke wisp, steam curl, bread-crumb speck, glass shard, star (for stuns). Make them with Higgsfield
`generate_image` (`gpt_image_2_5`, prompt "single hand-painted game VFX sprite of <thing>, soft edges,
centered, on pure black background, no text") and cut the alpha with Higgsfield `remove_background` or a
Python/PIL luminance-to-alpha pass; or with Blender (image editor, Lab MCP). Files →
`assets/marketing/vfx/*.png` (they are ours: register row). STOP: owner uploads via Creator Hub → Assets
(or PV-C01), pastes ids into `Config/Vfx.TEXTURES`.
**Accept:** ids non-zero in Config; `Fx.emitter(kind)` returns a pooled `ParticleEmitter` on an `Attachment`
with the right texture; zero-id kinds fall back to the current part-based effects.

### PV-B02 Hit feedback on the figure
- Hit flash: for MeshPart figures tint does not show through textures, so use a pooled `Highlight`
  (`FillColor` white, `FillTransparency` 0.55, 0.08 s) **only on bosses and the current target of the selected
  tower**; everyone else gets a 0.1 s scale punch on `Root` (0.94 → 1) through `BoneAnim`'s root offset.
- Impact burst: `Emit(6)` of the spark sprite at the hit point, colour by rarity (`Theme.rarityColor`).
- Damage numbers: a pooled `BillboardGui` pool (32), `FredokaOne` 18 px with a 2 px outline, rising 2 studs over
  0.5 s; crits (ability hits) 1.4× size in gold; `reduced` shows numbers only, `off` nothing. Numbers come from
  the existing `attack` events (`damage` field already in `MatchEvents`; verify in `TdSim`).
**Accept:** spec for the pool maths; Studio screenshot of a crowd with numbers; `[Fx] live` ≤ 80 at Endless
wave 30 with 4 players' towers (use `HaretDebug` `grant` + `place` and the party key `M`).

### PV-B03 Deaths and gate hits
- Death: play the `death` clip (PV-A03), then fade the mesh over 0.4 s with the petal/ash poof; bosses add a
  dust ring and a 0.2 s camera shake (respects Reduced Motion and the `Effects` setting).
- Reward pop: a copper coin sprite arcs from the corpse to the cash pill (one pooled `ImageLabel` flight,
  max 6 in flight) and `Juice.punch` the cash label.
- Gate hit: the existing red disc + edge flash, plus the gate leaves shudder (`PivotTo` wobble 0.25 s) and a
  dust burst at the foot of the doors; the gate HP bar shakes ±4 px.
**Accept:** before/after video-style screenshot pairs; `lune run tests/run` green.

### PV-B04 Per-role attack impacts
Keep the thrown props; add the impact frame per role using the lane's own objects:
melee (razor, cudgel, dagger) = a short white arc sprite + spark; ranged (stone, chickpeas) = puff at the
target; splash (bread, hammer, broom) = ground ring (exists) + dust puff + 0.05 s hit-stop on the figure's
clip (`BoneAnim` speed 0 for 3 frames); support (cane, lantern) = soft gold pulse ring on allies in range;
healer (remedy jar) = green-white sparkle rising on the gate or ally. Abilities keep the banner, add a
rarity-coloured radial vignette (exists) and a 0.3 s slow-in on the figure only.
**Accept:** one screenshot per role in `docs/TEST_REPORT_SLICE.md`; `Config/Vfx.ROLES` table drives it; spec
asserts every `Units[id].role` has an entry.

### PV-B05 Placement, upgrade, sell
Placement: the ghost already plays the idle; add a dust ring + 4 petals when the tower lands and a
`Juice.pop` on its card slot. Upgrade: a gold star burst (`Emit(10)` star sprite) and a 1 → 1.12 → 1 scale
punch; level 3+ adds a brief gold `Highlight`. Sell: a copper coin shower (6 sprites) into the cash pill.
Range preview on select: a soft ring with an ablaq (black/cream) dashed edge instead of the plain disc.
**Accept:** screenshots; no `Instance.new` per action except the first pool fill (counted in the overlay).

### PV-B06 Wave and boss presentation
- Wave clear: a short banner "Wave n cleared · +cash" sliding in from the top with a darbuka sting
  (`Audio.wave_start` exists; add `wave_clear` id 0 until commissioned).
- Boss intro: 1.2 s camera push toward the spawn gate (skipped when `Cutscenes` off; add that setting next
  to Effects), the boss `intro` clip, the red pulse rings (exist), the name banner in Arabic + English, the
  top boss bar (PV-A04).
- Final wave: moon turns warm, `Atmosphere` density up, lantern lights brighten 20 % (client-side tween).
- Victory: 'arada ribbons (two long sprite trails from the gate), petals from the sky for 3 s; defeat: the gate
  bar drops and the screen desaturates (`ColorCorrection`) for 1.5 s.
**Accept:** each moment captured with `screen_capture`; a `Logic/MatchMoments` pure module decides which
moment fires from events (specced) so the controller only draws.

### PV-B07 Lobby and UI motion
`Juice.press` on every button (audit: Codes/AFK/Settings rail buttons and the Wardrobe/Arabic pills); cards
in Units/Summon get a hover tilt (desktop only); the summon ×10 flip grid flips left-to-right (RTL in Arabic);
the lantern in `SummonSequence` gets the jasmine-petal sprite burst on Legendary+; the pass XP bar fills with
a shine sweep when XP changes; the daily chest wobbles when claimable; toasts slide instead of appearing.
**Accept:** reduced-motion mode disables all of it (spec on the gate function); screenshots.

---

## 5. Workstream C: the icon set (our own objects, not generic glyphs)

Goal: every number in the UI sits next to a painted icon of a thing from the lane, and the menu rail, store,
pass, daily, codes and summon screens use the same kit. Icons are 256² PNG with alpha, hand-painted flat
colour with a 2 px dark outline, readable at 28 px. Source: Higgsfield `generate_image` (`gpt_image_2_5`,
4 variants per prompt, pick one; preflight cost) with `remove_background`; final cleanup and 256² export in
Blender's image editor or PIL. Files → `assets/marketing/icons/<name>.png` plus a contact sheet in `docs/art/`.
Register row per batch (C-2xx, tool Higgsfield, prompt, date). All prompts end with: "flat hand-painted
cartoon game icon, thick dark outline, soft shading, warm Levantine palette, centered, isolated on plain
white background, no text, no watermark".

### PV-C01 Upload path (build P3-02 now)
Create `tools/upload_asset.py` exactly as BUILD_PLAN P3-02 describes (Open Cloud `assets/v1/assets`,
`ROBLOX_OPEN_CLOUD_KEY` + `ROBLOX_CREATOR_ID` from the environment, `--dry-run`, prints `rbxassetid://`,
never prints the key) and `tools/upload_manifest.json` (file → name → id). STOP: the owner approves the first
real upload (one test icon) before the batch. Fallback: the owner uploads through Creator Hub and pastes ids.
**Accept:** dry-run output in the commit body; one image id used from `Config/Icons`.

### PV-C02 `Config/Icons.luau` + `Icons.luau` image path
Pure data `{ [name] = { id = 0, tint = "#hex"? } }`; `Icons.draw(name, holder, colorHex)` first looks up the
id: non-zero → `ImageLabel` (`ScaleType Fit`, `ImageColor3` only when `tint` is set), zero → the existing
primitive drawer, unknown → text. Spec: every `Items[].icon`, every `ui_*` rail key, every currency and every
reward kind in `SeasonPass`, `Daily`, `Codes`, `Shops`, `Products` resolves to a known name.
**Accept:** spec green; no visual change yet with all ids 0.

### PV-C03 Currency and reward icons (the most important batch)
| name | subject |
|---|---|
| `lira` | an Ottoman-era gold lira coin seen at an angle, original ornamental calligraphic swirl in the centre (**not** a real tughra or a real coin's design), bevelled rim, warm gold with a copper edge |
| `qirsh` | a small copper qirsh coin, slightly worn, with an original star-and-crescent-free geometric rosette, copper and bronze |
| `lira_stack` / `qirsh_pouch` | a short stack of lira / a drawstring leather pouch spilling copper coins (store packs) |
| `stone` | a trait stone: a faceted amethyst-purple gem in a tiny brass setting with a jasmine-white glint |
| `stones_3` | three stones in a velvet-lined brass dish |
| `xp` | a Lane Diary page with a quill and a wax seal (season-pass XP) |
| `pass` | the Lane Diary itself: a leather notebook with a jasmine sprig on the cover |
| `ticket` | a summon ticket: a folded paper with a lantern stamp |
| `cash` | match cash: a copper coin with a tiny gate emblem (same shape family as qirsh, different colour so players never confuse them) |
Use them in: HUD pills (lobby lira/qirsh, match cash), summon buttons ("×1 · 50" + lira icon), Lane Diary
reward cells, daily rewards, code toasts, result screen rewards, store product cards, `reward.*` strings
(move the unit from text into the icon where a string currently says "+25 lira").
**Accept:** every currency number in every screen has an icon at its left (RTL: right) at ≥ 24 px; the pass
screen screenshot shows icons in the cells; Arabic layout verified.

### PV-C04 Menu rail, actions and roles
Rail: `units` (a tarboosh over a folded qumbaz), `summon` (the brass lantern), `pass` (the diary),
`codes` (a paper slip with a stamp), `play` (the lane gate with the bar), `event` (hanging crescent lantern),
`settings` (a brass coffee grinder), `afk` (tea glass on a saucer), `daily` (a wrapped sweets box), `shop`
(a copper scale). Actions: `upgrade` (arrow + star), `sell` (coins into a pouch), `target` (an eye), `speed`
(a darbuka), `skip` (two chevrons), `leave` (a door). Roles: `melee` (shibriyeh), `ranged` (sling), `splash`
(bread peel), `support` (lantern), `healer` (remedy jar), `farm` (coffee pot). Rarity gems: five small
gem shapes in the rarity colours for the card corner (replace the plain diamond seen on the Mythic slot).
**Accept:** rail screenshot before/after; icons hold up at 30 px on the phone emulator.

### PV-C05 Portraits for cards, hotbar and boss bars
Render a 128² portrait per character (27 defenders + attackers) from the imported models: one `ViewportFrame`
at a time in Studio through `execute_luau` (Client) plus `screen_capture`, or Blender renders of the GLBs with
`tools/anim/preview.py`'s camera and a transparent background. Crop to head-and-shoulders, add the 2 px outline
in post. Hotbar and grids use the portraits (`UnitCard` keeps the live viewport only for the selected/hero
card: `ANIME_VANGUARDS_STUDY.md` §7). Boss bar (PV-A04) uses the attacker portraits.
**Accept:** the Units grid opens with ≤ 2 live viewports (count with `execute_luau`); portraits match the
character's model version (file names carry the model name).

### PV-C06 Episode and mode art
One 512×288 painted banner per episode/mode (Night of the Thieves, The Rival Lane, The Siege, Endless Night,
Season 1 Episode 2) for the Play panel and the result screen; a difficulty ribbon set. Same pipeline; prompts
describe the lane at night, lanterns, silhouettes at the gate, never characters from TV.
**Accept:** Play panel screenshot with banners; register rows.

---

## 6. Workstream D: icon, covers, thumbnails, animated logo, loading screen

Facts (Creator Hub, checked 2026-10-17): the experience icon is a **static** square image, 512×512 minimum
(shown as small as 150 px, so test it at that size); thumbnails are 16:9, 1920×1080, up to 10 per page,
images or **uploaded videos** (3 video uploads per month); all are moderated. There is no animated icon on
Roblox, so "icon animation" lives in three places we control: the video thumbnail, the in-game loading screen
and a title card in the lobby. RELEASE_CHECKLIST §B stays the owner's upload step (STOP).

### PV-D01 The logo
A wordmark "Haret Al-Yasmin · حارة الياسمين" in a warm display style (no font licence issues: draw it as
vector shapes from a generated reference, or use an SIL-licensed Arabic display font and record its licence
in the register), with a jasmine sprig and the ablaq arch as the mark. Deliver `logo_512.png`,
`logo_wide_1600x400.png`, `mark_256.png` (the arch + jasmine alone) in `assets/marketing/logo/`.
**Accept:** owner approves; readable at 150 px; register row.

### PV-D02 Experience icon (512×512 ×3 candidates)
Key art: Al-'Akeed Abu Shehab (our Meshy model) three-quarter view in front of the barred lane gate at night,
one lantern, jasmine on the wall, the mark in a corner. Route: stage it in Studio (`screen_capture` with
`camera_position` after placing the model via `execute_luau` in Edit mode, night lighting, 2× supersampled by
capturing at the Studio window's max size), then Higgsfield `upscale_image` to ≥ 1024² and crop to 512²;
alternative candidates fully generated with `generate_image` using the staged capture as the reference
(`medias` role reference) so the character stays ours. No text on the icon except the mark.
**Accept:** three PNGs in `assets/marketing/icon/`; contact sheet at 512/256/150 px; owner picks (STOP).

### PV-D03 Thumbnails ×5 (1920×1080)
Staged captures after workstreams A–B land: (1) the wave-19 crowd at the gate with effects, (2) the summon
burst with a Mythic card, (3) the lobby lane at golden hour with players, (4) the Hakawati's room, (5) the
boss intro. Each gets the logo in the top-left and one short English + Arabic line (≤ 4 words) in the
display font; no series imagery, no Robux prices. Upscale with Higgsfield if the capture is below 1080p.
**Accept:** files in `assets/marketing/thumbnails/`; owner uploads (STOP); register rows.

### PV-D04 Trailer / video thumbnail (15–20 s)
Capture 6–8 clips with the Studio window focused (Windows Game Bar or Clipchamp screen record, both
installed) at 1080p60: gate closing ritual, a thrown tea glass shatter, Abu Khater's hammer, the shibriyeh
ultimate, the boss intro, the summon burst, the lobby. Cut in Clipchamp (or Higgsfield `generate_video` with
the captures as references only for transitions), the licensed `lobby` track is **Roblox-only** (register
C-101) so use a Clipchamp stock track or silence; end on the logo for 2 s. Export 1920×1080 MP4 ≤ 60 MB.
**Accept:** `assets/marketing/trailer_v1.mp4`; owner uploads as a video thumbnail (STOP, counts toward the
3-per-month quota).

### PV-D05 Loading screen with the animated logo
`default.project.json`: add `src/first` → `ReplicatedFirst` with `LoadingScreen.client.luau`:
`ReplicatedFirst:RemoveDefaultLoadingScreen()`, a limestone backdrop (`Palette.stoneLight`), the mark fading
in, jasmine petals (ImageLabels, 12, tweened), the wordmark, a thin ablaq progress bar driven by
`ContentProvider.RequestQueueSize`, bilingual "Jasmine Lane is waking up…" lines, then a 0.4 s crossfade into
the lobby. Max 2.5 s when assets are already cached; Reduced Motion = static.
**Accept:** `rojo build` ok; `script_grep LoadingScreen` finds it; a phone-emulator screenshot; join → lobby
time measured in the overlay (≤ 60 s rule from D-013 unaffected).

### PV-D06 Title card and Discord/social covers
A 1.5 s title card (mark + wordmark) on the first join of a session over the lane (client only), and the
cover set for the community: Discord server banner 960×540, forum post header 1200×400, a 1:1 social tile.
Same key art, exported from `assets/marketing/`.
**Accept:** files delivered; owner posts (STOP).

---

## 7. Workstream E: the lane and the arena feel alive

Budgets from ART_BIBLE §9 and D-014 still hold; measure `[World] built n parts` before and after, and keep
`Lights` ≤ 40 with shadows on ≤ 4 hero lights.

### PV-E01 Atmosphere and lighting pass
`default.project.json` Lighting: `Atmosphere` (density 0.32 day / 0.45 night, haze warm), `Bloom` (0.35, size
24), `SunRays` (0.08) for the lobby's late afternoon; match night: `ColorCorrection` slightly cool with +0.05
contrast, stars via `Sky` with a starfield **only if** a texture is approved (else `StarCount` 3000). Lantern
`PointLight`s get a slow 0.9–1.1 brightness flicker on the client (`Atmosphere.luau` already exists server-side;
flicker is client-only).
**Accept:** before/after captures from the same `camera_position`s; FPS unchanged in the overlay.

### PV-E02 Lobby life
Laundry lines between facades (`Beam` with a cloth texture or 3 flat parts swaying via `BoneAnim`-style tween),
jasmine vines on 6 walls (green parts + white petal sprite clusters, no particles), bird flocks (6 pooled
parts on a looping path, client-side), the fountain gets a water `ParticleEmitter` (Rate 6) and a ripple
decal, Abu Hatem's corner gets steam from the coffee pot (Rate 4), the bakery oven glows and puffs flour
dust when a player walks past (trigger zone, client-side), the cat (`Cat` model) sits on a crate and turns to
face the nearest player. All of it `Effects`-gated and off beyond 120 studs.
**Accept:** `[World] built` ≤ 2,200 parts in the lobby; captures; no server CPU change (`HaretDebug` state
unchanged; use the P1-18 method if in doubt).

### PV-E03 Arena dressing
The orchard arena: olive trees with a trunk mesh? No: keep primitives but add jasmine on the home wall, two
hanging lanterns on wires across the road, crates and sacks along the kerb (`Props2`), and a dust haze layer
on the road at night. Place the remaining imported props (`fountain`, `bread_oven` already placed) where they
help readability of the road. Then one more arena theme for the second episode ("The Rival Lane": cooler
palette, the rival gate from `gate.rbxm` at both ends).
**Accept:** overhead capture from `[3000, 75, 50]` → `[3000, 20, -12]` compared with
`polish_audit_match_overhead_2026-10-17.jpg`; part count per arena ≤ 1,200.

### PV-E04 Props through Meshy (≈ 110 credits, STOP before spending)
Three props we lack for the dressing: a hanging oil lantern on a chain (replaces the primitive wall lanterns),
a crate-and-sacks market bundle, a jasmine pot. Prompts follow `characters.json → props` style; ≤ 2k tris; no
rig. Import, `.rbxm` into `PropModels`, placements in `PropPlacements`.
**Accept:** three register rows; placements in both lobby and arena; part budget unchanged (meshes replace
primitives).

---

## 8. Order, sessions and budget

| Order | Tasks | Why first | Credits |
|---|---|---|---|
| 1 | PV-A01 → PV-A02 | the block enemies are what testers see as "ugly"; owner imports are the long pole | Meshy ≈ 250 |
| 2 | PV-C01 → PV-C02 → PV-C03 | unlocks every later icon; makes lira/qirsh ours | Higgsfield ≈ 60 |
| 3 | PV-B00 → PV-B02 → PV-B03 → PV-A03 → PV-B04 | the fight feels the difference immediately | Meshy ≈ 110 |
| 4 | PV-B05 → PV-B06 → PV-A04 → PV-B07 | moments and menus | 0 |
| 5 | PV-C04 → PV-C05 → PV-C06 | finish the kit | Higgsfield ≈ 80 |
| 6 | PV-E01 → PV-E02 → PV-E03 (→ PV-E04) | the world | Meshy ≈ 110 (optional) |
| 7 | PV-D01 → PV-D05 → PV-D02 → PV-D03 → PV-D04 → PV-D06 | marketing last, after the game looks finished | Higgsfield ≈ 150 |

Three sessions can run at once: A (Meshy pipeline, mostly waiting on jobs and the owner), B (match effects),
C (icons). D and E start when A and B are in. Credits: Meshy ≈ 470 of 1,304; Higgsfield ≈ 290 of 710.
Ask before exceeding either.

Owner-only clicks, batched (post one list, keep working on what is unblocked): Rojo Connect; Studio importer
for six GLBs + three props; first Open Cloud upload approval (or Creator Hub uploads of ≈ 70 images); icon
choice; thumbnail/video/icon uploads on the experience page; Discord covers; any publish.

Definition of done for the whole pass: a tester joins on a phone and sees the loading screen, the lane with
life, a lobby whose every number carries one of our icons, a match where every attacker is a painted
character with a walk, hit and death, every hit lands with numbers and sparks, bosses arrive with an intro,
and the experience page shows our icon, five thumbnails and a trailer. `tools/check.ps1` green,
`lune run tests/balance` unchanged (effects never touch play), the register complete.

---

## 9. Checklist (tick with the commit hash)

- [~] PV-A01 (concepts done, awaiting owner approval) · [ ] PV-A02 · [ ] PV-A03 · [ ] PV-A04 · [ ] PV-A05 (optional)
- [ ] PV-B00 · [ ] PV-B01 · [ ] PV-B02 · [ ] PV-B03 · [ ] PV-B04 · [ ] PV-B05 · [ ] PV-B06 · [ ] PV-B07 · [x] PV-B08 30e6a8f
- [ ] PV-C01 · [ ] PV-C02 · [ ] PV-C03 · [ ] PV-C04 · [ ] PV-C05 · [ ] PV-C06
- [ ] PV-D01 · [ ] PV-D02 · [ ] PV-D03 · [ ] PV-D04 · [ ] PV-D05 · [ ] PV-D06
- [ ] PV-E01 · [ ] PV-E02 · [ ] PV-E03 · [ ] PV-E04 (optional)

---

## 10. Tool crib for the executor (verified today)

- Launch: `mcp__computer-use__request_access(["Roblox Studio","Blender 5.2","blender.exe","nvidia overlay.exe"])`,
  `open_application("Roblox Studio")`, switch display to `D22-20`, click the "Haret Al-Yasmin (TEST)" tile;
  `list_roblox_studios` then returns the id; `get_studio_state` must say Edit. Rojo Connect: ask the owner.
- Playtest loop: `start_stop_play(true)` → `user_keyboard_input` wait 9 s → `get_console_output` shows
  `[HaretAlYasmin] server ready` → `user_mouse_input` one click at (900, 450) → keys `9`, `M`, `L`, `C`, `B`×6,
  `K`, `T` → `screen_capture` with `camera_position [3000,75,50]` / `look_at_position [3000,20,-12]` for the
  Episode 1 arena (origin 3000, 19.5, −12; the road's far end is around x 2945, z 12; the spawn gate around
  x 3050, z 5). `autoSkip` is on in the test profile, so waves advance fast: capture promptly.
- Enemy rigs on the client: `workspace.EnemyRender` children carry `LookId` and `Imported` attributes
  (primitive figures carry neither and have 30+ parts).
- Meshy: `python tools/meshy/meshy.py balance | library --search x | make <id> [--until concept|mesh|rig|anim] | clip <id> <name> <action>`;
  `python tools/anim/fetch.py`, `bake.py`, `baked_glb.py`, `islands.py`; previews need the full Blender path.
- Higgsfield: `balance`, `generate_image` (`gpt_image_2_5`, `get_cost: true` first), `generate_image_batch`,
  `remove_background`, `upscale_image`, `generate_video`, `media_upload` + `media_confirm` for references.
- Studio images: `store_image` (local png → `IMAGEID_` URI for Studio tools only), `upload_image` (needs an
  HTTP URL). Neither gives a permanent `rbxassetid`; that is PV-C01 or the owner.
