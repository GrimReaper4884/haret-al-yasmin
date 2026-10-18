# Mobile HUD refactor plan (MH): lobby and match UI for touch

*Written 2026-10-18 for the executing agent (Claude Opus 5.5 in Claude Code on the owner's machine). It
replaces the one-line task **P3-08 Mobile UI pass** in `BUILD_PLAN.md`. Read `CLAUDE.md` first: session
start, verify loop, hard rules, shared checkout. One MH task per commit, subject `MH-xx: <imperative>`.*

*Synced 2026-10-18 (evening) against `main` at `c8b6681`. Since the first draft every branch was merged into
`main` and deleted, and the game was **published as v1.0.0** (D-072, `RELEASE_CHECKLIST.md`): the HUD this
plan refactors is live for players. Season Story 1 (`STORY_PLAN.md`, workstreams S1-N/S/A/M/C all ticked)
added pieces the plan now carries: the Episode 4–6 mechanic HUD (burn pips under the gate bar, markers), the
level-7 signature chooser in the defender panel, shabriyeh bead slots and a bead picker in Units, the Play
panel's Story tab with nine episode cards, painted mode banners and the Hakawati's outro on the result
screen, two-road arenas, the pickle cart prompt, a version label in Settings. **No MH task has started.**
Line references below were re-read against `main`; the client is now 13,529 lines.*

## 0. Kickoff prompt (paste this into Opus 5.5)

> Read `CLAUDE.md`, `docs/TOOLS.md`, the last 40 rows of `docs/DECISIONS.md`, and all of
> `docs/MOBILE_HUD_PLAN.md`. Do the CLAUDE.md session start (git status, `ListAgents` and coordinate with any
> session touching `src/client` or Studio, `list_roblox_studios`, `rojo serve`, Rojo Connected). The branches
> were merged and deleted at v1.0.0, so ask the owner once, before the first commit: commit on `main`, or cut
> `phase/mobile-hud` from `main` (only if no other session has uncommitted work in this checkout: D-005 forbids
> `checkout` otherwise). Then work MH-00 → MH-18 in order. For every task: mark it `[~]` here, implement code
> and specs, `tools/check.ps1` green, `script_grep` sync check, Studio playtest with the Device Simulator
> captures the Accept line names, captures under `docs/captures/mh/`, the TEST_REPORT_SLICE and DECISIONS rows
> the task names, commit `MH-xx: <imperative>` with a `Verified:` body, mark `[x] <hash>`. Every commit must be
> publish-safe on its own (the game is live; the owner publishes when they choose): no half states, desktop
> behaviour unchanged unless the task says so. Numbers in `src/shared/Config/Hud`, pure logic in
> `src/shared/Logic` with Lune specs, every new remote through `RemoteGuard.wrap`, every new string in `en` and
> `ar`. Three honest attempts, then `[!]` with the reason and move on. Batch every STOP item (real-device run,
> Discord post, icon generation, anything the simulator cannot drive) into one message to the owner and keep
> working on unblocked tasks.

The game is public on the TEST place and `GAME_DESIGN.md` §"Mobile first" names a mid-range Android phone
as the design target, but the HUD was authored for a mouse and only *fits* a phone. This plan makes the
lobby and the match playable with two thumbs: no button under the Roblox corners, no element smaller than
a fingertip, a placement flow that cannot misfire, and panels that reach the thumbs. It is a refactor of
layout and input only. Nothing here touches the simulation, the economy or any server rule; the one server
change is a new analytics field.

Contents: Part A evidence (what mobile-friendly Roblox TDs do, platform facts, the audit of our code) ·
Part B the target design · Part C the tasks MH-00 … MH-18 with acceptance lines · Part D the verification
matrix and the STOP list.

---

## Part A: Evidence

### A1. What the mobile-friendly Roblox tower defenses do

Researched 2026-10-18 from the games' wikis and patch notes, the DevForum and Roblox docs. Reddit was not
reachable; anything not confirmed by a source is marked UNVERIFIED and was not used for a decision.

| Pattern | Who | Evidence |
|---|---|---|
| Hotbar along the bottom, 5–6 slots, cost on the slot, the **same layout on PC and phone** | Tower Defense Simulator (5 + 1 event slot), Anime Vanguards, Toilet TD, Tower Blitz | TDS wiki "How to Play": "Mobile and Tablet users have a similar UI to PC players" (tds.wiki/w/How_to_Play) |
| Tap slot → ghost → a **second, deliberate input commits**; never a single tap on the world | TDS: "For tablet/mobile users, you need to double tap to select and place down towers". Anime Vanguards: explicit **Place** button that reads **Queue** when unaffordable; Anime Last Stand U76 "Ghost Unit Placing" | tds.wiki/w/How_to_Play · wiki.vanguards.gg/Extermination_Event_(14.0)_Part_2 · alsroblox.fandom.com/wiki/2025_Update_Logs |
| One-tap **Quick Place** is an *opt-in* button on mobile, not the default | Anime Vanguards 10.5 (Feb 2026): "A Quick Placement button has been added to Console and Mobile" | wiki.vanguards.gg/Frozen_Solitude_(10.5) |
| **Camera locked while a ghost is active** on touch | Anime Vanguards treats camera movement during placement as a bug (11.0, 12.0, 12.5 fixes) | wiki.vanguards.gg/Turning_Tides_(12.5), Painful_Lessons_(12.0) |
| A **stray tap does not deselect** on mobile | Anime Vanguards 7.5: "tapping on the screen while you have a unit selected will no longer result in the unit being unselected"; 14.5 "Fixed the selection cancel button being too small on mobile" | wiki.vanguards.gg/Summer's_Pride_(7.5), 25th_Hour_(14.5) |
| Failed placements say **why**; the ghost does not linger when broke | AV 14.5 "Failed placements now tell you exactly why"; indie TD feedback: "I couldn't figure out how to confirm the placement so I left", "the ghost tower doesn't go away" | devforum.roblox.com/t/4107257 |
| Upgrade panel opens on **tap** of a placed tower; next cost and stats; **tap, never hover** for detail; TDS lets players pick a **vertical or horizontal** panel, both on mobile since v1.32.0 | TDS, AV ("Changed 'hover to view upgrade stats' to 'click' … for mobile usage"), Toilet TD | tds.wiki/w/Settings, tds.wiki/w/V1.32.0 · animevanguards.fandom.com/wiki/Update_Log |
| A **UI scale setting** (TDS: Small / Default / Large / Huge; AV: numeric slider), with long lists of "cut off at 1.0+" fixes behind it | TDS, AV | tds.wiki/w/Settings · wiki.vanguards.gg/Painful_Lessons_(12.0) |
| Speed and skip buttons **kept out of the hotbar row** | TDS v2.0.0 "Fixed the Timescale button overlapping other hotbar buttons"; ASTD 30.4 "Moved Fast forward Button On Mobile" | tds.wiki/w/V2.0.0 · allstartd.fandom.com/wiki/2023_Update_Log |
| Custom UI colliding with **Roblox's own corners** (menu icon, jump, dash) is the most common mobile bug class | AV 13.0 "Browse tab is covered by 'Roblox' icon in mobile", 13.5 jump/dash overlapping action buttons, 10.5 "players were able to lose the jump button" | wiki.vanguards.gg/Godly_Ascension_(13.0), Eternal_Adversaries_(13.5) |
| Automation toggles aimed at phones (auto skip, auto upgrade, auto ability) | AV, TDS | animevanguards.fandom.com/wiki/Update_Log |
| Lobby: a side button stack or bottom bar opening full-screen panels with big close buttons; secondary actions folded into a menu on small screens | ASTDX summon icon on the left, FNTD settings cog lower-left, Skibi Defense menu instead of portals; Roblox adaptive-design guidance "move less-important buttons into a collapsible menu" | create.roblox.com/docs/production/publishing/adaptive-design · pocketgamer.com/roblox/tower-defense-games |
| Free top-down camera is **not** a shipped mobile mode in any of them; players walk the map | TDS, AV | tds.wiki/w/How_to_Play; AV top-down exists only for spectators |

Mobile complaints that recur (TDS community pages, AV patch notes, DevForum): the finger hides the ghost and
towers land "in odd locations", the map pans with the tower, confirm and cancel are not obvious, upgrade
windows are hard to open, panels scaled wrong or unscrollable on phones, buttons under the jump button.

### A2. Platform facts the design relies on (verified on create.roblox.com, 2026-10-18)

- **Safe areas.** `ScreenGui.ScreenInsets = CoreUISafeInsets` (our `HaretHud` already) keeps content clear of
  the notch and the top bar. `GuiService.TopbarInset` (a Rect, dynamic) is the only honest top-bar height;
  the bar grew from 36 to 58 px with the new experience controls and "may vary based on device". Never
  hard-code it. `GuiService:GetInsetArea(Enum.ScreenInsets.None)` gives the full-screen rect relative to the
  safe area.
- **Device signal.** `UserInputService.PreferredInput` (`Touch`, `KeyboardAndMouse`, `Gamepad`) tracks the
  last used input and is the recommended layout switch; `GuiService.ViewportDisplaySize` (`Small` = phones
  and tablets, `Medium` = monitors, `Large` = TVs) measures physical size. `TouchEnabled` alone is wrong on
  touch laptops. Both have `GetPropertyChangedSignal`.
- **Touch events.** `TouchTap`, `TouchTapInWorld`, `TouchPan(positions, totalTranslation, velocity, state)`,
  `TouchPinch(positions, scale, velocity, state)`, `TouchLongPress`; raw `InputBegan/Changed/Ended` with
  `UserInputType.Touch` where one `InputObject` persists per finger. A TD developer reported `TouchTap` and
  `TouchTapInWorld` unreliable on some Android devices (DevForum 3987745); the design below does not depend
  on them. `gameProcessedEvent` is true when a GuiObject with `Active = true` handled the touch.
- **Default touch controls.** Thumbstick bottom-left, jump bottom-right (`PlayerGui.TouchGui.TouchControlFrame`);
  `GuiService.TouchControlsEnabled = false` hides both (we already do this in watchtower view). Never destroy
  the frames. Roblox: "the default controls occupy a portion of the bottom-left and bottom-right corners",
  "most mobile players use two thumbs", "a button 40% below the top edge is reachable on a phone but almost
  unreachable on a tablet".
- **Sizes.** Roblox publishes no minimum target; Apple 44 pt and Android 48 dp apply, and Roblox GUI px are
  already DPI-scaled, so **≥ 48 logical px** at the final scale. `UITextSizeConstraint.MinTextSize ≥ 9`;
  realistically ≥ 14 on phones. The accessibility "Preferred Text Size" setting rescales fixed text.
- **Feedback.** `HapticService` is deprecated; `HapticEffect` (`UIClick`, `UINotification`, …) assigned to
  `GuiButton.PressHapticEffect` plays on press. `GuiButton.SecondaryActivated` is a long press on touch.
- **Drag.** `UIDragDetector` with `ResponseStyle = CustomOffset` reports drags from a GuiObject without moving
  it, on all inputs. Not needed for v1 (no competitor ships drag-from-slot on touch), noted for later.
- **Device Simulator** (GA since 2026-10-16): Phone presets Flagship / Mid-range / Entry level, custom
  resolutions, `ActualResolution` and `ScaleToPhysicalSize` modes. `docs/TOOLS.md` says it is reachable only
  through the `rbx-device-simulator-lua` skill plus `execute_luau`; D-027 proved an iPhone 17 Pro run
  (874×402, viewport 750×381). Analytics dashboards break every chart down by Platform (Phone / Tablet /
  Computer), so the mobile share is readable without code; the in-game device class needs a custom field.

### A3. Audit of the current client (`src/client`, 13,529 lines, re-read on `main` 2026-10-18 evening)

Foundation. One `ScreenGui` (`UI/Root.luau`), `CoreUISafeInsets`, every layout in **offset px for a
844×390 phone** plus one `UIScale` of `clamp(min(H/390, W/760), 0.8, 1.5)` computed from
`Camera.ViewportSize` (not the safe-area `AbsoluteSize`). `Theme.TOUCH = 48` exists but is honoured by few
buttons. No `PreferredInput`, `TouchEnabled`, `TopbarInset`, `UITextSizeConstraint` or `TextScaled` anywhere.
A second ScreenGui tree now exists in `src/first` (the PV-D05 loading screen, `ScreenInsets = None`, its own
phone capture); it is out of scope.

Added by Season Story 1 and the release, all phone-fitted by eye in three-column or side-panel form but
none of it touch-first:

| Piece | Where | What the plan must carry |
|---|---|---|
| Burn pips under the gate meter (one per `TD.BURN_MAX_STACKS`, y 76 in the top block) | `MatchController.luau` build, `Vfx.STORY.burnPip` | the top block is ~96 px tall now; the boss bar hangs under it |
| Result screen: 110 px painted mode banner + the Hakawati's outro, then rewards | `MatchController.luau` (`resultBanner`, `resultOutro`) | the result modal is taller: sheet mode on phones (MH-13) |
| Level-7 signature chooser: a 92 px row of two half-width path cards (name 14 px, description **11 px**, cost 13 px) above Upgrade; the stat lines hide while choosing "so the panel fits a phone" (S1-C04) | `PlacementController.luau` (`sigRow`, `sigCards`, `UpgradeView.step`) | the bottom sheet (MH-09) needs a chooser state |
| Sabotaged / lantern-out lines in the panel (D-038) | `PlacementController.renderTowerPanel` | two more stat lines in the sheet |
| Two roads per arena: the ghost checks `Path.distanceToAll(arenaPaths, …)`; `TdTowers.canPlace` reads `state.paths` and takes a `trait` (miser prices) | `PlacementController.valid`, `Logic/TdTowers.luau:46` | MH-06's client view passes `paths` and the trait |
| Prices shown through `UnitLogic.costFor` (miser trait) on slots and Upgrade | `PlacementController.myCost` | keep when the hotbar is rebuilt (MH-05) |
| Portraits are images now (`UnitCard.portrait`, PV-C05), no ViewportFrames in the hotbar | `UI/UnitCard.luau` | cheaper slots; nothing to do |
| Units: three bead slots in the detail (42 px row), a bead picker panel (close 40×40, rows 44 px), Rates in two columns with a switch button 120×32 | `UnitsController.luau` | sizes to 48 in MH-13 |
| Play: the Story tab first, nine episode cards with 18 px mechanic icons, "Coming soon" cards, Episode 9 odds line; difficulty buttons 126×32; the Story detail was fitted to 750×381 in S1-C01 | `PlayController.luau:270-365, 517-595` | MH-14's two-step layout carries the cards and must not regress the fitted detail |
| Settings: a `v1.0.0` version label row | `SettingsController.luau` | keep below the new rows |
| Pickle cart "Look" prompt and bubble | `LobbyStoryController.luau` | a ProximityPrompt, touch-native; nothing to do |

What that means on real phones (numbers at the simulator's iPhone 17 Pro 750×381 and an entry-level
16:9 phone at 640×360 logical px):

| Problem | Where | Effect on a phone |
|---|---|---|
| Scale floor 0.8 **shrinks** targets on the smallest screens, the opposite of what touch needs | `Root.luau:21` | 640×360 → scale 0.84; a 48 px button becomes 40 px, the 32 px tower-panel close becomes 27 px |
| Single tap on the ground **places immediately**; the finger hides the ghost; no confirm | `PlacementController.luau` `tap()` at :603 and `TouchTap` at :1061 | the misplacement class every competitor fixed; `TouchTap` is also unreliable on some Androids |
| In walk mode a one-finger drag **orbits the camera** while the ghost follows the finger | `MatchCameraController` walk = `CameraType.Custom` | "the map pans with the tower" |
| Right column of **six** stacked buttons (skip, speed, leave+gear, codes, camera, mute) from y 60 to 316 | `MatchController.luau:119-168`, `MatchCameraController.luau:152` | the camera toggle sits on the jump button (y 270–340 on a 360 px screen) |
| Hotbar fixed at 518 px wide + cancel X at a fixed offset beyond it | `PlacementController.luau:88, 92` | on 640 px the cancel X lands under the jump button |
| Tower panel on the **left edge**, vertically centred, ~330 px tall (more with the chooser row) | `PlacementController.luau:95` | covers the thumbstick zone; its buttons are 32 / 40 / 44 px, the path cards' text 11 px |
| A tap on empty ground **deselects** | `PlacementController.luau` `tap()` fall-through at :654 | the AV 7.5 complaint |
| Lobby 3×3 grid at (10, 45 %) is 174 px tall | `LobbyMenuController.luau:69-86` | spans y 162–336 on 360 px: inside the thumbstick zone; captions 11 px |
| Top row: lira, coins, language, wardrobe, music ≈ 600 px wide, top-centre | `HudController.luau:38-141`, `LobbyMenuController.luau:55` | brushes the Roblox controls on 640–750 px screens |
| Dialogue panel 0.92 wide overlaps the jump button (known, `TEST_REPORT_SLICE.md:95`) | `DialogueController.luau:33` | |
| Play panel is three columns in a 780 px modal | `PlayController.luau:517-595` | at 705 px the detail column is squeezed; Join 84×30, difficulty 126×32 |
| Modal bodies are fixed offsets; close buttons 40 px; Pass claim buttons 26 px; Event buy 32; Wardrobe equip 34; Queue difficulty 36 | `Modal.luau`, `PassController.luau:86`, … | below 48 px before the scale floor |
| Codes modal with a `TextBox`: the on-screen keyboard covers the centre of the screen | `CodesController.luau:36-50` | the box and Redeem are hidden while typing |
| Hover-only affordances: mute tooltip (`MouseEnter`), hover grow and tilt | `SettingsController.luau:231-236`, `Juice.luau:55-66, 178-190` | harmless, but no touch equivalent |
| Settings has no UI scale, panel side, quick place or hand option | `SettingsController.luau:76-126` | |
| No tests cover layout; `tests/icons.spec.luau` is the only UI-adjacent spec | | |

Works already and stays: `CoreUISafeInsets`; `TouchControlsEnabled = false` in watchtower view; press
squash on touch (`Juice.press`); hold-to-upgrade on touch (and it never buys a signature: that is a choice);
the bottom-centre hotbar and cash pill; the chunky display font and outlines (`ART_BIBLE.md` §6); modals
opaque and above the HUD; Arabic RTL alignment through `Theme.align`; the Galaxy S23 run (lobby only)
passed; the S1-C01 Story detail and S1-C04 chooser were checked on the iPhone 17 Pro preset; the Rates
columns sit below the close button and mirror in Arabic (S1-S02).

---

## Part B: Target design

Decisions. Each one is backed by A1–A3; deviations from earlier docs are listed at the end of this part
for the DECISIONS log.

### B1. One layout engine, two profiles

- **Profiles.** `touch-phone` (PreferredInput Touch **and** ViewportDisplaySize Small **and** safe-area
  height < 500 px), `touch-tablet` (Touch, Small, height ≥ 500), `desktop` (everything else; gamepad is
  desktop with focus navigation later, out of scope). Re-evaluated on `PreferredInput`,
  `ViewportDisplaySize`, `AbsoluteSize` and `TopbarInset` changes; a change re-lays out live (Studio's
  device switch mid-playtest exercises this).
- **Scale.** Base scale from the safe-area `AbsoluteSize`: `H / 390` clamped to `[1.0, 1.5]` on touch
  profiles and `[0.9, 1.5]` on desktop, multiplied by the player's `uiScale` setting (`small 0.85`,
  `default 1`, `large 1.15`, `huge 1.3`), then clamped so the 6-slot hotbar plus 2 × 16 px margins still
  fits the width. Phones never go below 1.0: the smallest phone gets the **largest** relative UI.
