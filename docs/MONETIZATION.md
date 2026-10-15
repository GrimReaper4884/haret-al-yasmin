# Monetization Plan

*Status: v1 · 2026-10-15 · Code: `Config/Products.luau`, `Logic/MonetizationLogic.luau`,
`server/Services/MonetizationService.luau` · Nothing is live: every product ID is `0` until the owner creates
it in the Creator Dashboard (RELEASE_CHECKLIST §D).*

> Roblox programmes, fees and payout rates change. Check the Creator Hub before each launch decision.
> Figures below are planning assumptions, not facts.

## 1. Principles (non-negotiable)

1. **No pay-to-win.** Robux and qirsh buy looks, never quest progress, story access or advantages over others.
2. **No randomized paid rewards** (no loot boxes, spins or mystery crates).
3. **No pressure tactics aimed at kids:** no countdown timers on purchases, no "only 2 left", no guilt dialogue from NPCs.
4. **Everything earnable is earnable for free.** Robux-only items are the exceptions and are clearly labelled "Premium".
5. **Every Robux grant is server-side and idempotent** (see §5).

## 2. Revenue levers available on Roblox, and our plan for each

| # | Lever | How it earns | Plan for Haret Al-Yasmin | Status |
|---|-------|--------------|--------------------------|--------|
| 1 | **Developer products** (consumable) | Player pays Robux each time; creator keeps ~70% | Qirsh purses (25 / 99 / 199 R$); premium wardrobe pieces (gold-banded tarboosh 79 R$, wedding qumbaz 129 R$) | ✅ Code ready, IDs needed |
| 2 | **Game passes** (one-time) | One-time Robux purchase; ~70% to creator | "Lane Patron" (249 R$): gold-banded tarboosh + embroidered shawl. Later: "Family Home" plot upgrade (cosmetic decor slots) | ✅ Code ready, ID needed |
| 3 | **Premium Payouts** | Roblox pays by Premium subscribers' engagement time (no purchase needed) | Long-lived social play: episodes, daily errands, events. A free monthly cosmetic for Premium members is allowed | 🔜 Automatic once published |
| 4 | **Paid private servers** | Monthly Robux per private server | Roleplay groups (families, classes, friend circles) host their own lane. Price ~100 R$/month | 🔜 Owner toggles in Game Settings |
| 5 | **Experience subscriptions** | Monthly recurring Robux | Possible "Lane Membership": monthly cosmetic plus a nameplate colour. Needs care for a young audience; decide after launch data | ⏸ Later, needs approval |
| 6 | **UGC avatar items** | Selling items in the Avatar Marketplace; in-experience sales also earn an affiliate share | Publish the tarboosh, sherwal and qumbaz as real UGC accessories (needs 3D modelling and UGC programme access), sold through an in-game "try on" mirror | ⏸ Needs art and UGC access |
| 7 | **Immersive / rewarded ads** | Revenue share from ads shown to eligible (13+) users | Optional portal or billboard in the khan (outside gate). Never shown to under-13s per Roblox rules; no forced ads | ⏸ Evaluate after launch |
| 8 | **Seasonal cosmetic sets** | Dev products or passes during events | Ramadan lantern set, wedding (zaffeh) set, Eid set: clearly dated, returning yearly (no fake scarcity) | 🔜 With live events |
| 9 | **Season pass (free + premium track)** | One-time per season | "Lane Diary": free track rewards for everyone; premium track adds cosmetic variants only | ⏸ Needs approval and design |
| 10 | **Commerce / merch** | Physical goods linked from the experience (where eligible) | Tarboosh plush, cookbook… long-term only | ⏸ Long-term |

## 3. Economy balance (qirsh)

| Source | Amount |
|--------|--------|
| Ka'ak delivery | 50 |
| Episode 1 | 60 |
| Each later episode | 60–120 |
| Planned repeatable jobs (baker's helper, water carrier) | 10–25 per run, ~150/hour |

| Sink | Price |
|------|-------|
| Taqiyah 20 · Sash 30 · Red tarboosh 40 · Black tarboosh 60 · Hatta+agal 70 · Sherwal 80 · Sidriyye 90 · Shawl 100 · Abaya 120 · Qumbaz 150 | 760 total |

A free player can own the whole qirsh wardrobe after about 5 hours of play. Purses save time but never unlock
anything a free player cannot reach. A 100 qirsh purse is roughly 40 minutes of jobs.

## 4. Steps for the owner to go live (manual, needs approval)

1. Publish to a **test experience** first (approval required).
2. Creator Dashboard → the experience → Monetization → create each developer product and game pass with the
   approved price and an original icon.
3. Paste each ID into `src/shared/Config/Products.luau` (`productId` / `gamePassId`).
4. In Studio, test purchases are simulated (no Robux charged): buy each product, rejoin, confirm the grant once.
5. Record each product in RELEASE_CHECKLIST §D.

## 5. Technical safeguards (implemented)

- **Server-opened prompts:** the client sends only a product key (`RequestProduct`). The server checks that the
  product exists, that its ID is live, and that the item isn't already owned, then calls `PromptProductPurchase`.
- **Idempotent receipts:** `ProcessReceipt` → `MonetizationLogic.grantReceipt` records `receipts[PurchaseId]` in the
  same mutation as the grant. A re-sent receipt returns "already" and grants nothing.
- **Durable before acknowledged:** `PurchaseGranted` is returned only after `DataService.saveNow` succeeds.
  Otherwise the answer is `NotProcessedYet` and Roblox retries; the recorded receipt prevents double grants.
- **Offline buyer:** if the player left or their data isn't loaded, the answer is `NotProcessedYet` and the grant
  happens on their next session.
- **Race:** buying an item that is already owned grants `fallbackQirsh` instead, so Robux never buy nothing.
- **Game passes:** ownership is checked on join and on purchase, and the pass cosmetics are added to the inventory.
- **Analytics:** IAP economy events and custom events per product key.
- Unit tests: `tests/monetization.spec.luau`.

## 6. KPIs to watch (Creator Dashboard)

D1/D7 retention, average session length (drives Premium Payouts), payer conversion, ARPPU, purchases per
product, the funnel from qirsh store opened to purchase, and refunds. Change prices only with Roblox's price
testing tools and owner approval.
