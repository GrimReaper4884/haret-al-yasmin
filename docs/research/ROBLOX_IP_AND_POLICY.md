# Roblox IP & Policy Research — Bab al-Hara-inspired Tower Defense

**Date:** 2026-10-16 · **Status:** research memo, not legal advice · **Scope:** Roblox platform rules + practical IP risk for a TD game *inspired by* MBC's *Bab al-Hara* (Pan Arab Film Services / Bassam al-Mulla).

Legend: **[V]** verified against a primary source · **[S]** secondary/press · **[U]** unverified / inferred.

---

## 1. Fan-game practice on Roblox

**Roblox's position.** Roblox prohibits unauthorized IP use, removes content on a valid copyright *or* trademark notice, may *proactively* archive assets it suspects are infringing, and suspends/terminates repeat infringers. Credit, non-monetization or "I saw others do it" are not defenses. ([IP Guidelines](https://create.roblox.com/docs/en-us/production/publishing/ip-guidelines), [Community Standards — IP](https://about.roblox.com/en-au/community-standards)) **[V]**

**Process.** DMCA notice → removal (~24 h) → uploader notified → counter-notice → restored in 10–14 business days unless the claimant sues. Trademark removals are appealed by email, not counter-notice. Rights holders also use **Rights Manager** (2024; ID-verified exclusive-rights holders remove experiences, avatar items, assets; creators see hits under "Claims Against Me") and **License Manager** (2025; holders scan for their IP and *offer* licences). ([Rights Manager](https://create.roblox.com/docs/en-us/production/publishing/rights-manager), [DMCA process](https://videogamelaw.substack.com/p/robloxs-dmca-process)) **[V/S]**

**What has actually been taken down (and what survived):**

| Case | Trigger | Outcome | Lesson |
|---|---|---|---|
| **Anime Adventures / Anime Fighting Simulator (Dec 2023)** | DMCA reportedly by Gamefam for Crunchyroll (My Hero Academia assets) as the licensed MHA game launched | Privated; AA still down 2025; dev pivoted to a *licensed* spin-off (TenSura) | Real likenesses + rights-holder with a competing licensed product = highest risk ([Pocket Tactics](https://www.pockettactics.com/anime-adventures/private), [allthings.how](https://allthings.how/anime-adventures-roblox-return-tensura-reveal-and-the-re-adventures-dmca/)) **[S]** |
| **Toilet Tower Defense (Sep 2023)** | Skibidi Toilet creator DaFuq!?Boom! strikes | Down ~2 weeks; later obtained a character licence **[U]**; clones renamed ("Superbox Siege Defense") | Specific creator's characters → strike; rename/original models → survives ([game.guide](https://www.game.guide/why-was-toilet-tower-defense-deleted-on-roblox), [TTD wiki](https://toilet-tower-defense-game.fandom.com/wiki/Toilet_Tower_Defense_Under_Review)) **[S]** |
| **Football Fusion (Dec 2021; Mar 2025)** | NFL DMCA over team names, logos, uniforms | Relaunched 5 days later as *Football Fusion 2* with fictional teams | Swap names + trade dress, keep the game ([Distractify](https://www.distractify.com/p/what-happened-to-football-fusion), [PGG](https://progameguides.com/roblox/roblox-fusion-football-2-is-here-whats-different/)) **[S]** |
| **Skyblock → Islands (2020–21)** | Claim on the *title* | Forced rename, no content loss | A title alone draws claims ([PGG](https://progameguides.com/roblox/roblox-skyblock-skyblox-name-changed-to-islands/)) **[S]** |
| **Pokémon Brick Bronze (2018)** | Nintendo DMCA | Removed; Roblox then filtered "Pokemon"/"Mario" from names **[U]** | Big-brand titles get platform filtering ([Kotaku](https://kotaku.com/inside-the-fan-made-pokemon-mmo-played-by-tens-of-thous-1797638071)) **[S]** |

**What survives:** All Star Tower Defense, Anime Vanguards, Anime Defenders etc. use *altered names* ("Koku", "Gujo", "Alocard") and in-house models — units are "derived from iconic anime… although their names are usually changed" ([Pocket Tactics](https://www.pockettactics.com/anime-vanguards-units)). Pattern: **original models + changed names + no logos/music/footage = tolerated for years; verbatim names + ripped assets + a motivated licensor = takedown.** Renaming lowers but doesn't zero the risk when a licensor has a commercial motive (Gamefam).

---

## 2. Audio

**Upload rules (2025–26).** You must own the rights; single track, mp3/ogg/wav/flac, < 20 MB, < 7 min, ≤ 48 kHz. ID-verified accounts: 2,000 free uploads / 30 days; unverified: 100. ([Audio assets](https://create.roblox.com/docs/en-us/audio/assets)) **[V]**

**Audio privacy system.** Since 22 Mar 2022 new uploads are **private by default** and existing audio > 6 s was privated; a private asset is usable only by its owner and experiences the owner grants ([DevForum](https://devforum.roblox.com/t/1701697), [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy)) **[V]**. There is no "short clip" exemption for using someone else's audio; short SFX merely stayed public in the migration.

**Copyright moderation.** Uploads are fingerprinted (Audible Magic reported **[S]**) and matches auto-removed; false positives on licensed tracks are reported in 2026 ([DevForum](https://devforum.roblox.com/t/false-copyright-removal-of-audios-on-roblox/4338342)). Repeat hits count toward termination.

**Licensed library (Creator Store → Audio).** 100k+ royalty-free tracks/SFX from APM (May 2018; max **250 licensed tracks per experience**, Roblox-only, no download/streaming-service use — [Help: Licensed Music](https://en.help.roblox.com/hc/articles/360000927163)), Monstercat, Pro Sound Effects, Position, Nettwerk, **DistroKid (Sep 2024)** and **Too Lost (Jul 2026)** ([TechTimes](https://www.techtimes.com/articles/321852/20260728/roblox-adds-independent-music-catalog-creator-store-exposure-model-leaves-pay-gap-open.htm)) **[V/S]**. **Arabic content exists:** a Creator Store query for "arabic oud" returns ~1,000 results, e.g. *Golden Dune Oud Arabic House* (Armosa Project) and *Oud Strings and Neon Smoke (Arabic Lo-Fi)*, both from the verified **DistrokidOfficial** account ([toolbox API](https://apis.roblox.com/toolbox-service/v1/marketplace/3?keyword=arabic%20oud)) **[V, Oct 2026]**. Quality/period-fit must be auditioned; many DistroKid uploads are generic "desert lo-fi".

**AI-generated music.** No audio-specific rule: all content "including content created by or using generative AI" must meet Community Standards and *you* are responsible for third-party-tool output ([Generative AI](https://create.roblox.com/docs/en-us/generative-AI)) **[V]**. Use a generator whose terms grant commercial rights (Suno paid tiers do; Udio currently blocks downloads **[S]**), keep prompts free of artist/show names, and keep generation records.

**Conclusion on the real theme: No.** It is a copyrighted composition + master (MBC / composer) needing sync + master licences Roblox doesn't hold; fingerprinting would remove it and log a strike; and it is the strongest evidence that the game trades on the show. **Alternatives:** (a) commission or AI-generate an original Levantine cue (maqam Bayati/Hijaz, oud + qanun + riqq) — different melody, same mood; (b) licensed Arabic tracks from the DistroKid/Too Lost catalogues; (c) APM Middle-East library cues (verify in-store **[U]**).

---

## 3. Paid random items, codes, passes, subscriptions, ads, revenue

**Paid Random Items (PRI) policy** ([docs](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items), [Community Standards](https://about.roblox.com/en-au/community-standards)) **[V]**:
- Covers anything random bought with Robux **or with currency bought with Robux** (gems, spin tickets, keys, re-rolls); also *probability modifiers* (luck potions, rate-up, **pity**).
- **Disclose all outcomes with numerical % that sum to exactly 100 % before purchase**; rounding allowed with a disclaimer; a bare "(i)" icon is *not* enough — needs a labelled "Rates"/"Odds" button or inline list. Modifiers must show their numeric effect and update live. Once-only outcomes must be removed from the pool and odds re-stated.
- Every outcome must give some benefit (no "you lose" pulls). No playable gambling; no Robux/items wagered.
- **Regional opt-out:** call `PolicyService:GetPolicyInfoForPlayerAsync()`; if `ArePaidRandomItemsRestricted == true` you must hide/block the summon, or offer a fixed-order reveal, or sell specific outcomes at expected-value price, or an unpaid earnable path. Roblox does not publish the country list (policy is computed from region + age + platform). Belgium/Netherlands are widely assumed **[U]**; Korea drove a June 2026 global tightening and a per-country "block or replace with guaranteed purchase" switch ([TechTimes](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm)) **[S]**. Also honour `IsPaidItemTradingAllowed` if you add trading.
- Must be declared in the Maturity questionnaire ("Paid random items" descriptor). No age gate beyond PolicyService.
- **How TD games do it:** a "Rates" button next to Summon listing tiers (e.g. Rare 81.5 % / Epic 16 % / Legendary 2 % / Mythic 0.5 %) and visible pity counters ("Legendary pity 0/20", "Mythic 0/50") ([allthings.how](https://allthings.how/anime-expeditions-robloxs-upcoming-anime-tower-defense-game/), [UTDX](https://avergames.com/games/universal-tower-defense-x/summon-simulator/)) **[S]**.

**Codes.** No policy on redeem codes as such. Constraints: no off-platform links/handles *inside* the experience beyond what `AllowedExternalLinkReferences` returns (Discord never; page social links show only to 13+), and paid benefits may not require social-media tasks ([PolicyService guide](https://devforum.roblox.com/t/policyservice-guidelines/773321)) **[V/S]**. Free codes granting random rewards are exempt from odds disclosure.

**Passes vs Developer Products.** Game Pass = one-time permanent entitlement; Developer Product = repeatable consumable fulfilled via `ProcessReceipt`. Both pay **70 %** ([Earning on Roblox](https://create.roblox.com/docs/en-us/production/earning-on-roblox)) **[V]**.

**Experience Subscriptions.** Robux-priced (≥ 49 R$, any creator) or local-currency ($2.99–$14.99, ID/phone-verified; not sold in UAE, Türkiye, India). Creator gets 70 % (Robux) or 70 % month 1 / 100 % after (local). Max 50 per game, no mutually-exclusive tiers, same benefits on every platform; **season/battle passes may be sold as subscriptions** ([Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)) **[V]**.

**Immersive Ads.** Publisher: public experience, owner 13+, ID-verified + 2FA, approved questionnaire, ≥ 2,000 unique monthly visitors. Ads are served only to **users 13+**; hide units via `AreAdsAllowed` ([Immersive Ads](https://create.roblox.com/docs/en-us/production/monetization/immersive-ads), [2024 release](https://www.silicon.co.uk/press-release/roblox-expands-immersive-video-ads-access-to-all-advertisers-adds-new-measurement-partners)) **[V]**.

**Revenue / DevEx (Oct 2026).** **10,000 R$ → US$38 ($0.0038/R$)**, up 8.5 % from $0.0035 on 5 Sep 2025; minimum 30,000 earned Robux; 13+. From **8 Jun 2026** a **+42 % rate** applies to spend by age-checked US 18+ players in eligible R15 experiences ([Earning on Roblox](https://create.roblox.com/docs/en-us/production/earning-on-roblox), [Roblox newsroom](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42), [PocketGamer.biz](https://www.pocketgamer.biz/roblox-creators-will-now-earn-85-more-from-developer-exchange)) **[V/S]**. Effective take on a 70 % pass ≈ 26.6 % of the player's dollar **[S]**.

---

## 4. Trademark and names

**Is "باب الحارة" / "Bab al-Hara" registered?** Not confirmed. Searches found no WIPO/SAIP/EUIPO record either way, though MBC Group holds "many trademark registrations in Europe and… the Middle East" and runs a Licensing & Merchandising unit, and its MBC Game Studio (2025) now makes games ([WIPO D2012-2305](https://www.wipo.int/amc/en/domains/decisions/text/2012/d2012-2305.html), [Game Developer](https://www.gamedeveloper.com/business/saudi-owned-media-conglomerate-mbc-expands-into-the-game-industry)) **[U — run a WIPO Global Brand Database / SAIP / TMview search for "باب الحارة" and "Bab Al Hara", classes 9, 41]**. Even unregistered, a 20-year, pan-Arab famous title enjoys passing-off/well-known-mark protection in most MENA jurisdictions and the US; a Roblox trademark notice only needs a registration *somewhere*.

**What Roblox does with a series title in an experience name.** Nothing proactive for most titles, but a trademark notice gets the experience removed (appeal by email, no counter-notice), and for repeat big-brand cases Roblox has filtered the word platform-wide (Pokémon/Mario **[U]**). Titles that merely *describe* a genre survive; titles that *are* someone's brand get renamed (Skyblock → Islands).

| Option | Example | Risk |
|---|---|---|
| Use the title verbatim | "Bab Al-Hara Tower Defense" / "باب الحارة" | **High** — implies MBC endorsement; trademark notice = removal + strike; blocks any future licence talk |
| Variant spelling / translation | "Bab el-Hara TD", "Gate of the Alley" | **Medium–High** (confusingly similar) |
| Keyword in **description/tags** only, with disclaimer | "A tower defense inspired by classic Damascene hara dramas. Not affiliated with MBC." | **Low–Medium** — nominative/descriptive use; still avoid the exact title as a *tag* **[U]** |
| Original title using common nouns | **"Hara Defense"**, **"Haret Al-Yasmin"** (current project name), "Harat Dimashq TD" | **Low** — *hara* (neighbourhood) is generic Arabic |

**Character names.** "Abu Essam", "Abu Shehab" are kunyas — ordinary honorifics used by millions; a kunya alone is not protectable. Risk comes from the *combination*: same names + same roles + same looks + same catchphrases = copying the show's characters (protectable expression) and trading on its goodwill. Analogues: Football Fusion changed names + logos + uniforms and survived; Anime Vanguards alters a letter ("Gujo") and survives; Anime Adventures with true names fell. Recommendation: **kunyas not used by the show's principal cast** (Abu Jamil, Abu Nidal, Umm Zaki) on *generic* 1930s Damascus archetypes (za'eem, barber, baker, coffeehouse keeper — history, not MBC's), with no signature lines or costumes. Exact principal names: **Medium** legal risk, **High** reputational risk if MBC looks.

---

## 5. Safety / age

Target: **Minimal or Mild** label → eligible for Roblox Kids (5–8) and Select (9–15); **Moderate** → Select 9+ and 16+ only ([Content maturity](https://create.roblox.com/docs/en-us/production/promotion/content-maturity), [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines)) **[V]**.

- **Knives/daggers (shibriyya, swords, rifles).** Weapons are allowed; the label follows the *consequence*. Enemies that poof/ragdoll at 0 HP with no wounds or realistic blood = **Mild violence** (repeated is fine). Realistic injury, impalement or realistic blood ⇒ Moderate/Restricted. Cosmetic belt daggers are fine; torture/abuse is prohibited at every label.
- **Blood.** None, or unrealistic (pixel/colour-shifted) and fleeting, to stay Minimal/Mild.
- **Tobacco / argileh.** Community Standards prohibit depicting or promoting "tobacco, vaping and their associated paraphernalia" platform-wide; only alcohol has an 18+ carve-out, and a 2024 request to allow smoking in 17+ experiences went unmet ([Community Standards](https://about.roblox.com/en-au/community-standards), [DevForum](https://devforum.roblox.com/t/allow-smoking-tobacco-marijuana-usage-in-17-experiences/3121192)) **[V/S]**. **Drop argileh and cigarettes** (use tea, backgammon, prayer beads); the coffeehouse itself is fine. Arak ⇒ 18+: omit.
- **Religion / adhan.** No rule bans religious settings; religion is a *protected category* (no mocking), mosques exist on-platform, and the Aug 2025 "Sensitive issues" descriptor applies only to experiences *primarily themed* on a polarizing current issue — a background adhan or minaret is not that ([Sensitive Issues](https://devforum.roblox.com/t/updates-to-our-maturity-compliance-questionnaire/3860056), [RNS](https://religionnews.com/2025/10/17/roblox-says-it-is-investigating-anti-muslim-brain-rot-content-on-gaming-platform/)) **[V/S]**. Keep it ambient, non-interactive, never a combat cue, and don't use a specific muezzin's recording without licence.
- **Gambling.** Cards/backgammon fine without stakes; no playable gambling.
- **Kids (5–8) track** needs an age-checked creator with 2SV, a 250-play evaluation and a refundable fee or Roblox Plus/Premium; Select (9–15) is free ([Kids and Select](https://create.roblox.com/docs/en-us/production/publishing/kids-and-select)) **[V]**.

---

## Decisions

1. Title **"Haret Al-Yasmin"/"Hara Defense"**; "Bab al-Hara" never in title, icon or tags; description: "inspired by classic Damascus hara dramas — not affiliated with MBC".
2. Original kunyas, models and archetypes; no show quotes, logos, posters, footage.
3. No theme song; original maqam cue (commissioned or AI, provenance kept) or Creator Store Arabic tracks.
4. Labelled "Rates" panel (% summing to 100 %), live pity maths, `ArePaidRandomItemsRestricted` gate, questionnaire descriptor.
5. No tobacco/argileh/alcohol; stylized weapons, no realistic blood → Mild label.
6. Passes + Dev Products (70 %), season pass as Subscription, ads at ≥ 2k MAU; plan on $0.0038/R$.
7. WIPO/SAIP search for "باب الحارة" before marketing; per-asset entry in COPYRIGHT_REGISTER.
