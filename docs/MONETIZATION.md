# Monetization Plan

*Status: v2 (tower-defense update) · 2026-10-16 · Code: `Config/Products.luau`, `Config/TD.luau`,
`Logic/MonetizationLogic.luau`, `Logic/SummonLogic.luau`, `server/Services/MonetizationService.luau`,
`MetaService.luau` · Nothing is live: every product ID is `0` until the owner creates it in the Creator
Dashboard (RELEASE_CHECKLIST §D). Genre benchmarks: `docs/research/ROBLOX_TOWER_DEFENSE_GENRE.md`; platform
rules: `docs/research/ROBLOX_IP_AND_POLICY.md`.*

> Roblox programmes, fees and payout rates change. Check the Creator Hub before each launch decision.
> DevEx was US$0.0038 per Robux in late 2025 (minimum 30,000 earned Robux); the creator keeps ~70 % of a
> Robux sale, so a 799 R$ pass is roughly US$2.1 to us.

## 1. Principles

1. **Two currencies, two jobs.** *Qirsh* (earned) buys cosmetics. *Lira* (earned and sold) buys summons.
2. **Everything is earnable.** Every unit can drop from play-earned lira; the only exceptions are the
   starter bundle's unit copy (also in the banner pool) and the season's level-50 unit (a Mythic that also
   drops from banners). No gameplay power is Robux-only.
3. **Paid random items are disclosed.** Summons and trait rerolls are both paid random items (lira and
   trait stones are sold for Robux). The summon Rates screen lists every outcome's percentage, summing to
   100 %, live with pity, before any pull; the Units → Rates panel lists every trait's reroll chance for
   that defender before any reroll. Every product that pays lira or trait stones (packs, starter pack,
   premium Diary, Diary skips) is hidden for players whose region restricts paid random items
   (`PolicyService.ArePaidRandomItemsRestricted`); their earned lira and stones still work.
4. **No pressure tactics aimed at kids:** no countdown timers on purchases, no "only 2 left", no guilt
   dialogue from NPCs. Banners rotate on a fixed hourly clock, nothing is "last chance".
5. **Every Robux grant is server-side and idempotent** (§5). Fallbacks never let Robux buy nothing.

## 2. Catalogue (planned prices; real prices come from MarketplaceService)

### Developer products (consumable)

| Key | Grant | R$ | Notes |
|-----|-------|----|-------|
| `lira_100` … `lira_4000` | 100 / 320 / 700 / 1,650 / 4,500 lira | 49 / 129 / 249 / 499 / 1,199 | hidden where paid random items are restricted |
| `qirsh_pouch/purse/chest` | 100 / 450 / 1,000 qirsh | 25 / 99 / 199 | cosmetics currency |
| `stones_3`, `stones_10` | trait stones | 99 / 279 | trait rerolls (odds on the Units → Rates panel); hidden where paid random items are restricted |
| `pass_premium_s1` | premium Diary track for season s1 (a copy of Abu Brahim at level 20, LP-E04; the Akeed at level 50) | 799 | one per season; buying twice pays 800 lira instead; hidden where restricted (pays lira/stones) |
| `pass_skip_10` | +10 Diary levels | 999 | hidden where restricted (unlocked levels pay lira) |
| `starter_pack` | 300 lira + the 'Akeed + red tarboosh | 199 | once per player (`profile.bundles`); hidden where restricted (pays lira) |
| `item_tarboosh_gold`, `item_qumbaz_wedding` | cosmetics | 79 / 129 | |
| `ad_qirsh_25` | 25 qirsh | 7 | the rewarded video ad's reward (§5); not a store row |

All 16 products and 4 passes exist on the TEST experience since 2026-10-19 (ids in `Config/Products`,
managed pricing off). The creator account owns every pass automatically, so pass purchases can't be
test-bought from it; use a second account for that.

### Game passes (permanent)

| Key | Perk | R$ |
|-----|------|----|
| `vip` | −20 % summon cost, +25 % lira from matches, ×2 pay and daily cap in the Hakawati's room (AFK), 3×–5× match speed when hosting (LP-A03), embroidered shawl | 299 |
| `fast_mode` | 3×–5× match speed when hosting (1× and 2× are free for everyone). VIP and the premium Lane Diary of the running season unlock the same 3×–5× tier (LP-A03, D-093: the owner kept this pass, reworded) | 799 |
| `extra_slot` | 7th loadout slot | 149 |
| `lane_patron` | gold tarboosh + embroidered shawl (cosmetic support pass) | 249 |

### Other levers

Premium Payouts (engagement), paid private servers (~100 R$/month, owner toggle), rewarded video ads
(built, §5; serving off until the experience qualifies), UGC accessories later.

## 3. Lira economy

