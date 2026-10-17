# S1 · E2 — "Whispers" (همسات) — Build Spec

*Status: planned · 2026-10-15 · Depends on: S1E1 complete · Season arc: `docs/SEASON_1.md` ·
Period detail: `docs/research/DAMASCUS_LANE_LIFE.md` (§1 disputes and ṣulḥa, §5 theft in the lane, §7 phrases, §9 sensitivities)*

## 1. Player fantasy

"The whole lane is whispering and everyone has a theory. I'm the only one listening carefully, and if I
point a finger too soon, someone innocent pays."

## 2. Story beats

1. **Sunset at the coffeehouse.** Mansour the qabaday has gathered the men around the backgammon tables.
   He demands that whoever knows something speak before the evening call to prayer (off-screen, ambient
   only). He asks the player, the newcomer who "found traces", to bring him a name.
2. **Interviews (any order).** Four statements go into the new **casebook**:
   - **Umm Salma** (water seller, at the fountain) heard that Yusuf was seen near the chest at dawn. This rumour is the red herring.
   - **Yusuf** (errand boy, in the lane) admits he was in the storeroom but won't say why. Unlocked: follow him to the
     storeroom to find a stray kitten he's been feeding. That clears him (C4).
   - **Khalil** (tailor) recognises the indigo thread as his own dye and says he sold sashes in that colour
     to three people. He names them only if the player has good reputation with him (bought from him / was polite).
   - **Abu Nadim** (baker) fires the oven before dawn and saw a lantern moving across the rooftops toward the gate (C5).
3. **The accusation (key choice) at the coffeehouse.** Mansour asks: "Well? Who?"
   - **Accuse Yusuf** (possible if the kitten was never found): Yusuf's family is shamed. Umm Salma regrets
     her rumour; reputation with Yusuf's household −30. Mansour is satisfied *for now*. The episode ends with
     an "unease" ending, and in Episode 3 Layla privately tells you it wasn't him (the story self-corrects; no dead end).
   - **Ask for time and present the evidence** (needs C4 and C5): Mansour grudgingly agrees to a **ṣulḥa-style
     truce**: "No names in public until we're sure." Reputation with Mansour +10, Yusuf's family +20.
   - **Accuse Khalil** (possible if the thread is mentioned): Khalil swears an oath of innocence before the elders
     (*wallāh al-ʿaẓīm*); Mansour backs off; reputation with Khalil −20.
4. **Teaser.** Layla slips the player a note: "The copper token. My cousin has one like it." This points to
   Nasim without naming him and leads into Episode 3, outside the gate.

## 3. New content

| Type | Items |
|------|-------|
| NPCs | `mansour` (qabaday: black sherwal, waistcoat, moustache), `umm_salma` (water seller with a brass jug), `yusuf` (errand boy, younger body scale), `layla` (bride; appears for the teaser) |
| Zone | **Coffeehouse (qahwa)** on the east side of the square: benches, backgammon boards, a copper coffee pot, a hakawati chair (used in a later episode). No argileh or smoking (research §9). |
| Props | Storeroom door behind Rashid's shop; a kitten (simple primitive model with an idle bob) |
| Strings | ≈ 70 new keys EN + AR. Dialect phrases drawn from research §7 (e.g. *nāra ya walad!* at the coffeehouse, *wallāh al-ʿaẓīm*) |

## 4. New systems

1. **Generic objectives.** `investigate` quests gain typed objectives:
   `{ id, kind = "clue" | "statement" | "visit", ... }`. Clues keep working, statements are granted by dialogue
   actions (`{ type = "recordStatement", statement = "s_umm_salma" }`), and visits by zone triggers. Same progress map.
2. **Casebook UI.** A tabbed panel (Clues / Statements) opened from the HUD tracker. Each entry shows the text and who
   said it. Read-only; built from config and the progress map.
3. **Reputation.** `profile.reputation[household]` from 0 to 100, default 50, clamped. Changed only by dialogue
   actions declared in config (`{ type = "reputation", household = "yusuf_family", delta = -30 }`). Dialogue conditions
   gain `{ reputation = { household, atLeast } }`. HUD: none (felt through dialogue, not a number). The casebook shows a
   small "trust" hint per NPC.
4. **Choice record.** `profile.season1.e2Accused = "yusuf" | "khalil" | "none"`. Later episodes branch on it.
5. **Dialogue actions with multiple effects.** A choice may carry `actions = { … }` (list), applied atomically in one
   `DataService.mutate`. If any one fails validation, nothing is applied.

## 5. Data schema (v1 → v2)

| Field | Type | Default | Migration |
|-------|------|---------|-----------|
| `reputation` | `{ [household]: number }` | `{}` (missing = 50) | add empty table |
| `season1` | `{ e2Accused: string? }` | `{}` | add empty table |
| quest `progress` keys | statement/visit ids too | — | none (same map) |

`ProfileSchema.MIGRATIONS[1]` adds both tables and bumps `schemaVersion` to 2, with a fixture test of a v1 profile → v2.
Servers on v1 kick v2 profiles ("game updated") as designed.

## 6. Security

- Statements and reputation change **only** through server-side dialogue actions bound to the current node of a
  server-held dialogue session (the existing pattern); there's no remote that takes a statement id or a reputation delta.
- Zone "visit" objectives use server-side position checks (no client-reported visits).
- Each accusation choice is valid once (guarded by `season1.e2Accused == nil`).

## 7. Tests

- Unit: objective kinds, statement recording idempotency, reputation clamping, multi-action atomicity (one failure means
  no change), the v1 → v2 migration fixture, every accusation branch's resulting state, config integrity for statements,
  households and new dialogue action types.
- Studio: all three accusation branches, the kitten reveal, reputation-gated Khalil line, reload mid-episode, Arabic
  pass, phone layout of the casebook.

## 8. Acceptance criteria

- [ ] E2 unlocks only after E1 is complete; Mansour shows "!".
- [ ] Each of the four interviews adds exactly one casebook entry; replaying a conversation adds nothing.
- [ ] All three accusation outcomes are reachable and persist across rejoin.
- [ ] The wrong accusation never blocks Episode 3.
- [ ] No new client→server remote except opening and closing the casebook (read-only).
- [ ] EN + AR complete (config test), the Arabic reviewed, and a COPYRIGHT_REGISTER row added for the episode.

## 9. Work breakdown (estimated order)

1. Objectives refactor + migration v2 + tests.
2. Dialogue multi-action + reputation + conditions + tests.
3. Coffeehouse zone + NPCs (Mansour, Umm Salma, Yusuf, Layla) + the kitten.
4. E2 config: quest, statements, dialogue trees, strings (EN/AR).
5. Casebook UI (phone first).
6. Studio verification and test report.
