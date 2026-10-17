# Non-Anime Roblox Tower Defense Games and TD Design Lessons (TDS, TTD, Tower Battles, Tower Heroes, UTD, FNTD, TDX, BTD6)

> Method note (read first): Research done 2026-10-17. The sandbox's egress proxy blocked direct page fetches (fandom, namu.wiki, bloonswiki, rolimons, guide sites all returned CONNECT 403). Every finding below therefore comes from **search-engine result summaries/snippets** of the cited pages, not full-page reads. Numbers are the ones the snippets reported; when snippets from different pages disagreed, both are given. Fan wikis and SEO guide sites (towerdefensesimulator.com, dungeonpath.com, tower-defense-simulator.wiki, earnaldo.com, etc.) are secondary, community-maintained sources. Treat exact stats as **approximate/version-dependent**. Live-service games rebalance often; dated items are flagged.

## 1. Tower Defense Simulator (TDS, Paradoxum Games): towers/roles, support logic, detection, enemy classes, modes, Hardcore, cash/skip, monetization, events, unlocks

### Takeaway
TDS is the non-anime genre leader on Roblox. It is built on **attribute-gated enemies** (Hidden, Lead, Flying, plus Shield/Stun-immunity on elite and boss enemies) that force **detection-aware loadouts** (5 tower slots). Its economy runs on a **Farm tower**, a fixed per-wave bonus split among players, and **vote skip**. Difficulty is a ladder of separate modes (Easy 20 waves → Intermediate 30 → Molten 35 → Fallen 40 → Hardcore 45/50 → Voidcore). Towers are unlocked through levels plus currency or Robux, not gacha. Crates sell **cosmetic skins**, and "Golden" skins add a gameplay perk.

### Cited Findings

