# Look-and-play plan (LP): HUD, lobby, speed, buffs, the Defenders panel, Season 1's gold-gatherer

*Written 2026-10-19 for the executing agent (Claude Opus 5.5 in Claude Code on the owner's machine). It
follows the style of `MOBILE_HUD_PLAN.md` and `STORY_PLAN.md`. Read `CLAUDE.md` first: session start, verify
loop, hard rules, shared checkout. One LP task per commit, subject `LP-xx: <imperative>`.*

*Synced against `main` at `d6a1081` (v1.0.2 live on the TEST place). Nothing in this plan has started. Every
line reference below was read today; the client is ≈ 12,300 lines of controllers plus `src/client/UI`.*

## 0. Kickoff prompt (paste this into Opus 5.5)

> Read `CLAUDE.md`, `docs/TOOLS.md`, the last 40 rows of `docs/DECISIONS.md`, `docs/STORY_PLAN.md` §2–§4
> (who is who, the one-letter-off naming rule, the look rule) and all of `docs/LOOK_AND_PLAY_PLAN.md`. Do
> the CLAUDE.md session start (git status, `ListAgents` and coordinate with any session touching
> `src/client`, `src/server/World` or Studio, `list_roblox_studios`, `rojo serve`, Rojo Connected). The game
> is live: work on `main` unless the owner says otherwise, and every commit must be publish-safe on its own.
> Work the tasks in the order of §8 (LP-A first: they are bug fixes players feel today). For every task: mark it
> `[~]` in §9, implement code and specs, `tools/check.ps1` green, `script_grep` sync check, Studio playtest
> with the captures the Accept lines name (under `docs/captures/lp/`), the TEST_REPORT_SLICE and DECISIONS rows
> the task names, commit `LP-xx: <imperative>` with a `Verified:` body, mark `[x] <hash>`. Numbers go in
> `src/shared/Config`, pure logic in `src/shared/Logic` with Lune specs, every new remote through
> `RemoteGuard.wrap`, every new string in `en` and `ar`, every new name through the §4.2 table (STOP: the owner
> approves names before they ship). Three honest attempts, then `[!]` with the reason and move on. Batch every
> STOP item (name approvals, Meshy credit spend, product changes, real-device run) into one message to the
> owner and keep working on unblocked tasks. Never press `H` or let a Studio test match finish: Play Solo pays
> the owner's live profile (memory note, D-072); stop Play instead.

---

## 1. What the owner asked for (2026-10-19) and what this plan decides

| Ask (owner's words, paraphrased) | Decision in this plan | Where |
|---|---|---|
| "Fully focus on the HUD, the look of the lobby, buttons, popups, dialogs; more animations; more things from the lane drama" | A **Theme v2** pass (ornament, states, motion) on every lobby screen and the match HUD, plus a lobby-life calendar of drama beats (coffee-house evenings, the 'arada, the gendarme patrol, the gate at night) | §5, LP-C, LP-D |
| "Bigger lobby map; all NPCs from the real story" | The lane grows from 6 zones to 11 (souq alley, hammam, diwan, mosque court, police post, orchard road outside the gate). **Every NPC is a character of the drama by role**, named one letter off exactly as the units are (STORY_PLAN §3, D-042). The series title never appears (C-201, D-007) | §4, LP-D |
| "More than 2× speed: add 4×, and 5× for battle-pass owners or VIP" | Speed ladder **1·2·3·4·5**. Free stays 1–2×. 3×, 4× and 5× unlock for the host who owns **VIP, or the premium Lane Diary, or the Fast Mode pass** (the Fast Mode pass has no product id yet, so folding it is free: owner decides keep or retire, §3.3) | §3.3, LP-A03 |
| "Dead enemies keep their last HP bar during the death animation" | Confirmed in code: nothing hides the bar (`EnemyRenderController.luau:480-520`). Fix: hide the bar and the ring on the death event, before the clip plays | §3.1, LP-A01 |
| "Make sure the buff mechanism works perfectly; two Abu Issam near a unit → both buffs count; range and buffer counts computed right" | Confirmed in code: `buffFor` takes the **best** buff and ignores the others (`TdSim.luau:532-544`). New rule: **stacking with a cap**, same for haste; a sabotaged support stops buffing; the panel and badge show the total and the count; specs for every rule | §3.2, LP-A02 |
| "In a match, a button that opens a panel with all units: ult, auto-ult on/off, upgrade, sell" | The **Defenders panel** (rail button), one row per placed tower, per-tower auto-ult (new remote), tap-to-focus | §6, LP-B |
| "From the story, a fitting character to be the farmer of Season 1; all it does is gather gold; read Anime Vanguards' farm units; plan the whole mechanism; Meshy model and animations" | Season 1 is built on **Part 1** of the drama (STORY_PLAN §2), and Part 1 has no farmer (the sheep-farm owner Abu Zafer only arrives in Part 6, as the owner pointed out). Part 1's money character is **Abu Ibrahim, the cloth merchant whose hoarded gold is the season's theft plot**: he becomes **Abu Brahim the Cloth Merchant / أبو براهيم التاجر** (one letter off, already in the STORY_PLAN §3 table), an Epic farm with zero damage that pays at wave end, a "Count the gold" ability and two signature paths; Al-Adashari's cameo stealing from his shop ties him to the secret unit. Model, clips and lobby shop through the existing Meshy pipeline | §7, LP-E |
| "In the lobby Units tab, each unit shows its type; read other games" | Cards get **type badges** derived from config (role, attack pattern, reach, max placed) and the detail view gets a stat block like the genre's (DPS, cost to max, ability, beads, signature) | §6.3, LP-B05 |
| "Don't code or execute; write the plan for Opus 5.5" | This document. No source file changed; Studio was only used to look (Play Solo started and stopped, no match finished) | — |

What this plan does **not** change: odds and pity, prices, the sim's wave scripts, the kit pipeline, the
persistence schema (one additive field, §6.2). Robux products stay at id `0` until the owner creates them.

---

## 2. Evidence

### 2.1 Studio audit today (Play Solo on the TEST place, desktop 1636×584 safe area, UIScale 1.27)

Captures are in this session's tool results; the executor retakes them under `docs/captures/lp/` as the
"before" set in LP-C00.

| Where | What I saw | Problem it points at |
|---|---|---|
| Lobby, spawn at the gate | Two currency pills, a green `+`, the language pill, Wardrobe, mute; a 3×3 grid of flat-coloured squares bottom-left (Play, Event, Units, Summon, Diary, Daily, Codes, AFK, Settings); the errand card top-right | Grid reads as nine equal tiles: Play has no hierarchy; no notification dots (Daily claimable, Diary tier ready); nothing moves at idle; the pills do not count up when lira changes outside the summon screen |
| Lobby, lane | Block-figure NPCs (coloured R15 bodies with a tarboosh) next to Meshy-quality props and portraits | NPCs are the one thing in frame that is not drawn to the art bible; the coffee-house keeper and the barber already have Meshy unit models |
| Coffee house | Open floor, benches, samovar, one NPC | Empty: no customers, nobody at the backgammon tables, the Hakawati is off-map in the AFK room only |
| Units screen | "Your defenders": loadout strip, grid of portrait cards with name and rarity text, stars | **No type on the card** (role, attack, reach): a new player cannot tell a farm from a fighter |
| Summon screen | Banner, two featured cards, ×1 / ×10 / Rates | Fine; the only screen with a reveal animation |
| Lane Diary | Level, XP bar, tier strip, Unlock premium, Skip 10 | Static; claimable tiers do not pulse; the strip does not scroll to the current tier |
| Codes | Field + Redeem | Fine |
| Match HUD (Episode 1 Normal) | Wave pill, gate bar, hotbar of six cards, cash pill, rail: ≡, Tower (view), 1x speed, Skip 0/1 | The speed button cycles 1×→2×→1× (host only); no way to see all placed units; the hotbar cards show `0/1` placed but nothing about the unit's type |
| Console | `rbxassetid://203785492 failed: Asset type does not match requested type` ×6 on every join; the UIBlox `FoundationProvider` warnings | The asset id is not in `src/` or `default.project.json` (engine-side, probably a Sky/Studio asset) — LP-C00 investigates and documents; the UIBlox warning is Roblox's own |

### 2.2 Code audit (read today; the executor re-reads before changing anything)

- **Speed.** `TD.FREE_SPEED = 2`, `TD.PASS_SPEED = 3` (`src/shared/Config/TD.luau:25-26`). `Net.Events.SetSpeed`
  is "C→S 1 | 2 | 3 (host)" (`src/shared/Net.luau:39`). The server accepts a positive integer from the host
  only, caps it at `PASS_SPEED` when `MonetizationService.hasPerk(player, "fast")` else `FREE_SPEED`
  (`MatchService.luau:891-906`); otherwise it notifies `match.err.fast_pass`. The sim does not scale `dt`: it
  accumulates `dt × speed` and runs up to **6 fixed ticks** per Heartbeat, dropping the backlog beyond
  (`MatchService.luau:727, 802-803`). The client cycles `speed + 1` wrapping to 1 past its max
  (`MatchController.luau:230-241`), label `match.speed = "{n}x"`. Things that already follow speed: enemy bob
  (`EnemyRenderController.luau:1077-1101`), teleport telegraph (:792), ult cooldown display
  (`PlacementController.luau:1117-1123, 1266-1271`). Perks: `vip` (299 R$), `fast` (799 R$), `slot` (149 R$)
  from `Products.gamePasses`, all ids `0`; the premium Lane Diary is `profile.pass.premium`
  (`PassLogic.luau:21`), not a perk.
- **Enemy death.** `healthBar()` builds a BillboardGui on the head (`EnemyRenderController.luau:153-189`);
  the HP fraction is written from the `EnemyPositions` stream (:1042-1066). The `death` event calls
  `remove(id, true, e)` (:953-954) → `poof(model)` (:461-477) which plays `deathClip` (1.5–3.3 s depending on
  the enemy, `RigAnimController.luau:502-510`) then `fadeOut` over 0.35 s. **No line touches `rec.bar` or the
  BillboardGui's `Enabled`**: the bar stays at the last streamed fraction until `model:Destroy()`.
- **Buffs.** `buffFor(state, t)` (`TdSim.luau:532-544`) scans every tower, takes the **highest** `stats.buff`
  whose 2D range covers `t`, excludes `t` itself, and is called on every attack (:737). Haste (`hasteFor`,
  :520-530) is the same shape (best, not stacking). A sabotaged support (`disabledUntil`) **still buffs**; only
  revealers check it. Heals and bounties already **sum**. The server recomputes a display value
  (`refreshBuffs`, `MatchService.luau:588-605`) after place/upgrade/sell/disable/enable and shows a
  `BuffBadge` BillboardGui (`ArenaService.luau:112+`) and a `towerBuff` event; the panel prints "+N% buffed"
  (`PlacementController.luau:553-557`). Buff units: `mukhtar` Abu Bader (Epic support, buff 1.15→1.65, range
  12→17, signature `loud` 1.8), `umm_hara` Abu Hissam (Legendary healer, buff 1.1→1.45, range 14→19,
  signature `elder` 1.6). Specs: one support in range vs out of range (`tests/td.spec.luau:458-476`); **none
  for two overlapping supports, none asserting Abu Hissam's buff applies.**
- **Tower panel.** `UI/TowerPanelView.luau` (side column 232 px on desktop, bottom sheet on touch) shows
  portrait, level, stats, two signature cards, Upgrade / Target / Sell, ult button with cooldown fill and an
  Auto toggle. The Auto toggle is **per player** (`Settings.autoUlt`, reaching the sim as `ps.autoAbility`,
  `MatchService.luau:465,875`). Remotes: `PlaceTower`, `UpgradeTower`, `SellTower` (functions),
  `SetTargeting`, `UseAbility`, `VoteSkip`, `SetSpeed`, `LeaveMatch` (events). Rail: `HudLayout.rail` stacks
  View, Speed, Skip under the ≡ menu, `RAIL.maxButtons = 3` (`Config/Hud.luau`).
- **Lobby.** `WorldService` builds Lane, Shops, Square, House, Skyline, Extras: **1,423 parts of a 6,000
  budget**; `maxLights = 40`. NPCs are colour-block figures from `Config/Npcs.luau` (skin / robe / accent /
  headwear), eight of them (`abu_nadim`, `sitt_wardeh`, `hajj_rashid`, `khalil_tailor`, `barber`,
  `qahwaji`, `natour`, `hakawati`). `CrowdService` walks 8 humanoids between 13 points. `LobbyLife` (client)
  does laundry, birds, fountain, samovar steam, oven flare, cats, jasmine. Dialogue is one or two lines per
  NPC (`Config/Dialogue.luau`).
- **Units tab.** `UnitCard.create` shows portrait, rarity frame, name, stars, rarity text; the detail view
  shows "rarity · role · stars", description, level-1 stats, traits, beads. `Units.luau:76-91` has `role`
  (melee | ranged | splash | support | farm | healer), `maxPlaced`, `hitsStealth`, `revealsStealth`,
  `douse`, levels with `splash`/`slow`/`stun`/`buff`/`income`/`bounty`/`heal`, `ability` (shabriyeh | sweep |
  mark), `signature`, `beads`. **No `attackType`, no placement type, no element**; `bounty` is shown nowhere.
- **Farms today.** `qahwaji` Abu Hazem (Rare, max 4, income 90→620 per wave end, 4→18 chip damage) and
  `hummus` Abu Samih (Rare, max 3, bounty 6→24 per kill in range). Cash: `START_CASH 600`, wave clear
  `110 + 20 × wave`, `SKIP_BONUS 60`, kill cash = enemy reward × difficulty (1 / 1.6 / 2.4) × tower `cash`.
- **Theme and motion.** `UI/Theme.luau` tokens (panel #F1E9DA, stroke #4A2E18, button #6B4423, gold #E0A82E,
  rarity colours, BuilderSans + FredokaOne, radius 12/10, stroke 3). `UI/Juice.luau`: press 0.92, pop 0.8→1
  Back, punch, shake, count, shine, tilt, flip, wobble, slideIn; all respect Reduced Motion. `UI/Modal.luau`:
  centred panel or phone sheet with swipe-down. The lobby bar is a plain grid of coloured squares.

### 2.3 Genre research digest

The drama (research report, 2026-10-19; Arabic/English Wikipedia season pages, New Lines, Arabic Post,
TheTVDB): Harat al-Dab' in the 1920s–30s under the Mandate. A lane has a **za'im**, an **'akeed**, a hired
**gate guard**, the **sheikh**, the **coffee house** with the **Hakawati**, the **hammam**, the **bakery**,
souq shops (fabric, pottery, clogs, grocer, hummus, balila, pickles), the **police post** of Abu Jawdat
outside the walls, and the **Ghouta orchards** where the rebels hide. Characters with land or money **in Part 1**
(the part Season 1 adapts): **Abu Ibrahim**, the cloth merchant whose hoarded gold is stolen by
Al-Idaashari and who ends up giving half of it to the lane fund; Abu Khater (wealthy pottery merchant); Abu
Marzouq (greengrocer, Ghouta produce); Abu Hatem (coffee house, already our `qahwaji`); Abu Bashir (bakery,
already `farran`). The only literal farmer of the series, Abu Zafer the sheep-farm owner, appears in Parts 6–9
and is **out of scope for Season 1** (he can headline a later season's farm unit). The Ghouta orchards outside
the walls are Part 1 material: the rebels' hideout, not anyone's farm. Daily beats: the guard asleep at the gate and thieves at night; the za'im's
diwan hearing disputes; men at the coffee house every evening; marriage requests and weddings with the
**'arada** (sword-and-shield procession); condolence duty; gendarme raids and torture at the post; women's
rooftop and courtyard gossip (Fawziya, Feryal); the midwife's rounds.

Anime-TD conventions (research report 2026-10-19; wiki pages of Anime Vanguards, Anime Adventures, Anime
Defenders, All Star TD / ASTD X, Toilet TD, Tower Defense Simulator):
- **Cards** show rarity, element, attack shape (Single · Circle · Line · Cone · Full, with the upgrade index
  where it changes), placement type (Ground / Hill / Hybrid), **placement count**, and a stat block per level
  (Dmg, Rng, SPA, DPS, cost, total cost); roles are tagged Farm / Support / Summoner / Buffer; Anime Vanguards
  grades Dmg/Spa/Rng with a badge. Our equivalents are in §6.3.
- **Speed.** Anime Defenders: 2× free, **3× a 799 R$ gamepass**; All Star TD: **3× gamepass 799 R$**, free on
  some maps; Toilet TD: 2× in Endless after rank 10; Tower Defense X: +50 % pass, solo only; Anime Vanguards has
  no speed at all (vote-skip and auto-skip instead). No wiki documents a co-op vote rule; speed is an
  owner-level entitlement everywhere. Our 5× tier is above the genre; §3.3 measures it.
- **Unit Manager** (Anime Vanguards since 2024-09, ASTD X `T`): a list of placed units with hover highlight,
  Upgrade and Sell per row, "level n / max", **Sell All** with a "farms only" choice, a per-unit **lock**
  (excluded from Sell All), abilities usable from the list, targeting dropdown, **Auto Upgrade** per unit with a
  priority 1–6, two-step console flow. Separate "Auto Play" bots the whole match. No per-unit auto-ability
  toggle is documented: ours (§6.1) is a step past the genre.
- **Death.** TDS gives every enemy a bespoke fall clip, leaves a corpse variant, and plays cosmetic death
  effects "after the enemy disappears entirely"; the practical pattern is hide the bar on the kill event, play
  a 0.5–1.5 s clip or dissolve, then the reward burst. Anime Vanguards' log only notes bar polish and a netcode
  rewrite that cut enemy-health traffic 2–3×.

---

## 3. The three fixes (LP-A): what changes and the rule behind it

### 3.1 Death: hide the bar first, then play the clip

On the `death` event, before `poof`: `rec.bar.Parent.Enabled = false` (the whole BillboardGui, so the
armour/stealth markers go too), hide the target ring, and **drop the record from the position stream** so a
late `EnemyPositions` packet cannot re-show it (the packet is unreliable and may arrive after the event).
Bosses: `bossMeter` empties to 0 with a 0.3 s tween and then hides. The `reached` event already destroys the
model at once. Damage numbers in flight are left alone. Spec-level rule for the pure side: none (client only);
the Accept line is a Studio check (§8).

### 3.2 Buffs: stacking with a cap, visible counts, correct range

Rules (all in `TdSim`, numbers in `Config/TD.luau`, D-008 cap row):

1. **Covered** = the buffer's `stats.range` (2D, squared distance) covers the tower's position. Unchanged.
2. **Stacking.** The tower's damage multiplier is `1 + Σ (b_i − 1)` over every *other* covering support,
   **capped at `TD.BUFF_CAP = 2.4`** (+140 %). Two Abu Bader at level 6 (1.65 each) give 1 + 0.65 + 0.65 =
   **2.3×**; three would hit the cap. Haste stacks the same way on the cooldown side: product of `haste.mul`,
   floored at `TD.HASTE_FLOOR = 0.7`. Heals and bounties keep summing (already do).
3. **A sabotaged support (`disabledUntil`) does not buff** until it is back (consistent with revealers; the
   rifleman's sabotage finally bites supports).
4. **No self-buff**, no double count of the same tower, allies (`TdTowers` ally tower) count as supports if
   they carry `buff`.
5. **Recompute, don't rescan per attack.** Keep a per-tower cache `t.buffMul`, `t.buffCount`, `t.hasteMul`
   marked dirty by place / upgrade / sell / disable / enable / ally spawn (every place the server already calls
   `refreshBuffs`), recomputed at the start of `towersAct` when dirty. Same results, O(n·k) once per change
   instead of per shot. `TdSim.buffFor` keeps its signature (returns the capped total) and gains
   `TdSim.buffInfo(state, t) → { mul, count, sources }` for the server's badge.
6. **Display.** The badge and the panel show "+130 % · 2 supports"; selecting a support draws its range ring
   and highlights the covered towers (green outline) so the player sees who gets it. The Defenders panel row
   shows the same number.

Specs to add in `tests/td.spec.luau`: two supports stack additively; three hit the cap; out of range does not
count; self excluded; Abu Hissam's buff applies and stacks with Abu Bader; sabotaged support stops and
resumes at wave end; cache invalidates on place/sell/upgrade (damage changes next attack); haste floor;
bead-buff cap still holds; `tests/balance` re-run and the §5.3 ladder of STORY_PLAN still passes (if a mode
flips, tune `BUFF_CAP`, not the units; log TUNE in DECISIONS).

### 3.3 Speed: the 1–5 ladder and who gets what

`TD.SPEEDS = { 1, 2, 3, 4, 5 }`, `TD.FREE_SPEED = 2`, `TD.PREMIUM_SPEED = 5`. The host's max speed is
`PREMIUM_SPEED` when the host **owns VIP, or the premium Lane Diary of the running season, or the Fast Mode
pass**, else `FREE_SPEED`. Reasoning: the owner asked for 4× and 5× as the VIP / pass tier; 3× was the Fast
Mode pass's only perk and that pass has never been sold (id `0`), so the ladder stays monotonic (a cheaper VIP
can never beat a dearer pass) by giving all three passes the same ceiling. **Owner decision (STOP, batch it):**
(a) keep Fast Mode as a 799 R$ pass that only buys speed, with its string changed to "3×–5× match speed when
you host", or (b) retire it (delete from `Products.gamePasses` and `passOrder`, strings to `-- retired`) and
let VIP + premium Lane Diary carry speed. The plan's default is (a) renamed; nothing is sold either way until
ids exist.

Engineering notes the executor must check, not assume:
- Server load: 5× is 100 sim ticks/s per match. D-014 measured `TdSim.step` at 0.70 ms avg / 2.49 ms max with
  271 attackers; six matches at 5× in the worst wave is ≈ 0.42 s of sim per second of wall time on one core.
  Measure with the D-014 method after the change; if the p95 crosses 50 % of a frame, lower the per-frame step
  cap from 6 to 4 at speeds ≥ 4 (the match slows, never desyncs).
- `POSITION_RATE = 0.1` is wall time: at 5× enemies move five times farther between packets; raise the
  client's interpolation window with speed (`EnemyRenderController` lerp) or halve the rate at ≥ 4× on the
  server. Verify with a capture at 5× (no popping).
- The client speed button becomes a **speed sheet** (tap → five chips, locked ones greyed with a lock and the
  pass name; tapping a locked chip opens the Store at that pass through `MonetizationLogic` and never prompts
  a purchase for restricted players). The rail label keeps "{n}x".
- Non-host players see the current speed as a read-only chip (today they see nothing).
- `RemoteGuard`: `SetSpeed` validates membership in `TD.SPEEDS` (enum membership, not "positive integer").
- Ult cooldown display, teleport telegraph and bob already divide by speed; grep for any `task.wait` in match
  effects that assume wall time (`MatchFxController` wave banners are fine; `MatchMoments` cinematics must
  not run 5× long).

---

## 4. The bigger lane and its people (LP-D)

### 4.1 Zones

The lobby today is 6 zones in a 48 × 150 stud strip (WORLD_MAP.md). The new lane keeps every existing
coordinate (the portals, the AFK door, the quest route) and grows outward. All zones are built by code in
`src/server/World/Zones/*` from the kit (`KitModules`, D-053/D-054) and the existing `Props2`/`Facade`
helpers; **nothing is Studio-owned**. Each new zone is one `Model` with `ModelStreamingMode = Atomic`, ≤ 1,200
parts, and WORLD_MAP.md gets its row.

| Zone id | Where (studs) | What | NPCs (see §4.2) | Parts |
|---|---|---|---|---|
| `souq` | east alley off the lane, x 24..60, z 40..72, L-shaped, 8 wide | Covered souq: grocer's cart, pottery shop, clog-maker's bench, cloth shop with bolts on the awning; lanterns on chains; a cat on the pottery | Abu Marzouk (grocer), Abu Shater's forge *moves here from "blacksmith" sign only*, Abu Brahim (cloth) | ≤ 1,000 |
| `hammam` | west of the square, x −62..−40, z 0..26 (WORLD_MAP "future": Hammam) | Domed façade with bottle-glass oculi, steam from a roof vent (LobbyLife), a bench with towels, the entrance curtain | Abu Basim (hammam owner), Abdo (worker, crowd look) | ≤ 700 |
| `diwan` | south-east of the square, x 24..52, z −30..−4 | The za'im's house: ablaq portal, courtyard with a liwan where the za'im sits with two elders; the dispute scene (§4.3) plays here | Za'im Abu Faleh, Al-'Akeed Abu Shehan (standing guard), Abu Bader | ≤ 900 |
| `mosque_court` | east of the square, x 24..48, z −4..24 (exterior only, per WORLD_MAP) | Courtyard wall with a wooden door, the ablution fountain, a fig tree, the minaret moved from the skyline into this block | Sheikh Abd al-Halim (sits by the door; greets, no quest) | ≤ 500 |
| `post` | outside the gate, north-west, x −40..−16, z 96..120 | The gendarmerie post (makhfar): flag pole, a barred window, two gendarme dummies at ease, a wanted poster of "Al-Adashari" (secret-unit tease) | Abu Jawdan (sergeant), Corporal Houri | ≤ 600 |
| `orchard_road` | outside the gate, north, x −16..40, z 96..150 | The road to the Ghouta: low orchard walls, olive and apricot trees from the kit, a well, a donkey cart of pickles by the wall (Al-Idaashari's trade in Part 1), a rebel's rifle leaning in a tree hollow (tease); the road ends at a vista wall with the rival lane's gate (Abu al-Nahr) painted on it | the Adashari cameo (§4.2), two crowd orchard workers | ≤ 1,000 |
| `rooftop_view` | above the lane, no collision | Women on two rooftops (two seated NPC figures with laundry, waving at intervals: LobbyLife) | Fawza, Feryal (no prompt, ambient only) | ≤ 150 |

Totals: ≈ 5,000 new parts on top of 1,423. **Raise `WorldService.PART_BUDGET` to 9,000** and keep the ≤
6,000 figure for what streams at once (the gate end and the square end never fully co-stream on a phone:
`StreamingEnabled` is already on in `default.project.json`). `maxLights` stays 40: new zones use emissive
lantern meshes, not PointLights, beyond the two per zone. Verify with the D-014 method on the TEST place and
a phone capture (`docs/captures/lp/phone_lane_*.png`): ≥ 30 FPS, no streaming pop at the square.

The lane floor between the gate and the square is **not** widened (every tutorial coordinate stays); instead
the lane gains side openings: the souq arch at (8, 56) east and the hammam arch at (−24, 12) west.

### 4.2 The cast (STOP: owner approves this table before any string lands)

Rule: every NPC is a character of the drama **by role**, named by the one-letter rule of STORY_PLAN §3 (D-042),
Arabic first, no religiously or politically loaded result, trade kept in the role string. Where a unit with the
same character exists, the NPC **uses the unit's Meshy model** (`CharacterLooks[id].model`) so the lobby and the
roster agree. New looks go through Meshy with the §4.1 STORY_PLAN signature rule. The existing original NPCs
(Abu Nadim, Sitt Wardeh, Hajj Rashid, Khalil) **stay** as the slice's own characters: the owner keeps them for
the errand tutorial, and the drama had a baker, a spice seller and a tailor too.

| NPC id | Drama role | Name EN / AR (one letter off) | Zone | Look | Prompt / behaviour |
|---|---|---|---|---|---|
| `barber` (exists) | Abu Issam, the hakim-barber | Abu Hissam / أبو حسام | barber shop | **unit `umm_hara` model** | greets; evenings: walks to the coffee house (§4.3) |
| `qahwaji` (exists) | Abu Hatem, coffee-house owner | Abu Hazem / أبو حازم | coffee house | **unit `qahwaji` model** | serves; opens the AFK door |
| `natour` (exists) | Abu Fares, the gate guard | Abu Hares / أبو حارس | gate | **unit `natour` model** | bars the gate at "night" (§4.3), points to the portals |
| `hakawati` (exists) | Abu Adel, the Hakawati | Abu Tawfiq / أبو توفيق (keep; generic) | AFK room **and** the coffee house in the evening | Meshy (new, ≈ 60 credits) | tells a tale at the coffee house every lobby evening |
| `zaim_npc` | Abu Saleh, the za'im | Za'im Abu Faleh / الزعيم أبو فالح | diwan | **unit `zaim` model** | sits in the liwan; "the diwan is open" prompt opens the Lane Diary (the diary is the lane's record) |
| `akeed_npc` | Abu Shihab, the 'akeed | Al-'Akeed Abu Shehan / العكيد أبو شهان | diwan door, patrols to the gate | **unit `zaim_akbar` model** | patrol loop; prompt opens Play ("the lane needs you at the gate") |
| `mukhtar_npc` | Abu Badr, the neighbour | Abu Bader / أبو بادر | square bench | **unit `mukhtar` model** | comic lines about his wife on the roof |
| `fawza_roof` | Fawziya, the gossip | Fawza / فوزة | rooftop_view | **unit `saqqa` model** (seated pose) | ambient: calls down a line every 90 s (text bubble, no prompt) |
| `feryal_roof` | Feryal, the schemer | Firyal / فريال → **Feryal Khanum / فيريال خانم** (add ي) | rooftop_view | Meshy (new, ≈ 60) | ambient |
| `umm_hissam` | Suad, the matriarch | Su'da Khanum / سعدى خانم | courtyard house (shares Sitt Wardeh's zone liwan) | **unit `matriarch` model** | prompt opens Units ("show me your men") |
| `midwife` | Umm Zaki, the midwife | Umm Baki / أم باقي | lane, walking loop | **unit `qabilah` model** | walker; prompt opens Daily ("a gift for the house") |
| `hammam_owner` | Abu Qasim, hammam owner | Abu Basim / أبو باسم | hammam | **unit `hammam` model** | prompt opens Wardrobe ("come out looking like a groom") |
| `grocer` | Abu Marzouq, greengrocer | Abu Marzouk / أبو مرزوك (ق→ك) | souq | Meshy (new, ≈ 60) | prompt opens the Shop |
| `cloth_merchant` | Abu Ibrahim, the cloth merchant with the gold | Abu Brahim / أبو براهيم | souq (the cloth shop, with the money chest) | **unit `tajir` model** (§7, new) | prompt opens the Store (coins/lira): "my gold is the lane's gold"; the §7 lore line; at night the Adashari cameo creeps to his shutter (§4.3) |
| `sheikh` | Sheikh Abd al-Alim | Sheikh Abd al-Halim / الشيخ عبد الحليم | mosque_court | Meshy (new, ≈ 60; no prompt beyond a greeting; no religious lines) | greets; nothing to buy or do (respect) |
| `sergeant_npc` | Abu Jawdat, the police sergeant | Abu Jawdan / أبو جودان | post | **enemy `abu_jawdan` model** (boss, exists) | prompt: the Event board ("the Mandate has posted orders"); bluster lines |
| `corporal_npc` | Corporal Nouri | Corporal Houri / العريف حوري | post | **enemy `corporal` model** (exists) | ambient only |
| `ibrahim_son` | Ibrahim, his son (marries Dalal) | Brahim / براهيم | souq, beside the shop | crowd look | ambient, folds cloth |
| `balila` | Abu Ghalib, the chickpea seller | Abu Ghadeb / أبو غاضب | square → souq, walking | **unit `khayyat` model** | the lane's gossip: walker with three spiteful lines (Config/Dialogue) |
| `adashari_cameo` | Al-Idaashari, the fugitive | Al-Adashari / العدشري | at "night": creeps from the orchard wall to Abu Brahim's shutter, 20 s, every 6 min, then vanishes | **unit `adashari` model** | no prompt; a tease for the secret unit and for Part 1's theft (S1-A08 planned "the Adashari NPC") |

Twenty NPCs: 13 reuse models that exist, 4 need Meshy (Hakawati, Feryal, grocer, sheikh: ≈ 240 credits, STOP
before spending), 2 are crowd looks, 1 is the merchant unit's model (§7). Names marked "keep" are already in
`Strings` or are not a drama name. Every one is a Part 1 character except the Hakawati and the sheikh, who are
the lane's fixtures in every part.

### 4.3 Lobby life: the drama's beats as a calendar

A client-side **lane clock** (`Config/LobbyLife.CLOCK`, 12-minute cycle: dawn 0–1, day 1–8, evening 8–10,
night 10–12) drives Lighting (`Config/Lighting` adds `evening` and `night` presets: ClockTime, lantern
emissive on) and the beats below. Everything is client-side and deterministic from `workspace:GetServerTimeNow()`
so all players see the same lane; nothing touches the server except the clock origin on join.

| Beat (from the drama) | When | What happens | Pieces |
|---|---|---|---|
| The gate opens | dawn | Abu Hares lifts the bar, the leaves swing (`Props2.gate` already swings), roosters (Audio) | gate hinge tween, 1 SFX |
| The coffee house fills | evening | 6 crowd walkers sit on the dikkeh benches, backgammon clicks, the Hakawati walks in from the AFK stair and tells a 90-second tale (text bubbles from `Config/Dialogue.hakawati_tales`, 5 tales rotating) | seats as `Seat` parts, bubble UI, tale strings |
| The 'arada | every third evening (≈ 36 min) | A wedding procession from the diwan to the gate: 6 walkers with swords and shields (kit props), the `arada` unit's clip, drums, rice from the rooftops (particles) | path, props, 1 music loop (Audio bible) |
| The gendarme patrol | day, every 4 min | Corporal Houri and two gendarme walkers march gate → square → gate; crowd steps aside; Abu Ghadeb follows them whispering | path, crowd avoid |
| The diwan hears a dispute | day, every 5 min | Two walkers argue in the liwan; the za'im raises a hand; they shake hands; a "Lane fund +N" toast for players within 20 studs (**cosmetic only**: no currency) | animation triggers, toast |
| Night watch | night | Lanterns on, Abu Hares bars the gate and calls (text bubble), the Adashari cameo (§4.2), cats' eyes | lighting preset, cameo |
| The musaharati | night, Ramadan event only (`Config/Events`) | A drummer walker (enemy `drummer` model recoloured warm) calls the lane | event-gated |
| Rooftop women | day and evening | Fawza and Feryal lines every 90 s, laundry sway (exists) | ambient |

All beats obey `Settings.effects` (off = static lane) and Reduced Motion, and the 120-stud / 30 Hz LobbyLife
budget (D-035 era rule). Phone check: the evening preset must not drop the lane under 30 FPS.

---

## 5. Theme v2: buttons, popups, dialogs, motion (LP-C)

### 5.1 Principles

1. **One material language.** Panels are paper on wood with ablaq (banded stone) headers; buttons are carved
   wood with a brass edge; primary actions are gold leaf; danger is the red of the diwan cushions. Every shape
   comes from `Theme` tokens; no colour literal in a controller.
2. **Every control has four states** (idle, hover/focus, pressed, disabled) and a **ready** state where it
   matters (claimable Daily, Diary tier, summon affordable): ready = a slow brass shimmer (`Juice.shine` every
   4 s) plus a notification dot.
3. **Everything that appears, moves in.** Screens pop (exists), sheets slide, lists stagger (cards 30 ms apart,
   capped at 12), numbers count (exists), rewards fly (exists). Nothing teleports.
4. **Phones first.** No new element smaller than `Hud.TOUCH_MIN`; sheets keep MH-21/MH-22 rules.
5. **Arabic is first-class.** `AutoLocalize` off, our own `t()`; Arabic headers use the display font pairing
   chosen in MH (RTL alignment per `LocaleController`).

### 5.2 The pieces

| Piece | Today | Target |
|---|---|---|
| Lobby bar (desktop/tablet) | 3×3 equal tiles | A **wooden rail** with a large gold **Play** (1.6× tile) at the left, then Units, Summon, Diary; the rest in a second row of small tiles; dots for Daily / Diary / Event; Play breathes (scale 1.00→1.03, 2.4 s) |
| Lobby bar (phone) | MH bottom bar | unchanged layout, same skin, same dots |
| Currency pills | static counts | count-up on change, coin flight from the source (summon, claim, match result), a brief glow; the `+` becomes a brass coin-purse button |
| Panel chrome | flat paper, brown stroke | ablaq header band with the screen's icon, corner ornaments (one 9-slice image, `Config/Icons.chrome`), a 0.5-px inner highlight |
| Buttons | shaded rectangle | 9-slice wood with brass bevel; pressed = darken + 0.94 scale; disabled = desaturated, no bevel; primary = gold with a dark outline text |
| Modal open/close | pop 0.25 s | pop + backdrop fade; close reverses; sheets slide from the bottom with a handle (exists on phone) |
| NPC dialogue | plain box | **Portrait dialogue**: the NPC's portrait (from `Config/Icons` portraits, PV-C05) in a brass frame, name plate, typewriter text (18 chars/s, tap to complete), choice buttons slide in; Arabic typewriter runs RTL |
| Toasts | slideIn | stacked, icon per kind, 3 s, swipe to dismiss |
| Confirm dialogs | ad hoc | one `Modal.confirm(kind, body, yes, no)` with icon and the primary on the right (left in RTL) |
| Tabs (Play Story/Endless/Event, Units filters) | instant swap | underline slides, content cross-fades 0.15 s |
| Units grid | instant | stagger-in; new (unseen) units get a "new" ribbon; the selected card tilts (desktop) |
| Lane Diary | static | the tier strip auto-scrolls to the current tier; claimable tiers shimmer; claiming pops the reward and flies it to the pill |
| Summon | lantern reveal | unchanged, plus the ×10 result grid staggers and a Mythic shakes the screen (respects Reduced Motion) |
| Settings | list | grouped sections with icons; a "Lane life" slider (off / lite / full) replacing the Effects tier's lobby half |
| Match HUD | functional | wave pill gains an episode icon; the gate bar cracks at < 30 % (image swap); the rail buttons get the wood skin; the hotbar cards show a **type glyph** (§6.3) and dim when at `maxPlaced` |
| Result screen | existing | wave-by-wave cash sparkline (pure `MatchRewards` data), the Hakawati's outro line stays |

Sound: every state change calls `AudioController.ui(kind)` with the kinds in `Config/Audio.UI` (open, close,
tap, confirm, deny, claim, ready). The Audio bible already names the files; missing files are the owner's
STOP (AUDIO_COMMISSION.md).

---

## 6. The Defenders panel, per-tower auto-ult, unit types (LP-B)

### 6.1 The panel

A fourth rail button **Defenders** (icon: three fezzes) opens a panel listing every tower the player placed,
newest first (allies' towers in a second, read-only section). Desktop: a left column 300 px that replaces the
selected-tower side panel while open; touch: a bottom sheet of `Hud.SHEET_MAX_W`, height 60 % of the safe
area, scrollable; `RAIL.maxButtons` rises to 4 and `HudLayout.rail` already spills to a second column.

Row (72 px touch / 56 px desktop): portrait · name and level · one-line stat (DPS or income or buff) with the
buff count ("+130 % · 2") · **Ult** button with cooldown fill (hidden for units without `ability`) · **Auto**
toggle (per tower) · **Upgrade** with cost (long-press repeats, as the panel does) · **Sell** (two-step: the
button turns red and reads the refund; second tap sells) · **Target** cycle (hidden for 0-damage units).

Header: "N / `TOWER_CAP` placed", cash, **Auto-ult: all on / all off** (sets every row), sort chips (placed,
cost, level), and **Sell all** with the genre's two choices (farms only / all) behind a confirm. Each row has a
**lock** (client-side, no remote): a locked tower is skipped by Sell all and its Sell button needs the lock
opened first (the genre's Unit Manager pattern; it also stops thumb mis-taps on phones). Tapping a row's portrait **focuses** the watchtower camera on the tower (`MatchCameraController`
pan, 0.4 s) and selects it, so the existing panel's signature chooser is still reachable. Rows pulse gold when
their ult is ready; a row shakes when an upgrade is unaffordable. All strings in `en` and `ar`.

### 6.2 Server and sim

- New event `SetAutoAbility(towerId: string, on: boolean)` through `RemoteGuard.wrap`: identifier ≤ 64,
  boolean, ownership, phase (not during result), token bucket 10/s. Stored on the tower (`t.autoAbility:
  boolean?`); the sim's rule at `TdSim.luau:739-779` becomes `t.abilityQueued or (t.autoAbility ~= nil and
  t.autoAbility) or (t.autoAbility == nil and owner.autoAbility ~= false)`. The player-level setting stays the
  default for new towers.
- `MatchState` snapshot gains `towers[i].autoAbility` so a rejoin shows the right toggles.
- `UpgradeTower`, `SellTower`, `UseAbility`, `SetTargeting` are reused unchanged; the panel is a second view
  over the same `towers` table in `PlacementController`. Rate limits already exist; the "all on/off" header
  sends one `SetAutoAbility` per tower, spaced by the client over 0.3 s, never a burst.
- Persistence: none. (The one additive profile field in this plan is §7's story flag, not this.)

Specs: `tests/td.spec.luau` per-tower auto overrides player auto (on and off), nil falls back; `RemoteGuard`
rejections for a foreign tower, non-boolean, 1,000×/s (`tests/redteam.spec.luau`).

### 6.3 Unit types on the cards (lobby and hotbar)

No new config field is required for the first pass: `Logic/UnitLogic.kind(def) → Kind` (pure, specced)
derives:

| Field | From | Values shown (EN / AR) |
|---|---|---|
| Role | `def.role` | Melee · Ranged · Splash · Support · Farm · Healer, each with an icon (PV-C04 role icons) |
| Attack pattern | `levels[1]` | Single · Splash (radius) · Trap (iskafi's `slow` patch) · None (0 damage) |
| Reach | `hitsStealth`, `revealsStealth`, `douse` | Sees stealth · Lantern · Douses fire |
| Ability | `def.ability.kind` | Strike (shabriyeh) · Sweep · Mark, with cooldown |
| Economy | `income` / `bounty` | "+N cash per wave" · "+N per kill in range" (bounty finally shown) |
| Ability | `harvest` (new, §7.3) | "Count the gold: pays now" |
| Placement | `maxPlaced` | "max 3" |

Card: a role glyph in the corner, the attack pattern as a small pip row under the name (the genre's circle /
line glyphs), `maxPlaced` as "×3". Detail view adds a **stat block** like Anime Vanguards' (DPS at L1 and max
with cooldown and range, cost to max, sell value at max, beads kinds, signature paths with their numbers from
`UpgradeView`). Filter chips on the Units screen by role; sorting by rarity then role. Optional second pass
(`def.tags`: "gate", "souq", "diwan" lane-trade tags) is left as an owner idea, not a task.

---

## 7. Season 1's gold-gatherer: Abu Brahim the Cloth Merchant (LP-E)

### 7.1 Genre reference (farm units)

*(Research report 2026-10-19, read from the wiki pages; balance patches shift these, the executor re-checks
before tuning.)* Farm units are **zero-damage units that pay a fixed sum at the end of every wave, rising
with each upgrade**; the wikis hide their damage stats as "unimportant". Placement is capped (3 for the Epic
farms, 1 for the Legendary ones); the top farms are unsellable; each upgrade pays back in 3–4 waves; the last
upgrade is deliberately slow (6+ waves) so short modes stop one level early; only one trait touches farms
(Anime Vanguards **Fortune** +20 % income, Anime Adventures **Golden** +20 %, Anime Defenders **Midas**
+15 %). The meta is "2–3 farms in waves 1–5, maxed by wave 12, sold before the last waves"; All Star TD
added **farm-link placement limits** in 2026 to kill 3–4-farm loadouts, and now tracks cash income per wave on
screen.

| Game · unit (rarity, cap) | Place → max cost | Income per wave by level | Total | Payback per step |
|---|---|---|---|---|
| Anime Vanguards · Sprintwagon (Epic, 3) | 550 / 1,050 / 1,800 / 2,550 / 3,050 | 250 → 550 → 1,050 → 1,800 → 2,550 | 9,000 | 2.2 → 3.5 waves |
| Anime Vanguards · Takaroda (Legendary, 1, unsellable) | 800 … 12,500 | 250 → 750 → 1,500 → 3,000 → 5,000 → 8,000 → 10,000 | 39,800 | 3.1–3.5, last 6.25 |
| Anime Adventures · C.E.O. (Secret, 3) | 550 / 1,000 / 1,750 / 2,500 / 3,000 | 200 → 500 → 1,000 → 1,750 → 2,500 | 8,800 | ≈ 3 |
| Anime Defenders · Bloomer (Epic, 3) | 550 … (cum. 8,750) | 200 → 500 → 1,000 → 1,700 → 2,500 | 8,750 | 2.8–3.5 |
| All Star TD · Pizza Girl (5★, 1, unsellable) | 10 upgrades, 641,750 total | 701 → … → 148,000 | — | 0.5–1.5, last 4.4 |

Our scale is ten times smaller (`START_CASH 600`, wave clear 110 + 20 × wave, Episode 1 ends at wave 20), so
the merchant's curve below keeps the genre's **shape** (3–4-wave payback per step, a slow last step, cap 2) at
our numbers. Our `qahwaji` is already a farm at Rare scale (income 90→620, max 4, chip damage); the Season 1
merchant is the **Epic** version with **no damage at all**, a manual "Count the gold", two signatures, and a story tie.
Farm-income traits: our trait table has none; `Beads.byRole.farm` already exists and is the right slot (owner
idea for later: a "Baraka" trait +15 % income, farm-only, mirroring Fortune/Midas).

### 7.2 The character (why not a farmer, and why him)

Season 1 adapts **Part 1** of the drama (STORY_PLAN §2.1–2.2), and Part 1 has no farmer: the series' only
farm owner, Abu Zafer, enters in Part 6 (owner's correction, 2026-10-19). What Part 1 does have is the man
whose **gold** drives its whole plot: **Abu Ibrahim, the cloth merchant**, who hoards his savings at home, is
robbed by Al-Idaashari (our Episode 9 boss and secret unit), and when the gold is recovered gives **half of
it to the lane fund**. "All he does is gather gold" is literally his arc. One letter off (already in the
STORY_PLAN §3 table as a "new NPC"): **Abu Brahim / أبو براهيم**, role string "the Cloth Merchant / تاجر
القماش", unit id **`tajir`** (merchant). Lore line (`unit.tajir.desc`): "He never drew a knife in his life.
He counts, he saves, and when the lane needs it, he opens the chest." Story hooks: his shop is in the new
souq (§4.1); the Adashari night cameo creeps to his shutter (§4.3); the Episode 9 outro card ("the gold comes
home") names him; the Lane Diary's Season 1 premium track gives one copy at tier 20 (owner decision; else
banner only). Banner: joins the Epic pool (`Config/Banners`), odds unchanged.

### 7.3 Numbers (TUNE; all in `Config/Units.luau`, asserted by `tests/balance`)

| Level | Cost | Income at wave end | Cumulative cost | Payback (waves) |
|---|---|---|---|---|
| 1 | 450 | 150 | 450 | 3.0 |
| 2 | 400 | 270 | 850 | 3.1 |
| 3 | 650 | 440 | 1,500 | 3.4 |
| 4 | 1,000 | 680 | 2,500 | 3.7 |
| 5 | 1,500 | 980 | 4,000 | 4.1 |
| 6 | 2,200 | 1,350 | 6,200 | 4.6 |
| 7 (signature) | 3,400 | see paths | 9,600 | — |

`maxPlaced = 2`, `damage = 0` at every level (no targeting, no cooldown; the panel hides Target), `range` 8
(only for the Lane Fund signature and the badge ring), `role = "farm"`, `beads` = the farm kinds
(`Beads.byRole.farm`, exists). **Count the gold** (عدّ الذهب; `ability = { kind = "harvest", cooldown = 45 }`,
a new kind in `Units.luau:39-49` and `TdSim`): pays the current income at once, counts as the unit's attack
for clips and VFX; auto-ult fires it the moment it is ready, manual lets the player hold it for a boss wave.
Signatures (level 7, `UpgradeView` paths): **a "The Lane Fund"** (صندوق الحارة, his Part 1 gesture): every
teammate also receives 25 % of his wave income (co-op only; solo it reads "no one to share with" and the path
greys); **b "The Buried Jar"** (الجرّة المدفونة): every fifth wave pays double. Compared with `qahwaji`: 2.2×
income per level for 1.5× the cost; with two of each a maxed economy adds ≈ 4,000 cash per wave by wave 20,
which `tests/balance` must show does **not** flip a Hard or Nightmare episode (the ladder of STORY_PLAN §5.3);
if it does, cut Level 5–6 income first.

Sim rules: income pays at `endWave` like `qahwaji` (`TdSim.luau:824-830`); Count the gold pays immediately
and sets `abilityAt`; a sabotaged merchant pays nothing that wave (rifleman counterplay, consistent with §3.2
rule 3); a **pickpocket that reaches the gate steals 10 % of his next payout** (Part 1's theft, and the
pickpocket's existing `steal` flag gets a target); selling refunds 60 % of invested as for every tower. Specs:
pays per wave; Count the gold pays now and respects cooldown; the Lane Fund pays teammates and not solo; the
Buried Jar doubles on waves 5, 10, 15…; sabotage blanks a wave; the pickpocket steal; `maxPlaced` rejection;
zero damage never acquires a target.

### 7.4 Model, animations, VFX (≈ 90 Meshy credits, STOP before spending)

`tools/meshy/characters.json` entry `tajir` (height 1.75): "A plump, cautious 1930s Damascus cloth merchant,
greying beard trimmed short, red fez, long fine striped silk qumbaz under a dark green waistcoat with a watch
chain, a measuring stick under one arm, a small iron-banded money chest hugged to his chest with both hands,
wary sidelong look." Texture per the warm cast palette (cream, green, brass). Clips: `idle` (hugging the
chest, glancing left and right), `attack` = **count the gold** (Meshy library "count"/"cheer" action, or a
baked clip via `tools/anim/bake.py`: he opens the chest, lifts a handful of coins, lets them fall). Props: the
**money chest** as a ground prop and two **bolts of cloth** placed beside the tower on placement
(ArenaService dressing, like the coffee house's tray), a coin-jingle SFX on income (Audio). VFX on pay: coin
burst to the owner's cash pill (`CoinFlight`, exists) and a gold ring pulse on the chest. Import by the GLB
route (never the FBX clips), save to `assets/production/CharacterModels/AbuBrahim.rbxm`, register row,
`CharacterLooks.tajir`. The lobby NPC `cloth_merchant` (§4.2) reuses the model with the idle clip in the
souq's cloth shop.

---

## 8. Tasks

Statuses as in `BUILD_PLAN.md` (`[ ]`, `[~]`, `[x] <hash>`, `[!] <reason>`). Each task: **Goal · Create /
Change · Accept** lines. Captures go under `docs/captures/lp/`. Every task that touches numbers logs a TUNE row in
DECISIONS; every name goes through §4.2's STOP first.

### Workstream A: fixes players feel today (do first)

- [x] ff75c8d **LP-A01 Hide the health bar on death** · deps: none
  - Goal: §3.1.
  - Change: `EnemyRenderController.remove` disables the BillboardGui and the ring before `poof`; the position
    stream ignores ids with a pending death; `bossMeter` drains then hides.
  - Accept: a Studio capture of a dying thief (and a boss) with no bar; `execute_luau` (Client) finds no
    enabled `BillboardGui` under any model whose `deathClip` is playing; no console errors over 10 waves.

- [x] 19425ee **LP-A02 Buffs stack with a cap, haste too, sabotage counts, visible counts** · deps: none
  - Goal: §3.2.
  - Create: `TD.BUFF_CAP`, `TD.HASTE_FLOOR`; `TdSim.buffInfo`; the per-tower cache; specs listed in §3.2;
    TOWER_DEFENSE.md §buffs paragraph; DECISIONS TUNE row (D-008 cap row).
  - Change: `buffFor`/`hasteFor`; `refreshBuffs` sends `{ mul, count }`; the badge and the panel print
    "+N % · k"; selecting a support highlights covered towers.
  - Accept: specs green incl. "two Abu Bader stack to 2.3×, three cap at 2.4×, Abu Hissam + Abu Bader stack";
    `lune run tests/balance` ladder still passes (or a logged TUNE); Studio capture with two supports
    overlapping one fighter showing "+130 % · 2" and the highlight.
  - Shipped (D-092): one player's copies of a unit count once and `BUFF_CAP` is 1.8, the highest value that
    keeps the ladder; Abu Hissam + Abu Bader and two players' supports stack.

- [x] fb9bdaa **LP-A03 Speed ladder 1–5 with the premium tier** · deps: none · STOP (Fast Mode keep/retire; strings)
  - Goal: §3.3.
  - Create: `TD.SPEEDS`, `TD.PREMIUM_SPEED`; `MonetizationService.maxSpeed(player)` (VIP | premium diary |
    fast); the speed sheet; the non-host chip; strings; `RemoteGuard` enum check; specs for the perk resolution
    (`tests/meta.spec.luau`) and `SetSpeed` rejections (`tests/redteam.spec.luau`).
  - Change: `MatchService` speed handler; client `MatchController` button; `POSITION_RATE` handling at ≥ 4×;
    `Products.fast_mode` string; MONETIZATION.md row; DECISIONS row.
  - Accept: host without perks sees 3×–5× locked with the pass name and the Store opens on tap, no purchase
    prompt for a restricted player (Player Emulator policy check is the owner's STOP); with `HaretDebug`
    granting the perk, 5× runs 20 waves of Episode 1 with no desync, enemies move smoothly (capture), sim p95
    measured and logged (D-014 method); non-host sees the chip.
  - Shipped (D-093). Left for the owner: the Player Emulator policy check of the sheet (restricted region) and
    the non-host chip in Test → Clients and Servers; 5× was run to wave 19 (stopped, never finished).

### Workstream B: the Defenders panel and unit types

- [x] 01545af **LP-B01 `SetAutoAbility` remote and per-tower auto in the sim** · deps: none
  - Accept: specs in §6.2 green; red-team spec rejects a foreign tower id and a burst.
- [x] 17c73f4 **LP-B02 Defenders panel: list, rows, focus** · deps: LP-B01, LP-A02
  - Accept: desktop column and phone sheet captures (Device Emulator 844×390 and 1636×584) with 8 towers; a
    row's Ult fires and its fill drains; Upgrade/Sell/Target act on the right tower (console `[Match]` lines
    name the ids); tapping a portrait pans the camera; the panel never covers the hotbar or the cash pill.
- [x] 5cc73de **LP-B03 Header controls: all on/off, sort, counts; ready pulse** · deps: LP-B02
  - Accept: all-off then one wave: no auto ult fires (server log); all-on: they fire; sort chips reorder.
- [x] 82f876c **LP-B04 Rail to four buttons, phone rail spill verified** · deps: LP-B02
  - Accept: `tests/hud.spec.luau` cases for 4 buttons at the phone, tablet and desktop profiles; captures.
- [x] d315bda **LP-B05 Unit types on cards, hotbar glyphs, the detail stat block, filters** · deps: none
  - Create: `UnitLogic.kind`, `UnitLogic.statBlock` (pure, specced for every unit id: no `nil` fields);
    role icons (PV-C04 if missing: STOP for upload); strings.
  - Accept: every card shows role, pattern, reach, `×max`; the detail view shows the stat block incl. bounty
    for Abu Samih; hotbar cards show the glyph and dim at `maxPlaced`; Arabic capture.

### Workstream C: Theme v2 and motion

- [x] 373902b **LP-C00 "Before" captures and the console audit** · deps: none
  - Accept: 12 captures under `docs/captures/lp/before_*`; the `203785492` source identified (or documented as
    engine-side) in TEST_REPORT_SLICE.
- [x] 2ff7102 **LP-C01 Theme tokens v2, 9-slice chrome, button states** · deps: none · STOP (chrome image upload)
  - Create: `Theme.v2` tokens, `Config/Icons.chrome`, `UI/Button.luau` (one factory used by every screen),
    `Juice.breathe`, `Juice.stagger`, `Juice.dot`.
  - Accept: every lobby button is built by the factory (grep: no `Instance.new("TextButton")` left in
    controllers); four states captured; Reduced Motion respected.
  - Shipped (D-098) with the chrome at id 0 (drawn style kept): the 9-slice images wait for the owner's upload.
- [x] 3a9b3b8 **LP-C02 Lobby bar: hierarchy, dots, breathing Play; currency pills count and glow** · deps: LP-C01
  - Accept: captures desktop/tablet/phone; a Daily claim flies coins and counts the pill; dots clear on open.
- [x] **LP-C03 Panels, modals, sheets, tabs, toasts, confirm** · deps: LP-C01
  - Accept: every screen opens with the same motion; tab cross-fade; `Modal.confirm` used by Sell, Reroll,
    Leave, Redeem; toast stack capture.
- [ ] **LP-C04 Portrait dialogue with typewriter (EN and RTL AR)** · deps: LP-C01, PV-C05 portraits
  - Accept: Abu Nadim's errand in both languages captured mid-type; tap completes; choices slide.
- [ ] **LP-C05 Units, Summon ×10 stagger, Lane Diary auto-scroll and shimmer, Settings groups** · deps: LP-C01, LP-B05
  - Accept: captures; a Mythic ×10 shakes (and does not with Reduced Motion).
- [ ] **LP-C06 Match HUD skin: wave pill, gate crack, rail, hotbar glyphs, result sparkline** · deps: LP-C01, LP-B05
  - Accept: captures at 100 % and 25 % gate; result screen with the sparkline from `MatchRewards` data
    (pure, specced).
- [ ] **LP-C07 UI sound hooks** · deps: LP-C01 · STOP (missing files)
  - Accept: `Config/Audio.UI` kinds wired; missing files listed for the owner.

### Workstream D: the bigger lane and its people

- [ ] **LP-D00 Zone scaffolding: streaming models, budget 9,000, WORLD_MAP rows, perf baseline** · deps: none
  - Accept: `[World] built N parts (budget 9000)`; D-014-style numbers logged; phone capture ≥ 30 FPS.
- [ ] **LP-D01 Names and roles table approved; strings and register rows** · deps: none · STOP (owner approves §4.2)
  - Accept: `Strings` en/ar for every NPC; COPYRIGHT_REGISTER rows (C-2xx) per name; DECISIONS row.
- [ ] **LP-D02 NPC looks from existing models (13 NPCs), seated/patrol poses** · deps: LP-D01
  - Create: `Npcs.luau` gains `look: string?` (a `CharacterLooks` id) and `pose`; `NpcService` spawns the
    model with its idle clip; walkers use `CrowdService` paths.
  - Accept: capture of each NPC in place; no block figure left where a model exists.
- [ ] **LP-D03 The souq alley** · deps: LP-D00, LP-D02 · **LP-D04 The hammam** · **LP-D05 The diwan and the mosque court** · **LP-D06 The post and the orchard road** · **LP-D07 Rooftop women**
  - Each: zone built from the kit; ≤ its part budget; props from `PropModels` or kit; NPCs placed; WORLD_MAP
    row; captures from two angles; phone FPS check.
- [ ] **LP-D08 Four new NPC looks through Meshy (Hakawati, Feryal, grocer, sheikh)** · deps: LP-D01 · STOP (≈ 240 credits)
  - Accept: concept judged, GLB imported, `.rbxm` saved, register rows, idle clips, captures.
- [ ] **LP-D09 Lane clock, evening and night lighting presets** · deps: LP-D00
  - Accept: `Logic/LobbyLife.clock(t)` specced (phase boundaries, determinism); captures at the four phases.
- [ ] **LP-D10 Beats: gate, coffee-house evening with the Hakawati's tales, patrol, diwan dispute, night watch, cameo** · deps: LP-D09, LP-D02
  - Accept: each beat captured once; `Settings.effects off` shows a static lane; 30 Hz / 120-stud budget held.
- [ ] **LP-D11 The 'arada procession and the Ramadan musaharati (event-gated)** · deps: LP-D10 · STOP (music loop)
  - Accept: capture of the procession; the musaharati appears only with the Ramadan event active.

### Workstream E: Abu Brahim the Cloth Merchant

- [ ] **LP-E01 Name, lore, numbers approved; config, sim rules, specs** · deps: LP-A02 · STOP (name + numbers)
  - Accept: §7.3 specs green; `tests/balance` ladder holds or a TUNE row; Rates screen shows him in Epic.
- [ ] **LP-E02 "Count the gold" ability kind, the Lane Fund and Buried Jar signatures, the pickpocket steal, panel and Defenders row support** · deps: LP-E01, LP-B02
  - Accept: capture of Count the gold paying (coin flight); a two-player Studio server test (owner's STOP:
    Test → Clients and Servers) or a sim spec showing the Lane Fund paying the teammate.
- [ ] **LP-E03 Model, clips, chest and cloth props, VFX, the souq shop NPC** · deps: LP-E01, LP-D03 · STOP (≈ 90 credits)
  - Accept: `.rbxm` in production, register row, idle + count clips in Studio, chest and bolts on placement,
    `cloth_merchant` in the souq with the prompt and the lore line.
- [ ] **LP-E04 Story hooks: Episode 9 outro line, Diary tier copy, banner pool** · deps: LP-E03 · STOP (tier gift)
  - Accept: strings en/ar; `tests/season1.spec.luau` story-card case; Summon pool spec includes `tajir`.

### Order and sessions

1. LP-A01 → LP-A02 → LP-A03 (one session; ship as three publish-safe commits).
2. LP-B01 → LP-B05 in parallel with LP-C00 → LP-C01 (two sessions: one in `src/client/Controllers/Placement*`
   + server, one in `src/client/UI`; they share nothing but `Theme`, which LP-C01 owns).
3. LP-C02 → LP-C07 after LP-C01; LP-D00 → LP-D11 can run alongside in `src/server/World` (no file overlap).
4. LP-E after LP-A02 and LP-B02 (the Harvest row needs the panel).

Meshy budget: ≈ 330 credits (240 for four NPC looks + 90 for the merchant and his props); every spend is a STOP. No other paid resource.

---

## 9. Checklist (tick with the commit hash)

- [x] ff75c8d LP-A01 · [x] 19425ee LP-A02 · [x] fb9bdaa LP-A03
- [x] 01545af LP-B01 · [x] 17c73f4 LP-B02 · [x] 5cc73de LP-B03 · [x] 82f876c LP-B04 · [x] d315bda LP-B05
- [x] 373902b LP-C00 · [x] 2ff7102 LP-C01 · [x] 3a9b3b8 LP-C02 · [x] LP-C03 · [ ] LP-C04 · [ ] LP-C05 · [ ] LP-C06 · [ ] LP-C07
- [ ] LP-D00 · [ ] LP-D01 · [ ] LP-D02 · [ ] LP-D03 · [ ] LP-D04 · [ ] LP-D05 · [ ] LP-D06 · [ ] LP-D07 · [ ] LP-D08 · [ ] LP-D09 · [ ] LP-D10 · [ ] LP-D11
- [ ] LP-E01 · [ ] LP-E02 · [ ] LP-E03 · [ ] LP-E04

## 10. STOP list for the owner (batch these)

*Owner approved this list in chat on 2026-10-19 (DECISIONS D-091): names and Abu Brahim approved, Fast Mode kept and reworded (§3.3 option a), tier-20 gift in, ≈ 330 Meshy credits allowed task by task. Items 5–7 remain live STOPs when their task reaches them.*

1. Approve the §4.2 names table and the merchant unit (Abu Brahim / أبو براهيم, id `tajir`) and his lore.
2. Fast Mode pass: keep (renamed "3×–5×") or retire; speed stays host-gated.
3. Meshy credits: ≈ 240 (four NPC looks) + ≈ 90 (the merchant, chest and cloth props).
4. Lane Diary tier-20 gift copy of Abu Brahim: yes or banner only.
5. Chrome / role-icon image uploads (PV-C04/C05 route) if not already live.
6. Player Emulator policy check for the speed sheet; a real-device run of the new lane (FPS, streaming).
7. UI sound files that AUDIO_COMMISSION.md lists as missing.

## 11. Rules for this pass (in addition to CLAUDE.md)

- The game is live. Every commit publish-safe; desktop behaviour unchanged unless the task says so.
- Numbers in `Config`, logic in `Logic` with specs, every remote through `RemoteGuard.wrap`, every string
  en + ar, every name through §4.2 and the register, no series title anywhere, no actor likeness in prompts.
- Never finish a Studio test match (it pays the live profile); stop Play.
- Shared checkout: stage only your hunks; no stash, checkout, reset or whole-file reformat.