| Source | Lira |
|--------|------|
| Episode 1 / 2 / 3 win (Normal) | 80 / 140 / 240 (×1.6 Hard, ×2.4 Nightmare, ×2 first clear) |
| Loss | 25 % of the win value, scaled by waves reached |
| Endless | 100 / 230 / 390 / 420 / 450 per 10-wave tier, +5 per tier after 50 |
| Daily streak (7 days) | 20 + 30 + 0 + 45 + 60 + 0 + 120 = 275 per week |
| Hakawati's room (AFK) | 80 per hour sat (cups + tales), capped at 240 a day; VIP ×2 / Premium ×1.5 scale pay and cap (docs/AFK_CHAMBER.md) |
| Diary free track | ≈ 1,900 over the season |
| Launch codes | 100 + 50 + 150 + 40 |

A free player clears Episode 1 on Normal and Hard in the first session (≈ 400 lira ≈ 8 pulls), then earns
roughly 250–400 lira a day with dailies and two episodes: 5–8 pulls a day, a Legendary at most every 50
pulls by pity. A 499 R$ pack is ≈ 33 pulls.

| Sink | Lira |
|------|------|
| Summon ×1 / ×10 | 50 / 500 (VIP 40 / 400) |

## 4. Steps for the owner to go live (manual, needs approval)

The click-by-click version, with the id map, questionnaire answers and the Studio purchase test, is
`docs/RELEASE_CHECKLIST.md` §B2. The trait-stone products can now be created: the reroll shows its odds
and stones are region-gated (§B2.0, §5).

1. Publish to the **test experience** first (already done for the slice; republish with this update).
2. Creator Dashboard → Monetization → create each developer product and game pass with the approved price
   and an original icon; paste the IDs into `src/shared/Config/Products.luau`.
3. Maturity & compliance questionnaire: declare **paid random items**; label Mild (stylized daggers, no
   blood; no tobacco anywhere).
4. In Studio, test purchases are simulated (no Robux charged): buy each product, rejoin, confirm the grant
   once; buy the premium pass twice and confirm the second pays lira.
5. Record each product in RELEASE_CHECKLIST §D.

## 5. Technical safeguards (implemented)

- **Server-opened prompts:** the client sends a product key; the server checks the product exists, its ID is
  live, the item/pass/bundle isn't already owned, and the region allows paid random items, then prompts.
- **Region gate:** `MonetizationLogic.fundsRandomItems` marks every product that turns Robux into lira or
  trait stones: `lira_*`, `stones_*`, `starter_pack`, `pass_premium_s1`, `pass_skip_10` (and any product
  whose fallback pays lira). `canPrompt` refuses them for restricted players and the store / Diary hide
  them. Qirsh packs, cosmetics and game passes stay on sale everywhere.
- **Idempotent receipts:** `ProcessReceipt` → `MonetizationLogic.grantReceipt` records the PurchaseId in the
  same mutation as the grant; a re-sent receipt returns "already".
- **Durable before acknowledged:** `PurchaseGranted` only after `DataService.saveNow` succeeds.
- **Fallbacks:** already-owned item → qirsh; second premium pass or second starter bundle → lira. The toast
  names the currency actually paid (`MonetizationLogic.fallbackPayout`, shared by grant and toast).
- **Game passes:** ownership checked on join (`UserOwnsGamePassAsync`). A purchase reported by
  `PromptGamePassPurchaseFinished` is applied for the session straight away (perk flag + cosmetics), since
  the ownership check is cached and can lag a fresh or Studio test purchase. Perk flags (`vip`, `fast`,
  `slot`) are read server-side by the summon cost, match rewards, speed cap and loadout size.
- **Trait reroll odds:** `UnitLogic.rerollOdds` computes the exact chances from the same weights the roll
  uses, including the "same trait → roll once more" nudge (so they depend on the current trait). Tested
  against an exact enumeration of `rerollTrait`.
- **Policy:** `PolicyService` per player on join; failure to read the policy is treated as restricted.
- **Analytics:** IAP economy events for qirsh/lira, custom events per product key, summon and pass events.
- **Rewarded video ads:** the store shows a "Watch an ad · 25 qirsh" row when AdService says an ad is
  available; the client fires `RequestRewardedAd`, the server (`MonetizationLogic.canShowAd`: one per 10 min,
  6 a session, reward must exist and never fund random items) calls `ShowRewardedVideoAdAsync` with an
  `AdReward` made from `ad_qirsh_25`, and Roblox pays it through `ProcessReceipt` (channel `AdReward`) like a
  purchase. Qirsh only buys cosmetics, so the reward is never a random item (Roblox's rule). `Products.ads.enabled`
  is **false** until the owner turns on Creator Hub → Monetization → Ads → Rewarded Video → Serving
  (needs 13+, ID-verified and 2-step-verified publisher, an approved questionnaire and the visitor bar);
  Studio ignores the flag. Verified in Studio 2026-10-19: ShowCompleted → receipt → +25 qirsh, cooldown shown.
- Unit tests: `tests/monetization.spec.luau`, `tests/meta.spec.luau`.

## 6. KPIs to watch

D1/D7 retention, matches per session, summon count per DAU, payer conversion, ARPPU, lira pack mix,
premium Diary attach rate, VIP attach rate, refunds, and the share of restricted-region players.
