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

## Not tested / open issues

- **Real DataStores:** everything above ran on the in-memory mock (the place is unpublished). Session-lock contention between two servers needs a published **test** experience (`game.JobId` is empty in Studio).
- **Multi-client:** the two-player test (cosmetic visible to others, no cross-talk) has not been run yet.
- **Phone dialogue:** on the phone, the right edge of the dialogue panel slightly overlaps the jump button, and it covers the errand tracker while open.
- **Analytics:** events log "fired" in Studio; delivery to the Creator Dashboard is unverified.
- **Unrelated assets in the Toolbox:** the account's Toolbox ("My Models") contains models named after *Bab al-Hara* characters (`tower_abu_issam`, `tower_abu_shehab`, `tower_motaz`, …). They are not used by this project and must not be (see COPYRIGHT_REGISTER §1).
