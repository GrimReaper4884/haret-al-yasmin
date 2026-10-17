# Business, Live-Ops and Platform Policy for a Roblox Anime Tower Defense / Gacha Game (2024-2026)

Research note: compiled 2026-10-17. Direct page fetches (create.roblox.com, news sites) were blocked by the sandbox network, so findings below come from web-search result summaries of the cited pages. Where a figure comes from a third-party tracker or SEO blog, it is marked "(tracker estimate)" or "(unverified)". Dates of policy changes are given wherever the source had them.

## 1. Roblox policies affecting gacha: paid random items, PolicyService, trading, IP/DMCA, maturity labels, safety changes

### Takeaway
Any "summon"/banner bought with Robux, or with a currency that can be bought with Robux, is a Paid Random Item: you must show every outcome with exact percentage odds (summing to 100%) before purchase, update odds live when boosted, and use PolicyService to hide/replace summons and paid-item trading for restricted players (at least Australia, Belgium, Netherlands, UK under 18, Brazil under 18 from March 2026, plus others). Anime IP is the biggest existential risk: several top anime games (Anime Adventures 2023, Anime Rangers X 2025) went down via takedowns.

### Cited Findings
**Paid Random Items (PRI) rules**
- If you offer paid random items bought with Robux or with Robux-purchasable currency, you must list all possible outcomes and their actual numerical odds, shown as a percentage; all final outcome percentages must sum to exactly 100%; long decimals can be rounded to four or more decimal places — [Roblox Creator Hub: Paid random items policy](https://create.roblox.com/docs/production/monetization/paid-random-items)
- If outcomes don't fit on screen, a clickable pop-up is allowed, but a standalone symbol like an (i) icon without a descriptive word is not sufficient — [Roblox Creator Hub: Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- Odds-boosting items (e.g., luck potions, a "10x luck" gamepass) require that the new odds of the enhanced random items be dynamically updated/displayed — [Roblox Creator Hub: Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- Indirect purchases count: the older virtual items policy example — if a user buys a seed with Robux and later plants it for a randomized item, odds must be disclosed before planting. By analogy, gems bought with Robux then spent on summons are covered — [Roblox virtual items policy (older page)](https://developer.roblox.com/zh-cn/articles/virtual-items-policy)
- "Clarifying Requirements for Paid Random Items" DevForum announcement (appears to be ~May 2026): numerical odds must be disclosed before the moment of purchase for direct and indirect (in-game currency) purchases; creators must use PolicyService for ineligible users and test with the Player Emulator in regulated markets (Australia, Belgium, Netherlands, United Kingdom, Brazil) — [DevForum: Clarifying Requirements for Paid Random Items](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)
- A DevForum thread "What is considered 'Paid random items'?" exists as a community clarification resource (2026) — [DevForum](https://devforum.roblox.com/t/what-is-considered-paid-random-items/4413243)
- 2026 change (secondary report, dated 2026-06-26): Roblox changed odds-disclosure handling in response to South Korea's game law and applied it worldwide; it also reportedly added a way to block random-item purchases or replace them with guaranteed purchases depending on local regulation — [TechTimes](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm) (secondary; could not fetch full article)

**PolicyService**
- `PolicyService:GetPolicyInfoForPlayerAsync(player)` returns a table; `ArePaidRandomItemsRestricted` is true when the player cannot interact with paid random item generators (bought with Robux or with in-experience currency bought with Robux) — [robloxapi PolicyService reference](https://robloxapi.github.io/ref/class/PolicyService.html); [Roblox PolicyService docs](https://create.roblox.com/docs/reference/engine/classes/PolicyService)
- Roblox guidance: if `ArePaidRandomItemsRestricted` is true, hide, replace, or block random item purchases for that player; `IsPaidItemTradingAllowed` true means paid items can remain tradeable — [Roblox creator-docs on GitHub (content-maturity.md)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md)
- For users the API marks ineligible, creators should not let them trade paid random item results — [Roblox Creator Hub: Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- Policies vary by region, age group and platform (not only country) — so always query the API rather than hard-coding a country list — [DevForum: PolicyService Guidelines](https://devforum.roblox.com/t/policyservice-guidelines/773321)
- Dated change: `ArePaidRandomItemsRestricted` returns true for UK users under 18 from August 13 (2024 announcement) — [DevForum: Update on Paid Random Items Restriction for UK Users Under 18](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183)
- Netherlands/Belgium have long been treated as restricted; DevForum devs have asked how to make games suitable for these markets — [DevForum: How could I make my game suitable for Belgium and the Netherlands?](https://devforum.roblox.com/t/how-could-i-make-my-game-suitable-for-belgium-and-the-netherlands/1986236); [DevForum: Restricted paid random items](https://devforum.roblox.com/t/restricted-paid-random-items/2199080)
- Developers asked why Roblox restricts paid lootboxes in countries where Clash Royale can sell them (shows Roblox is stricter than some mobile platforms) — [DevForum](https://devforum.roblox.com/t/why-can-clash-royale-sell-paid-lootboxes-in-countries-where-roblox-can%E2%80%99t/4062791)
- CAUTION: a list "Singapore, Qatar, Australia, Netherlands, Belgium, UK (U18), Brazil (U18, effective March 2026)" circulated via a FireMonkey X post — [X/FireMonkey](https://x.com/FireMonkey/status/1988215839565189463). FireMonkey is a Fortnite leaker and the post refers to "islands" (Fortnite terminology), so this list is most likely Epic/Fortnite's, not Roblox's. Roblox's own 2026 post names Australia, Belgium, Netherlands, UK and Brazil as regulated markets ([DevForum](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)), which partially overlaps. Context: [Kotaku: Fortnite opens loot box flood gates in race with Roblox](https://kotaku.com/fortnite-loot-boxes-gambling-roblox-2000642980)
- Explain-geographic-restrictions documentation request thread (Jan 2025) shows Roblox has not published a definitive public country list — [DevForum](https://devforum.roblox.com/t/explain-potential-geographic-restrictions-for-experiences-in-randomized-virtual-items-policy/3373422)

**IP / DMCA cases in the anime genre**
- Anime Adventures (2023) was removed after a takedown request issued by Gamefam on behalf of Crunchyroll (alleged; developers did not confirm); Anime Fighting Simulator and Anime Fighting Simulator X (BlockZone) also disappeared — [Pocket Tactics: Three giant Roblox games disappear in potential DMCA battle](https://www.pockettactics.com/anime-adventures/private)
- Anime Adventures developers announced a return (teaser, holiday 2024) — [Beebom](https://beebom.com/roblox-anime-adventures-teaser-released/amp/); a later report says the team revealed a licensed spin-off "TenSura: Isekai Adventures" and issued its own DMCA against an unauthorized remake "Re:Adventures" — [allthings.how](https://allthings.how/?p=224262) (secondary)
- Anime Rangers X (April 2025) showed "Content Deleted"; Discord helpers and a lead dev initially said DMCA, then the co-owner claimed no official DMCA from any studio; JoJo/One Piece units were speculated as the trigger — [Pro Game Guides](https://progameguides.com/roblox/anime-rangers-x-content-deleted-did-dmca-strike-again/); [Mobile Matters](https://mobilematters.gg/guides/roblox/what-happened-to-roblox-anime-rangers-x-when-is-it-coming-back); [Roonby](https://roonby.com/2025/04/25/anime-rangers-x-deleted-reason-why-all-you-need-to-know/)
- Toilet Tower Defense was reportedly taken down after a copyright strike from DaFuqBoom (Skibidi Toilet creator) — secondhand, unconfirmed — [game.guide](https://www.game.guide/why-was-toilet-tower-defense-deleted-on-roblox)
- Anime Vanguards was criticized at launch as "a cheap attempt to copy Anime Adventures" — [FandomWire](https://fandomwire.com/its-a-cheap-attempt-to-copy-anime-adventures-anime-vanguards-has-the-potential-to-become-huge-but-fans-have-some-complaints-against-it/)
- The May 2026 Anime Vanguards lawsuit includes a copyright-infringement claim over code/work used in the game — internal team IP also matters — [Dexerto](https://www.dexerto.com/roblox/roblox-dev-sues-anime-vanguards-owners-after-claiming-he-was-cut-out-of-millions-3368438/)

**Content maturity labels**
- Labels: Minimal, Mild, Moderate, Restricted, plus "Content May Vary" and unrated (N/A). Games without maturity info are automatically restricted for all players. Inaccurate questionnaire answers expose the game and account to moderation — [Roblox Creator Hub: Content maturity and compliance](https://create.roblox.com/docs/production/promotion/content-maturity)
- Audiences: Minimal/Mild reach Roblox Kids (5-8) and Roblox Select (9-15); Moderate reaches Select and standard (16+); Content May Vary limited to age-checked 16+; Restricted to age-verified 18+ — [Roblox Creator Hub: Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity); [Roblox Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Until September 2025 unrated games were treated as 13+; after that unrated games cannot be played — [Roblox Fandom wiki: Content maturity](https://roblox.fandom.com/wiki/Content_maturity) (community wiki)

**2025-2026 safety changes**
- Age checks for chat: required from December 2025 in Australia, New Zealand and the Netherlands; extended worldwide in early January 2026 (announced Jan 7, 2026). Mainly facial age estimation (vendor Persona; images deleted after processing), ID as alternative for 13+. Users are banded (under 9, 9-12, 13-15, 16-17, 18-20, 21+) and these bands limit who can chat with whom; chat off by default under 9 without parental consent — [Roblox Newsroom](https://about.roblox.com/newsroom/2026/01/roblox-age-checks-required-to-chat); [BusinessWire](https://secure.businesswire.com/news/home/20260107986568/en/Roblox-Requires-Users-Worldwide-to-Age-Check-to-Access-Chat); [Gulf News](https://gulfnews.com/technology/media/roblox-now-requires-age-checks-for-all-users-to-access-chat-worldwide-1.500401325)
- Roblox will ask users to repeat age checks if behavior suggests a significantly different age — [Roblox Newsroom](https://about.roblox.com/newsroom/2026/01/roblox-age-checks-required-to-chat)

### Inferences
- Design the gacha with a server-side "PRI mode" switch per player: if `ArePaidRandomItemsRestricted`, replace Robux/premium-currency summons with guaranteed purchases (direct unit packs, shard exchange) or free-currency-only summons; if `IsPaidItemTradingAllowed` is false, mark Robux-derived units untradeable for that player. Keep summon currency earned only through gameplay separate from premium currency to simplify compliance.
- An odds table UI component that reads from the same server config as the RNG (including pity, banner rate-ups and luck boosts) is the safest way to satisfy "dynamic odds" requirements.
- The age-check-for-chat change reduces in-game chat-driven trading negotiation; build a structured trade UI and rely on Discord for community.
- Aim for Mild/Moderate maturity: anime combat with no realistic blood stays reachable to the large 9-15 Select audience.
- Use original characters "inspired by" archetypes (not named characters, logos, signature attacks or ripped models). Every big anime TD has had its existence threatened by IP; an original IP or a license (TenSura route) is the durable path.

### Gaps
- Could not retrieve the official full country list for ArePaidRandomItemsRestricted (Roblox does not appear to publish one). The Brazil U18 March 2026 restriction for Roblox is implied by the 2026 DevForum post naming Brazil as regulated, but exact Roblox terms were not confirmed.
- Exact Roblox Terms of Use wording on trading for real money / off-platform sales and on IP was not retrieved (sandbox blocked fetches). General understanding: selling Roblox items/accounts for real money off-platform violates Roblox Terms, but this needs verification on the Terms page.
- No confirmed DMCA filing records (Lumen etc.) for anime TDs; causes are mostly reported by fan sites.

## 2. Roblox monetization tools

### Takeaway
Core stack for 2026: Developer Products (summons, currency, boosts), Game Passes (2x speed, extra slots, auto-skip, VIP), Subscriptions (monthly VIP), Rewarded Video ads (reward = a developer product), Creator Rewards (replaced Premium Payouts in July 2025, 60-day hold), Managed Pricing (regional pricing + price optimization merged, auto-enrolled), and DevEx at $0.0038/R$ since Sept 5, 2025.

### Cited Findings
- DevEx rate raised from $0.0035 to $0.0038 per Robux (+8.5%) for all creators, announced at RDC25; effective 10:00 AM PT September 5, 2025; Robux earned before then cash out at $0.0035. 30,000 earned Robux = $114 USD at the new rate (30,000 is the documented example/minimum) — [DevForum: RDC25 What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245); [Roblox Creator Hub: Developer Exchange](https://create.roblox.com/docs/tr-tr/production/monetization/developer-exchange)
- DevEx eligibility (Premium required or not) conflicts across third-party sites; check official docs — [bloxodes calculator](https://bloxodes.com/tools/roblox-devex-calculator) vs. other guides (conflicting, unverified)
- Creator Rewards: introduced June 24, 2025 as successor to Engagement-Based (Premium) Payouts and the Creator Affiliate program; Premium Payouts replaced around July 24-25, 2025 — [Roblox Fandom wiki: Creator Rewards](https://roblox.fandom.com/wiki/Creator_Rewards); [Roblox Fandom: Engagement-Based Payouts](https://roblox.fandom.com/wiki/Engagement-Based_Payouts)
- Creator Rewards Robux are added after a 60-day holding period — [DevForum: Introducing Creator Rewards](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628); [Roblox docs: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- Developers complained about payout gaps/long hold after the switch and asked to restore Premium Payouts — [DevForum thread](https://devforum.roblox.com/t/shorten-the-hold-period-of-engagement-payouts-or-restore-the-old-premium-payouts-system/3956591)
- Managed Pricing (2026): Regional Pricing and Price Optimization unified; existing regional-priced items migrate automatically; new eligible items enrolled by default with opt-out; tests run at least every 90 days with at least 7 days' notice; a new price applies only if the experiment shows positive incremental revenue; creators can override — [DevForum: Managed Pricing](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738); [RobloNews](https://roblonews.com/news/roblox-managed-pricing-regional-optimization.html)
- Regional Pricing for Developer Products introduced (2025) and later enabled for all passes — [DevForum: Regional Pricing for Developer Products](https://devforum.roblox.com/t/introducing-regional-pricing-for-developer-products/3971235); [DevForum: Enabling Regional Prices for All Passes](https://devforum.roblox.com/t/enabling-regional-prices-for-all-passes-to-grow-your-global-audience/4471199); [Game Developer](https://www.gamedeveloper.com/business/roblox-rolls-out-regional-pricing-tools-for-developers)
- Roblox-reported results: regional pricing games saw 4-10% higher Robux spend on average; Price Optimization users averaged +4% earnings (Roblox aggregate claims) — [RobloNews](https://roblonews.com/news/roblox-managed-pricing-regional-optimization.html)
- Hard-coded Robux prices in UI won't match regional prices; read prices at runtime (MarketplaceService product info) — [Generalist Programmer](https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide)
- Rewarded Video ads: partnership with Google announced April 2025; ads up to 30 seconds; early tests >80% completion — [Music Ally](https://musically.com/2025/04/02/roblox-teams-with-google-for-new-ad-format-rewarded-video/). Initially self-serve for experiences with 100K+ average DAU over 28 days — [DevForum: More Creators Can Now Use Rewarded Video Ads](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678); later opened to all ads-eligible creators (ID-verified, 13+, public experience with at least 2,000 monthly unique visitors) — [DevForum: Rewarded Video ads now available to all ads eligible creators](https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278)
- Setup in Game Settings > Monetization; reward must be a developer product; cannot reward Robux — [DevForum](https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278). Enhancements post — [DevForum](https://devforum.roblox.com/t/boost-your-game-earnings-with-rewarded-video-enhancements/4645335). Studio plug-in with drag-and-drop placements expected Q4 2026 — [MediaPost](https://www.mediapost.com/publications/article/417959/roblox-eyes-expanded-placements-for-rewarded-vid.html)
- Anecdotal low earnings: one dev reported 171 Robux in a month after 600 rewards — [DevForum page 2](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678?page=2)
- Subscriptions: creator access began Sept 20, 2023, purchases from November 2023; recur monthly, paid to creator in Robux; reported 70% creator share — [80.lv](https://80.lv/articles/roblox-is-launching-subscriptions-for-eligible-creators/); [Campaign](https://campaignlive.com/article/roblox-launches-subscriptions-developers/1830660); [DevForum: Subscriptions now available](https://devforum.roblox.com/t/2702306)

### Inferences
- Typical anime-TD price ladder: dev products for gem packs/summons (regional-priced automatically), gamepasses for QoL (x2/x3 speed, extra unit storage, auto-skip waves, shiny/luck boost — luck boosts trigger dynamic-odds display), a VIP subscription for daily gems. Rewarded video is a supplement (free summon ticket / revive / 2x wave rewards), not a core revenue line.
- Because Creator Rewards pays on engagement/audience growth with a 60-day hold, cash flow for a new studio lags; plan runway accordingly.
- Revenue math example: 1,000,000 earned Robux = $3,800 at DevEx (developer receives ~70% of Robux spent on dev products/passes; marketplace fee per Roblox standard — not re-verified here).

### Gaps
- Exact Creator Rewards formula (Daily Engagement Rewards vs. Audience Expansion Rewards components and per-user rates) not verified from official docs; third-party per-user estimates are unverified.
- Commerce APIs (selling physical goods) and the newer "Commerce Products"/Shopify integration were not researched (limited relevance to TDs).
- Current subscription revenue share and price tiers not verified for 2026.

## 3. Live-ops cadence, community, marketing and the discovery algorithm

### Takeaway
Discovery in 2025-2026 is driven primarily by Recommended-for-You play-through rate, then qualified plays, first-play bounce (under 60s / 61-180s), and play days/playtime across D1, D2-7, D8-28. Top anime TDs ship a major numbered update every few weeks with code drops tied to updates and like/favorite milestones, run a large Discord, and use thumbnail personalization and Ads Manager to feed the funnel.

### Cited Findings
- Play-through rate (how often users who see the game in Recommended for You go on to play) is described as the most important signal; Roblox keeps adding/removing/reweighting signals with an aim of long-term retention — [Roblox Creator Hub: Discovery](https://create.roblox.com/docs/production/promotion/discovery)
- "Qualified play" = a meaningful session that filters accidental clicks and quick bounces; first-play bounce bucketed into <60s and 61-180s, a negative signal — [Roblox Creator Hub: Discovery](https://create.roblox.com/docs/en-us/discovery.md)
- Play days per user and playtime per user measured across D1, D2-D7, D8-D28; impression drops typically follow drops in play-through rate, play days and playtime, and increases in bounce rate; signals use only users who joined organically from Recommended for You — [Roblox Creator Hub: Discovery](https://create.roblox.com/docs/discovery.md)
- After updates, Roblox recommends checking D1 and D7 retention, average session time and qualified play-through rate in Analytics — [Roblox Creator Hub: Analytics](https://create.roblox.com/docs/production/analytics)
- No published numeric D1/D7 benchmarks were found in official docs.
- Thumbnail personalization: live for all games (announced Nov 2024; official launch referenced Feb 13, 2025); up to five thumbnails; multi-armed bandit, not classic A/B; Roblox reported +8.5% average qualified play-through rate, some up to 50% — [GamesBeat](https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/); [DevForum: Live now](https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233); [X/Roblox](https://x.com/Roblox/status/1856760513038110792)
- July 1, 2025 update: personalization remembers existing winners; new thumbnails tested while most traffic goes to the winner (+0.19% QPTR, 21% fewer impressions to non-winners) — [DevForum](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665)
- Open Cloud APIs for Analytics, Events, Experiments and Thumbnail Personalization announced; Experiments API does not cover thumbnails — [DevForum](https://devforum.roblox.com/t/new-opencloud-apis-for-analytics-events-experiments-and-thumbnail-personalization/4828676)
- Ads Manager: auto-bidding with daily or lifetime budgets; Engagement-objective campaigns cost more per play (smaller audience); if no progress after 3-5 days, fix onboarding first — [Roblox Creator Hub: Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager); [Sponsoring experiences](https://create.roblox.com/docs/production/promotion/sponsoring-experiences)
- Anime Vanguards codes drop alongside major updates and milestone events (like-count, subscriber milestones); Kitawari posts codes first in the Discord #announcements channel — [Pocket Tactics](https://www.pockettactics.com/anime-vanguards/codes); [PCGamesN](https://www.pcgamesn.com/anime-vanguards/codes)
- Anime Vanguards Update 15.0 "2nd Anniversary" deployed October 12, 2026 (launch Sept 8, 2024 => ~15 major numbered updates in ~25 months, plus event "parts") — [Pro Game Guides](https://progameguides.com/roblox/anime-vanguards-codes/); event-part naming (Extermination Event Pt.1/Pt.2, Holy Retribution, Wrathful Assault) visible in tracker titles — [RoWatcher](https://rowatcher.com/games/5578556129)
- Codes have expiry dates (e.g., an anniversary code expiring Oct 23, 2026 UTC) and reward sources conflict — [Pro Game Guides](https://progameguides.com/roblox/anime-vanguards-codes/)
- Anime Last Stand official Discord: ~842,513 members — [Discord invite](https://discord.com/invite/animelaststand); Anime Defenders' Roblox group (Small World Games x Anime Defenders): ~4.76M members — [Rolimons group](https://www.rolimons.com/group/34121350)
- Game titles carry live status tags (e.g., "[UPD + x4] Anime Last Stand", "[Shibuya Pt.1] Anime Last Stand", "[10X LUCK] ...") — [Rolimons ALS](https://www.rolimons.com/game/12886143095)

### Inferences
- Live-ops pattern: a major update every ~3-6 weeks (new world/story, new banner units, new mode) split into "Part 1/Part 2" events, with smaller balance/QoL patches in between, title tags announcing the update, a countdown in-game/Discord, and 2-4 codes per update plus milestone codes (likes/favorites/Discord members). Friday/Saturday releases align with weekend peaks.
- Roblox's own signals mean onboarding is critical: get players into a first wave and a free summon within 60 seconds to cut first-play bounce, and give D1/D7 reasons to return (daily rewards, battle pass, timed banners).
- YouTuber partnerships: big anime TDs are heavily covered by Roblox YouTubers/TikTok (codes, tier lists); early-access/code partnerships are common, but no primary source was found for specific deals.

### Gaps
- No primary source found on a fixed weekly cadence or Trello usage for Anime Vanguards/ALS; no source on YouTuber sponsorship terms.
- No public D1/D7 benchmark numbers for TDs.
- No official Ads Manager CPP figures; third-party CPM claims ($5-15 for rewarded video) unverified — [rolearn](https://rolearn.dev/insights/rewarded-video-ads-new-revenue-stream).

## 4. Data on top tower defense games: CCU, revenue, visits, rise and decline

### Takeaway
Anime TDs rose extremely fast (Anime Defenders ~378K peak within ~3.5 months; Anime Vanguards ~340K within 6 days of launch) and then decayed by an order of magnitude within months; the genre's evergreen leaders (TDS, ALS) peak around 150-160K during big updates. Declines are tied to competition/copycat launches, power creep, economy issues, and team disputes.

### Cited Findings
| Game | Launch | All-time peak CCU | Visits | Recent state | Source |
|---|---|---|---|---|---|
| Anime Vanguards (Kitawari) | Sept 8, 2024 | >340,000 (Sept 14, 2024); >215K within weeks | >1.9B; ~1.9M favorites | ~66.6K online, peak 71K-84K in Oct 2026 snapshots | [Beebom](https://beebom.com/anime-vanguards-surpasses-blox-fruits-top-earning-roblox-game/); [Rolimons](https://www.rolimons.com/game/16146832113); [Dexerto](https://www.dexerto.com/roblox/roblox-dev-sues-anime-vanguards-owners-after-claiming-he-was-cut-out-of-millions-3368438/); [RoVitals](https://rovitals.com/records) |
| Anime Defenders (Small World Games) | Apr 5, 2024 | 377,836 (likely July 21, 2024) | >3.43B | ~324-639 CCU in Aug 2026 | [Rolimons](https://www.rolimons.com/game/17017769292); [profitable.app](https://profitable.app/roblox/games/anime-defenders) |
| Anime Last Stand | Created Mar 24, 2023 (launch ~Feb 2024 reported) | 157,103 (Oct 23, 2025) | >1.08B | 30-day peak 8,896 | [Rolimons](https://www.rolimons.com/game/12886143095) |
| Toilet Tower Defense (Telanthric) | 2023 | 522,376 (Mar 9, 2024) — largest TD peak | ~5.9-6.18B (LEGACY listing) | legacy; multiple clone listings | [Adellion](https://adellion.com/roblox-tower-defense); [Rolimons](https://www.rolimons.com/game/13775256536); [Fandom](https://roblox.fandom.com/wiki/Telanthric_Development/Toilet_Tower_Defense) |
| Tower Defense Simulator | 2019 | 159,824 (Oct 4, 2025) | ~5B | evergreen | [Adellion](https://adellion.com/roblox-tower-defense) |

- Anime Vanguards reportedly surpassed Blox Fruits to become the top-earning Roblox game shortly after launch (Sept 2024) — [Beebom](https://beebom.com/anime-vanguards-surpasses-blox-fruits-top-earning-roblox-game/)
- Revenue estimates (tracker estimates, low confidence): Anime Vanguards ~$16.5M lifetime, ~$223K-311K per 30 days in mid/late 2026; Anime Defenders ~$27.4M lifetime but only ~$11.4K/30 days in Aug 2026 — [profitable.app AV](https://profitable.app/roblox/games/anime-vanguards-extermination-event-pt-1); [profitable.app AD](https://profitable.app/roblox/games/anime-defenders). Another tracker estimated AV at only ~$10,289/month — contradicts the above ([RoWatcher](https://rowatcher.com/games/5578556129)).
- Anime Vanguards lawsuit (filed May 22, 2026, SDNY): former programmer Rehaab Haque / Boss Studio LLC sued alleged owners Vladislav Popov and Andrei Acuña for breach of contract, fiduciary duty, copyright infringement and unjust enrichment; he was paid via Robux revenue share with no formal contract; the complaint alleges the game fell from 100K CCU to under 5K over a three-month period (allegation); stakes reported ~$10M-15M (secondary) — [Dexerto](https://www.dexerto.com/roblox/roblox-dev-sues-anime-vanguards-owners-after-claiming-he-was-cut-out-of-millions-3368438/); [Adam Starr on X](https://x.com/AdamStarrLawyer/status/2058325203999162482)
- Separate Roblox case: creator sued for $35M after a Discord-met business partner fired him by email — informal partnerships are a recurring risk — [Dexerto](https://www.dexerto.com/roblox/roblox-creator-sues-for-35m-after-business-partner-he-met-on-discord-fired-him-by-email-3411863/)
- Titan Tower Defense (March 2026): hacked item value led to rolling player decks back ~8 days — [NamuWiki](https://en.namu.wiki/w/Titan%20Tower%20Defense) (community wiki)
- ALS has balance passes nerfing top units while they remain strong (power creep management) — [Destructoid tier list](https://www.destructoid.com/roblox-anime-last-stand-unit-tier-list/)
- Platform context: Grow a Garden peaked at 22.3M CCU (Aug 23, 2025); Steal a Brainrot drove a 47.4M platform CCU record — the TD genre competes with these for attention — [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden); [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)

### Inferences
- Anime Defenders' trajectory (April 2024 launch, ~378K peak by July, then collapse after Anime Vanguards launched in Sept 2024) suggests the genre is winner-take-most and very vulnerable to a higher-polish competitor; AV recovered to 60-80K CCU in 2026 through sustained updates.
- Peak-then-decay is normal; sustained revenue comes from a stable 30-80K CCU base with periodic update spikes.
- Formal contracts/revenue-share agreements and code ownership (IP assignment) should be in place before launch.

### Gaps
- No verified primary data on what specifically caused Anime Defenders' decline (power creep vs. competitor vs. dev issues); attribution above is inference.
- ASTD (All Star Tower Defense) data not retrieved.
- Revenue figures are tracker estimates and conflict; Roblox does not publish per-game revenue.

## 5. Exploits common in TD games and anti-exploit lessons

### Takeaway
TD exploits target client-trusted remotes: placement anywhere/out of bounds, unit/item duplication, currency/reward remote spam, autofarm. Fix by validating everything server-side, making inventory changes atomic, and keeping rollback capability.

### Cited Findings
- Placement exploits: answer on DevForum is to validate on the server whether a placement is allowed, rather than trusting the client's position — [DevForum: TD preventing exploiters abusing placements](https://devforum.roblox.com/t/tower-defense-game-preventing-exploiters-from-abusing-placements/3801331)
- Exploiters' local changes don't replicate unless a RemoteEvent passes them along; all server handling of remotes needs validation — [DevForum: Exploiters using remote events](https://devforum.roblox.com/t/exploiters-are-using-remote-events-to-destroy-my-game/3058524)
- Anti-dupe fixes can fail: a community anti-dupe patch thread shows fixes that seemed to work but the exploit still replicated — [DevForum: Anti-Dupe Exploit Patch](https://devforum.roblox.com/t/anti-dupe-exploit-patch/1920329/20)
- Dupe scripts are marketed on TikTok for anime games (unverified, likely scams) — [TikTok](https://www.tiktok.com/discover/duplication-glitch-anime-defenders)
- Rollback precedent: Titan Tower Defense rolled decks back ~8 days after hacked item value (March 2026) — [NamuWiki](https://en.namu.wiki/w/Titan%20Tower%20Defense)

### Inferences
- Lessons: (1) server-authoritative placement (check path, slot cost, cash, cooldown, unit limit); (2) rate-limit and debounce every remote, especially summon, sell, upgrade, trade, claim-reward; (3) use DataStore UpdateAsync/session locking and unique item IDs (GUIDs) per unit so dupes are detectable; (4) trading should be server-escrowed and committed atomically to both profiles; (5) log economy events (summons, trades, currency gains) for anomaly detection; (6) keep versioned backups to enable targeted rollbacks; (7) autofarm/AFK: since many TDs sell auto-play passes themselves, focus on preventing reward-rate abuse (server-computed rewards per wave/time) rather than banning macros.

### Gaps
- No official developer post-mortem from Anime Defenders/AV/ALS about specific dupe incidents was found.

## 6. Team size, timeline and launch checklist

### Takeaway
No reliable public data on team sizes/timelines for top anime TDs was found; evidence suggests small, often remote/Discord-formed teams with informal Robux revenue-share arrangements, which have led to lawsuits.

### Cited Findings
- Anime Vanguards' former programmer was brought on in 2024 and paid via Robux revenue share without formal contracts (per complaint) — [Dexerto](https://www.dexerto.com/roblox/roblox-dev-sues-anime-vanguards-owners-after-claiming-he-was-cut-out-of-millions-3368438/); [Adam Starr on X](https://x.com/AdamStarrLawyer/status/2058325203999162482)
- Anime Vanguards launched Sept 8, 2024, about 5 months after Anime Defenders (Apr 5, 2024) at the height of the anime TD wave — [Beebom](https://beebom.com/anime-vanguards-surpasses-blox-fruits-top-earning-roblox-game/); [Rolimons](https://www.rolimons.com/game/17017769292)
- Pre-launch compliance items with official backing: complete the Maturity & Compliance Questionnaire (unrated = unplayable) — [Roblox Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity); odds disclosure and PolicyService handling, tested with Player Emulator in regulated markets — [DevForum](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622); up to 5 thumbnails for personalization — [GamesBeat](https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/); Ads Manager campaigns after onboarding is validated — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager); rewarded video requires 2,000 monthly unique visitors — [DevForum](https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278)

### Inferences
- Plausible launch team (inference, not sourced): 1-2 scripters (server/economy + UI), 1-2 builders/map artists, 1 modeler/animator for units + VFX artist, 1 UI artist, plus community manager/Discord mods; 3-6 months to a launchable MVP (2-3 maps, 20-40 units, summon system, trading off or limited at launch).
- Launch checklist (synthesized): original IP review; maturity questionnaire; odds UI + PolicyService gating + paid-item trading gating; regional pricing via runtime price lookups; server-authoritative placement/economy, remote rate limits, session-locked DataStores, backups; analytics events (funnel, D1/D7, QPTR) ; 3-5 thumbnails + icon; Discord with code channel, like/favorite milestone codes; update countdown; Ads Manager test budget; written contracts and IP assignment for every contributor.

### Gaps
- No developer interview or primary source on team size/timeline for Anime Vanguards, Anime Defenders, ALS, TDS or TTD was found.
