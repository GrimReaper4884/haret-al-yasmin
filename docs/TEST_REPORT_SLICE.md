# Vertical Slice — Test Report

*Date: 2026-10-15 · Build: branch `feat/vertical-slice` · Tester: Claude (driving Roblox Studio through
computer use; the Studio MCP server exposed no tools) · Place: unpublished `Place1`, synced via Rojo 7.7.1*

## Static checks

| Check | Result |
|-------|--------|
| `lune run tests/run` | 41 passed, 0 failed (plus one deliberate mutation: a wrong price was caught) |
| `selene src` | 0 errors, 0 warnings |
| `luau-lsp analyze` (strict, Roblox definitions, Rojo sourcemap) | 0 type errors |
| `rojo build` | OK |
| StyLua | **Not run**: the binary is blocked by Windows Application Control |

## Studio play tests (Play Solo, server + client)

| # | Feature | Steps | Result |
|---|---------|-------|--------|
| 1 | Spawn and map | Play | ✅ Spawns at the Jasmine Gate facing the lane; bakery, tailor, fountain square and courtyard house build; `[HaretAlYasmin] server ready`; no script errors |
| 2 | NPCs and dialogue | Prompt on Abu Nadim | ✅ The server opens the "offer" node; localized name tags; "!" marker on the giver |
| 3 | Quest accept | Choose accept | ✅ Basket granted; "New errand" and "Received" toasts; tracker updates; "!" removed |
| 3 | Delivery out of range | Open Sitt Wardeh's dialogue, teleport 40 studs away, choose "give" | ✅ "You're too far away."; no reward; dialogue closed |
| 3 | Delivery | Choose "give" in range | ✅ +50 qirsh, quest `completed`, tracker shows "Delivered" |
| 3 | Replay | Fire `DialogueChoose(1)` 20× from the client after completion | ✅ Balance still 50 |
| 4 | Remote abuse | Client: purchase with no shop open, table arg, wear unowned, NaN choice, language "xx" | ✅ `no_shop`, `bad_request`, `not_owned`; the rest silently ignored |
| 5 | Purchase | Open shop via Khalil, **double-click** Buy | ✅ Charged once (50 → 10); "Purchased" toast; button becomes "Wear" |
| 5 | Wear | Click Wear | ✅ Tarboosh welded to the player's head; toast |
| 6 | Persistence round trip | `HaretDebug:Invoke("reload")` (save + release + load) | ✅ Inventory, quest, language preserved; sessions 1 → 2; store record holds data and lock |
| 6 | Save retry | `failNext(3)` then save | ✅ 3 failures, success after 1 + 2 + 4 s of backoff; store updated |
| 6 | Load failure | `failNext(10)` then reload | ✅ Release save gives up after 5 attempts; load fails 5×; player kicked with the bilingual message; nothing overwritten with blank data |
| 7 | HUD (English and Arabic) | Language toggle | ✅ Arabic shaping and RTL alignment correct; mirrored dialogue header; preference saved (`settings.language = "ar"`) |
| 7 | Phone (iPhone XR emulator, landscape) | Play, open dialogue | ✅ HUD inside the safe area, clear of the thumbstick and jump button; touch prompt; readable dialogue |

## Defects found and fixed during testing

1. The template `SpawnLocation` competed with the gate spawn, so WorldService now removes template spawns.
2. The language button was hidden under the Roblox player list (top-right).
3. The HUD in the top-left collided with the Roblox chat window, so the coins and language toggle moved to the top centre and the errand tracker to the right edge.
4. The "✕" close glyph was missing from BuilderSans and rendered as a box; it is now "X".
5. The shop icon emoji 🎩 rendered as a purple top hat; there is now a primitive-drawn tarboosh icon (`UI/Icons.luau`).
6. The "test mode" toast was easy to miss (it lasted 3 s at join), so it is now a persistent HUD badge while the mock store is active.

## Season 1 · Episode 1 "Wedding Eve" (Studio, Play Solo)

| Check | Result |
|-------|--------|
| Locked before the ka'ak errand | ✅ Hajj Rashid answers "busy"; no "!" marker |
| Unlock and marker | ✅ After the delivery, "!" appears over Hajj Rashid |
| Accept | ✅ Toast, HUD "Season 1 · Episode 1 / Clues 0/3"; clue prompts and outlines appear only now |
| Clues ×3 (hold-to-inspect) | ✅ Each shows a clue card, a "Clue found (n/3)" toast and a journal line; the prompt disappears once found |
| Ready and turn-in | ✅ Objective switches to "Bring what you found…"; "?" marker; reward +60; "Episode 1 complete" |
| Persistence mid-episode | ✅ `reload` keeps `progress.clue_slipper`, quest active, language |
| Arabic | ✅ Clue card, journal and HUD re-render in Arabic |
| **Bug found and fixed** | Accepting an investigation errored (the "item received" toast assumed an item), so the dialogue didn't advance. The quest itself was saved correctly. Fixed in `QuestService.accept` and re-verified |
| **Layout fixed** | A square tree hid Hajj Rashid; moved |

## Shared world, wardrobe and store (Studio)

| Check | Result |
|-------|--------|
| **Multiplayer:** local server + 2 clients | ✅ Both players are in one lane and see each other; they overlap without colliding (collision group); each has their own balance (Player1 160, Player2 0) and quest state |
| **Cosmetic replication** | ✅ Player1 bought and wore the red tarboosh; Player2's client shows it on Player1's head |
| **Wardrobe:** black tarboosh, sidriyye, indigo sherwal, red sash | ✅ Bought (1000 → 740, exact prices), worn together; they fit the R15 body (screenshot checked front and back) |
| **Shop UI** | ✅ Scrolling catalogue of 13 items, drawn icons, qirsh prices, Premium rows |
| **Coin store ("+")** | ✅ Opens; packs and pass show "Coming soon" (no product IDs yet) |
| **Store abuse** | ✅ `RequestProduct('qirsh_pouch')` gets "This isn't available yet."; table / "../x" keys silently ignored; `RequestPass` likewise |
| **Streaming** | ✅ Enabled; NPC labels, prompts and clue spots still work (persistent models) |
| Unit tests | 61 passing (receipt idempotency, race fallback, prompt rules, pass grants, catalogue integrity) |

**Not testable yet:** actual Robux purchase flows. They need real product and pass IDs on a published
experience. Studio simulates purchases once IDs exist.

## Real device: Samsung Galaxy S23 (Android), private test experience

*2026-10-16 · Roblox app signed in as GrimReaper9248 (Early tester, friend of the owner account) · driven
over adb (screenshots, taps, thumbstick swipes)*

| Check | Result |
|-------|--------|
| Join private test place | ✅ After adding the account as an **Early tester** (Playtest access alone gives error 524 outside Studio) |
| Look on phone | ✅ The lane, gate, awnings, laundry, sabat and fountain render with lighting and haze; smooth movement |
| Touch controls | ✅ Thumbstick walking; NPC tap-prompt ("Abu Nadim · Talk") with a large hit area |
| HUD layout | ✅ Coin pill, "+", language and Wardrobe buttons clear of the Roblox menu, thumbstick and jump |
| Dialogue | ✅ Large readable panel, full-width choices; accept gives toasts and tracker update |
| **Real DataStore persistence** | ✅ Errand still active after force-closing the app and rejoining (real DataStores, not the mock) |
| Arabic on device | ✅ Shaped, RTL tracker and HUD |
| **Bug: modals overflowed the phone screen** | Fixed: the wardrobe and shop list heights now fit 390 px; modals are opaque, centred, and draw above the HUD (ZIndex 10). Re-verified on the device |
| **Bug: saved language not applied on join** | Fixed: the first snapshot could arrive before LocaleController subscribed. It now adopts the existing snapshot at start. Re-verified: rejoined directly in Arabic |

## Not tested / open issues

- **Real DataStores:** everything above ran on the in-memory mock (the place is unpublished). Session-lock contention between two servers needs a published **test** experience (`game.JobId` is empty in Studio).
- **Multi-client:** the two-player test (cosmetic visible to others, no cross-talk) has not been run yet.
- ~~**Phone dialogue:** on the phone, the right edge of the dialogue panel slightly overlaps the jump button, and it covers the errand tracker while open.~~ Fixed by MOBILE_HUD_PLAN MH-12 (2026-10-18): on touch the panel fits the band between the thumbstick and jump zones and the tracker hides while it is open (`docs/captures/mh/mh12_iphone17pro_dialogue_between_corners.jpg`).
- **Analytics:** events log "fired" in Studio; delivery to the Creator Dashboard is unverified.
- **Unrelated assets in the Toolbox:** the account's Toolbox ("My Models") contains models named after *Bab al-Hara* characters (`tower_abu_issam`, `tower_abu_shehab`, `tower_motaz`, …). They are not used by this project and must not be (see COPYRIGHT_REGISTER §1).

## Tower-defense update (Studio, Play Solo, 2026-10-16)

*Build: branch `feat/vertical-slice`, synced live with Rojo 7.7.1 into the published TEST place (Studio API
access off → mock store, nothing persists). Driven by computer use. Synthetic mouse clicks never reach the
running game viewport (keyboard does), so the run used the Studio-only harness in
`DebugKeysController` / `DebugOverlayController` (docs/TOWER_DEFENSE.md §10).*

### Static checks

| Check | Result |
|-------|--------|
| `lune run tests/run` | **103 passed, 0 failed** (sim, towers, waves, rewards/unlocks, summons/pity, loadout/traits, pass, codes, dailies, grants, schema v2, products) |
| `selene src` | 0 errors, 0 warnings |
| `luau-lsp analyze` (strict) | 0 type errors |
| `rojo build` | OK |

### Play tests

