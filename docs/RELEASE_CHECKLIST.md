# Release Checklist

*Status: living document · Last updated 2026-10-16 (§B2 added)*

Nothing on this list is done automatically. **Publishing, changing live settings, creating Robux
products and spending Robux all need explicit approval from the project owner.**

## A. Every build

- [ ] `selene src` has no errors
- [ ] `luau-lsp analyze` (strict) has no errors
- [ ] `lune run tests/run` passes
- [ ] StyLua formatting check (`stylua --check src tests`)
- [ ] Studio Play smoke test (1 player): spawn → quest → buy → equip → rejoin
- [ ] Studio multi-client test (2 players): cosmetic visible to the other player, no cross-talk in dialogue
- [ ] Device emulator: iPhone SE, a mid-range Android phone, iPad. HUD inside safe area, buttons ≥ 48 px
- [ ] Output log has no errors or warnings except the expected `PERSISTENCE DISABLED` in mock mode
- [ ] Docs updated (this folder)

## B. Before the first test publish (to a private test experience)

- [ ] Owner approves the publish target (a **separate test experience**, never the production one)
- [ ] Enable Studio API access on the test experience only
- [ ] Persistence tests: rejoin, two-server lock (Team Test), forced-failure retry (debug flag)
- [ ] Privacy settings: experience private / friends only

## B2. First monetized test publish (owner, one sitting, ~90 min)

*Written 2026-10-16 by Claude for the owner. Everything in B2.1–B2.5 happens in **your** Roblox account
and only you can do it; B2.6 is a paste into code that Claude can do for you if you send the IDs. The
experience stays **private** throughout. Studio test purchases never charge Robux; nothing here spends
Robux.*

### B2.0 Read first: two things that change what you create

1. **Trait stones are a paid random item, and now disclosed: create them.** `stones_3` / `stones_10` are
   sold for Robux and spent on a random trait reroll (weights in `Config/Traits.luau`: Steady 30 %, Swift
   22 %, Keen-eyed 18 %, Sharp 14 %, Golden hands 8 %, Hawk 5 %, Za'im's blood 2.5 %, Legend 0.5 %). The
   defender detail view (Units) now has a **Rates** button that lists every trait's exact reroll chance for
   that defender before you reroll (a reroll that lands on the current trait is rolled once more, so the
   shown rates depend on the current trait and already include that), and stones are hidden and refused
   where paid random items are restricted. That satisfies the Paid Random Items rules
   (`docs/research/ROBLOX_IP_AND_POLICY.md` §3), so **create both stones products** in B2.2 (rows 9–10).
   Questionnaire (B2.4): trait rerolls are a second paid random item. *(Code: commit `bde33e0`, branch
   `claude/affectionate-curie-b42f0c`; it must be merged before you publish.)*
2. **Products belong to one experience.** Everything you create now lives on *Haret Al-Yasmin (TEST)*
   (game 10771112137). The production experience will need its own products and its own ids later.

Also fixed in the same commit: the starter pack, the premium Diary and Diary skips (all pay lira or stones)
are now hidden and refused in restricted regions like the lira packs; an already-owned cosmetic's qirsh
fallback now toasts "+N qirsh"; and a game pass bought in-session (including a Studio test purchase) applies
at once instead of waiting for Roblox's ownership cache.

### B2.1 Before you start

- [ ] Sign in at <https://create.roblox.com/dashboard/creations> with the account that owns game 10771112137.
- [ ] Have this file and `src/shared/Config/Products.luau` open. Keep a scratch note for the ids.
- [ ] Icons: Roblox shows a default image if you skip the icon. Fine for a private test; original
      512 × 512 icons (no TV-series imagery) are needed before public release.
- [ ] If the dashboard offers **regional pricing / price optimization** on products or passes, leave it
      **off** for now so the prices below are what testers see.

### B2.2 Create the developer products (15)

