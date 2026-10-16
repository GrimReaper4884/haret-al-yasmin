# Anime Vanguards study → what we change (2026-10-16)

The owner asked us to study **Anime Vanguards** (Kitawari; place 16146832113, now titled
"Vanguards: 2nd Anniversary", ~70K playing at the time of writing). We looked at five things:

- how it builds its HUD and menus;
- how players get from the lobby into stages ("Play → Story" panel vs our ground pads);
- events;
- summon and ultimate presentation;
- the in-match camera and character.

Then we compared it with Haret Al-Yasmin.

**Originality rule (unchanged):** we study *patterns*: layout, flow, timing, settings. We copy none
of their art, names, units, icons, music or text. Everything we build stays in the lane's own
look (docs/ART_BIBLE.md).

## How this was researched

- **Hands-on:** the game was launched on the test phone (Galaxy S23 via adb, Roblox only). The
  lobby loaded, and we saw the global-event bar at the top, the 7-day login panel, the side
  reward list and the chat feed of server-wide "X obtained a Mythic" pulls. Samsung Game Booster's
  touch protection then locked the screen to injected input. We did not change Game Booster
  (owner's rule: only Roblox is touched), so the hands-on part stopped at the lobby.
- **Desk research:** mainly wiki.vanguards.gg patch notes up to Update 15.0, plus guide sites. The
  Fandom wiki blocked fetches. **[C]** = confirmed by a source, **[I]** = inference.
- **Already covered elsewhere:** genre economics and rates are in ROBLOX_TOWER_DEFENSE_GENRE.md
  and UI conventions are in ROBLOX_TD_UI_PATTERNS.md. This doc covers only the visual/UX
  questions the owner raised.

## 1. Lobby and how you get into a stage

**Their pattern [C]:**

- **A walkable plaza with themed areas:**
  - Summon area: banners, unit index.
  - **Play area:** a row of *chambers*.
  - Upgrade room.
  - Raids building.
  - AFK room.
- **Chambers open a panel; they are not the level select themselves.** Walking into a chamber
  opens a **stage-select popup** with mode tabs (Story, Legend, Bounties…). The panel holds:
  - a map list on the left;
  - acts for the selected map;
  - a Normal/Nightmare toggle;
  - a rewards preview;
  - an enemy preview ("Stage Mechanics");
  - drop pity;
  - a Start button.
- **Party:** Match Invites pull same-server friends into the party.
- **Areas menu:** a left-rail **Areas** button teleports you to any area (with search). An
  optional "area helper" setting floats clickable teleport icons in the world.
- **Loading:** custom loading screens, not Roblox's default teleport screen.
- **Staying in the loop:** the end screen has **Replay / Next**, plus an **Auto-Next** setting. Since 14.5 the stage
  picker works *inside* a match too, so players rarely walk back.

**Ours today:**

- Four ground pads in the fountain square (Modes.portal), one per mode (ep1/ep2/ep3/infinite).
- A billboard above each pad.
- Standing on a pad shows a small party panel with a difficulty row and a countdown.
- No stage list, no reward preview, no enemy preview, no Replay/Next.

**Change:**

- Keep **one** physical place. A **"Play" gate** in the square (the Bab el-Hara arch is the obvious
  spot) where walking in, or tapping **Play** on the left rail, opens a **Play panel**.
- **Tabs:** *Story* · *Infinite* · *Event* (and later *Challenges*).
- **Story tab:**
  - Episode cards on the left: art tile, name, lock state.
  - The selected episode on the right: acts (our wave sets), difficulty pills, first-clear and
    repeat rewards, enemy preview icons, party slots, and the **Start / Invite / Leave** buttons.
- **Party:** the countdown and party logic stay server-side in MatchmakingService. The panel just
  replaces the pads. Pads become one "Play gate" trigger.
- **End screen:** add **Replay** and **Next act**.

## 2. Events

**Their pattern [C]:**

- An **Event Calendar** panel with Temporary and Permanent sections.
- Event coins come from daily missions and milestones, and are spent in an event shop.
- Event banners with their own currency.
- Seasonal lobby theming (re-skinned plaza, music).
- A global-event bar across the top of the lobby with a countdown (seen on the phone: "Rift
  spawns in 00:0x:xx").

**Ours today:** nothing event-shaped. Codes and dailies exist.

**Change:**

- **The place:** an **event corner** in the lane. The courtyard by the coffee house is the obvious
  candidate: lanterns, banners, an event NPC and a board. A matching **Event** tab sits in the Play
  panel.
- **The first event:** "Ramadan Nights" or "Eid in the Hara", built as data (`Config/Events.luau`):
  - start and end time;
  - a special wave set on an existing arena with modifiers;
  - an event currency earned in that mode;
  - a small event shop of cosmetics;
  - a top-of-lobby countdown bar.
- **Rules:** server-validated like every other reward. No paid currency in v1.

## 3. Summons

**Their pattern [C/I]:**

- **Banner layout:**
  - 3 featured units, with the middle one big and tagged FEATURED.
  - Chase units in the background.
  - Currencies along the top.
  - Big **Summon ×1 / ×10** buttons.
  - Visible Legendary/Mythic pity bars.
  - An Index button for per-unit odds.
  - **Auto-sell by rarity** toggles.
- **Reveal:**
  - Each result shows the unit with its name, rarity and stats.
  - A **New Index Unlock!** pop-up for first-time units.
  - A **Skip Summon Animation** setting.
  - Shinies have their own animation, and top units have **summon cutscenes**.
  - Rarity frames have sparkles and animated gradients.
- **Social:** global chat messages for rare pulls (seen live on the phone).
- **Gap:** no source describes the exact orb/flash sequence [I].

**Ours today:**

- A 560 × 250 modal showing two featured cards, ×1 / ×10 / Rates buttons.
- A reveal grid where cards pop in, and a gold flash for Legendary or above.

**Change:** a full-screen summon *sequence*:

1. **Build-up (0.8 s):** the screen dims and a brass lantern (our "orb") drops in on a chain.
2. **Rarity tell:** the lantern glows in the highest rarity rolled: blue → purple → gold → red →
   black/rainbow for secret. Legendary or higher adds a second shake and a pause.
3. **Burst:** the lantern flares open (a ParticleEmitter in a ViewportFrame, or a 2D starburst of
   rotated frames) and the unit appears on a rarity-gradient plate. It does a 1-second turntable
   spin, with the name stamped in an outlined display font.
4. **×10 sequence:** one combined build-up, then a 5 × 2 grid that flips cards in order, rarity
   first. Tapping skips to the full grid, and **Skip animation** is a setting.
5. **New unit:** a "New in your diary!" stamp. For Mythic or higher, a lobby-wide toast ("X found
   a Mythic …"), rate-limited server-side.

Pity bars stay on the banner screen, and the Rates panel stays as is (rates are disclosed before
any purchase).

## 4. Units, attacks and ultimates

**Their pattern [C]:**

- **Attack shapes:** single, circle, cone, line and full-map. The **attack form changes at
  upgrade thresholds** (new name, hit count, hitbox).
- **Active abilities:**
  - Cooldowns, sometimes limited uses per match.
  - Fired from the unit panel or a keybind.
  - An **Auto Ability** toggle.
  - Big ones play **cutscenes** (camera/FOV moves) or **domains** (a screen tint).
- **Effect controls:** VFX, animations and cutscenes each have their own disable toggle, plus a
  Low Detail Mode.

**Ours today:**

- Two ability kinds, `shabriyeh` and `sweep`, fire automatically on cooldown in TdSim.
- The client shows a thicker gold beam and a sound sting.
- Attacks are a thin coloured beam per hit.
- RigAnimController swings per role.

**Change:**

1. **Manual ultimate:**
   - A server-validated `UseAbility(towerId)` request, checked for ownership, cooldown and match
     state.
   - An ultimate button on the selected-unit panel, plus a ring on the hotbar slot that fills as
     the cooldown recovers.
   - An **Auto Ultimate** toggle that keeps today's behaviour for idle players.
   - TdSim keeps one rule: abilities fire only when requested or when auto is on.
2. **Ultimate presentation (client only):**
   - a 0.6 s slow-in;
   - a short camera push toward the unit (skipped if *Cutscenes* is off);
   - a rarity-coloured screen vignette;
   - the unit's ultimate name in a big outlined banner;
   - then the effect itself.
3. **Per-role effects:**
   - *Shabriyeh:* a dagger-flash slash arc across the target.
   - *Sweep:* a ground ring that expands with dust.
   - Every effect is pooled, so there are no per-hit `Instance.new`s.
4. **Attack shapes as data:** add `shape = "single" | "circle" | "cone" | "line"` to levels, so
   upgrades can change form, and show the shape on the upgrade tooltip.

## 5. In-match HUD

**Their pattern [C]:**

- A bottom hotbar of 6 unit slots, showing cost and element.
- At the top: wave counter and timer, a "Wave Completed!" banner, yen.
- A collapsible stage-info panel (modifiers, rewards so far).
- **Base = 3 lives, not an HP bar.**
- **Selected-unit panel:**
  - upgrade with cost, and **hold to mass-upgrade**;
  - sell;
  - ultimate and its cooldown;
  - eDPS, kills and damage.
- A Unit Manager with Auto-Upgrade priorities.
- Auto Skip and Auto Play.
- Enemy HP bars that group when enemies bunch; enemy previews before a wave.
- **Placement:** range ring, Shift to quick-place, and a reason shown when placement fails.

**Ours today:** wave, countdown, gate HP, cash, skip/speed/leave, a loadout bar, a ghost with a
range ring, and a placed-unit panel (upgrade, sell, targeting). That covers the basics, but it is
built from small flat frames.

**Change:**

- **Restyle:** chunky outlined numbers and pills for cash and wave, bigger hotbar slots showing
  the unit portrait, cost and a cooldown ring.
- **Panel:** hold-to-upgrade, an ultimate button, and a "damage this match" readout.
- **Results:** wave-clear banner and Replay / Next on the results screen.

## 6. Character and camera in matches

**Their pattern [C]:** players are their real R15 avatar and **walk around during matches**. They
can dash and double jump, and mounts work in matches. The default camera is the normal
third-person follow camera. Freecam and spectating are opt-in.

**Ours today:** matches open in the overhead "watchtower" camera (`MatchCameraController`:
`overhead = true -- matches open in the tactical view`). V or the button switches back to the
character.

**Change:**

- Matches open **on foot in the character camera**. The watchtower view stays as a toggle (V or
  the button).
- Placement works from the character view, using the existing raycast ghost.
- A small "dash" (a short burst of WalkSpeed with a dust puff) is optional polish.

## 7. Why ours feels laggy, and what to fix

Their lag sources [C] are heavy particles, clones and global VFX, and they answer them with
per-category toggles. Ours, from reading the client code:

| Where | What happens | Fix |
|---|---|---|
| `UI/UnitCard` (inventory, summon, featured) | Every card builds a full 3D rig inside its own ViewportFrame. Spinning cards add a RenderStepped connection each. Grids rebuild every card on each state change while open. | Render a **portrait once per unit** (cached ViewportFrame snapshot, or a 2D portrait drawn from primitives) and reuse it. Diff the grid instead of destroy/rebuild. Spin only the hero card. |
| `EnemyRenderController` attack events | Each attack scans every arena's Towers folder to find the unit id, then creates a new Part plus a Tween. | Keep a `towerId → unitId` map from `towerPlaced`. **Pool** beam parts. |
| `RigAnimController.step` | Walks every tower and enemy model each frame and writes Motor6D transforms, even far off-screen (radius 220). | Update at 30 Hz for distant rigs. Skip rigs outside the camera frustum. Lower the radius on phones. |
| `EnemyRenderController.step` | PivotTo of a whole multi-part model per enemy per frame. | Use one anchored root part with welded parts (`BulkMoveTo`), or move only the PrimaryPart. |
| Summon / match FX | Tweens and frames created on demand. | Pool the flash/banner frames. Add **Settings → Effects: Full / Reduced / Off** and **Skip summon animation**. |

These need profiling on the phone (MicroProfiler) before and after each fix. The table is a code
reading, not a measurement.

## 8. Build plan (proposed order)

1. **Performance pass:** portrait cache, pooled beams, rig animation LOD, and an effects setting.
   Measure frame time on the S23 before and after.
2. **Match on foot:** character camera by default, watchtower as a toggle.
3. **Play panel:** replaces the pads, with Story / Infinite / Event tabs, episode and act cards,
   rewards and enemy previews, and Replay / Next on the results screen.
4. **Summon sequence:** lantern build-up, rarity tell, burst, ×10 flip grid, skip setting, and
   the new-unit stamp.
5. **Manual ultimates:** server request plus Auto toggle, the ultimate banner, camera push,
   vignette, and per-role effects. Attack shapes in data.
6. **Match HUD restyle:** hotbar portraits and cooldown rings, hold-to-upgrade, wave-clear banner.
7. **Event corner and the first event:** data-driven `Config/Events`, event currency and shop,
   and the countdown bar.

Each step ships behind the existing tests (`lune run tests/run.luau`), gets new specs for any
server-side logic (ultimate requests, event rewards, replay/next validation), and is play-tested
in Studio and on the phone before any publish to the private test experience.

## Open gaps

- The exact summon sequence, whether a 2×/3× speed button exists, the targeting options, boss HP
  bar styling, and countdown timing.
- These need either the phone unlocked (drag the Game Booster lock icon once) or gameplay video.

## 9. Built (2026-10-16, published to the private test experience as v62)

| Plan step | What shipped | Where |
|---|---|---|
| 1 Performance | **Rigs:** built once per id, then cloned (`RigBuilder.cached`) for cards, enemies and towers. **Beams and ultimate effects:** drawn from a pooled part budget of 80 (`UI/Fx`). **Enemy movement:** one `BulkMoveTo` per frame instead of a `PivotTo` per enemy. **Rig animation:** figures off screen are skipped; figures past 70 studs update every third frame. **Settings → Effects:** Full / Reduced / Off. | `Util/RigBuilder`, `UI/Fx`, `EnemyRenderController`, `RigAnimController`, `SettingsController`, `Logic/Settings` |
| 2 On foot | Matches open behind the character, and the phone keeps its thumbstick and jump button. The watchtower view is still a toggle (V or the button), and Settings → Match camera can make it the default. | `MatchCameraController`, `MatchController` |
| 3 Play panel | **Square:** one Play arch replaces the four portal pads; walking in opens the panel, and so does Play on the left grid. **Panel:** Story / Endless / Event tabs, mode cards (lock and cleared state), difficulty, waves, rewards, enemy and boss preview, Create party, and open parties with Join. **Party bar:** Start now (host) and Leave. **Results:** Replay and Next; the old team joins the same replay party. | `PlayController`, `QueueController`, `MatchmakingService`, `Logic/PartyLogic`, `World/Zones/Extras` |
| 4 Summons | **Build-up:** the lantern drops on its chain, swings and glows. For Legendary and better it glows blue first, shakes, then turns. **Burst:** a flash, rays and sparks. **×1:** one big turning card. **×10:** cards flip in, and a tap shows the rest. **Extras:** a NEW! stamp on first-time units, Settings → Summon animation (Skip), and a server-wide line for Mythic and better pulls. | `UI/SummonSequence`, `SummonController`, `MetaService` |
| 5 Ultimates | **Firing:** a tap (validated on the server by `TdTowers.useAbility`) or Auto (Settings, or the toggle on the defender panel). **Panel:** an ultimate button that refills as the cooldown recovers. **Effects:** the ultimate's name in the banner, a rarity-coloured edge flash, a zoom punch, and in the world a crossed blade flash (shabriyeh) or a ground ring with dust (sweep). | `Logic/TdSim`, `Logic/TdTowers`, `MatchService`, `PlacementController`, `MatchFxController`, `EnemyRenderController` |
| 6 Match HUD | Hold Upgrade to keep buying levels, a gold ultimate badge on hotbar units, a "Wave N cleared!" banner, and a settings gear next to Leave. | `PlacementController`, `MatchController`, `MatchFxController` |
| 7 Event | **The event:** "Olive Harvest Nights" (2026-10-16 → 2026-11-30 UTC), with an Orchard Raid mode of 15 waves on the orchard road. **Olives:** 3 per wave held, +25 for a full clear. **Event shop:** qirsh, lira, a trait stone and the embroidered shawl, all bought with olives on the server. **Square:** an event corner on the east side, mirroring the Play arch. **Lobby:** an Event button that shows only while an event runs. **Robux:** none. | `Config/Events`, `Logic/EventLogic`, `EventController`, `MetaService`, `MatchService`, `World/Zones/Extras` |

**Verified:**
- 123 Lune tests pass (new specs: settings, party, event, and manual/auto ultimates in td).
- selene shows only the existing DataService warning, and the luau-lsp type check is clean.
- `rojo build` succeeds.

**Studio play-test (PC):**
- Menu grid, Settings and the Event screen work, and Play → Event lists Orchard Raid.
- Walking into the Play arch opens the panel, Create party and Start now work, and the match opens on foot.
- Placing defenders works on foot, and the watchtower toggle works.
- The ×1 and ×10 summon sequences play.
- Auto ultimates fire: a client listener on MatchEvents saw `attack.ability`.
- Output shows no script errors, only the expected Studio DataStore message and Roblox CorePackages warnings.

**Not yet verified:**
- **Phone:** the S23 run. Game Booster's touch lock blocked input today.
- **On-screen ultimate:** the banner and camera punch were not caught in a screenshot.
- **Replay / Next with two players.**
- **Frame time:** measured with MicroProfiler before and after the performance pass.