| # | Feature | Result |
|---|---------|--------|
| 1 | Server boot with the new world | ✅ Lane builds with the rebuilt gate (open leaves, bar leaning by the jamb), nameplates, shop signs, notice board, coffee house, barber, four portals; the watchman Abu Fares, the barber and the coffee-house keeper spawn with prompts; 8 crowd walkers stroll the lane (Explorer: Workspace.Crowd) |
| 2 | Profile v2 | ✅ Migrated profile loads; starter unit and loadout present; 0 lira / 0 qirsh shown; test badge. **Bug fixed during the run:** the DataStore adapter picked the real store although Studio API access is off (403 on write) and the player was kicked; the probe is now a no-op write and the mock is used |
| 3 | Lobby HUD | ✅ Lira pill, coin pill, language, wardrobe, bottom menu (Units · Summon · Diary · Codes · Daily) with the Daily badge |
| 4 | Summon screen | ✅ Active banner name, next-banner timer, two featured 3D previews, lira balance, ×1 (50) / ×10 (500), Rates button; ten-pull deducts 500 and reveals ten cards with rarity colours, NEW / Copy tags; Legendary/Mythic flash path exercised in unit tests only (no Legendary rolled) |
| 5 | Units screen | ✅ Loadout 6/6 strip, grid sorted by rarity with stars; detail view (stats, trait, reroll, add/remove) exercised by code review only (needs mouse) |
| 6 | Diary / Daily / Store | ✅ Open and render (levels strip, XP bar, days left, premium/skip buttons; 7-day cards with today highlighted; store rows incl. lira packs, extras, passes marked Coming soon) |
| 7 | Portal queue | ✅ Teleporting onto the Episode 1 pad joins the party; panel shows mode, players, countdown, difficulty buttons, Leave; the match starts after the countdown |
| 8 | Match start | ✅ Party teleported to the arena pad; night lighting; MatchStart closes lobby screens (fixed during the run); HUD: cash, wave x/20, countdown, gate bar, Skip (0/1), speed, Leave; unit bar with costs; the watchtower camera opens by default with a Walk toggle |
| 9 | Placement rules | ✅ Placing at the spawn pad succeeds; placing by the road succeeds; after cash runs out `cannot_afford`; 6 defenders placed via the road-side debug spots |
| 10 | Waves and combat | ✅ Waves advance (1 → 5 observed), attackers walk the road with health bars, defenders that see stealth kill night thieves (gate stayed 100/100 with a road-side setup), kill cash and wave bonuses increase cash, skip vote starts the wave (+60), "Wave n" banners, boss/gate toasts, "The gate took a hit!" when thieves slipped past a spawn-pad setup (gate 100 → 58 over 6 waves) |
| 11 | End of match | ✅ Leave pays the loss share, shows the result modal and returns the player to the lane gate; the lost/won paths share `finish()` and are covered by `tests/td.spec.luau` |
| 12 | Overlay / errors | ✅ No server or client errors in the mirrored log during any run |

### Defects found and fixed during testing

1. Real DataStore chosen with API access off → kick (adapter probe). Also: in Studio a failed load no longer kicks (`KICK_IN_STUDIO`).
2. Lobby modals stayed open when a match started → `Modal.closeAll()` on MatchStart.
3. The summon reveal overlay stayed above other screens → overlays close when a modal opens.
4. Garden trees spawned on the party pad → gardens keep 12 studs from the spawn.
5. Enemy rigs could be dropped by a position packet overtaking the spawn event → grace period before removal.

### Not tested / open

- Real Robux prompts (no product IDs); PolicyService on a real client; multi-player parties (one client);
  Hard/Nightmare unlock flow end-to-end; touch placement on a phone (needs a device run); audio (all ids 0).
  The defeat screen and boss waves are covered in the next section.
- Balance: superseded by the auto-battler pass below.

## Balance pass: auto-battler harness (2026-10-16)

*Harness: `tests/autobattle.luau` (a scripted player on the real `TdSim`/`TdTowers`/`WaveLogic` at 20 Hz) and
`tests/balance.luau` (report). Tuned numbers and the design targets: `TOWER_DEFENSE.md` §5. Single player, no
selling, greedy placement; loadout codes are defined there.*

### Static checks

| Check | Result |
|-------|--------|
| `lune run tests/run` | **108 passed, 0 failed** (+5: difficulty growth/boss/endless-wall unit test, and four "Balance (auto-battler)" tests asserting the targets below) |
| `lune run tests/balance` | 96 runs (4 modes × 3 difficulties × 8 loadouts) in ≈ 8 s |
| `selene src` | 0 errors, 1 warning (unused `RunService` in `DataService.luau`, not part of this pass) |
| `luau-lsp analyze` (strict) | 0 type errors |

### Outcome matrix

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | myth12up | whale |
|------|-------|------|------|------|------|------|------|------|------|
| ep1 | normal | lost w14 | WIN 100/100 | WIN 100/100 | WIN 100/100 | lost w19 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep1 | hard | lost w10 | lost w19 | lost w14 | WIN 13/60 | lost w11 | WIN 57/60 | WIN 54/60 | WIN 60/60 |
| ep1 | nightmare | lost w9 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 32/35 | WIN 35/35 |
| ep2 | normal | lost w11 | lost w20 | WIN 68/100 | WIN 84/100 | lost w15 | WIN 90/100 | WIN 80/100 | WIN 96/100 |
| ep2 | hard | lost w9 | lost w10 | lost w9 | lost w10 | lost w10 | WIN 40/60 | WIN 33/60 | WIN 50/60 |
| ep2 | nightmare | lost w7 | lost w7 | lost w7 | lost w8 | lost w8 | lost w10 | WIN 3/35 | WIN 22/35 |
| ep3 | normal | lost w11 | lost w15 | lost w17 | lost w20 | lost w14 | WIN 94/100 | WIN 83/100 | WIN 96/100 |
| ep3 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w20 | WIN 26/60 | WIN 56/60 |
| ep3 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w10 | lost w15 | WIN 29/35 |
| infinite | normal | died w12 | died w16 | died w14 | died w16 | died w13 | died w60 | died w79 | died w93 |
| infinite | hard | died w10 | died w10 | died w10 | died w12 | died w10 | died w19 | died w30 | died w82 |
| infinite | nightmare | died w9 | died w10 | died w10 | died w10 | died w10 | died w50 | died w60 | died w60 |

Before the pass (old config, same harness): ep1 Normal wave 1 was all stealth thieves, so the starter Lane Boy
could not hit anything; Hard and Nightmare were lost by waves 5–10 by every loadout (500 start cash against
×1.6 / ×2.6 HP from wave 1); ep2/ep3 Normal were lost by waves 8–12 even by Mythic teams; and a Mythic team
lasted 100+ waves in Endless.

### Wave by wave (one representative run per mode)

Columns: enemies spawned, boss (`!N%` = it reached the gate with N % HP), attackers that reached the gate,
gate HP lost, gate HP after the wave, unspent cash, towers, sum of tower levels, and who leaked. Every run can
be reproduced with `lune run tests/balance <mode> <difficulty> <loadout>`; the Endless table keeps waves 1–3,
every fifth wave, the boss waves and the last wave.

**ep1 · normal · re6 (6 Rare/Epic, no upgrades) → lost w14**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        3  -                       0         0     100    192       3       3  ok
     2        4  -                       0         0     100    398       3       3  ok
     3        5  -                       0         0     100    188       4       4  ok
     4        5  -                       0         0     100    448       4       4  ok
     5        9  -                       0         0     100    258       5       5  ok
     6       11  -                       0         0     100    634       5       5  ok
     7       15  -                       0         0     100    600       6       6  ok
     8       18  -                       2         2      98   1098       6       6  ok     gendarme×1 thug×1
     9       19  -                       3         3      95   1606       6       6  ok     gendarme×1 thug×2
    10       23  sergeant!48%            7        46      49   2134       6       6  ok     gendarme×2 sergeant×1 thief×1 thug×3
    11       23  -                       6         6      43   2696       6       6  ok     gendarme×2 thief×1 thug×3
    12       27  -                      13        14      29   3238       6       6  ok     bandit×1 gendarme×5 thief×3 thug×4
    13       31  -                      20        22       7   3752       6       6  ok     bandit×2 gendarme×7 thief×5 thug×6
    14       32  -                       7         7       0   3900       6       6  LOST   thief×7
```

**ep1 · normal · re6up (6 Rare/Epic + upgrades) → WIN 100/100**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        3  -                       0         0     100    192       3       3  ok
     2        4  -                       0         0     100    398       3       3  ok
     3        5  -                       0         0     100    188       4       4  ok
     4        5  -                       0         0     100    448       4       4  ok
     5        9  -                       0         0     100    258       5       5  ok
     6       11  -                       0         0     100    634       5       5  ok
     7       15  -                       0         0     100    300       6       7  ok
     8       18  -                       0         0     100    334       6       8  ok
     9       19  -                       0         0     100    900       6       8  ok
    10       23  sergeant                0         0     100    934       6       9  ok
    11       23  -                       0         0     100    402       6      10  ok
    12       27  -                       0         0     100   1168       6      10  ok
    13       31  -                       0         0     100   2032       6      10  ok
    14       32  -                       0         0     100    618       6      13  ok
    15       36  -                       0         0     100   1112       6      14  ok
    16       38  -                       0         0     100    462       6      17  ok
    17       42  -                       0         0     100   1250       6      18  ok
    18       45  -                       0         0     100   1576       6      19  ok
    19       47  -                       0         0     100   1494       6      20  ok
    20       51  chief_thief             0         0     100   1150       6      21  ok
```

**ep1 · hard · re10up (10 Rare/Epic + upgrades) → WIN 13/60**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        3  -                       0         0      60    216       3       3  ok
     2        4  -                       1         1      59    432       3       3  ok     gendarme×1
     3        5  -                       0         0      59    262       4       4  ok
     4        5  -                       0         0      59    282       5       5  ok
     5        9  -                       0         0      59    681       5       5  ok
     6       11  -                       0         0      59    621       6       6  ok
     7       15  -                       3         3      56    633       7       7  ok     gendarme×2 thug×1
     8       18  -                       2         2      54    353      10      10  ok     gendarme×1 thug×1
     9       19  -                       0         0      54    449      10      14  ok
    10       23  sergeant!11%            2        41      13    736      10      15  ok     sergeant×1 thug×1
    11       23  -                       0         0      13    570      10      20  ok
    12       27  -                       0         0      13    778      10      21  ok
    13       31  -                       0         0      13    730      10      22  ok
    14       32  -                       0         0      13   1921      10      22  ok
    15       36  -                       0         0      13    956      10      24  ok
    16       38  -                       0         0      13   1552      10      25  ok
    17       42  -                       0         0      13   1892      10      26  ok
    18       45  -                       0         0      13    908      10      29  ok
    19       47  -                       0         0      13   1031      10      32  ok
    20       51  chief_thief             0         0      13   1762      10      35  ok