- **Reserved zones** (touch profiles only): bottom-left `160×160` and bottom-right `140×140` logical px
  while the thumbstick and jump are shown (lobby, walk camera); read the real frames from
  `PlayerGui.TouchGui.TouchControlFrame` when present and fall back to these numbers. The top strip is
  handled by `CoreUISafeInsets`; nothing interactive goes within 8 px of the top edge.
- **Targets.** Every `GuiButton` ≥ 48 px on both axes at the final scale (primary actions 56); text
  ≥ 14 px (numbers ≥ 18) at scale 1; hit areas may be larger than the drawn button (transparent padding).
- All numbers live in a new pure `src/shared/Config/Hud.luau`; the profile and scale maths live in a new
  pure `src/shared/Logic/HudLayout.luau` with Lune specs. The client reads both through a new
  `UI/Device.luau`. Offsets plus one `UIScale` stay the authoring model (`ART_BIBLE.md` §6 already says
  so; `SYSTEMS_ARCHITECTURE.md:17` "UI in Scale units" is wrong and gets corrected).

### B2. Match HUD (touch-phone; the desktop layout keeps its current shape where it already works)

```
┌──────────────────────────────────────────────────────────────────────┐
│ [Roblox ▣ 💬]        WAVE 7/20 · Next in 12s      [≡ Menu] [👥 Roblox] │  top strip = TopbarInset
│                      ████████████░░░ Gate 420/600                      │
│                                                              [⏩ Skip]  │  right rail, thumb arc,
│                                                              [2× Speed]│  above the jump zone
│                                                              [👁 View]  │
│  (thumbstick zone)                                                     │
│               [$ 1,240]                                                │
│      ┌────┬────┬────┬────┬────┬────┐                      (jump zone) │
│      │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │   ← 6 slots 72×88, gap 6          │
│      └────┴────┴────┴────┴────┴────┘                                   │
└──────────────────────────────────────────────────────────────────────┘
```

