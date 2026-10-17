# Haret Al-Yasmin — Game Design Document

*Status: living document · Last updated 2026-10-16 · Owner: lead engineer*

## 1. Pitch

**Haret Al-Yasmin** (حارة الياسمين, "Jasmine Lane") is a cooperative multiplayer roleplay game set in an
original, fictional walled neighborhood of a Levantine city in the late Ottoman period (roughly the 1900s).
Players arrive as newcomers to the lane, earn the trust of the neighbors by running errands and working
trades, build up a household and a small business, and take part in shared neighborhood events.

Tone: warm, communal, gently humorous. Conflict comes from everyday problems (a late delivery, a broken
fountain, a wedding to prepare), never from graphic violence.

**Originality rule:** every character, storyline, line of dialogue, song and set in the game is written
for this project. We draw on the *general* history, architecture and daily life of Levantine
neighborhoods, which are not protected. We never reproduce characters, plots, catch-phrases, music, logos
or distinctive sets from any TV series (see `COPYRIGHT_REGISTER.md`).

### 1b. The tower-defense update (2026-10-16)

The lane is now the lobby of a cooperative **tower-defense** game: players collect the neighbourhood's
defenders through summons, and parties of up to four defend the lane gate against waves of thieves,
gendarmes and rival-lane thugs across three story episodes and an endless mode. Design, balance and
monetization are in `TOWER_DEFENSE.md` and `MONETIZATION.md`. The roleplay errands remain as the lobby's
first-session hook and the cosmetics economy.

## 2. Audience and platform

- Primary: players aged 9–16 in Arabic-speaking regions and the diaspora; secondary: global roleplay fans.
- **Mobile first.** Design target: a mid-range Android phone (3 GB RAM) at 30 fps, and touch controls
  throughout. Desktop and console are supported but never the design baseline.
- Bilingual: Arabic (right-to-left) and English from day one.

## 3. Core loop

```
Talk to a neighbor ─► Accept an errand/job ─► Travel through the lane ─► Complete it
        ▲                                                                   │
        └──── Spend qirsh on cosmetics / home / business ◄── Earn qirsh + reputation
```

- **Session loop (5–15 min):** take two or three errands, earn qirsh (قرش, the in-game coin), buy one
  thing, chat with other players.
- **Mid-term loop (days):** unlock trades (baker's helper, water carrier, tailor's apprentice), furnish a
  home, raise reputation with each household.
- **Long-term loop (weeks):** own and upgrade a shop, take part in seasonal events (Ramadan evenings,
  weddings, the harvest market), hold neighborhood roles.

## 4. First playable vertical slice (this milestone)

The slice proves the whole stack end to end with the smallest possible amount of content.

| # | Feature | Acceptance criteria |
|---|---------|---------------------|
| 1 | Spawn and initial map | Player spawns at the lane gate in a compact lane with a bakery, a courtyard house, a tailor's stall and a fountain square. Mobile frame time is stable. |
| 2 | NPC interaction and dialogue | Three NPCs with ProximityPrompts. Dialogue is server-driven, data-driven, and shown in the player's language. |
| 3 | One delivery quest | "Warm Ka'ak for Sitt Wardeh": accept from Abu Nadim, receive the basket, deliver it to Sitt Wardeh, receive 50 qirsh. Only once per player. |
| 4 | Currency and inventory | Server-authoritative; the client only displays them. |
| 5 | One cosmetic purchase | Buy the Red Tarboosh (40 qirsh) from Khalil the tailor and equip it; other players can see it. |
| 6 | Persistence | Currency, inventory, quest state, equipped item and language survive leave/rejoin. Session-locked, versioned, retry-safe. |
| 7 | Minimal HUD | Coin pill, quest tracker, language toggle, dialogue panel, shop panel and toasts. Touch-friendly and safe-area aware. |

**Out of scope for the slice:** homes, jobs beyond the single quest, trading, Robux monetization,
events and parties.

## 5. Map zones (overview; detail in `WORLD_MAP.md`)

| Zone | Slice? | Purpose |
|------|:-----:|---------|
| Jasmine Gate / Bawwabet al-Yasmin (lane entrance) | ✅ | Spawn and orientation |
| Jasmine Lane (main alley) | ✅ | Spine of the map, traffic, ambience |
| Abu Nadim's bakery (al-furn) | ✅ | Quest giver |
| Sitt Wardeh's courtyard house | ✅ | Quest target, preview of homes |
| Khalil's tailor stall | ✅ | Cosmetic shop |
| Fountain square | ✅ | Social hub |
| Hammam, mosque courtyard exterior, khan (caravanserai) | — | Later milestones |
| Rooftops | — | Traversal and events |
| Player home plots | — | Home milestone |