Creator Dashboard → **Haret Al-Yasmin (TEST)** → **Monetization** → **Developer Products** →
**Create a Developer Product**. For each row: name, description, (icon), price → **Save** (or
**Create**). Then open the product, copy its **Product ID** and paste it into the line shown.

| # | Key (`devProducts.*`) | Name to type | Description to type | Price R$ | Paste id into `Products.luau` |
|---|-----------------------|--------------|---------------------|----------|-------------------------------|
| 1 | `qirsh_pouch` | Pouch of 100 qirsh | 100 qirsh for cosmetics. | 25 | line 36 `productId = 0` |
| 2 | `qirsh_purse` | Purse of 450 qirsh | 450 qirsh for cosmetics. | 99 | line 37 |
| 3 | `qirsh_chest` | Chest of 1,000 qirsh | 1,000 qirsh for cosmetics. | 199 | line 38 |
| 4 | `lira_100` | 100 lira | 100 lira for summons. Odds are shown on the Rates screen. | 49 | line 40 |
| 5 | `lira_300` | 320 lira | 320 lira for summons. Odds are shown on the Rates screen. | 129 | line 41 |
| 6 | `lira_650` | 700 lira | 700 lira for summons. Odds are shown on the Rates screen. | 249 | line 42 |
| 7 | `lira_1500` | 1,650 lira | 1,650 lira for summons. Odds are shown on the Rates screen. | 499 | line 43 |
| 8 | `lira_4000` | 4,500 lira | 4,500 lira for summons. Odds are shown on the Rates screen. | 1199 | line 44 |
| 9 | `stones_3` | 3 trait stones | 3 trait stones for trait rerolls. Odds are shown on the Rates panel. | 99 | line 46 |
| 10 | `stones_10` | 10 trait stones | 10 trait stones for trait rerolls. Odds are shown on the Rates panel. | 279 | line 47 |
| 11 | `pass_premium_s1` | Lane Diary: Premium (Season 1) | Unlocks the premium track of this season's Lane Diary. | 799 | line 49 |
| 12 | `pass_skip_10` | Skip 10 Diary levels | Adds 10 levels to your Lane Diary. | 999 | line 50 |
| 13 | `starter_pack` | Newcomer's bundle | 300 lira, the 'Akeed and a red tarboosh. Once per player. | 199 | line 53 |
| 14 | `item_tarboosh_gold` | Gold-banded tarboosh | A wedding-night tarboosh for your avatar in the lane. | 79 | line 64 |
| 15 | `item_qumbaz_wedding` | Wedding qumbaz | Cream silk qumbaz with gold embroidery. | 129 | line 72 |

The keys `lira_300 / lira_650 / lira_1500 / lira_4000` are historical names; the amounts in the Name
column are what the game grants.

### B2.3 Create the game passes (4)

Monetization → **Passes** → **Create a Pass** → image (optional for now), name, description → **Create
Pass**. Then open the pass → **Sales** (or **Monetization**) → switch **Item for Sale** on → price →
**Save**. Copy the pass id (in the URL, or **⋯ → Copy Asset ID**).

| # | Key (`gamePasses.*`) | Name | Description | Price R$ | Paste id into `Products.luau` |
|---|----------------------|------|-------------|----------|-------------------------------|
| 16 | `vip` | VIP | 20 % off summons, +25 % lira from matches, an embroidered shawl and a golden name. | 299 | line 83 `gamePassId = 0` |
| 17 | `fast_mode` | Fast Mode | 3x match speed when you host (2x is free for everyone). | 799 | line 91 |
| 18 | `extra_slot` | Extra slot | A seventh defender in your loadout. | 149 | line 99 |
| 19 | `lane_patron` | Lane Patron | Support the lane: the gold-banded tarboosh and the embroidered shawl. | 249 | line 107 |

A pass that is **not for sale** cannot be bought even in Studio, so check the toggle.

### B2.4 Maturity & compliance questionnaire