- **Top block** stays top-centre (wave pill, status line, gate meter, the burn-pip row under the meter)
  but is width-capped to leave TopbarInset's left and right controls clear; the boss bar hangs under it
  as today.
- **Right rail**: at most three 56 px buttons in the right thumb arc (vertically centred, bottom edge
  ≥ the jump zone): **Skip** (prep only), **Speed** (host only), **View** (walk ⇄ watchtower). Everything
  else (Leave, Codes, Settings, Music, Language) moves into a **Match menu** sheet opened by one `≡`
  button in the top-right of the safe area. Leave gets a confirm step inside the sheet (a mid-match
  leave is destructive). Desktop keeps the full column but inherits the sizes.
- **Hotbar**: bottom-centre, slot `72×88` on touch (`68×84` desktop), gap 6, width = slots × size (not
  the fixed 518), never wider than the free band between the reserved corners; the cash pill sits
  directly above the first slot. Slot shows portrait, cost (red when unaffordable), placed/limit; the
  number-key hint only on desktop (already so). The width fit is computed for **7** slots
  (`TD.LOADOUT_SLOTS = 6` plus the Extra Slot pass), so a pass holder's bar also clears the corners.
- **Toasts** move up so they never sit on the hotbar or the Place/Cancel pair.

### B3. Placement on touch: pick, aim, commit

