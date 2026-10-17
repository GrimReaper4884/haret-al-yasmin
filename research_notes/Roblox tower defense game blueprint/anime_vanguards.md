# Anime Vanguards (Roblox, Kitawari): Mechanical Breakdown for TD Design Replication (as of Oct 2026)

> **How this was researched.** Direct page fetching (WebFetch and curl) was blocked in this environment: DNS failures and proxy 403s on fandom.com, bloxodes.com, beebom.com, sportskeeda.com and others. Every finding below comes from search-engine result summaries and snippets of the cited pages, not from full page reads. Numbers were cross-checked across several results where possible, and conflicts are flagged. Treat single-source numbers as **uncertain**. The game updates every 2–4 weeks, so many guide pages are stale. Version numbering also differs between fan sites; for example, one fandom page labels an update both "11.0" and "9.0".
>
> **Source reliability tiers used here.** (1) Most trusted: wiki.vanguards.gg and animevanguards.fandom.com, the community wikis; Sportskeeda, Destructoid, Beebom, Gamezebo, ProGameGuides, TheGamer and Rolimons. (2) Medium: allthings.how, seemeta.com, techwiser, droidgamers. (3) Low or SEO-farm, possibly AI-generated: vanguards.wiki, animevanguardswiki.wiki, anime-vanguards-wiki.wiki, endsights, sabertoothgames, earnaldo (a Robux-reward site). Tier-3 pages often list unit names and mechanics from other games, so their numbers are quoted only when corroborated.

## Core loop & lobby (summon → match, party/matchmaking, AFK/auto)

### Takeaway
The game uses a classic Roblox anime-TD hub-and-instance loop. A social lobby ("Plaza"/"Vanguardian Plaza") has zones for Summon, Challenges, Raids, Rifts and shops. Players teleport into stage instances, where in-match currency (Yen) buys placements and upgrades, and match rewards (Gems, Gold, items, XP) feed back into gacha and unit investment. QoL automation is now built in: Auto Skip waves, skip-summon-animation, and an official **Auto Play** placement AI (Update 10, Dec 2025). These help sustain long AFK grinding sessions.