```

**ep1 · nightmare · myth12up (12 Mythic/Legendary + upgrades) → WIN 32/35**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        3  -                       0         0      35    272       2       2  ok
     2        4  -                       0         0      35    278       3       3  ok
     3        5  -                       0         0      35    618       3       3  ok
     4        5  -                       0         0      35    978       3       3  ok
     5        9  -                       0         0      35    679       4       4  ok
     6       11  -                       1         1      34   1234       4       4  ok     thief×1
     7       15  -                       2         2      32    425       5       5  ok     thief×1 thug×1
     8       18  -                       0         0      32   1334       5       5  ok
     9       19  -                       0         0      32    592       7       7  ok
    10       23  sergeant                0         0      32   1316       8       8  ok
    11       23  -                       0         0      32    814      10      10  ok
    12       27  -                       0         0      32    490      12      13  ok
    13       31  -                       0         0      32    654      12      14  ok
    14       32  -                       0         0      32   2267      12      14  ok
    15       36  -                       0         0      32   1638      12      16  ok
    16       38  -                       0         0      32    542      12      17  ok
    17       42  -                       0         0      32   2054      12      18  ok
    18       45  -                       0         0      32   4302      12      18  ok
    19       47  -                       0         0      32   1221      12      20  ok
    20       51  chief_thief             0         0      32   2994      12      21  ok
```

**ep2 · normal · re10up (10 Rare/Epic + upgrades) → WIN 84/100**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        4  -                       0         0     100    206       3       3  ok
     2        5  -                       0         0     100    426       3       3  ok
     3        8  -                       1         1      99    260       4       4  ok     gendarme×1
     4        9  -                       1         1      98    298       5       5  ok     thug×1
     5       13  -                       4         4      94    636       5       5  ok     gendarme×2 thug×2
     6       16  -                       4         4      90    522       6       6  ok     gendarme×2 thug×2
     7       18  -                       5         5      85    462       7       7  ok     gendarme×2 thug×3
     8       21  -                       0         0      85    334       9       9  ok
     9       22  -                       0         0      85    506      10      11  ok
    10       27  sergeant                0         0      85    956      10      12  ok
    11       29  -                       0         0      85    974      10      13  ok
    12       31  -                       0         0      85    656      10      14  ok
    13       34  -                       1         1      84   1584      10      14  ok     thug×1
    14       37  -                       0         0      84    561      10      24  ok
    15       39  -                       0         0      84   1664      10      24  ok
    16       44  -                       0         0      84   1100      10      25  ok
    17       46  -                       0         0      84   1592      10      26  ok
    18       52  -                       0         0      84   1857      10      27  ok
    19       52  -                       0         0      84    722      10      30  ok
    20       58  chief_thief             0         0      84   1065      10      33  ok
    21       61  -                       0         0      84   1191      10      36  ok
    22       64  -                       0         0      84    981      10      40  ok
    23       68  -                       0         0      84    684      10      42  ok
    24       70  -                       0         0      84    689      10      43  ok
    25       73  -                       0         0      84   1230      10      45  ok
    26       78  -                       0         0      84   1274      10      48  ok
    27       81  -                       0         0      84   1034      10      50  ok
    28       86  -                       0         0      84   1787      10      54  ok
    29       86  -                       0         0      84   4260      10      54  ok
    30       91  rival_zaim              0         0      84   7341      10      54  ok
```

**ep3 · normal · leg10up (10 with Legendaries + upgrades) → WIN 94/100**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        4  -                       1         1      99    372       2       2  ok     gendarme×1
     2        5  -                       0         0      99    312       3       3  ok
     3        6  -                       0         0      99    566       3       3  ok
     4        9  -                       5         5      94    812       3       3  ok     gendarme×3 thug×2
     5       11  -                       0         0      94    400       4       4  ok
     6       12  -                       0         0      94    372       5       5  ok
     7       13  -                       0         0      94    836       5       5  ok
     8       16  -                       0         0      94    546       6       6  ok
     9       18  -                       0         0      94    662       7       7  ok
    10       21  sergeant                0         0      94    752       8       8  ok
    11       23  -                       0         0      94    678       9       9  ok
    12       27  -                       0         0      94    580      10      11  ok
    13       30  -                       0         0      94   1086      10      12  ok
    14       33  -                       0         0      94   1378      10      13  ok
    15       37  -                       0         0      94   1351      10      14  ok
    16       39  -                       0         0      94    738      10      15  ok
    17       42  -                       0         0      94   1442      10      17  ok
    18       46  -                       0         0      94   2987      10      17  ok
    19       48  -                       0         0      94    588      10      20  ok
    20       54  chief_thief             0         0      94   1753      10      21  ok
    21       55  -                       0         0      94    604      10      24  ok
    22       64  -                       0         0      94    764      10      25  ok
    23       67  -                       0         0      94   2925      10      25  ok
    24       71  -                       0         0      94    884      10      27  ok
    25       75  -                       0         0      94   1224      10      29  ok
    26       79  -                       0         0      94   1595      10      31  ok
    27       83  -                       0         0      94   2245      10      32  ok
    28       88  -                       0         0      94   2148      10      33  ok
    29       90  -                       0         0      94   2764      10      34  ok
    30       91  rival_zaim              0         0      94   2474      10      37  ok
    31       90  -                       0         0      94   1953      10      39  ok
    32       90  -                       0         0      94   1037      10      42  ok
    33       90  -                       0         0      94   1813      10      44  ok
    34       90  -                       0         0      94    827      10      50  ok
    35       90  -                       0         0      94   1111      10      57  ok
    36       90  -                       0         0      94   3927      10      57  ok
    37       90  -                       0         0      94   6753      10      57  ok
    38       90  -                       0         0      94   9597      10      57  ok
    39       90  -                       0         0      94  12438      10      57  ok
    40       91  colonel                 0         0      94  16499      10      57  ok
```

**infinite · normal · myth12up (12 Mythic/Legendary + upgrades) → died w79**

```text
  wave  enemies  boss               leaked  gateLost  gateHp   cash  towers  levels  result leaked by
     1        4  -                       0         0     100    226       2       2  ok
     2        5  -                       0         0     100    166       3       3  ok
     3        6  -                       0         0     100    420       3       3  ok
     5       11  -                       4         4      96    210       4       4  ok     gendarme×4
    10       25  sergeant                0         0      89   1504       5       5  ok
    15       43  -                       0         0      89    502      12      13  ok
    20       64  chief_thief             0         0      89   1166      12      18  ok
    25       87  -                       0         0      85   1249      12      33  ok
    30       91  rival_zaim              0         0      85   1501      12      40  ok
    35       90  -                       0         0      85   1342      12      49  ok
    40       91  colonel                 0         0      85   3229      12      57  ok
    45       90  -                       0         0      85   6223      12      68  ok
    50       91  sergeant                0         0      85  21214      12      68  ok
    55       90  -                       0         0      85  36528      12      68  ok
    60       91  chief_thief             0         0      85  52616      12      68  ok
    65       90  -                       0         0      85  68907      12      68  ok
    70       91  rival_zaim              3         6      75  85977      12      68  ok     spy×3
    75       90  -                       6        10      32  102601      12      68  ok     spy×4 thief×2
    79       90  -                       1         1       0  114087      12      68  LOST   thief×1
```

### Studio play (Episode 1 Normal, keyboard harness)