**Scale and status (dated 2026)**
- RoWatcher reports an all-time peak of ~104K CCU on 2026-09-25 (during a "[NIGHT 1]" event-titled version) and ~4.63B lifetime visits. A snapshot from the same source showed 11K online with an 18K 7-day average. The page title is a variant listing that shares game ID 1176784616, so the figure is probable but not confirmed as the all-time record. — [RoWatcher](https://rowatcher.com/games/1176784616/night-1-tower-defense-simulator/dying); [RoWatcher main](https://rowatcher.com/games/1176784616/tower-defense-simulator)
- Profitable.app lists a peak CCU of 31.2K and 4.9B lifetime visits (Aug 29, 2026 snapshot). Its numbers do not match RoWatcher's. — [Profitable](https://profitable.app/roblox/games/tower-defense-simulator)
- Event-titled versions of the game page ("[NIGHT 1]", "[EVENT]", "[NEW BOSS]") show that Paradoxum puts the current live-ops beat in the game title as a discovery tactic. — [RoWatcher](https://rowatcher.com/games/1176784616); [Profitable](https://profitable.app/roblox/games/tower-defense-simulator)

**Difficulty ladder / modes and wave counts**
- Easy was shortened from 25 to 20 waves in a January 2026 update. — [NamuWiki Easy Mode (via search)](https://en.namu.wiki/w/Tower%20Defense%20Simulator/Easy%20Mode)
- Casual: an older source says 25 waves. No current figure was found. — [workshop.codes](https://workshop.codes/RWG8N)
- Intermediate: 30 waves, final boss Patient Zero. — [TDS wiki Intermediate](https://tds.fandom.com/wiki/Intermediate_Mode)
- Molten: 35 waves. — [TDS wiki Molten](https://tds.fandom.com/wiki/Molten_Mode)
- Fallen: unlocks after Molten, 40 waves, ends with the Fallen King. Base cash is the same as earlier modes, but upgrades cost more. — [DungeonPath Fallen guide](https://dungeonpath.com/posts/tower-defense-simulator/fallen-mode-guide/); [TDS wiki Fallen](https://tds.fandom.com/wiki/Fallen_Mode)
- Starting cash is $500 in Easy, Casual, Intermediate, Molten and Fallen, plus $100 for community-group members. A 2024 change made starting cash $500 regardless of player count. — [TDS wiki Waves](https://tds.fandom.com/wiki/Waves); [TDS wiki Molten](https://tds.fandom.com/wiki/Molten_Mode)
- Hardcore: requires Level 50. It is entered through dedicated Hardcore elevators or matchmaking. It rewards **Gems instead of Coins**, and beating it unlocks **Voidcore**. — [TDS wiki Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode); [towerdefensesimulator.com Hardcore guide](https://www.towerdefensesimulator.com/guides/hardcore-guide/)
- Hardcore wave count conflicts. The current wiki wave table ends at wave 45; waves 43 and 45 have no timer. Other pages describe 50 waves (the legacy version, with Void Reaver as the wave-50 boss). A fan revamp blog proposes 60 waves. — [TDS wiki Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode); [Legacy Hardcore rework blog](https://tds.fandom.com/wiki/User_blog:MrMosquito/Legacy_Hardcore_Mode_Rework)
- Current Hardcore uses wave-band music changes: waves 26–32 and 33–39 play "Ancient Dream" or "Broken Bastion", and waves 40–42 and 43–44 play "Fate Sealed Shut" or "Mauve Genocide". Enemies include VoidPike, VoidTitan and EliteMystery. — [TDS wiki Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode)
- Legacy Hardcore raised tower prices by 50% and capped lobbies at 3 players. — [NamuWiki Legacy Hardcore (via search)](https://en.namu.wiki/w/Tower%20Defense%20Simulator/Legacy%20Hardcore%20Mode)
- Hardcore player cap is 3 (solo/duo/trio). Starting cash reportedly scales down with team size: solo $900 ($1,000 with group bonus), duo $750 ($850), trio $600 ($700). A full run reportedly gives ~400 Gems, 400 XP and 350 Tower XP. These figures are from third-party guides and are uncertain. — [tower-defense-simulator.wiki Hardcore](https://tower-defense-simulator.wiki/modes/tower-defense-simulator-hardcore); [towerdefensesimulator.com](https://www.towerdefensesimulator.com/guides/hardcore-guide/)
- Public roadmap (third-party summary): PvP Season 1 is listed; "Golden mode", Community Gamemodes and a PvP mini-rework are planned for 2027. Status is unverified. — [tower-defense-simulator.wiki roadmap](https://tower-defense-simulator.wiki/updates/tower-defense-simulator-public-roadmap)

**Wave economy / skip / cash split**
- Wave-end bonus formula: **($325 + $50 × waves completed) ÷ number of players**. The legacy Hardcore used a different formula. — [TDS wiki Waves](https://tds.fandom.com/wiki/Waves)
- Each wave has a timer and a skip time. A skip prompt appears after a set time. Solo players skip instantly; in duos or larger groups, **all but one player must vote yes**. The vote UI shows a count (e.g., 0/2), and skipping can stack hordes. — [TDS wiki Waves](https://tds.fandom.com/wiki/Waves); [TDS wiki How to Play](https://tds.fandom.com/wiki/How_to_Play)
- Enemy kill cash is split among players regardless of who dealt the damage: 100% solo, 50% duo, 33% trio, 25% quad (Fallen; Intermediate and Frost likewise). — [TDS wiki Fallen](https://tds.fandom.com/wiki/Fallen_Mode); [TDS wiki Intermediate](https://tds.fandom.com/wiki/Intermediate_Mode); [tower-defense-simulator.wiki Frost](https://tower-defense-simulator.wiki/modes/tower-defense-simulator-frost-mode)
- Total tower caps by team size: 40 solo, 30 duo, 25 trio, 20 quad. — [TDS wiki How to Play](https://tds.fandom.com/wiki/How_to_Play)

**Tower roles: economy and support**
- **Farm (economy):** $60/wave at Lv0. Income at Lv1–5 is $100, $225, $500, $900, $1,500 per wave. Upgrade costs are Lv0 $300 (placement), Lv1 $200, Lv2 $600, Lv3 $1,250, Lv4 $2,500, Lv5 $4,500, for $9,350 total to max. Store unlock is 2,000 coins. — [towerdefensesimulator.com Farm](https://www.towerdefensesimulator.com/towers/farm/); [NamuWiki Farm (via search)](https://en.namu.wiki/w/Farm(Tower%20Defense%20Simulator))
  - Other numbers exist (e.g., 150/350/750 per wave, 400 base) that likely come from older versions. — [DungeonPath](https://dungeonpath.com/posts/tower-defense-simulator/beginner-guide/)
- Farm placement limit: 10 per player in regular modes, 8 in PvP. A January 2026 change raised the regular limit to 12. — [TDS wiki Farm](https://tds.fandom.com/wiki/Farm)
- **DJ Booth (support):** three selectable tracks.
  - Purple: +12.5% range at Lv0, scaling to 25%. It is on by default.
  - Green: 5% discount on towers, scaling to 15%.
  - Red: unlocks at Lv2, +10% damage scaling to 20%.
  - One guide says that at Lv5 all passive buffs apply regardless of track, with the active track strongest. This is a secondary source. — [TDS wiki DJ Booth](https://tds.fandom.com/wiki/DJ_Booth); [earnaldo tier list](https://earnaldo.com/blog/tower-defense-simulator-tier-list-2026)
- **Commander (support):** a passive fire-rate buff (cooldown cut) of 10% scaling to 20% for towers in range. Its active "Call to Arms" stacks a further 10–20% for 10 seconds. One strategy guide's "40%" figure conflicts with this. — [TDS wiki Commander](https://tds.fandom.com/wiki/Commander); [towerdefensesimulatorroblox.wiki combos](https://towerdefensesimulatorroblox.wiki/strategy/best-tower-combos/)
- **Cliff vs ground placement:** Mortar is **cliff-only** artillery. The limit is 4 per player (5 in PvP). Its unlock is Level 75 plus Robux; the price conflicts across sources: 300, 395, or 750 Robux (older). It is weak on maps with few cliffs. Guides recommend placing it at U-turns so slow shells still land in the pack, and say its slow fire rate makes it poor against bosses but good on minions. — [TDS wiki Mortar](https://tds.fandom.com/wiki/Mortar); [towerdefensesimulator.com Mortar](https://www.towerdefensesimulator.com/towers/mortar/); [TDS Category:Cliff](https://tds.fandom.com/wiki/Category:Cliff)
- Map examples: Toyboard puts cliff spots on card towers and Lego blocks and has winding paths. Cyber City has many cliffs plus room for ground towers. Grass Isle is poor for cliff towers. — [bloxodes tier list](https://bloxodes.com/articles/tower-defense-simulator-best-towers-tier-list); [NamuWiki TDS Map (via search)](https://en.namu.wiki/w/Tower%20Defense%20Simulator/%EB%A7%B5)
- **New tower unlock model, Enforcer (v2.6.0, Aug 14, 2026):**
  - Players raise the base Shotgunner to "evolution" Level 20 by earning XP on it (20 levels, base XP 50, growth 1.09), or skip that for 499 Robux. They then buy Enforcer for 4,750 Gems + 15,000 Coins.
  - Enforcer stats: placement $3,000, limit 5, Lead detection at Lv0, Hidden at Lv2. Its Lv2 flashbang stuns all enemies in radius except bosses and stun-immune enemies.
  - At Lv5 it forks into two paths: an auto-shotgun whose helicopter repositions your towers, or a pump shotgun that summons an exploding SWAT van.
  - The base Shotgunner has a 9-per-player cap, which is removed in PvP. — [Stealthy Gaming](https://stealthygaming.com/tower-defense-simulator-enforcer-tower-update/); [TDS wiki Shotgunner](https://tds.fandom.com/wiki/Shotgunner)

**Enemy attributes and detection**
- **Hidden:** towers need hidden detection to target these enemies. Towers without it can still hurt them **indirectly** (explosions, collisions). Examples: Scout gets detection at Lv2+, Paintballer at Lv1+. — [TDS wiki Hidden](https://tds.fandom.com/wiki/Hidden_(Attribute))
- **Lead:** only towers with lead detection can damage these enemies. Examples include Sniper, Demoman and Freezer at various levels. — [TDS wiki Lead](https://tds.fandom.com/wiki/Lead_(Attribute))
- **Elite Lead** (Hardcore/Voidcore) keeps Lead and stun immunity until its separate **shield HP** is depleted, then loses both. This is a two-stage "armor break" design. — [TDS wiki Elite Lead](https://tds.fandom.com/wiki/Elite_Lead)
- **Flying:** towers need flying detection. Counters are cliff and air towers plus some ground towers (Militant, Executioner, Engineer). — [TDS wiki Flying](https://tds.fandom.com/wiki/Flying)
- A general "Shield" status effect is listed as removed on the wiki, which suggests shields now live on specific enemies rather than as a generic status. — [TDS wiki](https://tds.fandom.com/wiki/Tower_Defense_Simulator_Wiki)

**Boss design (Fallen King example)**
- Abilities: summons Fallen minions, a stomp that stuns towers, a sword spin that stuns nearby towers (legacy: also 500 damage to units), and a thunderstorm. — [villains wiki](https://villains.fandom.com/wiki/Fallen_King_(Tower_Defense_Simulator)); [TDS Legacy wiki](https://tds-legacy.fandom.com/wiki/Fallen_King)
- Phase threshold (legacy): at 75,000 HP it enters Rage Mode. It moves faster, stuns more often, gains a 15,000-HP shield and spawns 3 Fallen Guardians. — [TDS Legacy wiki](https://tds-legacy.fandom.com/wiki/Fallen_King)
- The Hidden Wave form, **Awakened Fallen King**, is the second and later third phase with more HP and abilities. This is a secret extended boss. — [TDS wiki Awakened Fallen King](https://tds.fandom.com/wiki/Awakened_Fallen_King)
- HP conflict: 150,000 (legacy wiki) vs 250,000 (2026 guide). It is stun-immune, and a shield ability blocks all damage. — [towerdefensesimulator.com Fallen guide](https://www.towerdefensesimulator.com/guides/fallen-mode-guide/)

**Monetization: crates/skins/gold**
- Crates can be bought with Coins, Robux or event currencies (e.g., Shards). — [TDS wiki Crates](https://tds.fandom.com/wiki/Crates)
- The **Golden Crate** costs 50,000 coins and is the most expensive coin item. It grants one of 7 Golden skins (another source says 6), each with a **Golden Perk** that makes the tower much stronger but usually more expensive. This is a soft pay/grind-to-power layer that still sits inside the tower economy. — [TDS wiki Golden Crate](https://tds.fandom.com/wiki/Golden_Crate); [shapes.inc](https://shapes.inc/fandom/tower-defense-simulator/skins-and-crates)
- Deluxe Crate ~200 Robux (wiki). The daily skin store sells Common skins at ~255 Robux up to Legendary at ~560 Robux. The Premium Crate is Robux-only. Event crates (Bunny, Spooky) are not sold after their event. — [TDS wiki Deluxe Crate](https://tds.fandom.com/wiki/Deluxe_Crate); [NamuWiki skin box (via search)](https://en.namu.wiki/w/Tower%20Defense%20Simulator/%EC%8A%A4%ED%82%A8%20%EC%83%81%EC%9E%90)
- Parental guide: many high-tier towers can be bought instantly with Robux, some at 2,500+ Robux. It describes the grind as pressure to spend. This is a single secondary source. — [Screenwise](https://screenwiseapp.com/guides/tower-defense-simulator-roblox)

**Events / live ops**
- **Hexscape (Halloween 2024):** a 3-night event with 2 limited-time event towers and a battle pass. The pass reportedly ran Oct 23 – Dec 2, 2024 (sources conflict on Oct 23 vs Oct 24). Its story is about a cult freeing "Lord EXO", and the ending teased the Frost Spirit's return. — [Paradoxum on X](https://x.com/paradoxum_games/status/1849165104773816616); [TDS wiki Hexscape](https://tds.fandom.com/wiki/Hexscape_Event)
- Seasonal passes ran back-to-back: Halloween Season pass Oct 31, 2020 – May 8, 2021, then Frost Invasion pass May 8 – Dec 4, 2021. — [TDS wiki Passes](https://tds.fandom.com/wiki/Passes); [tds.wiki Passes](https://tds.wiki/w/Passes)
- A third-party site tracks a "Frost Champion countdown" and event schedule in 2026, which shows the event cadence continues. — [allthings.how](https://allthings.how/tower-defense-simulator-events-schedule/)

### Inferences
- TDS's core design lesson: **enemy attributes are loadout checks, not just stat checks.** With 5 slots, every mode forces you to cover Hidden, Lead and Flying (plus a boss-DPS tower and an economy tower). That creates strategic tension that pure-DPS anime TDs often lack.
- Elite Lead's "shield, then lose Lead and stun immunity" is a strong pattern: a mixed team must first break the shield before cheap DPS works.
- Four mechanisms keep the economy fair in co-op and prevent kill-stealing: the wave bonus scales up linearly and is divided by player count, kill cash is split evenly, Farms have a hard cap, and total tower caps fall as team size grows.
- The Enforcer "evolve your base tower" unlock (play-time XP on a tower, with a Robux skip) is a newer, softer monetization than gacha. It rewards using a tower and still sells time-skips.
- Wave counts (20→45) plus mode-specific music and boss finales give clear pacing anchors.

### Gaps
- The current full tower list (~60+ towers) with exact roles was not retrievable; only Farm, DJ, Commander, Mortar, Shotgunner/Enforcer, Scout, Paintballer and the detection towers above are confirmed.
- Exact current Hardcore wave count (45 vs 50), tower-price modifier and elite enemy list are unconfirmed.
- No reliable data on AFK kick rules, PvP mode rules or Voidcore details.
- Gold tower list and current Golden Crate composition conflict (6 vs 7).
- Wave HP/enemy-count tables could not be retrieved, so no HP-scaling curve is available for TDS.

## 2. Toilet Tower Defense (TTD, Telanthric Development): crate gacha, trading/inflation, upgrades, endless, peak and decline

### Takeaway
TTD rode the Skibidi Toilet meme to an all-time peak of **~522K CCU (March 9, 2024)**. It turned a simple TD into a **crate-gacha plus player-trading economy** priced in gems, with ultra-rare odds (Godly 0.01–0.15%, Ultimate 0.0001%) and 1% "Shiny" mutations. Its decline matches the fading meme, scams and volatile values, and a thin core loop. Telanthric shipped a **"Legacy Update" (the 97th and announced final update) on May 2–3, 2026**. Recent CCU is ~4–6K.

### Cited Findings
- Origin: based on the Skibidi Toilet meme. It was taken down Sept 22, 2023 over copyright and returned Oct 9, 2023. It had 5.9B+ visits as of July 2025. — [Roblox wiki](https://roblox.fandom.com/wiki/Telanthric_Development/Toilet_Tower_Defense)
- All-time peak: **522,376 CCU on March 9, 2024** (Rolimons "[LEGACY]" listing). The same listing showed ~5,153 current players and a 7,353 peak over the past 30 days. — [Rolimons](https://www.rolimons.com/game/13775256536)
- RoCodes showed ~3.9K players on Sept 30, 2026 and described the trend as downward. — [RoCodes](https://rocodes.gg/codes/toilet-tower-defense)
- A 2026 comparison blog says the game still regularly hits tens of thousands of CCU. This conflicts with the trackers above, so treat it as unreliable. — [earnaldo](https://earnaldo.com/blog/tower-defense-simulator-vs-toilet-tower-defense)
- **Legacy Update:** dated May 2, 2026 (fandom) or May 3, 2026 (NamuWiki). It is called the 97th and last update. CCU on release was reported as 40K (fandom) vs 20K+ (NamuWiki). The Legacy Lobby uses a **separate save file**: coins, gems, units and wins do not carry over, but gamepasses do. The developer's TikTok calls it "the FINAL UPDATE". No successor was found. — [TTD wiki Legacy Update](https://toilet-tower-defense-game.fandom.com/wiki/Legacy_Update); [NamuWiki (via search)](https://en.namu.wiki/w/Toilet%20Tower%20Defense); [Telanthric TikTok](https://www.tiktok.com/@telanthric_yt/video/7635154552173464862)
- Why it grew: guides credit the meme's viral reach ("riding the Skibidi Toilet wave", popular with Gen Alpha) plus a "surprisingly deep unit-collection and trading economy". — [towersdefense.org](https://towersdefense.org/articles/best-roblox-tower-defense-games); [Sportskeeda](https://sportskeeda.com/roblox-news/roblox-toilet-tower-defense-how-play-features)
- Criticism (opinion video): heavy microtransactions, lazy animations, gambling, boring gameplay, few features beyond the core loop. — [YouTube "Why Toilet Tower Defense Is DONE.."](https://www.youtube.com/watch?v=5ILng_1KfZM)
- **Crates:**
  - Basic Crate costs 100 coins for one pull or 900 for 10 (10-for-9). Odds: Godly 0.01%, Mythic 0.1%.
  - Mythic Crate costs 1,200 coins or 10,800 for 10. Listed odds: Godly 0.15% (0.148% actual), Mythic 1.5%, Legendary 10% (8.35% actual).
  - Ultimate tier: 0.0001% from the Basic Crate.
  - A luck gamepass and boosts raise Mythic/Godly odds (e.g., 0.2%/0.02% with one boost, 0.31%/0.031% with both).
  - Each unit has a 1% chance to roll "Shiny".
  - Exclusive crates sold for Robux; e.g., the Exclusive Scientist Crate cost 199 / 499 / 1,499 Robux for 1 / 3 / 10 (possibly outdated).
  - Later rarities such as "Celestial" were added. — [TTD wiki Crates](https://toilet-tower-defense-game.fandom.com/wiki/Crates); [TTD wiki Mythic Crate](https://toilet-tower-defense-game.fandom.com/wiki/Mythic_Crate); [TTD wiki Rarity](https://toilet-tower-defense-game.fandom.com/wiki/Rarity); [TTD wiki Summoning](https://toilet-tower-defense-game.fandom.com/wiki/Summoning)
- **Trading economy:**
  - Values are expressed in gems. Examples: Telanthric Titan at 3.80B gems (top unit); Upgraded Titan Clockman ~1.25M gems; Corrupted Cameraman ~39K gems; Scientist Crate ~800–1,000 gems.
  - TradingKeep tracked 461 items as of Aug 2026. — [game.guide](https://www.game.guide/toilet-tower-defense-value-list); [Calm Stretch](https://calmstretch.com/toilet-tower-defense-value-list/); [TradingKeep](https://www.tradingkeep.com/g/toilettowerdefense/values)
  - There is no official pricing; values are set by trading servers, Discord groups and player perception.
  - Updates, YouTuber showcases and buffs cause spikes, followed by crashes after the hype.
  - Units removed from crates rise in value as supply shrinks.
  - A "rare" unit made obtainable again drops quickly, and updates that flood the market with new units cause temporary crashes. — [RPGStash value list 2026](https://www.rpgstash.com/blog/updated-toilet-tower-defense-value-list-2026); [VCGamers](https://www.vcgamers.com/news/en/latest-tower-defense-toilet-value-list-2/)
  - The value wiki calls the market "unstable", with commons selling at widely varying prices. — [TTD wiki Values](https://toilet-tower-defense-game.fandom.com/wiki/Values)
  - A secondary Robux-trading market exists: third-party sites sell TTD units for real money. — [RPGStash store](https://www.rpgstash.com/roblox-store/toilet-tower-defense-telanthric-toilet-tower-defense-item-607.html)
- **Scams:**
  - Players were scammed with fake "timing trick" trades, fake "Signing Units" partner tags and a "-0" gem-count trick. Players felt reporting was useless (Feb 2024 forum).
  - A parental guide calls the Trading Plaza a scam hotspot and says the gacha "mimics gambling loops". — [TTD wiki Trading](https://toilet-tower-defense-game.fandom.com/wiki/Trading); [TTD forum post](https://toilet-tower-defense-game.fandom.com/f/p/4400000000000026424/r/4400000000000077024); [Screenwise](https://screenwiseapp.com/media/skibidi-toilet-tower-defense-game)
- Retention features: the Rewards Update (Sept 21, 2024) added daily and playtime rewards, new units and balance changes. A PvP update and a "Rewind" event also existed. — [Sportskeeda Rewards](https://sportskeeda.com/roblox-news/toilet-tower-defense-rewards-update-daily-rewards-toilet-man); [Sportskeeda PvP](https://www.sportskeeda.com/roblox-news/toilet-tower-defense-pvp-update-patch-notes); [Sportskeeda Rewind](https://sportskeeda.com/roblox-news/news-toilet-tower-defense-rewind-event)
- Endless mode exists ("beat waves to win or survive in Endless Mode"), but no design history was found. — [Rolimons](https://www.rolimons.com/game/13775256536)
- Over 40 units across rarity tiers, with Titan-class at the top. — [earnaldo](https://earnaldo.com/blog/tower-defense-simulator-vs-toilet-tower-defense)

### Inferences
- The TTD curve, from ~522K to ~4K in about 2.5 years, shows that **meme IP drives acquisition but not retention**. Once the meme faded, a shallow TD loop could not hold players, and the gacha-and-trade economy was the main reason left to log in.
- Very low top-tier odds plus tradability turn units into speculative assets. That drives engagement and Robux spending but invites scams, gray-market Robux sales, and "power creep equals value crash" whiplash for every new release.
- The game had to restart its economy with a separate-save "Legacy" lobby, a sign that the inflated economy could not be fixed in place. A new game should plan sinks (fusion, crate-retirement schedules, untradable event units) from day one.

### Gaps
- No primary data on TTD's upgrade system (per-unit upgrade levels and costs) or enemy and wave design.
- No developer postmortem found. Decline reasons are inferred from trackers and commentary.
- No confirmed data on dupes or exploits; one "HACKED?!" video exists but gave no detail.

## 3. Other notable non-anime Roblox TDs (Tower Battles, Tower Heroes, Ultimate Tower Defense, Five Nights TD, Tower Defense X)

### Takeaway
The other notable non-anime TDs split into three groups. **Competitive/versus-first** games: Tower Battles has 1v1–4v4 Versus, and wins come only from Versus. **Casual/collectible** games: Tower Heroes uses easy/medium/hard difficulty and badges. **Gacha-plus-trading** games: UTD (with merging and PvP) and FNTD (values priced in "souls"). TDX is notable as a **no-gacha** TD holding ~25K CCU in 2026.

### Cited Findings
- **Tower Battles:** the two main modes are Versus (1v1, 2v2, 3v3; 4v4 requires 50 wins) and Survival. Wins come only from Versus. — [Tower Battles wiki Versus](https://roblox-tower-battles.fandom.com/wiki/Versus); [Tower Battles wiki Survival](https://roblox-tower-battles.fandom.com/wiki/Survival)
- Tower Battles' **Venus** map is a short 150-stud map, Survival-only. It was (dated claim) the only map with intersecting paths, which suggests short or intersecting paths are kept out of competitive play for balance. — [Tower Battles wiki Venus](https://roblox-tower-battles.fandom.com/wiki/Venus)
- **Tower Heroes** (Pixel-bit Studio): difficulty is chosen as easy, medium or hard (another source mentions "Casual" and "Challenge" modes). Badges reward map-difficulty clears (e.g., Outdoors Hard → "Truer Tower Hero"). No Hardcore mode was confirmed. — [Roblox wiki Tower Heroes](https://roblox.fandom.com/wiki/Pixel-bit_Studio/Tower_Heroes); [towerheroes.wiki](https://towerheroes.wiki/maps/outdoors-hard-mode/); [RobloxDen](https://robloxden.com/game-codes/tower-heroes)
- **Ultimate Tower Defense:** its official listing advertises a trading system, PvP and **tower merging**. The wiki tags items as tradable or untradable. — [Roblox UTD page](https://www.roblox.com/games/5902977746/Ultimate-Tower-Defense); [UTD wiki](https://ultimate-tower-defense.fandom.com/wiki/Ultimate_Tower_Defense_Wiki)
- **Five Nights TD (FNAF-themed):** gacha determines which endgame units you get. Trading is called the best route to strong units, alongside quests and clans. Values are priced in "souls" and swing widely: e.g., Valkyrie Prime was 50–60K souls in Jan 2025 vs 200–250K in Jun 2025, and Titan Crusher Freddy 80–120K. — [PocketGamer](https://www.pocketgamer.com/roblox/five-nights-td-tier-list/); [ProGameGuides](https://progameguides.com/roblox/five-nights-td-trading-value-list-roblox/); [CND8](https://cnd8.com/news/five-nights-td-trading-value-list-roblox)
- **Tower Defense X (TDX):** 30-day peak 26,207 and 7-day peak 25,530 (Oct 2026); all-time 36,266 (Nov 2023); still labeled beta. Zombie theme, co-op and boss fights. **No gacha.** Top towers include "Golden" variants (Golden Mobster, Golden Juggernaut), echoing TDS's gold-tier concept. — [adellion.com](https://adellion.com/roblox-tower-defense); [Power Up Gaming](https://powerupgaming.co.uk/2025/10/20/tower-defense-x-tier-list-best-towers-ranked/)

### Inferences
- The market supports both business models. TDS and TDX sustain tens of thousands of CCU **without unit gacha**, by selling skins, unlock skips and passes. Gacha-and-trade games (TTD, FNTD, UTD) spike higher but suffer value volatility.
- A versus mode whose wins gate progression (Tower Battles) can anchor a competitive niche, but it needs map vetting (no very short or intersecting paths).

### Gaps
- No "Pixel Tower Defense" or other 2025–26 breakout non-anime TD was confirmed beyond TDX and FNTD; search did not surface reliable stats.
- Tower Battles' current status/CCU, Tower Heroes' current CCU and UTD's current activity were not found.

## 4. Best-practice wave/difficulty design: DPS checks, HP scaling, boss telegraphing, 15–30 min matches

### Takeaway
The benchmark pattern across TDS, BTD6 and Kingdom Rush:
- A difficulty curve that ramps through **new enemy properties introduced at fixed waves** (detection checks), with periodic **spike waves** followed by breathers.
- **Boss finales with HP-threshold phases** (skulls/rage at X HP) that spawn minions or stun towers.
- Increasingly **exponential HP late** (BTD6 health ramping after round 80; freeplay).
- Match length controlled by wave count per difficulty (20–45 waves) plus wave timers and vote skip.

### Cited Findings
- Kingdom Rush review: the genre's "obligatory difficulty spike" usually arrives as one wave twice the size of the previous one. Boss stages play as regular stages "up until the last three waves, where all Hell breaks loose". — [LoadLastSave Substack](https://loadlastsave.substack.com/p/talking-about-tower-defense-games)
- A gradual curve can be created by **limiting the player's toolset early** (GemCraft: 2–3 gem colors at first, more added over stages). — [LoadLastSave](https://loadlastsave.substack.com/p/talking-about-tower-defense-games)
- Kingdom Rush 5 review: spawn logic, enemy stats, gold economy and tower progression work together as the difficulty levers. Calling waves early can backfire even on easy. — [The Nerd Stash](https://thenerdstash.com/kingdom-rush-5-alliance-td-review-rushed-to-battle/)
- Player opinion (not a standard): an early spike followed by a linear rise feels bad; "the ideal difficulty curve for a tower defense is exponential". — [itch.io post](https://itch.io/post/12563138)
- TDS timers: every wave has a time limit and a skip time, and the final boss waves (43, 45 in Hardcore) have **no time limit**, so the boss fight cannot be skipped into. — [TDS wiki Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode)
- TDS telegraphs late-game phases with mode-specific music that changes by wave band (waves 26–32, 33–39, 40–42, 43–44). — [TDS wiki Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode)
- TDS boss phase design: Fallen King triggers Rage at 75K HP (faster, more stuns, a 15K shield, 3 Guardian summons). It is stun-immune with a damage-blocking shield. A hidden wave continues to a second and third phase (Awakened Fallen King). — [TDS Legacy wiki](https://tds-legacy.fandom.com/wiki/Fallen_King); [TDS wiki Awakened FK](https://tds.fandom.com/wiki/Awakened_Fallen_King)
- BTD6 HP scaling: MOAB-class health rises each round after round 81. Example: a round-100 BAD has an effective RBE of 67,200, and takes 28,000 hits on natural rounds vs 20,000 base. Freeplay "slowly advances health and speed every round", and bloons get progressively faster after the first ZOMG (round 80). — [Bloons wiki BAD](https://bloons.fandom.com/wiki/Big_Airship_of_Doom_(BAD)); [Bloons wiki Bloon Speed](https://bloons.fandom.com/wiki/Bloon_Speed); [Bloonswiki BAD](https://www.bloonswiki.com/BAD_(BTD6))
- BTD6 mixed "exam" round: round 95 = 500 Camo Regrow Purples + 250 Camo Regrow Fortified Leads + 50 Fortified MOABs + 30 DDTs. One round tests camo, lead, purple (energy-resistant), regrow (burst DPS) and blimp DPS at once. — [Bloons wiki Fortified Camo Regrow Bloon](https://bloons.fandom.com/wiki/Fortified_Camo_Regrow_Bloon)
- BTD6 introduces properties at milestones: MOAB first appears round 40, ZOMG round 80, BAD round 100. Mixed rounds like 50 (MOABs + Fortified Leads + Reds + Ceramics) test single-target and AoE together. — [Bloonswiki MOAB](https://www.bloonswiki.com/MOAB_(BTD6)); [Bloonswiki ZOMG](https://www.bloonswiki.com/ZOMG_(BTD6)); [Bloonswiki Rounds](https://www.bloonswiki.com/Rounds_(BTD6))
- A public dataset of BTD6 rounds 1–140 exists for modeling HP/RBE curves. — [Kaggle](https://www.kaggle.com/datasets/brandonconrady/bloons-tower-defense-6-rounds-1140/data)

### Inferences
- **Recommended structure for a 15–30 min Roblox TD match** (inferred from TDS wave counts and timers):
  - Wave count: 20–30 waves for normal modes, 35–45 for hard.
  - Pacing: ~30–60 s average per wave with vote skip.
  - Untimed final boss wave.
  - TDS's Easy cut from 25 to 20 waves in Jan 2026 suggests the developer shortened early modes for session length.
- **DPS-check cadence:**
  - Introduce one new attribute every ~5–8 waves: Hidden, then Lead, then Flying, then shielded/elite.
  - Put a mid-boss at roughly 50–60% of the run.
  - Put a combined "exam wave" two to three waves before the final boss.
  - Make the boss phase-based on HP thresholds, adding minion spawns and tower-stun abilities. Boss stun immunity keeps crowd control from trivializing the fight.
- **Telegraphing:** music changes by wave band, a boss HP bar with visible phase markers (BTD6 "skulls"), and enemy-preview UIs. Disabling skip on boss waves stops players from accidentally stacking a boss onto the previous wave.
- HP scaling: roughly linear-to-quadratic through normal waves, then a multiplicative ramp after the "end" round (BTD6 round 80+) for endless/freeplay.

### Gaps
- No GDC talk specifically on TD wave pacing was found; GDC Vault was not reachable via search.
- No TDS-specific per-wave HP tables were obtained, so no exact HP-scaling formula for TDS.
- The BTD6 freeplay ramp percentage per round was not retrieved.

## 5. Co-op design: cash split, per-player placement limits, voting, AFK

### Takeaway
TDS's co-op model is the clearest reference:
- **Kill cash split evenly among all players**, regardless of who dealt damage (100/50/33/25%).
- **Wave bonus divided by player count.**
- **Per-player tower caps that shrink as the team grows** (40/30/25/20).
- **Per-tower per-player limits** (Farm 12, Mortar 4, Enforcer 5).
- **Vote skip** that needs all-but-one yes.
- Harder modes cap lobby size (Hardcore 3) and scale starting cash down per player.

### Cited Findings
- Kill cash is split evenly regardless of who dealt the damage: solo 100%, duo 50%, trio 33%, quad 25%. — [TDS wiki Fallen](https://tds.fandom.com/wiki/Fallen_Mode)
- Wave bonus = ($325 + $50 × waves completed) ÷ players. — [TDS wiki Waves](https://tds.fandom.com/wiki/Waves)
- Total tower caps: 40 solo, 30 duo, 25 trio, 20 quad. — [TDS wiki How to Play](https://tds.fandom.com/wiki/How_to_Play)
- Per-tower limits are per player and differ in PvP: Farm 10→12 (Jan 2026) regular, 8 PvP; Mortar 4 (5 PvP); Shotgunner 9 (none in PvP); Enforcer 5. — [TDS wiki Farm](https://tds.fandom.com/wiki/Farm); [TDS wiki Mortar](https://tds.fandom.com/wiki/Mortar); [TDS wiki Shotgunner](https://tds.fandom.com/wiki/Shotgunner); [Stealthy Gaming](https://stealthygaming.com/tower-defense-simulator-enforcer-tower-update/)
- Vote skip: solo skips instantly; in groups all but one player must vote yes. The UI shows a vote counter. — [TDS wiki Waves](https://tds.fandom.com/wiki/Waves); [TDS wiki How to Play](https://tds.fandom.com/wiki/How_to_Play)
- Support towers buff **all towers in range**, including teammates' (Commander fire rate, DJ range/discount/damage). This enables a dedicated support role in co-op. — [TDS wiki DJ Booth](https://tds.fandom.com/wiki/DJ_Booth); [TDS wiki Commander](https://tds.fandom.com/wiki/Commander)
- Hardcore: 3-player cap. Starting cash per player falls with team size (900/750/600; uncertain third-party data). — [tower-defense-simulator.wiki](https://tower-defense-simulator.wiki/modes/tower-defense-simulator-hardcore)
- In 2024, starting cash became a flat $500 regardless of player count in normal modes. — [TDS wiki Molten](https://tds.fandom.com/wiki/Molten_Mode)

### Inferences
- Splitting cash evenly regardless of damage removes kill-stealing and lets roles specialize (one player farms, one supports, one carries DPS).
- Shrinking per-player caps keep total board density roughly constant (40 solo vs 80 in a quad) so maps don't become cluttered or lag. That matters on Roblox's mobile-heavy audience.
- "All-but-one" voting stops a single AFK player from blocking skips. A design blueprint should add idle detection that counts AFK players as abstaining, plus a reconnect window that keeps their towers alive (not confirmed for TDS).

### Gaps
- No source on TDS AFK handling: idle kick, tower handover, or what happens to a leaver's towers and cash.
- No confirmed info on whether cash can be gifted or transferred between players in TDS.

## 6. Bloons TD 6 lessons: upgrade paths/crosspaths, MOAB-class, camo/lead/purple/fortified, boss events

### Takeaway
BTD6's enduring lessons:
- **Upgrade design:** 3 paths × 5 tiers with a crosspath restriction (one path to tier 5, a second to tier 2, the third locked; e.g., 5-2-0). This creates build identity from one tower.
- **Damage-type-vs-property counters:** lead is immune to sharp, purple resists energy/fire/plasma, camo needs detection, regrow punishes slow DPS.
- **Fortified as a multiplier modifier.**
- **MOAB-class blimps that "pop open" into children.**
- **Boss events with skull HP thresholds and Elite variants.**

### Cited Findings
- Crosspath notation counts the upgrade tiers bought on each of the 3 paths. Choices are build-dependent: Bloon Crush is best 5-2-0 (attack speed gives reliable stuns), while Bloon Solver prefers 5-0-2. Rare exceptions (Paragons, Wizard Lord) break the rule. — [Bloons wiki Crosspathing](https://bloons.fandom.com/wiki/Crosspathing/Engineer_Monkey); [Bloonswiki Bloon Crush](https://www.bloonswiki.com/Bloon_Crush_(BTD6)); [KosGames](https://kosgames.com/bloons-td-6-best-crosspath-tier-5-tower-15974/)
- **Properties:**
  - **Camo:** ignored by towers without camo detection. Detection can be granted to nearby towers by support upgrades such as Sonar Beacon and Crow's Nest.
  - **Lead:** immune to sharp damage; must be blown up or melted.
  - **Purple:** resists energy, fire and plasma.
  - **Regrow:** heals if left undamaged.
  - **Fortified:** applies to Lead, Golden, Ceramic and MOAB-class; Fortified Lead has +3 HP (26 RBE). — [Bloons wiki Bloon Properties](https://bloons.fandom.com/wiki/Bloon_Properties); [Bloons wiki Camo](https://bloons.fandom.com/wiki/Camo_Bloon); [Bloons wiki Lead](https://bloons.fandom.com/wiki/Lead_Bloon); [Bloons wiki Fortified](https://bloons.fandom.com/wiki/Fortified_Bloon)
- Fortified doubles MOAB-class durability. — [Bloonswiki Fortified](https://www.bloonswiki.com/Fortified_Bloon_(BTD6))
- MOAB-class bloons cannot inherit Camo/Regrow unless naturally camo. The DDT is natively camo, a dedicated "stealth blimp" that tests detection at blimp scale. — [Bloonswiki Camo](https://www.bloonswiki.com/Camo_Bloon_(BTD6))
- **MOAB-class stats:**
  - **MOAB:** 200 HP, first appears round 40, releases 4 Ceramics. Easy mode reduces round-40 MOAB HP (one source: 133).
  - **BFB:** 700 HP per Fandom (an itch comment says 600; unreliable).
  - **ZOMG:** 4,000 HP (8,000 fortified), RBE 16,656, round 80.
  - **DDT:** 400 HP; faster than other blimps.
  - **BAD:** 20,000 HP (40,000 fortified), RBE 55,760, round 100.
  - **Speed:** ZOMG and BAD move at 0.18× red-bloon speed. — [Bloonswiki MOAB](https://www.bloonswiki.com/MOAB_(BTD6)); [Bloons wiki Bloon Health](https://bloons.fandom.com/wiki/Bloon_Health); [Bloonswiki ZOMG](https://www.bloonswiki.com/ZOMG_(BTD6)); [Bloonswiki BAD](https://www.bloonswiki.com/BAD_(BTD6)); [Bloons wiki Bloon Speed](https://bloons.fandom.com/wiki/Bloon_Speed)
- Counter guidance: high-DPS camo-detecting towers, or the Monkey Intelligence Bureau (MIB), which grants all bloon-property damage. One Radar Bomb or Flash Bomb is not enough vs Fortified Leads. — [Bloons wiki Fortified Camo Regrow](https://bloons.fandom.com/wiki/Fortified_Camo_Regrow_Bloon)
- **Boss events:**
  - **Bloonarius:** spawns bloons when it loses set HP chunks; 3 skulls Normal, 7 Elite; Tier 1 has 50,000 HP.
  - **Lych:** tombstones raise undead blimps; at each skull it becomes **Ethereal** (half speed, invulnerable); Elite has more than twice Normal HP.
  - **Vortex:** no minions; speeds up bloons behind it ×2.5; wind bursts stun towers (every 2.5 s on Elite vs 5 s; longer stuns). It also has a time limit: each tier must be beaten within 20 rounds.
  - Beating all 5 tiers of Normal unlocks Elite. — [Bloons wiki Boss Event](https://bloons.fandom.com/wiki/Boss_Bloon_Event_(BTD6)); [Steam guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2824477232); [Bloons wiki Vortex](https://bloons.fandom.com/wiki/Vortex:_Deadly_Master_of_Air_(BTD6)); [Bloons wiki Lych](https://bloons.fandom.com/wiki/Gravelord_Lych)

### Inferences
- **Crosspaths:** a three-path, five-tier tree with a 5-2-0 rule gives each tower 2–4 distinct roles (single-target vs AoE vs support) without adding new unit IDs. That deepens strategy compared with anime TDs' linear upgrades. A Roblox TDS-style "Lv5 fork" (like Enforcer's two Lv5 branches) is a lighter version that suits casual players.
- **Damage types vs immunities** (sharp vs lead; energy vs purple) make mixed teams necessary. This is more interesting than flat armor percentages.
- **Fortified** is a cheap way to make late-wave variants of existing enemies without new art.
- **Blimps that release children** create layered DPS checks: big single-target HP first, then a swarm needing AoE.
- **Boss design kit:**
  - skull/HP thresholds that spawn minions or grant invulnerability;
  - tower-stun pulses;
  - a lane-speed aura;
  - a hard time limit (Vortex 20 rounds);
  - Normal → Elite unlock progression for live-ops boss events with leaderboards.

### Gaps
- BTD6 monetization and live-ops cadence (Odysseys, Contested Territory, Races) were not researched within the tool budget.
- The freeplay ramp formula and exact boss HP per tier (beyond Bloonarius T1 = 50K) were not retrieved.
- Some low-quality guide sites (btd6apk, mobilegamemaster) contained errors and were excluded.