### Cited Findings
- The tutorial introduces the lobby, whose first/central area is "the Plaza". It then introduces Yen, "the currency used to place and upgrade units". — [wiki.vanguards.gg Tutorial](https://wiki.vanguards.gg/Tutorial)
- The lobby has a dedicated Challenges area "where you can get a lot of materials". — [Item Level Gaming beginner guide](https://itemlevel.net/anime-vanguards-complete-beginners-guide-tips-tricks/)
- Recommended settings: "Auto Skip Enemies" (auto wave skip) and "Skip Summon Animation". One guide claims auto-skip cuts match duration by ~20% (**uncertain**, tier-3-ish source). — [Item Level Gaming](https://itemlevel.net/anime-vanguards-complete-beginners-guide-tips-tricks/); [animevanguards.org beginner guide](https://animevanguards.org/guides/beginners)
- **Auto Play (Update 10, released Dec 23, 2025):** the player selects a point on the map, and the game places and upgrades all of the player's units around that point. It "does not toggle any active abilities, and strictly places and upgrades your units." — [Sportskeeda Update 10 patch notes](https://www.sportskeeda.com/roblox-news/anime-vanguards-update-10-patch-notes); [fandom Update Log](https://animevanguards.fandom.com/wiki/Update_Log)
- Auto Play builds shared as **import codes** exist (e.g., "GQL-8RP-5MF" for the Wrath event). This suggests Auto Play layouts are shareable strings. — [allthings.how Wrath auto play](https://allthings.how/anime-vanguards-wrath-event-auto-play-guide-code-gql-8rp-5mf-and-units/)
- The fandom update log mentions "public matchmaking to the game, allowing players to host and join matches", plus later matchmaking bug fixes. — [fandom Update Log](https://animevanguards.fandom.com/wiki/Update_Log)
- **Rifts** spawn in the Vanguardian Plaza hub about every hour, for teams of up to 6. A "Temporal Rift" can be bought from the Rift Shop to summon one on demand. — [fandom Rifts](https://animevanguards.fandom.com/wiki/Rifts) (via search summary)
- Units can be sold mid-match (default key F) for a partial refund (exact % unknown; tier-3 source). — [vanguards.wiki guide](https://www.vanguards.wiki/en/guides/anime-vanguards-guide/)
- Before Auto Play, players used third-party macros and auto-clickers (TinyTask etc.), which may breach Roblox ToS. This is a design signal that players wanted official automation. — [vanguards.wiki macro guide](https://vanguards.wiki/en/guides/anime-vanguards-how-to-macro/)

### Inferences
- Shipping official Auto Play with shareable layout codes absorbed the macro culture into a sanctioned feature. Leaving actives manual keeps a skill and attention ceiling for hard content.
- The hourly Rift that spawns in the hub is a lobby-population driver: it rewards players for staying in the social space.

### Gaps
- Exact lobby map layout (zone positions), party size for standard Story matches (4 players is typical for the genre; not confirmed), and the vote-skip and replay or "next stage" flow were not found.
- The sell-refund percentage was not found.

## Maps/stages & game modes (story, legend, raids, challenges, infinite, rifts, portals, dungeons, towers, PvP)

### Takeaway
Anime Vanguards layers 10+ mode types on one stage library:
- Story: 6 acts per world, Normal and Nightmare.
- Legend Stages: harder Nightmare-only remixes.
- Infinite: unlocked after a world's 6 acts.
- Challenges: modifier rotations on 30-minute, daily and weekly timers.
- Raids.
- Dungeons: 30-wave or endless, with roguelite modifier cards.
- Paragon: card-stacking difficulty.
- Worldlines: a 50-floor ladder, then endless "Infinite Convergence".
- Elemental Towers: floor ladders with rewards that loop every 50 floors.
- Rifts: hourly hub events with an MVP bonus.
- Portals.
- Boss Events, and timed events with their own currencies.
- PvP: Gauntlets/Arena, added 2026.

Each mode is mostly a reward funnel for a specific currency (trait rerolls, stat chips, evolution items, familiars).

### Cited Findings
- **Story stages (as of Update 11.0), 12 worlds:** Planet Namak, Sand Village, Double Dungeon, Shibuya Station, Underground Church, Spirit Society, Martial Island, Edge of Heaven, Lebereo Raid, Hill of Swords, Frozen Port, Downtown Tokyo. Each has "6 acts each, as well as normal and nightmare mode". — [fandom Story](https://animevanguards.fandom.com/wiki/Story); [fandom Gamemodes](https://animevanguards.fandom.com/wiki/Gamemodes)
- At launch (2024) there were only 3 worlds: Planet Namak, "Hidden Sand" (later Sand Village) and Double Dungeon. The content cadence works out to roughly one world per 1–2 major updates. — [old Story Mode fandom page](https://anime-vanguard.fandom.com/wiki/Story_Mode) (stale, ~717 days old)
- Finishing all 6 Story acts of a map unlocks that map's **Infinite Mode**, an endless-survival mode with rewards scaling with waves cleared. — [vanguards.wiki game modes](https://vanguards.wiki/en/game-modes/anime-vanguards-game-modes/); [fandom Gamemodes](https://animevanguards.fandom.com/wiki/Gamemodes)
- **Legend Stages** are harder remixes of Story stages. They unlock after specific Story chapters and always run on Nightmare. Examples include Sand Village, Double Dungeon, Shibuya Aftermath and Golden Castle. — [Sportskeeda Legend Stages](https://www.sportskeeda.com/roblox-news/how-legend-stages-anime-vanguards-89c98c23); [fandom Gamemodes](https://animevanguards.fandom.com/wiki/Gamemodes)
  - First clear of a Legend stage reportedly gives a one-time Mythic Shard and a permanent stat boost; repeat clears give Legend Medals with a small cap (**uncertain**). — [allthings.how trait rerolls](https://allthings.how/anime-vanguards-trait-rerolls-guide-fastest-farming-order/) (via search summary)
- **Challenges** are Story/Legend stages with added Modifiers that "revolve every 30 minutes/24 hours/7 days".
  - The fandom wiki says they refresh per player. wiki.vanguards.gg says they reset globally. **The two wikis conflict.**
  - **Trait Reroll Challenge:** 30-minute cooldown, 1 Trait Reroll per run, max 20 completions/day.
  - **Daily Challenge** pays 3 Trait Rerolls; **Weekly Challenge** pays 20.
  - Rewards are doubled on weekends, except the Weekly Challenge.
  - **Boss Bounties:** 1 reroll each, capped at 10/day.
  - — [fandom Gamemodes/FAQs](https://animevanguards.fandom.com/wiki/FAQs); [wiki.vanguards.gg Challenges](https://wiki.vanguards.gg/Challenges)
- **Paragon mode:** players add difficulty "cards" that raise enemy HP. Update 1 notes:
  - Paragon became Nightmare-only.
  - The scaling base was raised so enemy HP starts higher.
  - The "Strong" modifier adds +10% enemy HP per card.
  - The rework gives +5% gold and gems per level cleared.
  - One guide describes Paragon as Infinite-meets-Story with 25 stages per area (**uncertain**).
  - — [VGC Update 1 patch notes](https://www.videogameschronicle.com/guide/anime-vanguards-patch-notes-changelogs/); [Sportskeeda Update 1](https://www.sportskeeda.com/roblox-news/anime-vanguards-update-1-patch-notes)
- **Dungeons** are longer modes of 30 waves or endless. Players pick **modifier cards** that make the run easier or raise rewards. A Dungeon Shop sells Familiars, trait rerolls and more.
  - Ant Island is a 30-wave dungeon whose base reward is Monarch Tokens/Coins.
  - Frozen Volcano dungeon pays "DragonToken".
  - Update 14.5 added the Lunar Bridge dungeon.
  - — [fandom Dungeons](https://animevanguards.fandom.com/wiki/Dungeons); [TechWiser familiars](https://techwiser.com/anime-vanguards-familiars-guide/); [earnaldo update log](https://earnaldo.com/blog/anime-vanguards-update-log) (tier 3)
- **Worldlines:** the first 50 floors ("Worlds Collide") are followed by "Infinite Convergence" from floor 51, with a seasonal leaderboard. Gems are paid per floor, at a higher rate in floors 1–50. — [fandom Gamemodes](https://animevanguards.fandom.com/wiki/Gamemodes) (via search summary)
- **Elemental Towers** (added Update 10, Dec 2025):
  - Endgame mode in the Raids area; requires level 30.
  - Originally each tower accepted only its own element. Later, all units were allowed, with matching-element units dealing more damage.
  - Rewards at floors 5 and 10, then every 10 floors; the reward set loops after 50 floors (Floor 51 = Floor 1 rewards). One guide claims ~300 trait rerolls per 50-floor loop (**uncertain**).
  - Since Update 15.0 there are solo and multiplayer versions, progress was reset, and the skill tree was removed (**single source**).
  - — [fandom Elemental Towers](https://animevanguards.fandom.com/wiki/Elemental_Towers); [noleep Update 10](https://noleep.com/en/anime-vanguards-update-10-elemental-towers-auto-play-and-new-codes/); [robolibrary 2nd Anniversary](https://robolibrary.org/wikis/anime-vanguards)
- **Rifts:**
  - Hub spawn about every hour; up to 6 players.
  - **MVP system:** with 3+ players, the top damage dealer gets double rewards.
  - Global player tasks (clearing waves, spending gold) speed up spawns.
  - Update 14.5 (Aug 2026) made Rifts a weekly-rotating system headlined by a featured unit (**tier-3 source**).
  - — [fandom Rifts](https://animevanguards.fandom.com/wiki/Rifts); [earnaldo update log](https://earnaldo.com/blog/anime-vanguards-update-log)
- **Portals:** the fandom wiki describes them as a 20-wave survival mode with tiers and enemy elements. Another guide calls them consumable-key private dimensions with tiers up to Secret. **Conflicting.** Tier 4 "Cursed Familiar Portals" are cited as a Pass XP source. — [fandom Gamemodes](https://animevanguards.fandom.com/wiki/Gamemodes); [allthings.how battle pass](https://allthings.how/anime-vanguards-how-to-max-the-meliodas-battle-pass-fast/)
- **Raids:** stage-based mode with boss waves. One raid guide puts bosses at waves 5 and 10; another puts the same act's boss at wave 7 (**conflicting/stale**). — [ofzenandcomputing raid guide](https://www.ofzenandcomputing.com/clear-new-raid-act-1-2-in-anime-vanguards/); [wiki.vanguards.gg Raids](https://wiki.vanguards.gg/Raids)
- **Boss Events** exist as a separate mode, with a fandom page. — [fandom Boss Events](https://animevanguards.fandom.com/wiki/Boss_Events)
- **Event hard modes:** for example, the Wrath Event Hard Mode applies a 10× enemy health modifier (**tier-3 source**). The Wrath Event gives 3× Pass XP. — [animevanguardsgame.wiki Wrath](https://animevanguardsgame.wiki/modes/anime-vanguards-wrath-event/); [allthings.how battle pass](https://allthings.how/anime-vanguards-how-to-max-the-meliodas-battle-pass-fast/)
- **PvP and new modes in 2026:**
  - Update 14.5 "25th Hour" (Aug 10/11, 2026) added a "Gauntlets" tournament mode, described as a weekly tournament with placement rewards and unit/trait entry restrictions (**tier-3 source**).
  - Update 15.0 (2nd Anniversary, Oct 12, 2026) added:
    - Shadow Trials
    - Card Battle
    - Apostles Vs Vanguards
    - Pirate Dynasty Arena: Capture the Flag, 3v3 PvP or 3v3 vs AI
    - 17 Battle Towers restricted by category/element, opening a week after launch
    - a full UI rebuild
  - An older FAQ lists PvP modes "Assault, Defense, Ranked".
  - — [robolibrary](https://robolibrary.org/wikis/anime-vanguards); [ugphone 15.0](https://www.ugphone.com/news/gameguides/anime-vanguards-15-new-features-en); [fandom FAQs](https://animevanguards.fandom.com/wiki/FAQs)
- A tips guide suggests story-mode reward efficiency beats Challenges until a team can consistently reach wave 30+ in challenges. — [Item Level Gaming](https://itemlevel.net/anime-vanguards-complete-beginners-guide-tips-tricks/)

### Inferences
- The core design pattern is that each stage asset gets reused across Story N/NM, Legend, Challenge, Infinite, Paragon and Raid variants through modifiers and HP scalars. This multiplies content without new maps.
- Each mode maps to one currency:
  - Challenges → trait rerolls
  - Dungeons → familiars and tokens
  - Towers → bulk rerolls
  - Legend → evolution materials and shards
  - Rifts/events → event currency for banners
- Hard daily caps (20 challenge runs, 10 bounties) plus a 30-min timer create check-in rhythms.
- The 50-floor reward loop in Elemental Towers is a cheap way to make an endless ladder rewarding without inflating rewards.

### Gaps
- Exact wave counts per Story act and per Legend stage, starting Yen per stage, and boss wave placement in Story were not found in any snippet.
- Placement areas (ground/hill) per map and path design (single vs. multi-lane) were not found for this game specifically.
- Raid reward tables and cadence were not found reliably; one tier-3 claim of a "3-day cycle" is unverified.

## Enemies (types, shields, boss mechanics, immunities, HP scaling, elements)

### Takeaway
Enemy design is mostly a stat-template system: a per-enemy Health Multiplier, Speed, and optional Overshield. Bosses have **unit-stun abilities** with a radius and duration. Stage or challenge **Modifiers** add the complexity: CC immunity, Dispersal, Strong, Dodge. Elements exist but sources say the weakness effects are minimal; elements mostly act as unit-side buffs.

### Cited Findings
- Enemy entries list a Health Multiplier, Speed and "Overshield" (e.g., Overshield 25). Example base HP multipliers: 1.375 for "Alien Enlist" and 30 for "Hirko" (a boss). — [wiki.vanguards.gg Enemies](https://wiki.vanguards.gg/Enemies)
- Bosses stun **your units** with stated ranges and durations. Examples: one boss "stuns all units in 20 range for 4 seconds"; another stuns a single unit in 18 range for 5 seconds. — [wiki.vanguards.gg Enemy Mechanics](https://wiki.vanguards.gg/Enemy_Mechanics)
- The "Unit Stun Immunity" starting modifier makes enemies immune to crowd control (Slow, Stun). — [wiki.vanguards.gg Enemy Mechanics](https://wiki.vanguards.gg/Enemy_Mechanics)
- **Mutators/Modifiers:**
  - "Dispersal": enemies take 30% of damage received and spread the other 70% onto nearby enemies.
  - Bosses can have their own **Dodge** chance.
  - "Strong" raises enemy HP (+10% per Paragon card).
  - — [fandom Modifiers](https://animevanguards.fandom.com/wiki/Modifiers); [VGC Update 1](https://www.videogameschronicle.com/guide/anime-vanguards-patch-notes-changelogs/)
- Nightmare's "Empowered" buff reportedly doubles enemy health (**uncertain**, third-party tips page). — [LDCloud tips](https://www.ldcloud.net/blog/roblox-anime-vanguards-tips-tricks)
- Flying enemies appear on roughly 30% of mid-game maps, and teams need anti-air coverage (**tier-3 source**). A Sept 2026 tier list names Quetzalcoatl (Sun God) as "premier anti-air", applying burn to flyers. — [endsights](https://endsights.com/anime-vanguards-tips); [Beebom tier list](https://beebom.com/anime-vanguards-tier-list/)
- **Elements:**
  - Unit elements give buffs; for example, Fire grants Snare immunity and Water grants immunity to SPA debuffs (per most guides).
  - Curse's boss-damage bonus is cited anywhere from 5% to 30%. **Conflicting.**
  - One guide says "elemental weaknesses exist but their effects are minimal".
  - A detailed weakness chart circulating is a fan "rework concept", not live.
  - Portals carry "enemy elements".
  - — [Gamezebo Elements](https://www.gamezebo.com/walkthroughs/anime-vanguards-elements/); [Deltia's Elements](https://deltiasgaming.com/elements-in-anime-vanguards-roblox-everything-to-know/); [fandom concept post](https://animevanguards.fandom.com/f/p/4400000000000100543); [ProGameGuides Elements](https://progameguides.com/roblox/anime-vanguards-unit-elements-guide-roblox/)
- Unit passives target boss mechanics directly. For example, Igros gets +25% damage vs bosses and stun immunity. — [search summary of unit guides](https://wiki.vanguards.gg/Enemy_Mechanics)

### Inferences
- The design pattern is that bosses attack the player's board (stuns in a radius) rather than just having big HP. This forces unit spacing and rewards stun-immune or CC-cleanse units, which in turn monetizes specific gacha units.
- Per-enemy HP multipliers times a difficulty scalar times modifier stacks form a simple, data-driven scaling model that is easy to replicate.

### Gaps
- No authoritative per-wave HP growth formula or Nightmare multiplier was found.
- No list of speed classes (fast/tank archetypes) and no armor (damage-reduction %) mechanic was found; only Overshield is confirmed.

## Units (rarities, placement, upgrades, stats, attack patterns, roles, passives/actives, evolution, shiny)

### Takeaway
Rarity tiers:
- Rare, Epic, Legendary, Mythic, Exclusive (limited), Secret, and an apex **Vanguard** tier.
- Wiki claim: rarity "largely has no inherent impact" on gameplay. In practice, rarer units get more passives and fewer placements.

Stats and kit:
- Core stats are Damage, SPA (seconds per attack, i.e., cooldown) and Range.
- Units have multiple passives and some have actives.

Roles:
- Farm units generate Yen per wave and have tiered upgrade tables. Supports and buffers also exist.

Evolution:
- Mythic/Exclusive/Secret units evolve with Gold (~15k–30k), unit-specific items and Essence Stones. Some evolutions need takedown counts.

2026 additions:
- **Memoria**: equippable unit-like cards giving flat Damage/Range and a passive.
- "Transcendent" evolutions.

Removed:
- Ascension was removed in Update 15.0.

### Cited Findings
- **Rarities:** Rare, Epic, Legendary, Mythic, Exclusive ("limited tier"), Secret ("elevated tier").
  - Exclusive units usually have 2 passives; Mythic and higher usually 3.
  - Secret behaves like Mythic, with more room for unusual designs.
  - "A Unit's Rarity largely has no inherent impact on a Unit's gameplay properties."
  - Rare units typically have more placements.
  - — [wiki.vanguards.gg Unit List / Vanguards](https://wiki.vanguards.gg/Unit_List)
- "All units are governed by the traditional Damage, Cooldown, and Range system, but also operate on a system of 'passive abilities'". — [wiki.vanguards.gg Vanguards](https://wiki.vanguards.gg/Vanguards)
- **Vanguard rarity:**
  - ~0.005% per summon on event banners; Alocard is listed at 0.004% from the Special Banner.
  - Alocard was reworked from Secret to Vanguard in Update 11.0.
  - Some Vanguard forms come from evolution; e.g., Sung Jin Woo is a Mythic that evolves into a Vanguard form.
  - — [fandom Summon](https://animevanguards.fandom.com/wiki/Summon); [wiki.vanguards.gg Alocard](https://wiki.vanguards.gg/Alocard); [Sportskeeda Vanguard Evo SJW](https://www.sportskeeda.com/roblox-news/how-get-vanguard-evo-sjw-anime-vanguards)
- **Farm units (Yen/wave), current wiki data:**
  - **Sprintwagon:** placement limit 3; 9,000 Yen total cost.
    - Yen/wave: 250 (placed) → 550 → 1,050 → 1,800 → 2,550 at Upgrades 1–4.
    - Costs: 550 to place, then 1,050 / 1,800 / 2,550 / 3,050 for Upgrades 1–4.
  - **Takaroda:** placement limit 1; 39,800 Yen total.
    - Yen/wave: 250 → 750 → 1,500 → 3,000 → 5,000 → 8,000 → 10,000 at Upgrades 1–6.
    - Costs: 800 to place, rising to 12,500 at Upgrade 6.
  - Guidance: Sprintwagon for short modes, Takaroda for long modes (Paragon/Infinite/Boss). Takaroda's edge appears only from Upgrade 4.
  - A tier-3 page lists different Takaroda numbers, which conflict.
  - — [wiki.vanguards.gg Sprintwagon](https://wiki.vanguards.gg/Sprintwagon); [wiki.vanguards.gg Takaroda](https://wiki.vanguards.gg/Takaroda); [Gamezebo Sprintwagon vs Takaroda](https://www.gamezebo.com/walkthroughs/anime-vanguards-sprintwagon/)
- Run 1–2 farm units per team and upgrade the farm first, then put Yen into the main DPS. — [Item Level Gaming](https://itemlevel.net/anime-vanguards-complete-beginners-guide-tips-tricks/)
- **Unit level cap:** raised from 50 to 60 in Update 1 (2024; later caps not found). — [Sportskeeda Update 1](https://www.sportskeeda.com/roblox-news/anime-vanguards-update-1-patch-notes)
- **Placement-limit mechanics are unit-specific** and can change during play. For example, Path of Freedom's "Rumbling" ability lowers placement limits. "Shinobi God (Infinite Dreams)" can auto-place itself and instantly upgrade itself to max for free on placement (conditional). — [wiki.vanguards.gg Unit Mechanics](https://wiki.vanguards.gg/Unit_Mechanics)
- **Ground vs Hill:** a tier list describes ground units as close-range/melee placed at the frontline and hill units as ranged/support placed further back (**secondary source**). — [knowthelore tier list](https://knowthelore.com/games-tier-list/anime-vanguards-unit-tier-list/)
- **Evolution:**
  - Only Mythic, Exclusive and Secret units evolve, and most keep their rarity.
  - Requirements: a unit-exclusive Evolution Item, Gold and Essence Stones; some also need a takedown count.
  - Standard evolutions cost ~15,000 Gold; Secret units (e.g., Alocard, Igros) cost ~30,000.
  - Example: Riner needs 12 "Star Ribbon" plus Essence Stones.
  - Special quests guide each evolution.
  - — [TechWiser Evolution](https://techwiser.com/anime-vanguards-evolution-guide/); [ProGameGuides Evolution](https://progameguides.com/roblox/anime-vanguards-evolution-guide-roblox/); [animevanguards.org evolution](https://animevanguards.org/guides/evolution); [fandom Quests](https://animevanguards.fandom.com/wiki/Quests)
- **Ascension:** formerly a unit-power system. **Removed entirely in Update 15.0**: previously ascended units lose their bonuses, and an NPC, "Friran", now handles Masteries and the Memoria Maker. Older ascension guides (Gamezebo/Gamerant, ~2024) are obsolete. — [wiki.vanguards.gg Ascensions](https://wiki.vanguards.gg/Ascensions); [urgametips](https://urgametips.com/anime-vanguards-anniversary-true-shadow-monarch)
- **Memoria:**
  - Equippable onto nearly any unit; they give flat Damage and Range buffs plus at least one unique passive, and some are unit-specialized.
  - They level by feeding other Memoria or duplicates.
  - A later update removed Memoria evolutions; Memoria now come fully evolved.
  - Memoria Shards are a premium/code currency.
  - — [wiki.vanguards.gg Memoria](https://wiki.vanguards.gg/Memoria); [fandom Memoria](https://animevanguards.fandom.com/wiki/Memoria)
- **Update 15.0** added the "True Shadow Monarch", a **Transcendent** evolution from Song Jinwu plus Igros with its own progression system ("the System"), a "Shadow Army" and the "Memoria Maker". The anniversary event also added a "God Ascended" evolution of God (Standless), reached via four "sacred searches". — [ugphone 15.0](https://www.ugphone.com/news/gameguides/anime-vanguards-15-new-features-en); [vanguards2ndanniversary.wiki](https://www.vanguards2ndanniversary.wiki/)
- **Shiny:** separate roll at a base ~1.5% per summon; the Shiny Hunter gamepass raises it to 3%. Requires account level 10. — [Droid Gamers Shiny](https://www.droidgamers.com/guides/anime-vanguards-shiny-guide/); [Gamezebo Shiny](https://www.gamezebo.com/walkthroughs/anime-vanguards-shiny/)
- **"Serialized" variants** exist; the wikis give 0.5% vs 7.5% shiny odds for them (**conflicting**). — [fandom Summon](https://animevanguards.fandom.com/wiki/Summon); [wiki.vanguards.gg Summon](https://wiki.vanguards.gg/Summon)
- Top meta examples (Update 14.5 tier list, S+): Apathetic Savior, Holy Deceiver (Dark), Super Vogito, Wrath (Assault). The names are IP-adjacent parody spellings. — [BlueStacks tier list](https://www.bluestacks.com/blog/game-guides/roblox/rl-anime-vanguards-tier-list-en.html)

### Inferences
- Sideways investment axes stack on top of rarity: level, traits, stat grades, evolution, Memoria, familiars. Together they create a deep sink for duplicate and currency drops. The farm-unit upgrade tables give a ready template: about 5–7 upgrade tiers with roughly geometric costs, and payback curves tuned so the "premium" farm only wins in long modes.
- Removing Ascension in 15.0 shows the devs prune systems when power layering gets unwieldy, at the cost of invalidating player investment.

### Gaps
- Attack-pattern taxonomy (single/cone/circle/line/full-map) was not found in snippets, though unit pages list per-attack stats.
- Generic upgrade-level counts for non-farm units and default placement caps per rarity were not found.
- The team slot count was not confirmed; one tier-3 source says 6–8.

## Summon/banner system (rotation, costs, rates, pity, auto-sell, capacity)

### Takeaway
- **Costs:** Gems at 50 per pull and 500 per 10× (VIP 40 per pull, i.e., 20% off).
- **Standard rates:** Rare ~75.5%, Epic 20%, Legendary 4%, Mythic/Exclusive 0.5%, Secret ~0.004%, Vanguard ~0.005%.
- **Pity:** Legendary at 50 pulls and Mythic at 400; a one-time huge Vanguard pity per banner (20k–25k pulls).
- **Event banners:** separate event currency, ~150 per pull.
- **Rotation:** the Special Banner rotates hourly.
- **Gates:** Secret/Vanguard/Shiny results unlock at account level 10.
- **Auto-sell:** by rarity, never touching shiny or summon-trait units.
- **Storage:** expandable via gamepass (+50).

### Cited Findings
- **Cost:** 50 Gems per roll, 500 per 10×. On the Selection Banner a single pull is 50 Gems, or 40 with VIP. — [allthings.how how to get units](https://allthings.how/anime-vanguards-on-roblox-how-to-get-and-equip-units/); [Sportskeeda beginner guide](https://sportskeeda.com/roblox-news/anime-vanguards-a-beginner-s-guide)
- **Standard rates:** Rare 75.496%, Epic 20%, Legendary 4%, Mythic or Exclusive 0.5%, Secret 0.004%, Vanguard 0.005% (community data; check the in-game Index). — [bloxodes banners](https://bloxodes.com/wiki/anime-vanguards/banners)
- **Pity:** Legendary at 50 summons, Mythic at 400; the Selection Banner shares the same counter. — [bloxodes banners](https://bloxodes.com/wiki/anime-vanguards/banners); [jujutsucalc pity calculator](https://jujutsucalc.com/anime-vanguards-calculator)
- **Vanguard pity:**
  - The counter does not reset on a Vanguard pull, and the pity is consumed once per banner, so the guaranteed Vanguard is available once per banner.
  - The threshold is cited as 20,000 summons (3,000,000 event currency, "Update 7.5") or 25,000 summons (~1,250,000 gems). **Conflicting.**
  - Vanguard Memoria pity on Winter/event banners is 15,000 summons.
  - — [fandom Summon](https://animevanguards.fandom.com/wiki/Summon); [wiki.vanguards.gg Alocard](https://wiki.vanguards.gg/Alocard); [jujutsucalc](https://jujutsucalc.com/anime-vanguards-calculator)
- The **Special Banner rotates every hour**. Event banners feature a unique Vanguard unit. — [wiki.vanguards.gg Alocard / Summon](https://wiki.vanguards.gg/Summon)
- **Event currency:** event banners often cost 150 event currency per summon. For example, the Anniversary '26 banner costs 150 "Cake Slices '26" per pull. — [west-games pity calculator](https://west-games.com/anime-vanguards-pity-calculator/); [allthings.how 2nd Anniversary units](https://allthings.how/anime-vanguards-2nd-anniversary-how-to-get-all-new-units-update-15-0/)
- **Level gate:** Secret, Vanguard and Shiny results only unlock at account Level 10. — [allthings.how](https://allthings.how/anime-vanguards-on-roblox-how-to-get-and-equip-units/)
- **Luck potions** raise Legendary/Mythic chances but not Secret, Vanguard or Shiny rates, nor pity. — [allthings.how](https://allthings.how/?p=170767) (via search summary)
- **Auto-sell** never sells shiny units or units that rolled a trait from summoning. A Settings→Miscellaneous toggle allows selling trait units. Secret and Vanguard rarities have no auto-sell option at all. — [fandom Summon](https://animevanguards.fandom.com/wiki/Summon); [Droid Gamers](https://www.droidgamers.com/guides/anime-vanguards-shiny-guide/)
- **Storage:** the Extra Unit Storage gamepass adds +50 inventory slots (149 R$). Extra storage slots can also be bought with gold (price not found). — [fandom Store](https://animevanguards.fandom.com/wiki/Store); [twinfinite gamepass](https://twinfinite.net/guides/how-to-get-anime-vanguards-gamepass-coupons/)

### Inferences
- The pity design is two-layer. Soft-guaranteed tiers (Legendary at 50, Mythic at 400) keep F2P progress feeling steady. The headline Vanguard guarantee is set at whale scale (20–25k pulls ≈ 1M+ gems) and consumed once per banner. That combination is a strong monetization template.
- The hourly Special Banner rotation creates FOMO and frequent return visits, while gem-equivalent event currencies separate event economies from the standard one.

### Gaps
- Whether the 10× pull gives a bonus pull or a guaranteed rarity was not found.
- The base unit storage cap was not found.
- Featured-unit rate-up share within Mythic was not found.

## Rerolls: Traits & Stat potential (grades, odds, pity, items)

### Takeaway
There are two independent reroll layers:
1. **Traits**, rolled with Trait Rerolls: 15 or so traits from Vigor/Swift/Range I–III up to **Monarch** (0.1%, +300% dmg, 1-placement cap, pity at 1,500).
2. **Stat grades** on Damage, SPA and Range, rerolled with Stat Chips (all three) or Super Stat Chips (one stat), with odds improved by a "potential" meter filled by takedowns.

Pity exists only for the top four traits and is tracked per unit.

### Cited Findings
- **Trait table** (rate per reroll; effects):

  | Trait | Rate | Effect | Pity |
  |---|---|---|---|
  | **Monarch** | 0.1% | +300% Damage, −10% SPA, +5% Range; **placement limit 1** | 1,500 rerolls |
  | **Ethereal** | 0.175% | +20% Damage, −20% SPA, +5% Range; wiki-calculated ~+50% DPS | 858 |
  | **Deadeye** | 0.375% | 45% crit chance, +50% crit damage; ~+33.75% DPS (crit chance buffed from 30% to 45% in Sept 2024) | 400 |
  | **Solar** | 0.5% | +10% Damage, −5% SPA, +25% Range; ~+15.8% DPS | 300 |
  | **Blitz** | 1.85% | −20% SPA; ~+25% DPS | none |
  | **Fortune** | 2.5% | +20% farm-unit income, −10% upgrade cost for non-farm units | none |
  | **Marksman** | 6.5% | +30% Range | none |
  | **Scholar** | 10% | +50% XP | none |
  | **Vigor III / Swift III / Range III** | 5% each | +15% Damage / −12.5% SPA / +15% Range | none |
  | Vigor/Swift/Range lower tiers | ~26% each tier-family (aggregation unclear) | — | none |

  - Only the top four traits have pity.
  - Tier-3 sites (sabertoothgames +50%, endsights +35%) give different Monarch damage figures and are likely wrong.
  - — [seemeta traits (Sept 2026)](https://seemeta.com/en/anime-vanguards/traits); [fandom Traits](https://animevanguards.fandom.com/wiki/Traits); [Beebom traits](https://beebom.com/anime-vanguards-traits/); [Sportskeeda traits](https://www.sportskeeda.com/roblox-news/anime-vanguards-traits-guide); [earnaldo Monarch](https://earnaldo.com/blog/anime-vanguards-how-to-get-monarch); [GINX (stale 30% Deadeye)](https://www.ginx.tv/en/anime-vanguards-traits)
- **Trait pity is tracked per unit** and survives evolving, normalizing and stat transfers. — [allthings.how Monarch on Jotaro](https://allthings.how/anime-vanguards-how-to-roll-the-0-1-monarch-trait-on-jotaro/)
- **Tier opinion is split.** ProGameGuides ranks Monarch A-tier because the 1-placement cap hurts strategy; Twinfinite and TechWiser rank it top. — [ProGameGuides traits](https://progameguides.com/roblox/anime-vanguards-traits-tier-list-all-traits-ranked/); [TechWiser traits](https://techwiser.com/anime-vanguards-traits-tier-list/)
- **Trait Reroll sources:**
  - Level milestones, achievements, daily challenges, Battle Pass, and Robux in the Store.
  - Codes (e.g., "LagGone" reportedly gives 1,000 rerolls; "Assault" gives 100).
  - The Trait Reroll Challenge (1 per 30 min, 20/day), Daily Challenge (3), Weekly Challenge (20), Boss Bounties (1 each, 10/day), and Elemental Towers.
  - — [Destructoid traits](https://destructoid.com/?p=595841); [roonby codes Oct 2026](https://roonby.com/2026/10/13/anime-vanguard-codes/amp/); [fandom FAQs](https://animevanguards.fandom.com/wiki/FAQs)
- **Stat grade ranges** (Damage / SPA & Range bonus):

  | Grade | Damage | SPA & Range |
  |---|---|---|
  | D | 0–4.99% | 0–2.49% |
  | C | 5–7.99% | 2.5–3.99% |
  | B | 8–10.99% | 4–5.49% |
  | A | 11–13.99% | 5.5–6.99% |
  | S | 14–16.99% | 7–8.49% |

  - Destructoid says there are **8 grades** from D up to "Deity (神)", with Z/Z+ tiers above S added by later updates.
  - — [fandom Stats](https://animevanguards.fandom.com/wiki/Stats); [Destructoid stat potential](https://www.destructoid.com/increase-reroll-potential-fast-anime-vanguards/)
- **Grade odds by potential:**
  - At base potential: D 40%, C 30%, B 30%, A ~4.35%, S 1%. The figures as reported sum to more than 100%, so the snippet is likely garbled.
  - At **100% potential**: A 75%, S 20%, and nothing below A can roll.
  - Reaching 100% potential takes 5,000 unit takedowns, and potential resets after each roll.
  - — [fandom Stats](https://animevanguards.fandom.com/wiki/Stats); [wiki.vanguards.gg Stats](https://wiki.vanguards.gg/Stats)
- **Stat Chips** reroll all three stats; **Super Stat Chips** reroll one stat. Both are Mythic-rarity items. The advice is to use regular chips until reaching a Z/Z+ stat, then Super chips. Codes give Stat Chips (e.g., "FreedomsCallPart2" gives 5,000 Gems and 50 Stat Chips). — [Gamezebo Stats](https://www.gamezebo.com/walkthroughs/anime-vanguards-stats/); [Destructoid](https://www.destructoid.com/increase-reroll-potential-fast-anime-vanguards/); [DigitalCitizen codes](https://www.digitalcitizen.life/anime-vanguards-codes/)
- Traits, Ascensions and unit levels **reset on trade**. — [wiki.vanguards.gg Trading](https://wiki.vanguards.gg/Trading)

### Inferences
- Monarch's "+300% but only 1 copy" design is a strong pattern. It creates a chase item without breaking multi-placement balance, and the 1,500-reroll pity bounds the worst case.
- The "potential meter fills with takedowns" mechanic ties reroll quality to playtime. This is an anti-pure-P2W lever that monetizes chips while rewarding grinding.
- Resetting traits on trade prevents the trade market from becoming a trait-laundering exchange.

### Gaps
- A trait lock mechanic (locking a stat while rerolling) was not found; the Super Stat Chip single-stat reroll acts as the de facto lock.
- Exact S+/Z/Z+/Deity ranges and current odds were not found.

## Economy & progression (level, battle pass, items, shop, gamepasses, codes, trading, quests, familiars)

### Takeaway
Currencies:
- **Yen**: in-match.
- **Gems**: gacha.
- **Gold**: evolution and storage.
- Plus mode tokens (Monarch Coins, DragonToken, Raid tokens, Legend Medals) and event currencies.

Progression systems:
- Account level gates features: Lv10 for Secret/Shiny results, Lv30 for Towers and many codes, Lv50 for trading.
- A 50-level Battle Pass with free and premium tracks, fed by Pass XP from quests and events.
- Daily/Weekly/Infinite/Special quests.
- **Familiars**: a pet-like stat slot with random stats at obtain, Corruption Crystals, and some tradeable.

Monetization:
- Moderately priced gamepasses: VIP 299, Shiny Hunter 1,299, Display All Units 599, Extra Storage 149, Premium Pass 799.
- Generous codes: 5k–50k gems each.

### Cited Findings
- **Gamepasses (Robux):**
  - Shiny Hunter 1,299 (shiny rate 1.5% → 3%).
  - Display All Units 599.
  - Extra Unit Storage 149 (+50 slots).
  - Premium Pass 799.
  - **VIP 299**: perks described as 20% off summons, +10% XP and 2× Time Machine Gems (sources vary slightly).
  - Some passes, including VIP, can be gifted with single-use gift codes.
  - No "2x speed" gamepass was found in any source.
  - — [twinfinite gamepasses](https://twinfinite.net/guides/how-to-get-anime-vanguards-gamepass-coupons/); [ProGameGuides gift code](https://progameguides.com/roblox/how-to-get-a-gamepass-code-gift-in-anime-vanguards-free-premium-pass/); [fandom Store](https://animevanguards.fandom.com/wiki/Store)
- A "Time Machine" offline/idle gem generator exists, boosted 2× by VIP (inferred from the VIP perk). — [twinfinite](https://twinfinite.net/guides/how-to-get-anime-vanguards-gamepass-coupons/)
- **Trading:** introduced in Update 9; requires **level 50**; the Trade button is under Events. Familiars are tradeable except Vanguard Familiars. Traits, Ascensions and unit levels reset on trade. — [wiki.vanguards.gg Trading](https://wiki.vanguards.gg/Trading); [Sportskeeda trading guide](https://www.sportskeeda.com/roblox-news/anime-vanguards-trading-guide)
- **Quests:** Daily, Weekly, Infinite and Special (evolution-guide) types. Rewards include Gems, Gold and Pass XP; e.g., 1,500 Pass XP for completing 4 daily quests. Dailies reset whether or not you log in. — [fandom Quests](https://animevanguards.fandom.com/wiki/Quests); [wiki.vanguards.gg Quests](https://wiki.vanguards.gg/Quests)
- **Battle Pass:**
  - 50 levels; the 2026 pass ended with a featured unit, "Wrath (Assault)", on both free and premium tracks.
  - Named passes (e.g., a "Meliodas" pass).
  - Pass XP sources: Wrath Event (3× XP), Warfront, Tier 4 Cursed Familiar Portals, daily quests.
  - — [allthings.how battle pass](https://allthings.how/anime-vanguards-how-to-max-the-meliodas-battle-pass-fast/)
- **Familiars:**
  - Count: 23 (Exclusive/Secret/Mythic plus 3 Vanguard-rarity familiars tied to units) or 30 (8 Vanguard plus 22 regular), depending on source and date.
  - Stats are determined at obtain.
  - **Sources:**
    - Dungeon shops: Ant Island for Monarch Coins, Frozen Volcano for DragonToken (e.g., "Chili", Mythic).
    - Permanent event shops: "The Strongest", "The King's Return" (Vanguard familiars).
    - Raid clears (chance).
    - Story drops: e.g., "Nose", 10% from Hill of Swords stages.
    - Legend drops: e.g., "Pupper", 5% from Land of the Gods Legend Act 3.
    - Newer Trial and Adventure sources (Oct 2026).
  - **Corruption Crystals** (from the "Odyssey" realm) corrupt familiars.
  - — [TechWiser familiars](https://techwiser.com/anime-vanguards-familiars-guide/); [bloxodes familiars](https://bloxodes.com/wiki/anime-vanguards/familiars); [Pocket Tactics familiars](https://www.pockettactics.com/anime-vanguards-familiars); [Deltia's familiars](https://deltiasgaming.com/all-familiars-in-anime-vanguards-roblox/)
- **Items:** a community database lists 280 items with sources, rarities, uses and EXP value. — [bloxodes items](https://bloxodes.com/wiki/anime-vanguards/items)
- **Codes** (Oct 2026 list):
  - Retribution: 20,000 gems (Lv10).
  - MiniUpd2: 50,000 gems (Lv30).
  - Wrath: 50,000 gems (Lv30).
  - AnniNextHopefully: 5,000 gems (Lv30).
  - LagGone: 1,000 rerolls plus 200k "IcedTea26" (Lv30, 7-day expiry).
  - New 15.0 codes: 2ndAnniversary, TrueShadowMonarch, HappyAnniversary, Finally.
  - Codes are case-sensitive and level-gated.
  - — [roonby codes](https://roonby.com/2026/10/13/anime-vanguard-codes/amp/); [seemeta codes](https://seemeta.com/de/anime-vanguards/codes)
- Update 1 raised the unit level cap to 60 and gave Paragon +5% gold/gems per level. — [Sportskeeda Update 1](https://www.sportskeeda.com/roblox-news/anime-vanguards-update-1-patch-notes)
- **Purchasable shortcuts:** trait rerolls, Memoria Shards and stat chips. The anniversary banner, bundles and pity track are the main spend levers (fan FAQ). — [robolibrary](https://robolibrary.org/wikis/anime-vanguards)

### Inferences
- Gem code payouts are huge relative to pull cost: 50,000 gems equals 1,000 pulls, or 2.5× Mythic pity. This suggests the gem economy is intentionally inflated, and that real scarcity sits in rerolls, chips, event currency and Vanguard pity.
- Level gates (10 → 30 → 50) serve as onboarding pacing and alt-account and trade-abuse friction.

### Gaps
- Gem pack Robux prices, Battle Pass price per season, achievement list, crafting recipes and the full shop list were not found.
- No "artifacts" system was found; familiars and Memoria fill that role.

## Events, live ops, update cadence & player counts

### Takeaway
- **Launch:** Sept 2024 (source states Sept 8, 2024).
- **Peak CCU:** an all-time ~340k CCU on Sept 14, 2024.
- **Revenue:** top-earning Roblox game within 10 days.
- **Visits:** ~1.82B by 2026.
- **Cadence:** major updates roughly every 3–8 weeks, with ".5" mid-updates and event "Parts".
- **Typical update payload:** new units, a new world or mode, a new event currency banner, and codes.
- **CCU now:** ~78–84k in Oct 2026, far below peak; the 2nd Anniversary (15.0) shipped Oct 12, 2026.

### Cited Findings
- **Peak CCU** 340,167 on Sept 14, 2024 (Rolimons; also ranked #45 all-time on an EverybodyWiki list). An earlier tweet reported 330k CCU and top-3 Roblox. — [Rolimons](https://www.rolimons.com/game/16146832113); [EverybodyWiki list](https://en.everybodywiki.com/List_of_Roblox_games_by_peak_concurrent_users); [Lia Zhang on X](https://x.com/liaazhang/status/1838218521714590104)
- **Oct 2026 CCU:** a tracker reports 78,036 live and a recorded peak of 84,091 on Oct 12, 2026 (2nd Anniversary launch day; hourly sampling). — [bloxguidesgg](https://bloxguidesgg.com/roblox-stats)
- **Launch** Sept 8, 2024. It overtook Blox Fruits as **top-earning Roblox game within 10 days** (top 5 alongside Dress to Impress, Rivals and Blade Ball). — [Beebom](https://beebom.com/anime-vanguards-surpasses-blox-fruits-top-earning-roblox-game/amp/)
- **Visits:** 65M within weeks (Sept 2024); ~1.82B by 2026. — [Pocket Tactics visits](https://www.pockettactics.com/anime-vanguards/visits); [RoWatcher](https://rowatcher.com/games/5578556129)
- **Timeline (approx.; numbering inconsistent across sources):**
  - Update 0.5: raid mode, new boss.
  - Update 1: Paragon rework, level cap 60.
  - Update 1.5, 4.0, 4.5, 5 and 6.0 ("Heaven & Hell").
  - Summer Events from Aug 5, 2025: 11 events in Update 7.5.
  - Unending Rage Events: Aug 22, 2025.
  - Innocent Wrath Events: Sept 16, 2025 (Update 8.5).
  - **1st Anniversary (9.0): Oct 31 / Nov 1, 2025**, which introduced trading.
  - **Update 10: Dec 23, 2025** (Elemental Towers, Auto Play).
  - Update 11.0 (Demonic Rampage).
  - 12.5 (Turning Tides).
  - 13.5: June 22, 2026.
  - 14.0 Part 1: July 5, 2026; Part 2: July 27, 2026.
  - **14.5 "25th Hour": Aug 10/11, 2026**: 9 units, Lunar Bridge dungeon, Gauntlets, weekly Rift.
  - **15.0 "2nd Anniversary / Rise of the True Shadow Monarch": Oct 12, 2026**: Ascension removed, UI rebuild, PvP arena, Battle Towers, Anniversary '26 banner, 7-day login rewards.
  - — [fandom Events](https://animevanguards.fandom.com/wiki/Events); [fandom Update Log](https://animevanguards.fandom.com/wiki/Update_Log); [ProGameGuides 0.5](https://progameguides.com/roblox/anime-vanguards-update-0-5-patch-notes-new-units-boss-raid-mode-more/); [Sportskeeda 4.5](https://sportskeeda.com/roblox-news/anime-vanguards-update-4-5-patch-notes); [Sportskeeda 5](https://sportskeeda.com/roblox-news/anime-vanguards-update-5-patch-notes); [Deltia's 6.0](https://deltiasgaming.com/?p=251033); [wiki.vanguards.gg 1st Anniversary](https://wiki.vanguards.gg/1st_Anniversary_(9.0)); [wiki.vanguards.gg Turning Tides](https://wiki.vanguards.gg/Turning_Tides_(12.5)); [earnaldo update log](https://earnaldo.com/blog/anime-vanguards-update-log); [allthings.how 2nd Anniversary](https://allthings.how/anime-vanguards-2nd-anniversary-update-features-and-release-status/)
- The Roblox experience title is renamed per update (e.g., "Anime Vanguards: Wrathful Assault", "Holy Retribution", "Extermination Event Pt. 2", "Vanguards: 2nd Anniversary"). — [RoWatcher](https://rowatcher.com/games/5578556129/vanguards-2nd-anniversary)
- The anniversary event used **7-day login rewards** (Day 1: unit "Yuvi" plus a "Hex Stone"), an event currency ("Cake Slices '26") at 150 per pull, and a multi-step quest ("four sacred searches") leading to an evolution. — [Gamezebo 2nd Anniversary codes](https://www.gamezebo.com/walkthroughs/anime-vanguards-2nd-anniversary-codes/); [allthings.how](https://allthings.how/anime-vanguards-2nd-anniversary-how-to-get-all-new-units-update-15-0/)

### Inferences
- The live-ops recipe:
  - Each update renames the game title for algorithmic freshness.
  - Each update ships a new event currency, banner and featured Vanguard, plus a big gem code, plus a new mode.
  - A ".5" or "Part 2" follow-up keeps the gap between beats at 2–4 weeks.
  - Login streaks and 7-day rewards at anniversaries.
- CCU decayed from 340k to roughly 80k over two years, but the game stays a top-tier Roblox title. Content cadence sustains a core rather than recapturing launch hype.

### Gaps
- Per-update CCU peaks between 2024 and 2026 were not found, beyond Oct 12, 2026.
- No Halloween/Christmas-specific event details were found, though "Winter" banners are referenced in the Summon wiki.

## Praise & complaints (balance, P2W, grind, controversy)

### Takeaway
Little Reddit or critic sentiment was retrievable. What exists points to:
- Commercial success.
- Generous codes.
- A deep grind built on layered RNG: traits at 0.1%, stat grades, and Vanguard pity at 20k+ pulls.
- Recurring system churn: the Ascension removal invalidated investment.
- Off-game controversy: IP-infringement criticism and a ~$10M revenue-share lawsuit by a former programmer (2026).

### Cited Findings
- An industry observer called it the "most blatant IP infringement of all the top anime games". Unit names are parody spellings (e.g., "Sprintwagon", "Takaroda", "Alocard", "Igros", "Song Jinwu"). — [Lia Zhang on X](https://x.com/liaazhang/status/1838218521714590104)
- A former programmer, Rehaab Haque, sued the alleged owners in New York federal court. He claims his revenue share was cut from 20% to 10% and that he was then removed. A lawyer's post describes "nearly $10M at stake"; a YouTube video claims $15M (**conflicting**). Another developer publicly alleged being shorted $20k (unverified). — [Dexerto](https://www.dexerto.com/roblox/roblox-dev-sues-anime-vanguards-owners-after-claiming-he-was-cut-out-of-millions-3368438/); [Adam Starr on X](https://x.com/AdamStarrLawyer/status/2058325203999162482); [Lonegladiator on X](https://x.com/Lonegladiator_/status/2022097145730601168)
- A fan FAQ says progression is "largely earned in-game". It names the anniversary banner, bundles and pity track as real spend levers, and trait rerolls, Memoria Shards and stat chips as purchasable shortcuts. — [robolibrary](https://robolibrary.org/wikis/anime-vanguards)
- Ascension removal in 15.0 means "previously ascended units no longer receive their bonuses". This is a likely source of player frustration; direct complaints were not retrieved. — [wiki.vanguards.gg Ascensions](https://wiki.vanguards.gg/Ascensions)
- Monarch's 1-placement limit is viewed as a strategic drawback by some guide writers (rated A rather than S). — [ProGameGuides traits](https://progameguides.com/roblox/anime-vanguards-traits-tier-list-all-traits-ranked/)
- The prevalence of macro/AFK tool guides indicates grind fatigue before official Auto Play arrived. — [vanguards.wiki macro guide](https://vanguards.wiki/en/guides/anime-vanguards-how-to-macro/)

### Inferences
- Power creep is implied by the constant addition of higher evolutions (Vanguard → Transcendent) and the rarity reworks (Alocard Secret → Vanguard), but no source quantifies it.

### Gaps
- No r/AnimeVanguards threads or critic reviews were retrievable: searches returned irrelevant results and page fetches were blocked. Community sentiment on balance, P2W and grind is therefore largely **unverified**.