| # | Check | Result |
|---|-------|--------|
| 1 | Tuned config live | ✅ Restarted Play with Rojo connected. Start cash 600 (placing the Blacksmith for 520 left $80); wave 1 is three gendarmes, no stealth opener |
| 2 | Waves 1–9 | ✅ Run 1: four Rare/Epic defenders at the road-side spots (B: Blacksmith, 'Akeed, Baker, Barber; the Mukhtar was refused for cash), +5000 debug cash, **no upgrades**, 2× speed, skip votes (K): gate 100 through wave 7, 94 after wave 8, 89 during wave 9 (thugs slipping through) |
| 3 | Boss render | ✅ The wave-10 Sergeant carries the wide **red** boss health bar (regular attackers: small teal bars). Run 2, measured from the command bar during wave 10: the Sergeant's rig is **8.54 studs** tall against 5.89 for gendarmes/thieves and 6.48 for thugs, i.e. ×1.45, its `visual.scale` |
| 4 | Boss gate damage | ✅ Run 1's un-upgraded team let the Sergeant through: gate 77 → 37 (its new 40 gate damage), the "no upgrades breaks at wave 10" outcome the harness predicts |
| 5 | Defeat | ✅ Run 1: `G` (gate 1 HP) on wave 11 → gate 0/100, back in the lane after the result timer with the loss share (+10 lira, +15 qirsh). Run 1b, to see the modal: `G` then one leaked wave-1 gendarme → **"The gate has fallen…"** with Waves held 0, Rewards +0 lira · +0 qirsh · +0 XP and *Back to the lane* |
| 6 | Errors | ✅ No server or client errors in the mirrored log |

Not covered here: Hard/Nightmare and Episodes 2–3 in Studio (harness only), the win screen in Studio,
multi-player parties (enemy HP does not scale with party size yet), touch placement on a phone.

## Phase 0 verification (2026-10-17, branch `phase/0`)

*Build: `feat/vertical-slice` at f46109a plus the Phase 0 commits · Place: "Haret Al-Yasmin (TEST)" (120389740593436),
Studio API access on · Driven entirely through the Studio MCP server (`start_stop_play`, `execute_luau`,
`user_keyboard_input`, `screen_capture`), no computer use · Plan: `docs/BUILD_PLAN.md` Phase 0.*

### Static checks (`tools/check.ps1`)

| Check | Result |
|-------|--------|
| `selene src` | 0 errors, 0 warnings (the unused `RunService` in `DataService` removed) |
| `lune run tests/run` | **147 passed, 0 failed** |
| `luau-lsp analyze` (strict, Rojo sourcemap, Roblox definitions) | 0 errors (3 at HEAD before P0-03: `BoneAnim.clipsFor` narrowing, `RigAnimController` calling `animateTower`/`animateEnemy` with the wrong arguments) |
| `rojo build` | OK |
| `stylua --check src tests` | 96 files unformatted, advisory only (DECISIONS D-005); generated clips ignored via `.styluaignore` |
| Mutation test (P0-04) | `TD.ODDS.rare` 0.755 → 0.75: `meta.spec` fails twice ("odds sum to 1, got 0.995", pity roll expected mythic got rare); file restored, 147 green again |
| `lune run tests/balance` | 96 runs in 7.7 s; every asserted cell holds. Non-asserted drift vs `TOWER_DEFENSE.md` §5: infinite/normal leg10up died w22 (doc w60), ep1 hard re6up lost w20 (doc w14), re10up WIN 15/60 (doc 13/60). The harness and `TdSim` have no fixed seed, so re-measure before tuning (P1-18) |

### Tool and sync checks

| # | Task | Evidence |
|---|------|----------|
| P0-01 | Tool inventory | `docs/TOOLS.md`; `list_roblox_studios` → the TEST place; Blender Lab server answers `get_blendfile_summary_path_info` / `get_objects_summary` |
| P0-02 | Rojo round-trip | In Edit: `ServerScriptService.Server.Main` (Script), `.Services` (20 modules), `.World`; `ReplicatedStorage.Shared.{Net,Config,Logic,Util,Anim}`, `CharacterModels` (21 models), `PropModels` (6). A nonce comment appended to line 2 of `Main.server.luau` showed up in `script_grep` ("P0-02 nonce 7f3a9c") within seconds; reverted from HEAD, nothing committed |
| P0-02 | Playtest console | `[World] built 1498 parts (budget 6000)`, `[HaretAlYasmin] server ready`, no `PERSISTENCE DISABLED` (real DataStore), no errors or warnings from our code. Remaining noise is Roblox's: UIBlox `FoundationProvider not found` warnings from CorePackages and `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` ×8, an id that appears nowhere in `src/`, `docs/`, `tools/`, the production `.rbxm` files or any instance property (110,827 instances scanned); it comes from the Roblox avatar/core scripts |
| P0-05 | Place layout | Edit-mode `Workspace`: `Terrain`, `Baseplate` (+Texture), `SpawnLocation` (+Decal), `Camera` only; the template `Baseplate` and `SpawnLocation` are the only Studio-owned leftovers (WorldService removes template spawns at runtime; owner's call whether to delete the Baseplate). During Play the server `Workspace` holds `Map`, `Npcs`, `Clues`, `Arenas`, `Crowd`, `HakawatiRoom`; 49 remotes under `ReplicatedStorage.Remotes`; no scripts outside the Rojo folders except Roblox's own (CoreGui, PlayerModule, character `Animate`). Lighting at runtime: ClockTime 15.6, Brightness 2.4 (project file 15.2 / 2.2, adjusted by `World/Atmosphere`) |
| P0-06 | Blender | `execute_blender_code`: Blender 5.2.2 LTS, default cube 12 tris, FBX and glTF exporters present, unit system Metric. `render_thumbnail_to_path` wrote a PNG (to Blender's own temp folder, see TOOLS.md). Headless: `blender -b --factory-startup -P tools/anim/preview.py -- assets/unapproved/characters/qahwaji/clips/axebreathe.glb out.png 8 front` rendered an 8-frame sheet of Abu Hatem (checked visually: fez, striped qumbaz, apron, idle sway) |
| P0-07 | Open Cloud | `GET https://apis.roblox.com/assets/v1/assets/112157925514712` with `x-api-key` from `ROBLOX_OPEN_CLOUD_KEY` → HTTP 200: `displayName "Armature|Idle|baselayer"`, `assetType Animation`, creator `2465538767` (the owner). Key never printed. Upload tool deferred (D-004) |
| P0-08 | Imported asset round trip | `ReplicatedStorage.CharacterModels.AbuHatem`: Model, `Mesh_0` MeshPart primary, 24 Bones, `AnimationController`, 0 scripts (all 21 models: 23–25 bones, 0 scripts; the static `Cat` has none). In a match the placed towers measured: qahwaji / natour / hallaq / farran / saqqa bounding height 5.59–5.60 studs (= `RigBuilder.HEIGHT` 5.6 at scale 1, within 0.2 %), zaim_akbar 6.6 (giant build ×1.18); every tower `Rigged = true`, 2 parts (MeshPart + Root), 0 scripts. Screenshot: Wave 5/20 "Episode 1 · Night of the Thieves · Normal", gate 100/100, Abu Hatem with his tea tray, Abu Bashir, Fawzia with her broom and a night thief on the road |

### Match drive-through (Episode 1 Normal, solo)

Keys sent with `user_keyboard_input` after one viewport click: `9` (teleport to the portal; the Play screen opened),
`X`, `M` (party created and started: `[DebugKeys] party true true nil`), `C` (+5000 cash), `B` ×6
(`[HaretDebug] place qahwaji,18,0 true nil` … `saqqa,44,12 true nil`). Loadout granted beforehand with
`HaretDebug:Invoke("grant", "qahwaji,zaim_akbar,natour,farran,hallaq,saqqa")`. Waves 1 → 5 ran with the gate at
100/100 and cash climbing 600 → 4,114.

**P0-03 animation fix, measured on the client at 54 fps** (per-frame rotation of one bone over 12 frames):

| Figure | Bone | mean °/frame | max °/frame |
|---|---|---|---|
| Enemy_14 (gendarme, walking) | LeftArm | 1.17 | 1.82 |
| Enemy_15 (gendarme, walking) | LeftArm | 1.71 | 2.31 |
| Tower_4 (Abu Hatem, idle) | RightUpLeg | 0.29 | 0.32 |

Before the fix `animateEnemy` received the match speed multiplier as `dt`, so a walk clip advanced by whole
seconds every frame. Figures outside the camera frustum are (correctly) not stepped at all: a first sample taken
with the camera facing away read 0.00° on every frame.

### Owner items from this pass

- `Workspace.Baseplate` and `SpawnLocation` are template leftovers in the saved place; harmless, delete if you like.
- The `rbxassetid://203785492` warning is not from our content; it tracks with the Roblox avatar/core scripts.
- Balance drift in the non-asserted Endless cells (above) needs a seeded harness before it means anything.

## Phase 2 verification run · 2026-10-17 (TEST place, Studio Play Solo, driven through MCP)

*Build: `phase/0` at 447a4b8 + the funnel-reset debug command · Persistence: real DataStore (the owner's TEST
profile; the run added one seeded `summon_x1` and two `match:ep1` ledger entries) · Console: no errors or
warnings from our code (the `rbxassetid://203785492` lines are Roblox core, not in `src/`).*

### P2-16 onboarding funnel

| Run | join | summon | portal | wave 1 | wave 5 | clear |
|---|---|---|---|---|---|---|
| 1 (first session, tool latency included) | 0 s | 44 s | 50 s | 70 s | 141 s | 584 s (Episode 1 won) |
| 2 (clean: `HaretDebug:Invoke("funnel", "reset")`, then keys `7 X M C P B B B B K T` in one batch) | 0 s | 17 s | 23 s | **52 s** | | |

Every reached step printed `[Funnel] <player> reached <step> (step n) <s> s after join` and fired
`LogOnboardingFunnelStepEvent`; `HaretDebug:Invoke("funnel")` returned the seven rows. "prompt" (first
dialogue answered) is not part of the harness and stayed empty. Accept: join → wave 1 in ≤ 60 s ✅ (52 s).
The live median is the owner's to read from the Creator Dashboard after the next publish (STOP).

### P2-17 match effects

Evidence from a 28 s client-side watcher over `Workspace.ClientFx` during waves 17–19, then 24 s around the
wave-20 boss (counts of pooled parts by shape/colour, peak live parts):

| Effect | Seen | Where |
|---|---|---|
| Strike streaks | 36 + 17 | every attack (P1) |
| Hit sparks | 23 + 15 | at the target |
| Petal poofs | 103 + 36 petals | thieves' deaths (no blood) |
| Sweep rings | 2 | an ultimate |
| Gate-hit discs | 1 + 2 | thieves reached the gate (gate 100 → 89); screen-edge blink in `MatchFxController` |
| Boss telegraph rings | 4 (first 7.6 s after the skip) | wave 20 "The 'Akeed's Charge" banner; 3 pulses + the spawn ring |
| Peak pooled parts | 25 / 21 | cap 80, per-frame cap 14, `skipped` stayed 0 in the overlay |

Screenshots taken: the fight at waves 4 and 15 (crowd with sparks), the boss banner at wave 20, the victory
screen ("The lane is safe!", +80 lira · +120 qirsh · +120 XP). The effects never pushed `[Fx] skipped` above 0.

### P1-18 performance gate (server side)

See DECISIONS D-014: `TdSim.step` 0.70 ms avg / 1.23 ms p95 / 2.49 ms max with 271 live attackers and 60
towers (the 4-player cap); `MatchEvents` batch 100 B avg, 3 KB max. Server ✅. Client ❗ needs the owner:
Studio throttled RenderStepped to a flat 66.7 ms (Heartbeat 16.7 ms) because the window was unfocused during
MCP driving, so no honest FPS number exists yet; the phone check needs the Device Emulator.

### P3-09 red-team pass (Studio half)

*Build: `phase/0` at 33e81d3 · Persistence: real DataStore (the owner's TEST profile) · Console at start:
`[HaretAlYasmin] server ready`, nothing from our code.*

| Check | Result |
|---|---|
| Fuzz: 34 events × 1,000 fires + 14 RemoteFunctions × 1,000 invokes, hostile arguments, Client context | profile unchanged byte for byte (2,015 B, ledger 2 → 2); 0 `ok = true`; 0 `[RemoteGuard]` handler errors; 32,801 throttles (985–996 of every 1,000 invokes `rate_limited`); no match, party or AFK session created |
| Console during the fuzz | engine only: queue-exhausted warnings on server→client-only remotes and "Unreliable Event dropped" for the 10,000-char string; nothing from `src/` |
| Session lock: foreign lock + reload | `session lock lost … not saving` and `load failed …: locked`; client kicked in 7.2 s; record intact and the lock cleared afterwards |

Full table and the driver: `docs/review/REDTEAM_P3-09.md`.

## Phase V polish (branch `phase/polish`, TEST place, Studio Play Solo through MCP)

### PV-B08 music and sound toggles (2026-10-17)

*Persistence: real DataStore (the owner's TEST profile); every setting was put back to on afterwards. Console:
`[HaretAlYasmin] server ready`, nothing from `src/` (engine-only CorePackages warnings and the external
`rbxassetid://203785492` line, PV-B00).*

| Check | Result |
|---|---|
| `tools/check.ps1` | selene 0/0, 228 Lune specs passed (new: music/sfx accept true/false, reject `"off"`/`1`/nil, default true, sanitize), strict analyze clean, `rojo build` OK |
| Sync | `script_grep "ui_music"` finds `UI.Icons` and `Controllers.SettingsController` |
| Lobby mute | GUI click on `HaretHud.Music` (MCP `user_mouse_input` by instance path works for GUI buttons): `lobby` loop gone within 0.8 s, tooltip "Music off (tap to play)"; profile `settings.music = false` |
| Persists | `HaretDebug "reload"` → `settings = { music = false, … }`; Stop + Play: no loop is ever created on join (the controller waits for the first snapshot) |
| Muted match | Episode 1 Normal via `M`; waves 1–20 polled every second: **no looped Sound at all**, including the wave-10 Sergeant and wave-20 Al-Idaashari boss waves |
| Unmute mid-match | wave 11 → `match` fades in (0.17 → 0.40 over 1.5 s); re-muted, then unmuted during the wave-20 boss → `boss` at 0.45 (its Config volume) |
| Sound effects off | Settings → Sound effects Off → profile `sfx = false`; a new match to wave 2: SoundService holds only the `match` loop, no sting was ever created (`gate_close`, `wave_start` skipped); set back to On |
| Settings screen | 8 rows now scroll inside a 280 px body (fits 390 px phones); Music and Sound effects sit under Effects; Arabic labels "الموسيقى" / "المؤثرات الصوتية" right-aligned |

Screenshots: `docs/art/pvb08_lobby_music_on_2026-10-17.jpg`, `pvb08_lobby_music_off_…`,
`pvb08_match_boss_muted_…` (wave 10, slashed speaker beside Leave and the gear), `pvb08_match_music_on_…` (hover
hint to the left of the button), `pvb08_settings_en_…`, `pvb08_settings_ar_…`.

### PV-C02 icon registry (2026-10-17)

| Check | Result |
|---|---|
| `tools/check.ps1` | 233 Lune specs (new `tests/icons.spec.luau`: ids whole and ≥ 0, every id-0 name has a primitive drawer, every rail/HUD/item icon, every reward key in SeasonPass/Daily/Codes/Events and every product kind resolves), strict analyze clean, `rojo build` OK |
| Sync | `script_grep "IconIds.images"` finds `UI.Icons` |
| Image branch (Client `execute_luau`, fresh module copies) | `Config/Icons.images.lira = { id = 123456, tint = "#FFD970" }` → one `ImageLabel`, `rbxassetid://123456`, ScaleType Fit, tint ffd970; back to id 0 → the primitive drawer (2 frames, no image); unknown name → TextLabel |
| No visual change | live rail buttons hold 0 ImageLabels; screenshot `docs/art/pvc02_rail_unchanged_2026-10-17.jpg` matches the PV-B08 lobby shots |

### PV-C03 currency and reward icons (2026-10-18)

*Icons drawn by the primitive fallbacks (Config/Icons ids are 0 until the painted PNGs are uploaded).*

| Check | Result |
|---|---|
| `tools/check.ps1` | selene 0/0, 233 specs, strict analyze clean, `rojo build` OK |
| Sync | `script_grep "Amount.reward"` finds Codes, Pass, Daily, Match and `UI.Amount` |
| Lobby pills | gold lira coin + `50940`, copper qirsh coin + `50398` (no unit text) |
| Summon | balance row lira icon + number; buttons "Summon ×1 · [lira] 50" and "Summon ×10 · [lira] 500" |
| Lane Diary | every free/premium cell shows icon + number (lira, qirsh, stone); Arabic: icon right of the number, first entry rightmost |
| Daily | 7 cards, Day 7 wraps three entries (lira, qirsh, xp) inside the card |
| Codes | granted row "[lira] +50 [qirsh] +150 [stone] +1" under the result line (rendered into the live row; no one-time code spent) |
| Store | lira packs use the `lira_stack` icon (Icons.product) |
| Play panel | "20 waves · Rewards: [lira] 80 [qirsh] 120 [xp] 120 (First clear ×2)" |
| Match | cash pill: cash coin + `600`; hotbar card costs: cash coin + 350/1500/180/220/280/300 |
| Result screen | stacked: waves + "Rewards", icon row, "First clear!" (no overlap after the stack fix) |
| Console | nothing from `src/` |

Screenshots: `docs/art/pvc03_{summon,diary,diary_ar,daily,codes,store,play,match_hud,result}_2026-10-18.jpg`;
the painted kit at 256/64/28 px on light and dark: `docs/art/icons_currency_2026-10-18.png`.

### PV-B00 console hygiene (2026-10-18)

| Check | Result |
|---|---|
| Repo | `grep -r 203785492 src default.project.json assets` and every `.rbxm`: no match |
| Edit DataModel | 24 content properties over 101,597 instances: no match |
| Play server | the same over 110,723 instances incl. the player's character; HumanoidDescription items do not use it |
| What it is | economy API: "Pop Close Sound", AssetTypeId 3 (Audio), created 2015 by a third party |
| Join log otherwise | `[World] built 1498 parts`, `[HaretAlYasmin] server ready`, then engine-only CorePackages warnings; nothing from `src/` |

Verdict: external (Studio or a plugin), ignored (D-020).

### PV-B02 hit feedback (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 237 specs (new: `HitFx` plans per Effects level, number pool reuses free then oldest and never grows, 100 hits/s for 10 s stays inside 32 slots, rise/knock curves; `TdSim` attack events carry `damage` = stats × multiplier × (1 − armour)), strict analyze clean, `rojo build` OK |
| Sync | `script_grep "EnemyRenderController.impact"` finds EnemyRender and RigAnim |
| Numbers | Episode 1 Normal, six towers: white numbers rise over hit gendarmes ("9 / 9 / 5"), `docs/art/pvb02_damage_numbers_2026-10-18.jpg` (one frozen copy kept 8 s for the capture; numbers live 0.5 s) |
| Boss flash | wave 10, the Sergeant: Highlight frames seen 5×, at most 3 at once, 2 pooled Highlights created in total; `docs/art/pvb02_boss_flash_2026-10-18.jpg` (frozen copy) |
| Budget | 60 s through waves 10–12: `[Fx] live` peak 14 of 80, skipped 0; damage numbers peak 3 on screen, pool 32 fixed |
| Not reproduced | the Endless wave-30 run with four players' towers (no multi-client tool, one player caps at 15 towers); covered by the 100 hits/s pool spec and the `VfxBudget` hard cap of 80 parts |
| Console | nothing from `src/` |

### PV-B03 deaths, reward coins, gate hits (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 238 specs (new: coin arc ends at both points and lifts its middle above both ends; shake decays to 0; coin/dust caps), strict analyze clean, `rojo build` OK |
| Sync | `script_grep "gateShudder"` finds MatchFxController |
| Gate hit | undefended wave 1: the west leaf turns 3° on its hinge 25 s in (LookVector delta 0.052) and 4 dust puffs rise at the foot of the doors with the red disc and edge flash; before/after the scatter fix: `pvb03_gate_hit_before_scatter_*.jpg` (a neat row) → `pvb03_gate_hit_dust_*.jpg` |
| Reward coins | watchtower view: 2 coins in flight at once from kills toward the cash pill; pool of 6 frames built once; `pvb03_reward_coins_*.jpg` (frozen copies) |
| Boss death | wave 10 Sergeant killed: the static watchtower camera shook for 12 frames, peak 0.82 studs, 0 drift afterwards |
| Console | nothing from `src/` |

### PV-A03 attacker clips, first five (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 240 specs (new `tests/clips.spec.luau`: every attacker with a baked file has walk/hit/death, bosses intro/stagger, rotations = frames × bones × 6 bytes, hips per frame; the six awaiting PV-A02 are listed and must have no file) |
| Previews | `blender -b … preview.py` of the baked slots: `docs/art/pva03_clip_previews_2026-10-18.jpg` (thief run, gendarme quick walk, four deaths, the boss intro) |
| Stride (Studio, Episode 1, 6 towers) | measured speed ÷ clip speed: gendarme median 1.64× (range 0.15–1.74, never clamped, 570 samples); thief median 0.87× (189 samples; 4 below 0.15 while stunned). Before the change: gendarme 2.3–3.6× (clamped), in-place walks unmatched |
| Deaths before the poof | time from a figure stopping on the road to its removal: gendarme 2.95–2.97 s ×6 (77-frame knock-down 2.53 s + 0.4 s fade), thief 1.78 s (fly-up 1.57 s + fade) |
| Boss intro / stagger | code path in place (spawn event with `boss`, flinch uses `stagger` when the figure has it); the in-game check rides on PV-B06 (wave 20) |
| Still open | thug, bandit, rider, sapper, the Sergeant and the Commandant: clips after their import (PV-A02) |

### PV-B04 per-role impacts (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 241 specs (new: every `Units[id].role` has a `Config/Vfx.ROLES` entry with a known kind; hit-stop ≤ 0.1 s; splash fits one frame's budget) |
| Studio | the five impacts drawn side by side on the Episode 1 road via the Studio-only `HaretFxDemo` hook and frozen ~0.08 s in (12 pooled parts): melee white blade sweep + spark, ranged dust puff, splash ground ring + 3 dust puffs, support soft gold pulse, healer rising green-white motes. `docs/art/pvb04_roles_labelled_2026-10-18.jpg` (with labels, before softening the pulse) and `pvb04_roles_2026-10-18.jpg` |
| Not captured | the 0.05 s hit-stop and the 0.3 s ability slow-in are too short for a still; code path `BoneAnim.slow` |

### PV-B05 placement, upgrade, sell (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 242 specs (new: dust + petals and the star burst fit one frame, the sell shower never outgrows the 6-coin pool, punch ≤ 1.25, even dash count, hex colours) |
| Range ring | placement ghost: soft disc with 24 alternating basalt/cream dashes welded to it (follows the ghost); `pvb05_ablaq_range_ring_2026-10-18.jpg` |
| Upgrade | `P` then `U` ×2: the level-3 figure glows gold (pooled Highlight, 0.4 s), gold sparks and the scale punch play; `pvb05_upgrade_glow_2026-10-18.jpg` |
| Sell | `J`: 6 coins (the whole pool) fly into the cash pill; `pvb05_sell_coins_2026-10-18.jpg` |
| Pooling | 40 s of placing, upgrading, hits and selling used 22 distinct pooled effect parts (pool cap 80); coin frames fixed at 6; one upgrade Highlight |

### PV-B06 wave and boss presentation (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 248 specs (new `tests/moments.spec.luau`: plain/boss/final wave starts, camera push gated by cutscenes / effects off / reduced motion, clears carry the bonus but not after the last wave, victory fx need full effects, defeat fx unless off, `cutscenes` setting; Vfx MOMENTS budget) |
| Wave cleared | "Wave 1 cleared! · +130 cash" drops over the wave panel; before/after the move: `pvb06_wave_cleared_before_move_*.jpg` (overlapped the skip toast) → `pvb06_wave_cleared_*.jpg` |
| Boss intro | Episode 1 wave 10: the camera moved 9.8 studs toward the spawn gate (Scriptable during the push, then restored); Olive Harvest wave 8 and 15 banners: "The Sergeant · الشاويش", "Al-Idaashari · الإدعشري" (`pvb06_final_wave_boss_banner_*.jpg`) |
| Final wave | Olive Harvest wave 15: tint `#FFE2C2`, arena lantern 1.10 → 1.32 (+20 %), Atmosphere density 0.30 → 0.40; all restored when the match ends |
| Victory | "The lane is safe!" + result with icon rewards (`pvb06_victory_result_*.jpg`); 24 pooled parts frozen 0.9 s in: red and gold ribbon segments above the gate and falling petals (`pvb06_victory_ribbons_petals_*.jpg`, seen from the lobby after the arena streamed out; ribbons thickened afterwards) |
| Defeat | gate set to 1 HP: `ColorCorrection` saturation −1 for 1.77 s, then back to 0 |
| Console | nothing from `src/` (the "execute_luau changed camera type. Resetting" line is Studio reacting to a probe during the push) |

### PV-A04 enemies at a glance (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 249 specs (ENEMY_READ config; `shield` / `eye` registered with primitive drawers) |
| Phone (Device Simulator, iPhone 17 Pro, viewport 750×381) | wave 10: the boss bar under the wave panel with the Sergeant's portrait, name and red meter (`pva04_phone_boss_bar_2026-10-18.jpg`); the ultimate banner covers it for its 2 s; simulator reset to default afterwards |
| Health bars | every enemy bar has a dark-red ring; stealth thieves show the eye marker left of the bar, gendarmes (no armour) none (`pva04_stealth_marker_*.jpg`, zoom `pva04_bar_ring_zoom_*.png`) |
| Boss disc | one pooled part follows the boss in the existing `BulkMoveTo`; released on death |
| Not yet seen | the shield marker on an armoured attacker in play (thug, bandit, rider and sapper come later in the waves and are still block figures); same code path as the eye |

### PV-B07 lobby and UI motion (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 250 specs (new: `Motion.allowed` for every kind under Reduced Motion, Effects off/reduced/full and with/without a mouse) |
| Daily chest | badge shown (client-only): the rail icon wobbles −7°…+8°; badge hidden: back to 0 within 2.5 s |
| Card tilt | hovering a Units grid card: Rotation −3°, scale 1.04 (`pvb07_card_tilt_2026-10-18.jpg`) |
| ×10 summon | 10 cards flipped face up in reading order (StartCorner TopLeft in English, TopRight in Arabic by code); `pvb07_summon_flip_grid_2026-10-18.jpg` (one ×10 pull spent 500 TEST-profile lira) |
| Toasts | the skip-vote toast slides −12 → +2 → 0 px (Back easing) |
| Not seen live | the Legendary+ petal burst (no Legendary in the pull), the Diary XP shine (needs an XP gain) and Reduced Motion itself (a user setting scripts cannot change); all go through the same gate, specced |

### PV-B01 particle sprites, code half (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 251 specs (TEXTURES: eight kinds, whole ids, life ≤ 2 s, emitter cap ≤ 24) |
| Sprites | 8 × 256² PNG with alpha in `assets/marketing/vfx/`, registered (id 0) in `tools/upload_manifest.json`; preview over black and green `docs/art/vfx_sprites_2026-10-18.png` |
| Emitter path (Studio Client, fresh module copies) | id 0 → `Fx.emitter` nil; id patched → one ParticleEmitter on an Attachment, `rbxassetid://123456`, Rate 0, the same instance on the next call; Effects reduced → nil; `Fx.emit("dust")` with id 0 → false (part fallback) |
| Open | upload the eight sprites (owner), paste ids into `Config/Vfx.TEXTURES` |

### PV-C04 rail, action and role icons, art half (2026-10-18)

| Check | Result |
|---|---|
| Art | 23 painted icons cut to 256² alpha (`assets/marketing/icons/`); all 23 at 30 px on dark and light (`pvc04_icons_at_30px_2026-10-18.png`): every one reads, the sling recut with `--all-white` (its loop kept a white fill) |
| Registry | `Config/Icons` gains ui_shop, act_*, role_*, gem; primitive fallbacks drawn for each (`pvc04_fallback_drawers_2026-10-18.jpg`); `tests/icons.spec.luau` green (251) |
| Open | upload (41 images now pending in `tools/upload_manifest.json`), then the rail / match buttons / role badges show the painted versions with no further code: `Icons.draw` already prefers ids |

### PV-E01 atmosphere and lighting (2026-10-18)

| Check | Result |
|---|---|
| `tools/check.ps1` | 252 specs (new: flicker stays in 0.9–1.1, moves smoothly at 15 Hz, seeds differ; night denser than day; ≤ 40 lights) |
| Lighting children before | place `Atmosphere` d 0.30 + our `LaneHaze` d 0.32, place `Bloom` 1.0/24 + our `SoftBloom` 0.35/22, SunRays 0.04 |
| After | one `LaneHaze` 0.32 (day) / 0.45 (night, #2E3550), one `SoftBloom` 0.35/24, SunRays 0.08, `NightGrade` cool +0.05 contrast at night and neutral by day; Sky stars 3000 |
| Lanterns | 17 lights flickering near the camera in the lobby |
| FPS (Studio window, focused) | lobby 60.0, Episode 1 match 60.0 (same as before) |
| Captures (same cameras) | lobby `[0,10,75]→[0,6,0]`: `pve01_lobby_before_*` → `pve01_lobby_after_*` (warm daylight, softer bloom); arena `[3000,75,50]→[3000,20,-12]`: `pve01_arena_night_before_*` (grey fog) → `pve01_arena_night_after_*` (blue night, lantern pools) |
| Restore | leaving the match: haze 0.32 #DEC8AA, NightGrade neutral, ClockTime 15.6 |

### Natour lantern reveals stealth to nearby defenders (2026-10-18, D-031)

| Check | Result |
|---|---|
| `tools/check.ps1` | 253 specs (new: a tailor inside the lantern's range is revealed and attacks the thief; out of range it stays blind; selling the lantern removes the reveal; the lantern doesn't count itself) |
| Play (Episode 1, 2×, waves 1–6) | lit Khayyat at (-23,0) beside a Natour at (-18,6): 6 hits on thieves; unlit Khayyat at (17,0): 0 hits on thieves (28 on gendarmes); Natour 3 thief hits |
| Panels | lit Khayyat "Sees hidden thieves: lit by Abu Fares the Watchman's lantern" (`reveal_lit_defender_2026-10-18.jpg`); Natour "Lantern: defenders in its range see hidden thieves / Defenders in his light: 1" (`reveal_natour_panel_2026-10-18.jpg`); after selling the Natour the open Khayyat panel turns to red "Can't see hidden thieves" live (`reveal_after_sell_2026-10-18.jpg`) |
| Console | no errors from our code |
| Restore | owner's loadout restored (qahwaji, zaim_akbar, natour, farran, hallaq, saqqa), language en, no lira spent |

### PV-E02 lobby life (2026-10-18, D-032)

| Check | Result |
|---|---|
| `tools/check.ps1` | 261 specs (new `lobbylife.spec`: Effects tiers, 120-stud gate, sway bound and smoothness, flock on its circle and heading, cat turns the short way without overshoot, ripple stagger, oven trigger/cooldown/flare, config budgets) |
| `[World] built` | 1,499 parts (was 1,498; +1 crate under the bakery cat), plan cap 2,200. Client-only parts: 6 vines × 12 = 72, 6 birds, 4 ripples, 2 emitter anchors |
| Play (lobby) | 6/6 vines found their walls; 5 cloths swaying; flock at y 34 moving 4.8 studs/s; spray + steam enabled; the two cats within 24 studs turned to face the player (0° off), farther ones held still; oven light Boost 1.85 → 1.43 over 1.2 s after walking past, cooldown 6 s |
| Effects | full: vines 6, birds 6, spray/steam on; reduced: vines 6, birds 6, spray/steam off; off: vines 0, birds 0, emitters off |
| FPS (Studio, square) | 60.0 with Effects off, 60.0 with full |
| Server | nothing new runs server-side (HaretDebug state unchanged apart from the Effects setting I toggled and restored) |
| Captures (Effects off = before, full = after, same cameras) | square `[16,11,19]→[0,5,0]` (`pve02_square_*`), fountain `[6,8,7]→[0,6,0]` (`pve02_fountain_*`, ripples + spray), lane `[3,7,44]→[0,11,80]` (`pve02_lane_*`, vines); also `pve02_bakery_cat`, `pve02_samovar_steam`, `pve02_birds`, `pve02_laundry` |
| Console | no errors from our code; the shard/steam textures logged "Asset content representation is being generated" once (Roblox processing on first use) |
| Restore | Effects back to full, language en, loadout unchanged, no lira spent |

### PV-E03 arena dressing and the Rival Lane (2026-10-18, D-033)

| Check | Result |
|---|---|
| `tools/check.ps1` | 266 specs (new `arenadressing.spec`: every arena has a complete theme; Episode 2 = `rival_lane` on the orchard's exact road/bounds/spawn; kerb props off the road, off the spawn, inside the field, 8–40 per arena, deterministic; wire lanterns hang over the road with posts clear of it; house fronts outside the field, clear of both gates, facing in) |
| `tests/balance` | identical to the D-031 run, row for row (the dressing touches nothing the sim reads) |
| Parts per arena (cap 1,200) | orchard 393 (kerb props 72, wire lanterns 12, haze 7, gate wall with jasmine 106); Rival Lane 382 (houses 81, kerb props 72, wire lanterns 18); lights 4 / 10 (≤ 40) |
| Haze | Effects full 7/7 emitters on, reduced 0/7, full again 7/7 |
| FPS (Studio, Episode 1 match) | 60.0 at full, 60.0 at reduced |
| Captures | overhead `[3000,75,50]→[3000,20,-12]`: before `pve01_arena_night_after_2026-10-18.jpg`, after `pve03_orchard_overhead_after_2026-10-18.jpg` (jasmine on the home wall, lantern pools on the road) and `pve03_rival_lane_overhead_2026-10-18.jpg` (cool paving, dark road, houses all round); close-ups `pve03_orchard_kerb_wire_*` (crate and copper jug on the kerb, hanging lantern), `pve03_orchard_haze_jasmine_*` (haze wisps over the road), `pve03_rival_lane_street_*` (rival gate at the start, wire lantern, house fronts) |
| Tuning during the run | Rival Lane road #8E8D86 → #625D55 (it barely read against the paving); haze transparency 0.86 → 0.76, size 7 → 8, rate 0.12 → 0.16 per stud (invisible at first) |
| Console | no errors from our code |
| Restore | Effects full, language en, loadout unchanged, no lira spent |

### PV-E04 Meshy props: hanging lantern, market bundle, jasmine pot (2026-10-18, D-035)

| Check | Result |
|---|---|
| Meshes | hanging_lantern 1,354 tris, market_bundle 1,961, jasmine_pot 1,893 (all ≤ 2k); one 1024² base-colour map each after `tools/meshy/shrink_textures.py`; re-imported headless in Blender 5.2 (1 object, 1024×1024 each) |
| Import | Studio 3D importer (File → Import, Studio Default preset, Creator Me), one MeshPart per model; saved to `assets/production/PropModels/*.rbxm`; Rojo synced them into `ReplicatedStorage.PropModels` |
| Lobby swap | 16 hanging lanterns, 4 market bundles, 9 jasmine pots; no tagged primitive left; 16 lights now on the lantern meshes; `[World] built` 1,499 → 1,423 parts |
| Arena swap (orchard) | 8 market bundles (kerb and garden crates), 2 jasmine pots, 4 hanging lanterns (gate wall and two wires); 393 → 333 parts; lights 4 |
| `tools/check.ps1` | green, 267 specs (new: swap config names the three props with prop-sized heights) |
| Captures | `pve04_lane_bundle_lanterns_*` (bundle on the kerb, brass lanterns on their brackets), `pve04_lane_jasmine_pots_*`, `pve04_arena_kerb_bundles_*` |
| Console | no errors from our code |

### PV-D01 logo and PV-D05 loading screen (2026-10-18, D-036)

| Check | Result |
|---|---|
| Logo | 4 generated marks (`logo_mark_variants_2026-10-18.jpg`), owner picked variant 3; set composed with the shaped Arabic + English wordmark (`logo_set_v2_2026-10-18.jpg`); readable at 150 px on light and dark |
| Uploads | mark 94560000612541, wide logo 89973783873794, text wordmark 124741548596324 (Open Cloud, in moderation at upload) |
| `tools/check.ps1` | my specs green (loading.spec: bar progress and easing, finish rule, cached ≤ 2.5 s with the fade, 30 s cap under the 60 s join rule, line cycling, stripe stops within ColorSequence rules, copied colours = Palette, petal id = Vfx, logo ids = manifest). Two failures belong to another session's in-progress PV-A02/A03 attacker work (Icons portraits, Baked clips) |
| Sync | `script_grep RemoveDefaultLoadingScreen` finds `ReplicatedFirst.LoadingScreen` (after restarting `rojo serve` for the new tree) |
| Desktop | fallback mark, petals, ablaq bands and bar, bilingual line (`pvd05_loading_fallback_desktop_2026-10-18.jpg`, held 12 s with `DebugHoldLoading`) |
| Phone (Device Simulator, iPhone 17 Pro, viewport 750×381) | the uploaded mark and wordmark swapped in, full bleed after `ScreenInsets = None` (the first capture showed the world round the safe area) (`pvd05_loading_iphone17pro_2026-10-18.jpg`) |
| Timing (cached Studio join, no hold) | `[Loading] done in 2.32 s` (hand-over; gone after the 0.4 s fade); the wait is the character spawning, the screen's own minimum is 1.2 s |
| Bugs found and fixed in the run | `ColorSequence.new(): table is too long` (40 stripes = 80 keypoints) and `ColorSequence must end at time=1.0` |
| Restore | Device Simulator back to default, `DebugHoldLoading` removed, Studio in Edit |

## PV-A02/A03: the last six attackers (2026-10-18)

| Check | Evidence |
|---|---|
| Models synced | `ReplicatedStorage.CharacterModels` lists 27 models; Thug, Bandit, Rider, Sapper, Sergeant, Commandant each have their skinned `Mesh_0` |
| Tris | thug 5,628 · bandit 5,604 · rider 5,603 · sapper 5,616 (≤ 6k) · sergeant 8,067 · colonel 8,300 (≤ 12k) |
| Live match, Episode 1 Normal | wave 7: 2 thugs imported; wave 10: the Sergeant as the Meshy figure with his new portrait on the boss bar (`docs/art/pva02_sergeant_boss_bar_2026-10-18.jpg`); wave 12: bandit, 5 thugs, 9 gendarmes, 8 thieves, all imported, no primitive enemy |
| Walk clips | all six built by `RigBuilder` and walking on their baked clips (`docs/art/pva02_six_attackers_walk_2026-10-18.jpg`) |
| Console | `[HaretAlYasmin] server ready`; no errors from our code (UIBlox and D-020 noise only) |
| Specs | `tools/check.ps1` green, 276 passed (clips spec now requires all 11 attackers; icons spec checks every portrait matches its model) |

### Sabotaged lantern goes dark (2026-10-18, D-038)

| Check | Result |
|---|---|
| `tools/check.ps1` | green, 328 specs (new: revealerFor returns nil while the Natour's `disabledUntil` runs and the lantern again once it passes) |
| Play (Episode 1, orchard; Natour 4 studs off the road, Khayyat 7 studs from it; 3 then 4 riflemen via `HaretDebug spawn`) | 5.0 s `towerDisabled` Natour → Khayyat `towerReveal` by nil at once; re-sabotaged 7.4 s and 10.0 s; 12.5 s `towerEnabled` → Khayyat lit by the Natour again. Second run the same (48.3 s off, 56.0 s back) |
| Panel (Device Simulator 844×370, the other session's device) | sabotaged Natour: red "Sabotaged: can't attack for now" and "Lantern out: no hidden thieves revealed" (`lantern_sabotaged_panel_2026-10-18.jpg`); after `towerEnabled` back to "Lantern: defenders in its range see hidden thieves / Defenders in his light: 1" |
| Restore | owner's loadout restored (qitt, arada, zaim_akbar, pahlawan, umm_hara, zaim), settings unchanged, Studio in Edit |

## MH baseline: the HUD before the mobile refactor (2026-10-18, MH-00)

*Studio Play on the TEST place, Device Simulator in ActualResolution, landscape. Captures in
`docs/captures/mh/before_*.jpg`; the probe is `tools/studio/hud_audit.luau` (pasted into `execute_luau`,
Client). The Studio-only log overlay was hidden for most captures. Two Episode 1 matches were started with
the harness (`M`) and ended by stopping Play (no result, no reward); the result screens are client-only
`MatchEnd` fires. Simulator reset to FitToWindow and default afterwards.*

| Device (viewport → safe area · UIScale) | Captures |
|---|---|
| iPhone 17 Pro (874×402 → 750×382 → 750×324 · 0.979) | `before_iphone17pro_lobby`, `_dialogue`, `_play`, `_units`, `_pass`, `_codes_keyboard`, `_match_ghost`, `_match_panel`, `_result` |
| Entry phone, custom 640×360 (no "Entry-level" preset in this Studio; 640×340 → 640×282 · 0.842) | `before_entry640_lobby`, `_dialogue`, `_play`, `_units`, `_pass`, `_codes_keyboard`, `_match_ghost`, `_match_panel`, `_result` |
| iPad 10th Generation (1180×820 → 1180×762 · 1.5) | `before_ipad_lobby`, `_play`, `_match_panel`, `_result` |

Probe output (`visible buttons · undersized < 48 px · corner collisions`, corners bottom-left 160×160 and
bottom-right 140×140 of the safe area):

| Run | Result |
|---|---|
| iPhone 17 Pro, lobby idle | 13 · **4** · **9**. Small: `Coins.Store` 37×37, `Language` 94×43, `Music` 47×47, `Wardrobe` 110×43. Corner: all nine `Menu.*` grid cells (play, event, units, summon, pass, daily, codes, afk, settings) in the left zone |
| iPhone 17 Pro, match (panel open) | 18 · **12** · **6**. Small: `CameraToggle` 118×43, `MatchHud…Codes` 110×41, `Music` 47×47, `Settings` 41×41, Leave 63×41, Skip/speed 110×47, five `TowerPanel` buttons (101×39 ×2, 147×43, 31×31 close, 55×43) and Upgrade 208×45. Corner: `CameraToggle` and `Codes` (right), four `TowerPanel` buttons (left) |
| 640×360, lobby idle | 13 · **13** · **9**. Every grid cell is 45×45 (UIScale 0.842 shrinks the 53 px cells), plus Store 32×32, Language 81×37, Music 40×40, Wardrobe 94×37 |
| 640×360, match (panel open) | 18 · **12** · **9**. As the iPhone plus the first and last hotbar slots inside the corners (`UnitBar` slot 1 at x 135–192, slot 6 at x 447–504) and the tower-panel close at 27×27 |

Measured touch controls: iPhone jump button at x 655–725, y 234–304 of 750×324 (95 px from the right
edge, 90 px from the bottom); 640×360 jump at x 545–615, y 192–262 of 640×282. The thumbstick is the
Dynamic Thumbstick: its frame spans the lower-left 40 % of the screen, so the plan's 160×160 fallback is the
honest left zone. `TopbarInset` = (208, 0)–(width, 58): Roblox's controls take the left 208 px of a 58 px bar.

What the captures show, beyond the probe:

- The thumbstick sits on the lobby grid on every device, the tablet included.
- The placement cancel X lands on top of "Watchtower view" (iPhone and 640).
- The tower panel covers the left third of the screen and the thumbstick zone; at 640 it starts under the top bar band.
- The match result's buttons touch the bottom edge on both phones (the 110 px banner plus the outro).
- Codes: with the box focused the simulator reports `OnScreenKeyboardVisible = true`, keyboard 181 px tall
  (iPhone) / 162 px (640) from y 201 / 178: the box and Redeem sit under it. The simulator does not draw the
  keyboard in a capture.
- `PreferredInput` reads `Touch` in the simulator until the first synthetic key press, then
  `KeyboardAndMouse`: harness keys flip the device signal, so touch-profile tests need a Studio-only override.
- Bugs seen in passing (pre-existing, not in MH scope): an open dialogue stays on screen into the match;
  Al-Adashari's ultimate button reads the raw key `ult.adashari`.

## MH after: the Part D matrix on the finished touch HUD (2026-10-18, MH-18)

*Studio Play on the TEST place at b357075 (MH-00 … MH-17), Device Simulator in ActualResolution, landscape,
`Workspace.DebugHudProfile` pinning the profile (the harness keys flip `PreferredInput`). Captures in
`docs/captures/mh/after_*.jpg` beside the `before_*` ones; the probe is `tools/studio/hud_audit.luau`'s check
(visible GuiButtons under 48 px, and buttons inside the bottom-left 160×160 or the measured jump button padded
8 px, counted only while Roblox's touch controls show). The Studio log overlay was hidden. Episode 1 matches
were started with the harness and ended by stopping Play or by leaving at wave 0 (nothing paid; the ledger
tail shows no entry from these runs); result screens are client-only `MatchEnd` fires. The owner's settings
were changed for single checks and put back (uiScale huge → default, language ar → en).*

| Profile · preset (safe area · UIScale) | Screen | Probe (buttons · undersized · corner) | Capture |
|---|---|---|---|
| touch-phone · iPhone 17 Pro (750×324 · 1.000) | Lobby (bottom bar) | 7 · 0 · 0 | `after_iphone17pro_lobby` |
| | Play list / Episode 3 detail | 14 · 0 · 0 / 13 · 0 · 0 | `_play_list`, `_play_detail` |
| | Units | 26 · 0 · 0 | `_units` |
| | Lane Diary | 22 · 0 · 0 | `_pass` |
| | More sheet / Settings | — / 19 · 0 · 0 | `_more`, `_settings` |
| | Codes with the keyboard up (box 74–122, keyboard top 143) | header kept | `_codes_keyboard` (reported keyboard drawn as an overlay) |
| | Match walk view (hotbar, rail) | 9 · 0 · 0 | `_match_walk` |
| | Aiming: Place / Cancel in the corners, controls hidden | 11 · 0 · 0 | `_aim_place_pair` |
| | Watchtower view with the rail column | 9 · 0 · 0 | `_overhead_rail` |
| | Defender sheet (640 px max width) | 9 · 0 · 0 | `_defender_sheet` |
| | Result | 7 · 0 · 0 | `_result` |
| | Arabic: lobby, Settings, defender sheet | read right to left | `_ar_lobby`, `_ar_settings`, `_ar_defender_sheet` |
| touch-phone · 640×360 entry (640×282 · 1.000) | Lobby, Play list and detail, queue, walk view, defender sheet (MH-14 run on the same layout) | 7 · 0 · 0 lobby, 9 · 0 · 0 walk, 7 · 0 · 0 sheet | `mh14_640_*` |
| | Settings | 17 · 0 · 0 | `after_640_settings` |
| | Aiming | 11 · 0 · 0 | `after_640_aim_place_pair` |
| | `uiScale = huge` match (the width clamp keeps 1.000; hotbar x 171–489 of 640, inside both corners) | 10 · 0 · 0 | `after_640_huge_match_hotbar` |
| | `uiScale = huge` Settings scrolled to its last row (v1.0.0) | scrolls | `after_640_huge_settings_scrolled_to_end` |
| | Codes with the keyboard up (header drops, box 18–66, keyboard top 120) | — | `mh15_640_codes_above_keyboard` |
| touch-tablet · iPad 10th gen (1180×762 · 1.500) | Lobby (grid stays) | 13 · 0 · 0 | `after_ipad_lobby` |
| | Play (three columns) | 25 · 0 · 0 | `after_ipad_play` |
| | Defender sheet between the corners / watchtower view with hotbar | 9 · 0 · 0 / 9 · 0 · 0 | `after_ipad_defender_sheet`, `after_ipad_overhead_hotbar` |
| desktop · Studio window (1636×584 · 1.497) | Lobby, Play | 25 · 0 (lobby) | `after_desktop_lobby`, `after_desktop_play` |
| | Match: key 1 aims (hint, cancel X), Q clears, V toggles the watchtower | unchanged | `after_desktop_aim_key1`, `after_desktop_overhead_keyV` |

Before → after on the phones: iPhone lobby 4 undersized · 9 corner → 0 · 0; iPhone match 12 · 6 → 0 · 0;
640 lobby 13 · 9 → 0 · 0; 640 match 12 · 9 → 0 · 0.

D3 behaviour checks (phone preset):

1. Aim without quick place: a tap only moves the ghost; one Place tap committed once (cash 5600 → 4700, one
   defender, slot 1/1); Cancel cleared (MH-07/08 runs covered slot re-tap and long press).
2. Quick place on: covered in the MH-08 run (`mh08_*`); not repeated here.
3. Selection: tapping a defender in the watchtower view opens the sheet; its close clears it; no tap-through
   to the rail button under the close (the camera stayed overhead).
4. Rail: Skip shows only before the wave (the owner's Auto-skip setting votes at once, which is why Skip often
   reads "voted"), View toggles; the rail hides while a tall sheet leaves no room for a 56 px button.
5. Lobby bar: Play, Units, Diary, More open their sheets; the bar hides under the queue panel and returns on
   Leave (`mh14_640_queue_*`).
6. Device switch mid-Play (phone → desktop with the simulator stopped): the layout re-flowed without errors;
   the Codes panel became a centred panel (the fix in D-083 removed a 1 px scroll bar found there).
7. `uiScale = huge` at 640×360: see the table.
8. Console: `[HaretAlYasmin] server ready` in every run; no errors or warnings from our code (Roblox's own
   UIBlox warnings and the old `rbxassetid://203785492` asset-type line are not ours).

Simulator limits found in this run (moved to the owner's device run):

- **Top-row taps.** On the iPhone 17 Pro preset a synthetic tap in the top ~64 px of the safe area reaches
  `UserInputService` but no GuiButton (the sheet close X at y 18–66, probably also the lobby "+" and the match
  menu button). Taps lower down work, the same buttons work on the 640 and iPad presets with path-based taps,
  and the Galaxy S23 run used the top row, so this looks like the simulator's notch handling. The device run
  must confirm the sheet X, "+" and the match menu on a real iPhone.
- The keyboard is reported, never drawn; pinch, haptics and a real keyboard need the device.

## MH follow-ups: MH-19 … MH-22 (2026-10-18)

*Studio Play on the TEST place, Device Simulator in ActualResolution, landscape, `Workspace.DebugHudProfile =
"touch-phone"` (removed afterwards, simulator back to default), the Studio log overlay hidden. Probe:
`tools/studio/hud_audit.luau`; corner collisions count only while Roblox's touch controls show, as in MH-18
(an open sheet hides them; the raw hits listed under sheets are the sheet's own and the lobby's buttons
behind it). The one Episode 1 match was ended by stopping Play at wave 1 (nothing paid, nothing claimed).*

| Task · preset | Check | Probe (buttons · undersized · corner) | Capture |
|---|---|---|---|
| MH-19 · iPhone 17 Pro (750×324) | Qahwaji dialogue open in the lobby, `M` starts Episode 1: dialogue hidden at wave 1/20; lobby with controls up / match | 7 · 0 · 0 / 9 · 0 · 0 | `mh19_iphone17pro_dialogue_open_in_lobby`, `_match_start_dialogue_closed` |
| MH-20 · iPhone 17 Pro / 640×360 entry (640×282) | Lane Diary: free and premium rows on screen, content window = canvas (230 / 188, no sheet scroll), premium buttons end at 244 of 262 (640); desktop shape unchanged | 22 · 0 / 20 · 0 (controls hidden) | `mh20_iphone17pro_pass_both_tracks`, `mh20_640_pass_both_tracks`, `mh20_desktop_pass_unchanged` |
| MH-21 · iPhone 17 Pro / 640 | Summon: content window = canvas (230 / 188), no outer bar; Rates panel with the pity line fits; desktop row layout unchanged | 11 · 0 / 11 · 0 (controls hidden) | `mh21_iphone17pro_summon_no_outer_scroll`, `_rates`, `mh21_640_*`, `mh21_desktop_summon_unchanged` |
| MH-22 · 640 / iPhone 17 Pro | Play detail scrolled to the end: last line (Episode 1 bosses; Episode 9 odds + enemies) ends at 202, Create top 206 (640); 244 / 248 (iPhone) | 13 · 0 / 13 · 0 (controls hidden) | `mh22_640_play_detail_top`, `_scrolled_enemies_above_create`, `mh22_640_play_ep9_*`, `mh22_iphone17pro_*` |