1. **Pick.** Tap a slot. The slot lifts (as today). The ghost appears with its range ring at the last
   ground tap, else at the screen centre's ground hit, else in front of the character.
   `GuiService.TouchControlsEnabled = false` for the duration (also in walk mode) and a full-screen
   transparent **PlacementCatcher** frame (`Active = true`, below the HUD in ZIndex) takes every touch,
   so the camera cannot orbit while aiming (the AV rule).
2. **Aim.** Drag anywhere on the catcher: the ghost follows the finger with a vertical offset of
   `Hud.PLACE.FINGER_OFFSET_PX` (70) so the fingertip never hides it; a tap (slop ≤ 12 px, ≤ 0.35 s)
   jumps the ghost there. Validity tints green/red as today and a one-line reason label sits under the
   ghost's screen position (`on_path`, `too_close`, `out_of_bounds`, `cannot_afford`, `unit_cap`,
   `tower_cap`: the existing `ERR_KEYS`), evaluated by the shared `TdTowers.canPlace` (the client stops
   re-implementing bounds/path/spacing in `valid()`).
3. **Commit.** A bottom-right pair above the hotbar, **Place** (green, 56 px, shows the cost; disabled
   with the reason when invalid) and **Cancel** (red, 56 px), always clear of the jump zone. Place sends
   `PlaceTower(unitId, x, z)` exactly as today; the server stays the judge.
   **Quick place** (setting, default off on touch, on for desktop where a click already commits): a tap
   on valid ground commits at once, as now. Cancel also by re-tapping the slot or the catcher's long press.
4. **Select.** With no ghost, a tap on a defender (touch pick radius 44 px instead of 34) opens its panel;
   a tap on empty ground does **not** deselect on touch (close button, another defender, or a slot do).
   Mouse keeps click-to-deselect.
5. **After commit** the ghost clears, the catcher drops, touch controls return (walk mode) and a
   `UIClick` haptic plays.

Raw `InputBegan/Changed/Ended` on the catcher frame carry the touch; `TouchTap`/`TouchTapInWorld` are
not used (A2).

### B4. Defender panel as a bottom sheet on touch

While a defender is selected on a touch profile the hotbar slides away and a **bottom sheet** of the same
height band takes its place: portrait + name + level pips on the left, two stat lines (damage → next,
range → next, plus the stealth line) in the middle, and a button block on the right: **Upgrade · $n**
(56 px, hold to repeat as today), **Target**, **Sell · $n**, and the ultimate button with its cooldown
fill when the unit has one (Auto toggle beside it). A 48 px close at the sheet's top-right. At the last
level of a unit with a signature (`UpgradeView.step == "choose"`) the stat block gives way to the two
**path cards** (each ≥ 48 px tall, name 14, description 13, cost 14) and Upgrade reads "Pick a path" /
"Confirm · $n", exactly the S1-C04 flow; the sabotaged and lantern-out lines stay in the stat block.
Desktop keeps the left side panel; the setting `panelSide` (`auto` / `side` / `bottom`) overrides either,
the TDS "Prefer Vertical Upgrades" idea. Hover-only stat detail does not exist today, so nothing to convert.

### B5. Camera

Walk stays the default on every device (every competitor walks; the lane's arenas are built for it). The
**watchtower** view becomes a real phone mode: one-finger pan (`TouchPan` on the catcher-free HUD, or raw
touches when no GUI processed them) clamped to the arena bounds plus a margin, pinch zoom between 0.6 and
1.4 of the default height, momentum off (Reduced Motion safe), and a "recentre" double-tap on the View
button. The View button also lives in the right rail (B2). The Settings `camera` row stays; a future TUNE
may flip the touch default to overhead once telemetry says phone players prefer it (MH-17 measures it).

### B6. Lobby (touch-phone)

```
┌──────────────────────────────────────────────────────────────────────┐
│ [Roblox ▣ 💬]       [⚙ 1,240 +] [◈ 12]              [≡] [👥 Roblox]    │
│                                                         ┌──────────┐ │
│                                                         │ Errand ▸ │ │  collapsed chip; tap expands
│  (thumbstick zone)                                      └──────────┘ │
│                                                              (jump)  │
│          [ ▶ Play ] [ Units ] [ Summon ] [ Diary ] [ ⋯ More ]         │  bottom bar 64 px, centred
└──────────────────────────────────────────────────────────────────────┘
```

- **Bottom bar** of five 64 px buttons centred between the reserved corners: Play, Units, Summon, Diary
  (pass), **More**. More opens a sheet with Daily, Codes, Hakawati (AFK), Wardrobe, Event (while one runs),
  Language, Music, Settings; badges (daily claim, pass tier) aggregate onto More. Tablets and desktop keep
  the left grid, moved up so its bottom edge sits above the thumbstick zone, cells 64 px, captions 13 px.
- **Top row**: coins (+ store) and lira pills only, centred inside TopbarInset. Language, Wardrobe and
  Music leave the top row on touch (they live in More and in Settings).
- **Errand tracker**: a one-line chip on the right edge on phones (episode · title), tap to expand to the
  full card for 6 s or until tapped again; full card on tablets and desktop as now.
- **Dialogue**: width capped to the band between the reserved corners; choices stay full-width 48 px; the
  errand tracker hides while a dialogue is open (the menu already does).
- **Queue panel** (party countdown): same place (top-centre under the top block), buttons to 48 px.
- Portals, NPC prompts and pads stay as the world's way in; the bar duplicates them (Skibi Defense's
  reasoning: a menu is less overwhelming than hunting portals on a small screen).

### B7. Modals and screens

- `Modal.create` gains a **sheet** mode chosen by the profile: on touch-phone the panel fills the safe
  area minus 8 px margins, the body is `1, -header` tall and scrolls, the close button is 48 px at the
  top-right and a swipe-down on the header also closes. Tablet and desktop keep the centred max-width
  panel with the existing body heights. `Modal.scroller` sets `ScrollBarThickness 10` on touch and
  `ElasticBehavior.Always`.
- **Play**: on touch-phone the three columns become two steps: a horizontal tab strip (Story · Endless ·
  Event, 48 px) over the mode list (cards 64 px, full width); tapping a mode slides to its detail (back
  arrow 48 px, difficulty segmented control 48 px, rewards, enemies, **Create party** 56 px, open parties
  with **Join** 48 px). Tablet/desktop keep three columns with the button sizes fixed.