> We deliberately avoid the phrase "Bab al-Hara" for any zone, title or branding, even though it is a
> common phrase, to avoid any confusion with the TV series of that name.

## 6. NPC roster

| ID | Name (EN / AR) | Role | Slice? | Personality |
|----|----------------|------|:------:|-------------|
| `abu_nadim` | Abu Nadim / أبو نديم | Baker | ✅ | Booming voice, generous, always short of time |
| `sitt_wardeh` | Sitt Wardeh / الست وردة | Elderly neighbor | ✅ | Sharp-witted, knows every rumor, rewards kindness |
| `khalil_tailor` | Khalil the tailor / خليل الخيّاط | Tailor (shop) | ✅ | Proud of his craft, perfectionist |
| `umm_salma` | Umm Salma / أم سلمى | Water seller | — | Future water-carrier job |
| `hajj_rashid` | Hajj Rashid / الحاج رشيد | Spice merchant | — | Future business mentor |
| `yusuf` | Yusuf / يوسف | Errand boy | — | Tutorial companion, comic relief |
| `mukhtar_said` | Mukhtar Said / المختار سعيد | Neighborhood headman | — | Events and civic roles |

All names are common given names or kunyas. They were picked so as not to match principal characters of
well-known Levantine series, and the copyright register tracks this review.

## 7. Progression

- **Currency:** qirsh (integer). Earned through quests and jobs, spent on cosmetics, furniture and business
  upgrades. Soft cap: 1,000,000 (guards against overflow and exploits).
- **Reputation (post-slice):** per household, 0–100. Unlocks dialogue, discounts and jobs.
- **Trades (post-slice):** tiers per job (Helper → Journeyman → Master) with cosmetic titles.
- **Slice economy:** start with 0 qirsh; the delivery quest pays 50; the tarboosh costs 40. One complete
  loop therefore leaves the player with 10 qirsh and the confidence that the economy is fair.

## 8. Social and cooperative design (post-slice)

- Shared events with neighborhood-wide goals (e.g. "bake 200 ka'ak for the wedding").
- Two-player jobs (one draws water, one carries it).
- Emotes and sit spots in the fountain square, coffee-house tables.
- Safety: default Roblox chat filtering; no free-text fields stored in DataStores; report flow uses the
  Roblox built-in tools.

## 9. Monetization principles (post-slice; nothing is implemented now)

- Cosmetic-only Robux items and an optional Game Pass ("Family Home" plot upgrade). **No pay-to-win**, no
  loot boxes, no paid randomized rewards, no countdown pressure aimed at children.
- Every Robux product is listed in `RELEASE_CHECKLIST.md` and needs explicit approval before creation.
- Receipts go through `MarketplaceService.ProcessReceipt` with an idempotent, persisted receipt log (the
  field is already reserved in `DATA_SCHEMA.md`).

## 10. Analytics

Roblox `AnalyticsService`:
- Onboarding funnel (one per experience; `Logic/FunnelLogic`, `FunnelService`): 1 join → 2 first prompt
  (first dialogue answered) → 3 first summon → 4 portal (first match started) → 5 wave 1 cleared → 6 wave 5
  cleared → 7 first story clear. Each step is stamped once per player lifetime in `profile.funnel`, so the
  funnel reads as "players who ever got this far". The slice's quest funnel (spawned → talked → accepted →
  delivered → purchased) was replaced on 2026-10-17 (DECISIONS D-013). Studio: `HaretDebug:Invoke("funnel")`
  and a `[Funnel] … s after join` line per step; live medians come from the Creator Dashboard.
- Economy events: every lira, qirsh and trait-stone move, emitted from the audit ledger (`DATA_SCHEMA.md` §9)
  with the mutation source as the SKU.
- Custom events: language toggled, shop opened, summons, matches, pass claims, codes, AFK visits.

## 11. Localization

All player-facing strings live in `src/shared/Config/Strings.luau` with `en` and `ar` tables. The initial
language follows the player's Roblox locale (`ar*` → Arabic) and can be changed with the HUD toggle; the
choice is persisted. Arabic layouts mirror alignment (right-aligned text, choices ordered right to left).
After the slice: export to a Roblox LocalizationTable to use the cloud translation tooling.

## 12. Risks

| Risk | Mitigation |
|------|-----------|
| Cultural misrepresentation | Review by native-speaker consultants before release; avoid caricature |
| IP confusion with existing series | Copyright register, no derivative names or sets, legal review before launch |
| Data loss | Session locking, retries, BindToClose, schema versioning, and refusing to play on a failed load |
| Mobile performance | Primitive-based kit, part budget per zone, StreamingEnabled from the map milestone |
