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
- **Phone dialogue:** on the phone, the right edge of the dialogue panel slightly overlaps the jump button, and it covers the errand tracker while open.
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
  Hard/Nightmare unlock flow end-to-end; the defeat screen itself (gate never fell against a road-side
  setup within the time box); touch placement on a phone (needs a device run); audio (all ids 0).
- Balance: the road-side setup of six Rare/Epic defenders held Episode 1 Normal waves 1–5 without damage;
  later waves and bosses untested in play.