- **Units**: grid cells ≥ 96×124 as now; detail buttons (Add/Remove, Reroll, Rates, back) to 48 px;
  tap-to-select, long press does nothing (AV's accidental-equip lesson).
- **Summon**: ×1 / ×10 / Rates already ≥ 44 → 48; the reveal's full-screen skip button stays.
- **Lane Diary (pass)**: tier columns stay a horizontal strip; Claim buttons 26 → 48 px, premium and skip
  buttons 48; a "Claim all" is not added (scope).
- **Daily**: the seven cards scroll horizontally when they do not fit; Claim 48.
- **Codes**: when the `TextBox` focuses on touch, the sheet anchors to the top of the safe area so the
  on-screen keyboard (`UserInputService.OnScreenKeyboardVisible/Position`) never covers the box or Redeem.
- **Settings**: rows 48 px; new rows **UI scale**, **Defender panel**, **Quick place**, **Rail side**
  (right/left mirrors the right rail and the Place/Cancel pair for left-handed players); language row added
  here as well. Options as segmented buttons ≥ 48 px.
- **Shop, Wardrobe, Event, Clue card, AFK room panel, Match result**: sizes to the 48 px rule, sheet mode
  on phones, no layout redesign.

### B8. Feedback and measurement

- `HapticEffect` `UIClick` on Place, Upgrade, Sell, Summon, Claim; `UINotification` on gate hit. Off under
  Reduced Motion? No: haptics are not motion; they follow the `sfx` setting.
- Press feedback already squashes; add a 2 px darker "lip" state for touch (no hover exists).
- **Telemetry** (server, through the existing `AnalyticsService.custom`): a `ui_device` event once per
  session with the profile as the value index (0 desktop, 1 touch-phone, 2 touch-tablet) reported by the
  client through a new validated `ClientProfile` remote (`RemoteGuard.wrap`, enum of three strings, one
  call per session accepted); and `place_outcome` counts (placed / cancelled / invalid) which the server
  already knows from `PlaceTower` results plus a `PlaceCancelled` fire-and-forget event (rate-limited).
  These give the before/after misplacement rate per device class.

### B9. Deviations to log in DECISIONS

1. **Landscape only.** `StarterGui.ScreenOrientation = LandscapeSensor` in `default.project.json`; the
   P3-08 line "portrait-proof modals" is dropped: no competitor supports portrait and the arena is wide.
2. **Touch placement commits through a Place button** (quick place opt-in), replacing tap-to-place.
3. **Stray taps keep the selection on touch.**
4. **Leave, Codes, Settings, Music move into a Match menu sheet** on every profile (desktop too, to keep
   one mental model); Skip, Speed, View stay on screen.
5. **Lobby bottom bar on phones**, grid elsewhere; Language and Wardrobe leave the top row on touch.
6. **Scale floor 1.0 on touch**, `uiScale` presets; `SYSTEMS_ARCHITECTURE.md:17` corrected.

---

## Part C: Tasks

Statuses as in `BUILD_PLAN.md` (`[ ]`, `[~]`, `[x] <hash>`, `[!] <reason>`). Each task: **Goal · Create
or change · Accept**. Every Accept assumes the CLAUDE.md verify loop: `tools/check.ps1` green (selene, Lune
specs, luau-lsp strict, rojo build), `script_grep` confirms sync, a Studio playtest with no errors or
warnings from our code, a Device Simulator capture where the Accept says "phone capture", and a commit.
Branch: `main` or `phase/mobile-hud` cut from `main`, as the owner answers the kickoff question (the phase
branches were deleted at v1.0.0, D-072); never push or publish unasked. The game is live: every commit
leaves desktop play exactly as it was unless its task says otherwise, and Studio play-tests run on the TEST
place against the owner's real profile (memory note: restore the loadout and settings you change).
"Phone capture" means the `rbx-device-simulator-lua` skill + `execute_luau` per `docs/TOOLS.md` on two
presets: **iPhone 17 Pro (D-027 proved it; viewport 750×381)** and the **Entry-level phone** preset (or a
custom 640×360 if the preset list lacks one); "tablet capture" means the iPad preset. Reset the simulator
afterwards (D-027). Strings: every new label gets an `en` and an `ar` entry in `Config/Strings` (the Arabic
goes on the P3-10 review list in `docs/review/ARABIC_STRINGS_REVIEW.md`). Icons: reuse `UI/Icons`
primitives or the PV-C01 kit; anything generated gets a COPYRIGHT_REGISTER row.

### Milestone 0: foundations (no visible change yet)

- [x] 9a97e45 **MH-00 Baseline captures** · deps: none
  - **Goal:** Evidence of the current state so every later task has a before/after.
  - **Do:** Phone captures (both presets) and a tablet capture of: lobby idle, dialogue open, Play panel,
    Units, Pass, Codes with the keyboard up (simulator shows it), match in walk mode with a ghost, the
    defender panel open, the match result. Save under `docs/captures/mh/before_*.jpg` and list them in a
    new `docs/TEST_REPORT_SLICE.md` section "MH baseline". Also run a Studio probe (`execute_luau`,
    Client) that walks `PlayerGui.HaretHud` and prints every visible `GuiButton` whose `AbsoluteSize` is
    under 48 px on either axis, and every one whose `AbsolutePosition` rectangle intersects the
    bottom-left 160×160 or bottom-right 140×140 corner. Keep the probe as `tools/studio/hud_audit.luau`
    (a file the agent pastes into `execute_luau`; never a script instance).
  - **Accept:** captures exist; the probe output (count of undersized buttons, list of corner collisions)
    is pasted into the report section. No code change.

- [x] e549d16 **MH-01 `Config/Hud` and `Logic/HudLayout`** · deps: MH-00
  - **Goal:** Every mobile number in one pure config; the profile and scale maths pure and tested.
  - **Create:** `src/shared/Config/Hud.luau` with: `TOUCH_MIN = 48`, `PRIMARY = 56`, `TEXT_MIN = 14`,
    `NUMBER_MIN = 18`; `SCALE = { base = 390, touchMin = 1.0, desktopMin = 0.9, max = 1.5, presets =
    { small = 0.85, default = 1, large = 1.15, huge = 1.3 } }`; `RESERVED = { left = {160,160}, right =
    {140,140} }`; `HOTBAR = { slot = { touch = {72,88}, desktop = {68,84} }, gap = 6, margin = 16 }`;
    `RAIL = { button = 56, gap = 8, maxButtons = 3 }`; `PLACE = { TAP_SLOP_PX = 12, TAP_MAX_S = 0.35,
    LONG_PRESS_S = 0.5, FINGER_OFFSET_PX = 70, PICK_PX = { touch = 44, mouse = 34 } }`; `CAMERA =
    { PAN_STUDS_PER_PX = 0.12, ZOOM = { min = 0.6, max = 1.4 }, BOUNDS_MARGIN = 12 }`; `PHONE_MAX_HEIGHT =
    500`; `LOBBY_BAR = { button = 64, gap = 8 }`; `SHEET_MARGIN = 8`.
    `src/shared/Logic/HudLayout.luau` (pure, `--!strict`, exported types): `profile(input) → "touch-phone"
    | "touch-tablet" | "desktop"` from `{ preferredInput, displaySize, safeSize }`; `scale(profile,
    safeSize, preset, slotCount) → number` (floors, preset, width fit); `reserved(profile, touchControls,
    measured?) → { left: Rect?, right: Rect? }`; `hotbar(profile, scale, safeSize, slotCount) → { slotW,
    slotH, gap, width, x, y }`; `rail(profile, scale, safeSize, side) → { x, y, buttonH }`; `freeBand(
    safeSize, reserved) → { x0, x1 }` (the horizontal band clear of both corners); `fits(rect, reserved)
    → boolean`; `isTap(dx, dy, dt)`; `clampPan(x, z, bounds, margin)`.
    `tests/hud.spec.luau`: profile for (Touch, Small, 750×381) = touch-phone, (Touch, Small, 1024×768)
    = touch-tablet, (KeyboardAndMouse, Medium, 1920×1080) = desktop, (Touch on a touch laptop: Touch,
    Medium, 1366×768) = touch-tablet; scale never < 1.0 on touch and ≥ 0.9 on desktop, presets multiply,
    the 7-slot hotbar always fits the width at the chosen scale for widths 640 … 2560; hotbar, rail and
    the lobby bar rectangles never intersect the reserved corners for the three test sizes; `isTap`
    boundaries; `clampPan` at the four edges.
  - **Accept:** `lune run tests/run` green with the new spec (list the count); selene and luau-lsp clean;
    no Roblox globals in either module (the runner bans them).

- [x] b40dd2e **MH-02 `UI/Device` and the new Root scale** · deps: MH-01
  - **Goal:** The client knows its profile and scale and re-lays out when they change.
  - **Change:** new `src/client/UI/Device.luau`: reads `UserInputService.PreferredInput`,
    `GuiService.ViewportDisplaySize`, `GuiService.TopbarInset`, `Root.get().AbsoluteSize` and the
    `TouchGui` frames; exposes `Device.profile()`, `Device.scale()`, `Device.reserved()`,
    `Device.freeBand()`, `Device.isTouch()`, `Device.Changed` (a `Signal`), debounced one frame.
    `UI/Root.luau`: scale from `HudLayout.scale` using `Device`, the `uiScale` setting and the loadout
    size; keep the single `UIScale`. `Logic/Settings.defs` gains `uiScale` (enum small/default/large/huge,
    default "default"), `panelSide` (auto/side/bottom, auto), `quickPlace` (bool, default false),
    `railSide` (right/left, right). `tests/settings.spec.luau` extended (defaults, sanitize, accept).
    `default.project.json`: `StarterGui.ScreenOrientation = LandscapeSensor`.
  - **Accept:** specs green; in Studio, switching the Device Simulator from desktop to the phone preset
    mid-playtest prints the profile change (one debug line in `DebugOverlayController`, Studio only) and the
    `UIScale.Scale` value moves to ≥ 1.0; DECISIONS row for B9-1 and B9-6; `SYSTEMS_ARCHITECTURE.md:17`
    corrected in the same commit.

- [x] 28a4aaf **MH-03 Theme touch tokens and the button audit helper** · deps: MH-02
  - **Goal:** One place that makes a button touch-legal.
  - **Change:** `Theme.button` enforces a minimum drawn size of `Hud.TOUCH_MIN` unless `props.compact`
    is set (desktop-only decorations), and adds a transparent hit-pad child when the drawn size is smaller
    than the minimum on purpose; `Theme.touchPad(gui, minPx)` helper; `Theme.lip(button)` press state;
    `GuiButton.PressHapticEffect` with a shared `UIClick` `HapticEffect` on every `Theme.button`
    (`HapticEffect` parented once under the ScreenGui). `Theme.TOUCH` now reads `Hud.TOUCH_MIN`.
    `UI/Juice.press` unchanged. `tools/studio/hud_audit.luau` reports zero undersized buttons as the
    pass condition from now on.
  - **Accept:** the audit probe in the lobby (no modal open) and in a match (hotbar + panel open) reports
    **0** undersized visible buttons on the iPhone preset; captures saved as `after_m0_*.jpg`.

### Milestone 1: match chrome

- [x] eda4136 **MH-04 Match menu sheet and the right rail** · deps: MH-03
  - **Goal:** Three buttons in the thumb arc; everything else behind one menu.
  - **Change:** `MatchController.build`: the right column becomes `rail` (Skip, Speed, View; 56 px;
    position from `HudLayout.rail`, side from `railSide`) and a 48 px `≡` button at the top-right inside
    the safe area that opens `MatchMenu`, a small `Modal` (sheet on phones) with Leave (two-step: tap →
    "Leave the match?" with Confirm/Back), Codes, Settings, Music, Language. `MatchCameraController` hands
    its button to the rail (`MatchController.railButton("view")`) instead of placing it at y 272. Desktop
    uses the same rail and sheet (B9-4). The mute's hover tooltip stays desktop-only.
  - **Accept:** phone captures (walk mode) show the rail clear of the jump button and the top-right `≡`
    clear of Roblox's controls; pressing Leave in the sheet needs the confirm; `LeaveMatch` fires once;
    keyboard V still toggles the view; DECISIONS row B9-4.

- [x] 62812f9 **MH-05 Hotbar, cash pill and toast band** · deps: MH-04
  - **Goal:** The hotbar sized by `HudLayout.hotbar`, never under a corner.
  - **Change:** `PlacementController.build`/`slotFor`: slot size from the layout; bar width = slots;
    bar position from the layout (centred in the free band); slot prices still through `myCost`
    (the miser trait) and portraits through `UnitCard.portrait`; cash pill anchored above the first slot;
    `cancelButton` removed from its fixed offset (MH-07 replaces it); `ToastController` top offset below
    the top block and never inside the bottom 160 px. Re-run on `Device.Changed` and on loadout change.
  - **Accept:** phone captures at both presets with a 6-unit loadout (`L` key) show six readable slots
    (cost ≥ 16 px) between the thumbstick and jump zones; the tablet capture shows the desktop size; the
    audit probe reports no corner collision.

### Milestone 2: placement

- [x] e1ce4af **MH-06 Shared validity and the placement state machine** · deps: MH-05
  - **Goal:** One client-side validity source and a tested state machine before any input work.
  - **Change:** `PlacementController.valid` calls `TdTowers.canPlace(state, owner, unitId, def, x, z,
    rules, trait)` (`Logic/TdTowers.luau:46`) with a client-side view of the match instead of its own
    bounds/path/spacing copy: `state = { players = { [me] = { cash } }, phase, paths = arenaPaths (the
    `Path.buildAll` list the client already keeps for two-road arenas), towers }`, `rules` built from
    `TD` the way `MatchService` builds it (`bounds` from `Arenas`, `pathHalfWidth`, `spacing`,
    `towerCap`, `sellRefund`, `starBonus`, `traitCaps = Traits.caps`), and `trait = myTrait(unitId)` so
    the miser price matches; the preview then returns the same reason strings the server does
    (`out_of_bounds`, `on_path`, `too_close`, `tower_cap`, `unit_cap`, `cannot_afford`, `match_over`).
    The `towers` view needs the fields `canPlace` and `countOwned` read (owner, unitId, x, z); add a spec
    that feeds the client-shaped view through `canPlace` on a two-road arena. New pure
    `src/shared/Logic/PlaceFlow.luau`:
    states `idle → aiming(unitId) → committing → idle`, events `pick(unit)`, `move(screen)`, `tap(screen)`,
    `place()`, `cancel()`, `longPress()`, `selectTower(id)`, with `quickPlace` and `touch` flags; returns
    the next state and an action list (`showGhost`, `moveGhost`, `commit(x,z)`, `clear`, `select(id)`,
    `toast(reason)`). `tests/placeflow.spec.luau`: touch without quick place never emits `commit` on
    `tap`; with quick place a valid `tap` commits; mouse commits on `tap`; `pick` of the same unit
    cancels; `selectTower` while aiming clears the ghost; invalid `place()` emits the reason and stays
    aiming; `cannot_afford` on `pick` emits a toast and stays idle.
  - **Accept:** specs green; Studio: placing with the mouse behaves exactly as before (keys 1–9, Q,
    click); `redteam.spec` untouched and green.

- [x] fa95fa3 **MH-07 Touch aiming: catcher, finger offset, Place and Cancel** · deps: MH-06
  - **Goal:** B3 on a phone.
  - **Change:** `PlacementController`: a `PlacementCatcher` frame (full safe area, `Active = true`,
    `BackgroundTransparency = 1`, ZIndex under the HUD) shown only while aiming on touch; raw touch
    `InputBegan/Changed/Ended` on it drive `PlaceFlow.move/tap/longPress` with `Hud.PLACE` thresholds;
    ghost raycast from `(finger.X, finger.Y - FINGER_OFFSET_PX)`; `GuiService.TouchControlsEnabled =
    false` while aiming (restored to the camera mode's value after); **Place** (green, 56 px, text
    `match.place_confirm` "Place · $n") and **Cancel** (red, 56 px) above the hotbar on the rail side,
    `Place.Active = valid`; a reason label (`ERR_KEYS`) under the ghost's screen point; ghost start
    position per B3-1; quick-place honoured from Settings; the `TouchTap` connection removed; mouse path
    unchanged except that it goes through `PlaceFlow`. Haptic on commit.
  - **Accept:** iPhone preset playtest driven by `user_mouse_input` taps on the simulator (touch is
    emulated as mouse there; if the simulator does not deliver `UserInputType.Touch`, STOP and ask the
    owner for the real-device step with the exact checklist): tap slot → ghost at centre → drag moves it
    with the offset → Place commits once (`[HaretAlYasmin]`-prefixed console line from MatchService shows
    one `PlaceTower`) → Cancel clears; dragging while aiming never rotates the camera; an invalid spot
    greys Place and shows the reason; phone captures of aiming (valid, invalid) and of the Place/Cancel
    pair. DECISIONS row B9-2.

- [x] 99efd39 **MH-08 Touch selection rules** · deps: MH-07
  - **Goal:** B3-4.
  - **Change:** `towerAtScreen` radius from `Hud.PLACE.PICK_PX[touch/mouse]`; on touch a tap on empty
    ground keeps the selection (mouse still clears); selection ring and `EnemyRenderController.setSelectedTower`
    unchanged; `PlaceFlow` already covers "select while aiming".
  - **Accept:** on the phone preset: tap a defender opens the panel; tap empty ground keeps it; tap
    another defender switches; the close button clears; mouse click on ground still clears. DECISIONS
    row B9-3.

### Milestone 3: defender panel

- [x] 7074899 **MH-09 Bottom sheet defender panel** · deps: MH-08
  - **Goal:** B4.
  - **Change:** `PlacementController.build` builds both panels (side, bottom) from one `renderTowerPanel`
    data step (title, level or signature name, stats lines incl. sabotaged / lantern-out, the
    `UpgradeView.step` state, button states) and shows the one `HudLayout`/`panelSide` selects; the
    bottom sheet replaces the hotbar band while open (hotbar `Visible=false`, restored on close); in the
    `choose` state the two path cards (≥ 48 px, text ≥ 13 px) replace the stat block and Upgrade confirms
    the picked path with `UpgradeTower(id, path)` as today (`sigPick` resets on another defender);
    buttons 56 px (Upgrade) and 48 px (Target, Sell, Ult, Auto, Close); hold-to-upgrade kept and still
    never buys a signature; `ultFill` kept; RTL alignment through `Theme.align`; the Studio hooks
    `debugSelect/debugPick/debugPress/debugWrongPath` keep working for the harness.
  - **Accept:** phone captures of the sheet for a damage unit with an ultimate, for a support unit
    (income/buff/heal lines) and for a level-7 chooser (both cards, one picked) in English and Arabic;
    upgrade, path confirm, target cycle, sell and ult all fire their remotes once per tap; the wrong-path
    debug call still shows its error toast; desktop still shows the side panel; `panelSide = bottom` on
    desktop shows the sheet; DECISIONS row noting the TDS precedent.

### Milestone 4: camera

- [x] 0018bfd **MH-10 Watchtower pan and pinch** · deps: MH-04
  - **Goal:** B5.
  - **Change:** `MatchCameraController`: in overhead mode, `TouchPan` (ignore when `gameProcessedEvent`)
    moves the look-at point by `totalTranslation` deltas × `Hud.CAMERA.PAN_STUDS_PER_PX` × zoom, clamped
    by `HudLayout.clampPan` to the arena bounds + margin; `TouchPinch.scale` changes the zoom factor in
    `[ZOOM.min, ZOOM.max]`; desktop gets WASD/arrow pan and the scroll wheel zoom with the same clamps;
    double-tap on the View button recentres; `overheadCFrame` takes the pan/zoom; boss push and shake
    unchanged. Pan and pinch are disabled while aiming (the catcher owns touches).
  - **Accept:** on the phone preset a drag in overhead mode pans and stops at the arena edge; pinch (if
    the simulator cannot pinch, zoom via a two-finger emulation is not required: test the clamp with
    the desktop wheel and STOP-list the pinch for the device run); walk mode unchanged; `TouchControlsEnabled`
    restored on match end; phone capture of the panned view.

### Milestone 5: lobby chrome

- [x] **MH-11 Lobby bottom bar, More sheet, top row** · deps: MH-03
  - **Goal:** B6 bar and top row.
  - **Change:** `LobbyMenuController.build` builds the grid (tablet/desktop; raised above the reserved
    zone, 64 px cells, 13 px captions) or the bottom bar (touch-phone; Play, Units, Summon, Diary, More)
    from `HudLayout`; `More` opens a `Modal` sheet listing Daily, Codes, Hakawati, Wardrobe, Event (when
    visible), Language, Music, Settings with their badges; the aggregate badge on More. `HudController`:
    Language, Wardrobe and Music buttons hidden on touch-phone (they are in More); coins + lira pills
    centred in the free top band; `LOBBY_WIDGETS` updated. `register`/`opener` API unchanged so every
    controller keeps working.
  - **Accept:** phone captures: lobby idle at both presets shows the bar between the corners, pills clear
    of Roblox's top controls, no 11 px text; the badge appears on More when a daily claim is ready
    (`HaretDebug` can grant or roll the day); tablet capture shows the raised grid; desktop unchanged
    apart from sizes; DECISIONS row B9-5.

- [ ] **MH-12 Errand chip, dialogue width, queue panel** · deps: MH-11
  - **Goal:** The rest of B6.
  - **Change:** `HudController` errand tracker: chip mode on touch-phone (one line, 48 px tall, tap to
    expand 6 s); `DialogueController` panel width capped to `Device.freeBand()` on touch; the errand
    tracker hides while the dialogue is open; `QueueController` buttons to 48 px and the panel kept under
    the top block; the clue card OK button 48.
  - **Accept:** phone capture of a dialogue with choices shows no overlap with the jump button (closes
    the open issue in `TEST_REPORT_SLICE.md:95`); the chip expands and collapses; the queue panel on the
    phone preset with a party of one.

### Milestone 6: modals and screens

- [ ] **MH-13 `Modal` sheet mode and the common screens** · deps: MH-11
  - **Goal:** B7 for every screen that needs only sizes and the sheet.
  - **Change:** `Modal.create(name, maxWidth, bodyHeight, opts?)`: on touch-phone the panel is a sheet
    (safe area minus `SHEET_MARGIN`, body fills and scrolls, 48 px close, swipe-down on the header
    closes), else as today; `Modal.scroller` touch thickness and elastic; `Modal.closeAll` unchanged.
    Then: Units (buttons 48, no long-press actions; the bead slot row to 48 px and the bead picker's
    close and rows to 48; the Rates switch 48), Summon (48), Pass (Claim 48, premium/skip 48, strip
    scroll), Daily (horizontal scroll, Claim 48), Event (Buy/Play 48), Settings (rows 48, options 48,
    the four new rows + Language, the version label last), Shop, Wardrobe (equip 48), AFK intro and
    room panel (48), Match result (buttons 48; sheet on phones so the 110 px banner, the outro and the
    reward row fit at every `uiScale`), Clue card.
  - **Accept:** the audit probe reports 0 undersized buttons with each of these screens open on the
    phone preset (loop through them with the debug keys 1–6 and the openers); phone captures of Units,
    Pass, Settings and the match result; the Arabic Settings labels still right-aligned.

- [ ] **MH-14 Play panel two-step on phones** · deps: MH-13
  - **Goal:** B7 Play.
  - **Change:** `PlayController.build` renders the list step (tab strip Story · Endless · Event + the
    cards: the nine episode cards with their 18 px mechanic icons and "Coming soon" state, or the mode
    cards) and the detail step (back, name, the Hakawati's intro or description, difficulty segmented
    control, gifts and rewards, enemies, the Episode 9 odds line, Create party 56, parties with Join 48)
    inside the sheet with a slide between them on touch-phone; three columns (sizes fixed) elsewhere,
    keeping the S1-C01 phone fit of the detail; `PartyCreate`/`PartyJoin` unchanged; the PlayGate pad
    still opens it; `Logic/StoryCards` stays the data source.
  - **Accept:** on the phone preset: open Play from the bar, see the nine episode cards, open Episode 9's
    detail (odds line), pick Endless, change difficulty, Create, see the queue panel, Leave the queue;
    phone captures of both steps; desktop capture unchanged in shape.

- [ ] **MH-15 Codes and the on-screen keyboard** · deps: MH-13
  - **Goal:** B7 Codes.
  - **Change:** `CodesController`: on touch, `TextBox.Focused` anchors the sheet to the top of the safe
    area and `FocusLost` restores it; use `UserInputService.OnScreenKeyboardVisible` and
    `OnScreenKeyboardPosition` when available to pad the body so Redeem stays visible; Redeem 48 px;
    the shake-on-failure kept.
  - **Accept:** phone capture with the simulator keyboard shown (the Device Simulator renders a keyboard
    height for the preset) showing the box and Redeem above it; a redeem still works with the mouse.

### Milestone 7: feedback, telemetry, evidence

- [ ] **MH-16 Haptics and press states** · deps: MH-03, MH-07, MH-09
  - **Goal:** B8 feel.
  - **Change:** `UIClick` effects on Place, Upgrade, Sell, Summon, Claim; `UINotification` on gate hit
    (`MatchController.gateHitFlash`); all gated by the `sfx` setting; `Theme.lip` press state applied
    through `Juice.press` on touch.
  - **Accept:** no errors on desktop (HapticEffect is inert there); the setting toggles them; one line
    in DECISIONS.

- [ ] **MH-17 Device and placement telemetry** · deps: MH-07
  - **Goal:** B8 numbers.
  - **Change:** `Net.Events.ClientProfile` (C→S, `RemoteGuard.wrap`: enum of `desktop | touch-phone |
    touch-tablet`, first call per session accepted, later calls dropped and logged), server stores it on
    the player state (not the profile) and logs `AnalyticsService.custom(player, "ui_device", index)`;
    `MatchService.placeTower` results already classify placed/invalid: log `place_outcome_<result>` per
    match as a custom event with the device index as the value; `Net.Events.PlaceCancelled` (C→S,
    rate-limited 2/s) → `place_outcome_cancelled`. Specs: `redteam.spec` gains the two remotes (fuzz:
    wrong enum, floods); `RemoteFuzz` list updated.
  - **Accept:** specs green; Studio console shows the three event names fired in a match; the fuzz
    run reports 0 state changes; the owner is told which Creator Hub charts to read (STOP-list item, no
    click needed now).

- [ ] **MH-18 Verification matrix, docs, owner device run** · deps: MH-04 … MH-17 · STOP
  - **Goal:** The whole Part D matrix green, the docs true, the owner's real phone run.
  - **Do:** run Part D in full; `after_*` captures next to the `before_*` ones in
    `docs/TEST_REPORT_SLICE.md`; `ART_BIBLE.md` §6 and `research/ROBLOX_TD_UI_PATTERNS.md` updated with
    the final numbers; `BUILD_PLAN.md` P3-08 marked `[x]` with the MH hashes; `RELEASE_CHECKLIST.md`
    device row updated (iPhone 17 Pro and entry-level presets, iPad); `playtests/` gets the Discord
    post text asking phone testers to try the new placement and telling every player that touch
    placement now ends with a Place button (quick place in Settings brings the old tap back): the
    change ships to a live game, so the note goes out with the publish (the owner posts and publishes,
    STOP; `RELEASE_CHECKLIST.md` gets its publish-log row).
  - **STOP for the owner:** the real-device run (B3 placement, pinch, the on-screen keyboard, haptics)
    on the Galaxy S23 and an iPhone if available, with the checklist from Part D; the Discord post.
  - **Accept:** owner reports the device run; issues become `MH-19+` tasks; P3-08 ticked.

---

## Part D: Verification matrix and STOP list

### D1. Automated (every task)

`tools/check.ps1`: selene, `lune run tests/run` (328 specs passed at D-038; expect the count to grow by
`hud.spec`, `placeflow.spec`, the settings and redteam additions), `luau-lsp analyze` strict, `rojo build`.
`lune run tests/balance` must be unchanged by this plan (nothing touches play).

### D2. Studio matrix (MH-18, and the relevant rows per task)

| Profile | Simulator preset | Lobby | Dialogue | Play | Units · Pass · Settings · Codes+keyboard | Match walk: hotbar, aim, Place, panel | Match overhead: pan, rail | Result |
|---|---|---|---|---|---|---|---|---|
| touch-phone | iPhone 17 Pro (750×381) | capture | capture | capture | capture ×4 | capture ×3 | capture | capture |
| touch-phone | Entry-level / 640×360 | capture | | capture | Settings | capture ×3 | | |
| touch-tablet | iPad preset | capture | | capture | | capture (grid + side panel) | | |
| desktop | none (Studio window, focused) | capture | | | | capture (keys 1–9, Q, V unchanged) | | |

Pass conditions on every capture: the audit probe reports 0 undersized visible buttons and 0 corner
collisions; no element under the Roblox top controls; Arabic captures of the lobby, the defender sheet and
Settings read right-to-left.

### D3. Behaviour checks (phone preset)

1. Aim without quick place: a single tap on the ground never places; Place commits once; Cancel, slot
   re-tap and long press all clear; the camera never moves while aiming.
2. Quick place on: a valid tap commits once; an invalid tap shows the reason and keeps aiming.
3. Selection: ground tap keeps it; close, another defender, a slot clear it; the sheet's buttons each fire
   their remote once; hold-to-upgrade repeats.
4. Rail: Skip only in prep, Speed only for the host, View toggles; the menu sheet's Leave needs the
   confirm.
5. Lobby bar: every button opens its screen; More badges; the PlayGate pad still opens Play; a dialogue
   hides the bar and the tracker and fits between the corners.
6. Device switch mid-playtest (desktop ⇄ phone preset): the layout re-flows without errors; the UIScale
   value follows the profile floors.
7. `uiScale = huge` at 640×360: the hotbar still fits (the width clamp wins) and every sheet scrolls to
   its last control.
8. Console: `[HaretAlYasmin] server ready`, no errors or warnings from our code in any run.

### D4. STOP list (batch these into one message to the owner, keep working meanwhile)

- The real-device run (MH-18) on the Galaxy S23 (and an iPhone if one is at hand): the D3 list plus pinch
  zoom, the on-screen keyboard in Codes, haptics on Place; screenshots back to the agent.
- If the Device Simulator does not deliver `UserInputType.Touch` to the catcher (MH-07) or cannot pinch
  (MH-10): say so and move those checks to the device run.
- Posting the Discord call for phone testers (text prepared in `docs/playtests/`).
- Any new icon that needs generation (More, View, Place) beyond the PV-C01 kit: Meshy/Studio generation
  spends credits; ask first, use `UI/Icons` primitives meanwhile.
- No Robux, no product ids, no publishing is involved in this plan.

### D5. Out of scope (do not drift)

Gamepad focus navigation; portrait; drag-from-slot placement (`UIDragDetector`, noted for later); UI
Styling / StyleSheets migration; new units, modes or balance; painted portraits (PV-C05); any server rule;
the AFK room's internal screens beyond button sizes; a "Claim all" for the pass; Auto Play (P3-06).