Creator Dashboard → the TEST experience → **Audience** → **Maturity & Compliance** → **Take
questionnaire** (or **Edit**). Answer from the facts below; if a question is worded differently, answer
the fact, not the expected label. Save a screenshot of the result page into your own records.

| Topic | Answer | Fact it rests on |
|-------|--------|------------------|
| Violence | **Yes, mild**: repeated, non-realistic | Stylised daggers (shabriyeh), swords and shields ('arada), sling, razor, hammer; enemies poof/collapse, no wounds |
| Blood | **No** | None anywhere |
| Fear / horror | **No** (at most "mild") | Night setting, no jump scares |
| Crude humour | **No** | — |
| Romance | **No** | A wedding is mentioned; nothing romantic is shown |
| Strong language | **No** | All text is ours; no swearing |
| Alcohol | **No** | — |
| **Tobacco / vaping** | **No** | No argileh, cigarettes or pipes (deliberately removed) |
| Drugs | **No** | — |
| Gambling | **No** | No wagering of Robux or items; backgammon/cards absent or stake-free |
| **Paid random items** | **Yes** | Summons cost lira; lira is sold for Robux (`lira_*`, `starter_pack`, premium Diary). Odds and pity are on the Rates screen. Trait rerolls are a second PRI: trait stones are sold for Robux (`stones_*`, premium Diary); every trait's chance is on the Units → Rates panel. |
| Free-form user creation | **No** | No player-made text or builds shown to others (Roblox chat aside) |
| Social hangout / voice | Answer as configured | Text chat on by default; voice not enabled by us |
| Sensitive issues | **No** | Historical setting; not themed on a current political/religious issue |
| Real-world locations / religion | Answer truthfully if asked | A 1930s Damascus lane; adhan/prayer only mentioned in dialogue ("after the evening prayer") |

Expected outcome: **Mild**, with the *Paid random items* descriptor. If the result is Moderate, stop and
send Claude the questions that pushed it there.

- [x] Questionnaire submitted; label shown: **Mild**, descriptor *Violence (Repeated/Mild)*, no non-compliant regions, no age restriction; date: **2026-10-16** (filled by Claude in the owner's browser, answers approved by the owner in chat). Answers: violence Yes/Mild/Repeated; blood, fear, crude humour, unplayable gambling (decorative backgammon boards only), strong language, romance, alcohol, social hangout, free-form creation, sensitive issues, cross-experience content, AI interaction No; paid random items **Yes**, respects `ArePaidRandomItemsRestricted` Yes; paid item trading No (no trading exists; re-file when it ships); media sharing, continuous feed/autoplay No.

### B2.5 Experience settings to check while you're there

- [ ] Experience is still **Private** (Settings → Access / Privacy). Only you (and invited testers) can play.
- [x] **Enable Studio Access to API Services: ON** (2026-10-17, set by Claude in Studio; DataStore read probe passes) for this TEST experience only (in Studio with the TEST
      place open: **Home → Game Settings → Security**). Needed so a Studio "rejoin" really reloads from
      the DataStore; otherwise the game runs on the mock store and forgets everything on Stop. Record it
      in §E.
- [ ] Third-party sales / teleports: leave off.

### B2.6 Paste the ids

- [ ] Paste each id into `src/shared/Config/Products.luau` at the lines above (or send the 15 ids to Claude
      to paste). Do not change `robux = …`; that field is display-only and the real price always comes
      from Roblox.
- [ ] `lune run tests/run` still passes. Commit with a message like "Products: TEST experience ids".
- [ ] Open the TEST place in Studio (**File → Open from Roblox**, or `rojo serve` + Connect on that place).
      Test purchases only reach `ProcessReceipt` in the experience that owns the products.

### B2.7 Studio verification script (≈ 40 min)

Run with **Play** (F5), one player. Switch the command bar to **Server** (Test tab → *Current: Server*)
for the snippets. Debug keys and the on-screen log overlay are Studio-only (`DebugKeysController`).
Every Studio purchase dialog says it is a **test purchase**: no Robux are charged.

**Snapshot snippet** (paste in the server command bar; run it before and after every step):

```lua
local H = game:GetService("HttpService"); local p = H:JSONDecode(game.ServerStorage.HaretDebug:Invoke("state")); local n = 0; for _ in p.receipts do n += 1 end; print(("qirsh=%d lira=%d stones=%d premium=%s xp=%d receipts=%d bundles=%s units.qabaday=%s inv=%s"):format(p.qirsh, p.lira, p.traitStones, tostring(p.pass.premium), p.pass.xp, n, H:JSONEncode(p.bundles), tostring(p.units.qabaday ~= nil), H:JSONEncode(p.inventory)))
```

**Rejoin** = Stop (Shift+F5), wait 5 s, Play (F5) again. Quick in-session check without stopping:
`print(game.ServerStorage.HaretDebug:Invoke("reload"))` (save, release, load from the store).

**Direct prompt** (server command bar; bypasses the game's "already owned" guard, used for fallback tests):

```lua
game:GetService("MarketplaceService"):PromptProductPurchase(game.Players:GetPlayers()[1], PRODUCT_ID)
```

| # | Do | Expect | Then rejoin and expect | ✓ |
|---|----|--------|------------------------|---|
| 0 | Play. Output shows no `PERSISTENCE DISABLED` (API access on). Take a snapshot. | Baseline numbers noted | — | |
| 1 | Key **6** (Store) → buy *Pouch of 100 qirsh* → confirm test purchase | Toast "+100 qirsh added"; qirsh +100; receipts +1 | qirsh still +100 (not +200); receipts unchanged | |
| 2 | Same for *Purse* and *Chest* | +450, +1,000 | unchanged after rejoin | |
| 3 | Store → **Lira** tab → buy each of the 5 lira packs | +100 / +320 / +700 / +1,650 / +4,500 lira, one toast each | totals unchanged after rejoin | |
| 3b | Store → Extras → buy *3 trait stones*, then *10 trait stones*; key **1** → open a defender → **Rates** → close → **Reroll** | +3 / +10 stones, one toast each; Rates lists all 8 traits (current one marked, e.g. from Steady: Steady 9.00 %, Swift 28.60 %, … Legend 0.650 %) with the rounding note; reroll spends 1 stone and the Rates panel updates to the new trait | stones and the new trait kept after rejoin | |
| 4 | Key **2** (Summon) → Summon ×10 with the bought lira | Lira −500, 10 results; Rates button lists % summing to 100 % and the pity line | units kept after rejoin | |
| 5 | Store → Extras → *Newcomer's bundle* | +300 lira, the 'Akeed in Units (key **1**), red tarboosh in the wardrobe; `bundles` has an entry | After rejoin the bundle button says owned / is blocked ("You already own that") | |
| 6 | Bundle fallback: run **Direct prompt** with the starter_pack id | Toast "+300 lira"; lira +300; no second 'Akeed copy, no second tarboosh | unchanged after rejoin | |
| 7 | Key **3** (Diary) → **Unlock premium** → confirm | Toast "Premium Diary unlocked!"; `premium=true`; premium column claimable | still `premium=true` | |
| 8 | **Premium twice:** press Unlock premium again | Button hidden, or the game refuses with "You already own that." (no Roblox prompt) | — | |
| 9 | **Premium twice, forced:** **Direct prompt** with the pass_premium_s1 id → confirm | Toast "+800 lira"; lira **+800**; premium unchanged; receipts +1 | lira still +800, not +1,600 | |
| 10 | Diary → **Skip 10 levels** → confirm; buy it a second time | Toast "+10 Diary levels!" each time; xp jumps twice | levels kept after rejoin | |
| 11 | Store → buy *Gold-banded tarboosh*, then *Wedding qumbaz* | Toast "Purchased: …"; item in wardrobe; can wear it | still owned after rejoin; Buy button gone/blocked | |
| 12 | Item fallback: **Direct prompt** with the item_tarboosh_gold id | Toast "+300 qirsh"; qirsh **+300**; lira unchanged | qirsh unchanged after rejoin | |
| 13 | Store → **Passes** → buy **VIP** | Toast "Unlocked: VIP" (only if the shawl is new); shawl in wardrobe; Summon ×1 now costs **40** lira (×10 = 400) | see note below | |
| 14 | Buy **Fast Mode** (no toast: it grants no item); join Episode 1 (key **9**) as host, click the speed button | 3x is selectable while hosting; before buying, 3x shows "3x speed needs the Fast Mode pass." | — | |
| 15 | Buy **Extra slot** (no toast); key **1** → loadout | Loadout shows **7** slots | — | |
| 16 | Buy **Lane Patron** | Gold tarboosh + shawl owned, no duplicates; toast only if one of them was new (after steps 11 and 13 there may be none) | — | |
| 17 | Cancel check: in a step above, close Studio's purchase dialog with **Cancel** | Nothing granted, no toast | — | |
| 18 | Failure retry: `print(game.ServerStorage.HaretDebug:Invoke("failNext", 3))` *(mock store only; skip with API access on)*, then buy a qirsh pouch | First attempts warn, grant arrives once when the store recovers; never twice | — | |

**Note on game passes in Studio.** Studio pass purchases are simulated. The game applies a pass's perk and
cosmetics for the session as soon as `PromptGamePassPurchaseFinished` reports `purchased = true`, so steps
13–16 should show the toast/perk in Studio too. `UserOwnsGamePassAsync` (checked on join) may not reflect a
Studio test purchase, so the perk is not expected after a rejoin (see below). If steps 13–16 still show no
perk, record it as **"pass grant not observed in Studio"** with the Output log. Final pass checks then happen
in a live private server (Roblox charges real Robux there; buying your own pass as the owner is a real
purchase, so decide before doing it).

Pass ownership after a Studio rejoin is not expected to persist (Studio does not record simulated pass
ownership); pass perks are re-checked on every join from Roblox, not saved in the profile.

- [ ] All rows ✓ (or failures written down with the Output log lines) · date: ________
- [ ] Fill §D "Approved by / Date" for every product you created; note the API-access change in §E.

## B3. Schema v3 (S1-S12b, the Cat → Al-Adashari)

- Publishing the build with `Economy.SCHEMA_VERSION = 3` migrates every profile on its next load: the Cat
  (`qitt`) is replaced by one Al-Adashari with the Cat's trait plus 100 lira, and leaves the loadout.
- Servers still on v2 refuse a v3 profile (`newer_schema`): **shut down old servers** right after publishing,
  or a player who loads on a new server and then lands on an old one is kicked.
- Studio Play on the TEST place uses the real DataStore: one Play with v3 code migrates the owner's own
  profile, and the published v2 servers then kick the owner until v3 is published.
- One release later: delete the `QITT` line from `Config/Codes`.

## C. Before a public release

- [ ] All `COPYRIGHT_REGISTER.md` rows Approved, including a trademark search for the title
- [ ] Cultural review by native-speaker consultants (Arabic text, depictions)
- [ ] Arabic and English strings complete; no missing keys (enforced by unit test)
- [ ] Experience Guidelines questionnaire (maturity label) completed truthfully
- [ ] Monetization review: paid random items disclosed (summon Rates screen, trait Rates panel, questionnaire), lira/stones products hidden where restricted, no pay-to-win, prices fair for the target age
- [ ] Every Robux product approved in writing and listed below
- [ ] `ProcessReceipt` idempotency tested with duplicate and failed grants
- [ ] Analytics funnels verified in the Creator Dashboard
- [ ] Performance: ≥ 30 fps on the reference Android phone in a 20-player server; memory < 1.2 GB
- [ ] DataStore budget review and backup/rollback plan (versioned keys and `ListVersionsAsync` runbook)
- [ ] Moderation: report flow, server-side chat filtering for any displayed player text
- [ ] Rollback plan: previous place version noted; known-good config tagged in Git

## D. Robux products register (planned — nothing approved or created yet)

| Product | Type | Planned price | Approved by | Date |
|---------|------|---------------|-------------|------|
| lira_100 / lira_300 / lira_650 / lira_1500 / lira_4000 | Developer product | 49 / 129 / 249 / 499 / 1,199 | — | — |
| qirsh_pouch / qirsh_purse / qirsh_chest | Developer product | 25 / 99 / 199 | — | — |
| stones_3 / stones_10 | Developer product | 99 / 279 | — | — |
| pass_premium_s1 | Developer product | 799 | — | — |
| pass_skip_10 | Developer product | 999 | — | — |
| starter_pack | Developer product | 199 | — | — |
| item_tarboosh_gold / item_qumbaz_wedding | Developer product | 79 / 129 | — | — |
| vip / fast_mode / extra_slot / lane_patron | Game pass | 299 / 799 / 149 / 249 | — | — |

Before creating any of these: declare paid random items in the maturity questionnaire, and confirm the
Rates screen and the regional restriction behave on a published test place.

## E. Live settings changes log

| Date | Setting | Old → New | Approved by |
|------|---------|-----------|-------------|
| 2026-10-15 | New experience "Haret Al-Yasmin (TEST)" (place 120389740593436, game 10771112137) | — → **Private**; devices Computer/Phone/Tablet/VR; Team Create off; AI data sharing off | Owner (chat, 2026-10-15) |
| 2026-10-16 | Published place version 64 (feat/vertical-slice working tree + bde33e0 monetization safeguards + 9add4b9 party scaling; 132 tests pass, Studio smoke test clean). All product ids still 0, so nothing is for sale | previous → v64 | Owner (chat, 2026-10-16) |
| 2026-10-16 | Content rating questionnaire | none → **Mild** (Violence Repeated/Mild) | Owner (chat, 2026-10-16) |
| 2026-10-16 | Social link | none → Discord `https://discord.gg/VeT9cvbuMq` "Join the Haret Al-Yasmin Discord" | Owner (chat, 2026-10-16) |
| 2026-10-16 | Game access (Manage audience → Release publicly) | Private → **Public**, audience reach "Ages 16+ and trusted friends" (under-16 needs ID verification, 2-step verification, and 250 engaged players or the 1,000 R$ refundable Kids & Select fee) | Owner (chat, 2026-10-16) |
| 2026-10-17 | Published place version 65: tester code `HARATESTERWRCF5G` (`Config/Codes.luau`, `allUnits`, expires 2026-11-17) grants every defender the player doesn't own; verified in Studio (15 granted, second redeem refused) | v64 → v65 | Owner (chat, 2026-10-17) |
| 2026-10-17 | Published place version 71 to the public experience: commit 658e4e5 (3D cast, 21 character models, 6 prop models, TD-style UI pass) incl. tester code `HARATESTERWRCF5G`; 133 tests pass, Studio smoke test clean, code re-verified | v65+ → v71 | Owner (chat, 2026-10-17) |
| 2026-10-17 | Server management → Restart Servers (outdated only, no delay): 1 outdated server, 2 players migrated to v71 after testers reported the tester code "not working" (their server predated the code). After every publish, restart outdated servers or new codes/fixes won't reach players already in game | — | Owner (chat, 2026-10-17) |
| 2026-10-17 | Published place version 88 from Studio (Alt+P, driven by Claude with the owner's approval): branch `phase/0` at 5460ef1 = feat/vertical-slice f46109a (Discord bug fixes, AFK room, baked signature animations, hand props, clean Abu Hatem and Fawzia meshes) plus the Phase 0 fixes (smooth enemy walk clips, DataService lint). Check script green (selene 0/0, 147 specs, luau-lsp strict clean, rojo build OK); solo Studio match verified (docs/TEST_REPORT_SLICE.md, Phase 0 verification). Two-client test not run. Product ids still 0. Outdated servers not yet restarted | v71 → v88 | Owner (chat, 2026-10-17: "Publish it to test it") |
| 2026-10-17 | Published place version 90 from Studio (Alt+P, driven by Claude): branch `phase/0` at 38b6bc3 = v88 plus owner-only code `MONEY50K` (`Config/Codes.luau`, `matchCash` 50,000, `onlyUserIds` = owner; repeatable, works only in a match) and a Codes button in the match HUD (Watchtower toggle moved down to y 272). Check script green (148 specs); Studio match verified (two redeems in wave 1, cash $600 → $100,600; lobby redeem refused with match_only). Typing into the Codes box not driven through MCP; two-client test not run. Outdated servers not restarted | v88 → v90 | Owner (chat, 2026-10-17: "publish the game with all changes") |
| 2026-10-17 | Published place version 95 from Studio (File → Publish to Roblox, driven by Claude via computer use): branch `phase/0` at 3f3a2ef, the same tree as the single squash commit 0fc597d pushed to GitHub `main` (all of phase/0 plus the research notes; the side branches' code was already in phase/0). Since v90: stun-chain cap (6 s, then 3 s immune), buffed-defender badges, match HUD cleared on return, gate rooftops fixed, onboarding funnel, match VFX budget, audit ledger, P3-09 remote hardening (loadout locked mid-match, NaN guards, arena slot release). Check script green (selene 0/0, 227 specs, luau-lsp strict clean, rojo build OK); Studio solo lobby verified (server ready, HUD and NPCs render). Two-client test not run. Product ids still 0. Outdated servers not restarted | v90 → v95 | Owner (chat, 2026-10-17: "merge all commits … publish everything to the release", "you click use my desktop") |
| 2026-10-18 | Published the TEST place from Studio (File → Publish to Roblox, driven by Claude via computer use) at 23:20:29 UTC 2026-10-17 (Roblox asset `Updated` timestamp); the new version number is not shown in Studio's Edit session (it still reports the loaded v95), so it is v96 unless someone else published in between. Code: branch `phase/polish` at 75e1472, **not merged into phase/0 or main and not pushed**. Since v95: music/sound toggles and HUD mute (PV-B08), damage numbers, boss hit flash, reward coins, boss-death shake, gate shudder, per-role impacts, tower place/upgrade/sell effects, wave/boss/final-wave/victory/defeat moments, UI motion, enemy health-bar ring + markers + boss bar, attacker death/intro/stagger clips and faster gaits, currency icons next to every amount (primitive drawers until the images are uploaded), night lighting fix (place default Atmosphere/Bloom dropped at runtime). Check script green (252 specs); each task play-tested in Studio solo. Two-client test not run. Product ids still 0. Outdated servers not restarted | v95 → v96 (expected) | Owner (chat, 2026-10-18: "Publish via studio to try use desktop to do it") |
| 2026-10-18 | Published the TEST place as **v1.0.0** from Studio (File → Publish to Roblox with Notes, title `v1.0.0`, driven by Claude via computer use) at about 17:28 local; Studio showed "Published. Eligible players can play now." Code: `main` at 029d119 (tag `v1.0.0`), every branch merged into main and deleted (D-072). Schema v3 is now live (D-052). Play-tested solo before publishing: server ready, no errors from our code, Episode 1 match started, Settings shows `v1.0.0`. Experience icon `assets/marketing/icon/icon_512.png` **not yet uploaded**: Studio's Experience Settings has no icon field and Creator Hub needs the owner signed in. Discord #announcements post 1561386102101774377 (animated banner + embeds, no pings). Outdated servers not restarted; product ids still 0 | v1.0.0 | Owner (chat, 2026-10-18: "publish in studio as v 1.0.0") |
