# Out-Build Roblox's Anime Tower Defense Giants

Every famous Roblox tower defense game runs the same loop. A social lobby sends players into stage instances. In-match cash buys placements and upgrades there. Match rewards feed a gem gacha plus a stack of sideways investment systems (traits, stat grades, evolutions, equipment), and an update every three to six weeks refreshes it all. **Anime Vanguards** perfected the formula and hit **~340,000 concurrent players six days after its September 2024 launch** ([Rolimons](https://www.rolimons.com/game/16146832113)). Its toolkit:

- 50-gem pulls, with Legendary pity at 50 and Mythic pity at 400.
- A 0.1% "Monarch" trait worth +300% damage but limited to one placement.
- Stat grades whose odds improve as a unit racks up takedowns.
- More than ten modes, each paying out one scarce currency.

The non-anime leaders supply what the anime games lack. **Tower Defense Simulator** forces real loadout decisions through Hidden, Lead and Flying enemy attributes, and keeps co-op fair by splitting cash evenly. **Toilet Tower Defense** shows that a meme plus a tradeable crate gacha can reach 522,000 concurrent players and still fall to about 4,000.

Two threats repeatedly ended the genre's biggest games: **IP takedowns** (Anime Adventures in 2023, Anime Rangers X in 2025) and **pay-to-win backlash** (Anime Defenders' 249-Robux Wishes). The best plan for haret-al-yasmin follows from that:

- **Original characters.**
- **Vanguards-grade meta depth, with bounded and friendlier pity.**
- **TDS-style attribute checks and a TDS-style co-op economy.**
- **Paid summons gated by PolicyService, with live odds tables.**
- **A production loop** in which Claude Fable 5.1 in Claude Code drives Roblox Studio's built-in MCP server and Blender MCP on a Windows or macOS machine, with all code kept in Rojo and git.

One caveat on evidence: the underlying research was gathered from search-engine summaries because direct page fetches were blocked. Many figures come from fan wikis for games that rebalance every few weeks, so treat exact percentages as "as last reported."

## Hype peaks in days; cadence and IP decide who survives

The genre is winner-take-most and front-loaded. Anime Vanguards launched on **September 8, 2024**. Within 10 days it overtook Blox Fruits as **Roblox's top-earning game** ([Beebom](https://beebom.com/anime-vanguards-surpasses-blox-fruits-top-earning-roblox-game/amp/)), and it has since passed ~1.82B visits ([RoWatcher](https://rowatcher.com/games/5578556129)). Two years later it holds roughly **78,000–84,000 concurrent players**, measured around its 2nd Anniversary update on October 12, 2026 ([bloxguidesgg](https://bloxguidesgg.com/roblox-stats)). That is a quarter of its peak, but still top tier.

Anime Defenders shows the opposite path. It launched April 5, 2024 and peaked at **377,836 CCU on July 21, 2024** ([Rolimons](https://www.rolimons.com/game/17017769292)). Then came backlash over a 30-minute hardest-difficulty grind for "Wishes" that also sold for 249 Robux each ([ProGameGuides](https://progameguides.com/roblox/after-negative-fan-reactions-roblox-developer-promises-improved-f2p-experience/)), followed by the arrival of a higher-polish competitor. By August 2026 it sat at **a few hundred players** ([profitable.app](https://profitable.app/roblox/games/anime-defenders)).

| Game | All-time peak CCU | Recent state | What it teaches |
|---|---|---|---|
| Toilet Tower Defense | **522,376** (Mar 9, 2024) ([Rolimons](https://www.rolimons.com/game/13775256536)) | ~3.9K (Sept 2026); "final" Legacy Update May 2026 ([RoCodes](https://rocodes.gg/codes/toilet-tower-defense)) | Meme IP drives acquisition, not retention; tradeable gacha inflates |
| Anime Defenders | 377,836 (Jul 2024) | a few hundred CCU (Aug 2026) | Selling summon currency at premium prices triggers collapse |
| Anime Vanguards | 340,167 (Sept 2024) | ~78–84K (Oct 2026) | Deep layered meta plus relentless cadence sustains a core |
| All Star Tower Defense | 164,029 (Sept 2021) ([Rolimons](https://www.rolimons.com/game/4996049426)) | rebooted as ASTDX | Long life, but reboots split the audience |
| Tower Defense Simulator | ~159,824 (Oct 2025) ([Adellion](https://adellion.com/roblox-tower-defense)) | evergreen; ~4.6–4.9B visits | Strategy depth without unit gacha |
| Anime Last Stand | 157,103 (Oct 2025) ([Rolimons](https://www.rolimons.com/game/12886143095)) | 60+ updates; ~842K-member Discord ([Discord](https://discord.com/invite/animelaststand)) | Steady cadence and mode-linked evolutions |
| Anime Rangers X | 119,341 (Apr 2025) ([Rolimons](https://www.rolimons.com/game/72829404259339)) | deleted 2025; Re:Rangers X peaked at 59,765 ([Rolimons](https://www.rolimons.com/game/111446873000464)) | Relaunches recover about half |
| Tower Defense X | 36,266 (Nov 2023) | ~26K 30-day peak, no gacha ([adellion](https://adellion.com/roblox-tower-defense)) | A no-gacha TD can hold tens of thousands |

The IP lesson is the most important one in this report. **Anime Adventures was removed on December 22, 2023**, after a takedown reportedly issued by Gamefam, which holds a licensed anime game. It returned only on December 24, 2024, after an extensive unit revision ([Roblox Fandom](https://roblox.fandom.com/wiki/Gomu/Anime_Adventures); [Pocket Tactics](https://www.pockettactics.com/anime-adventures/private)). **Anime Rangers X showed "Content Deleted" in April 2025.** Staff first blamed a DMCA notice, and the co-owner later denied that any studio had filed one ([Pro Game Guides](https://progameguides.com/roblox/anime-rangers-x-content-deleted-did-dmca-strike-again/)). Toilet Tower Defense also went down in September 2023 over copyright ([Roblox wiki](https://roblox.fandom.com/wiki/Telanthric_Development/Toilet_Tower_Defense)). Anime Vanguards itself has been called the "most blatant IP infringement of all the top anime games" for parody names like "Alocard" and "Song Jinwu" ([Lia Zhang on X](https://x.com/liaazhang/status/1838218521714590104)).

Internal IP matters too. In May 2026 a former Vanguards programmer sued the alleged owners for breach of contract and copyright infringement. He had been paid through an informal Robux revenue share, and nearly $10M is reportedly at stake ([Dexerto](https://www.dexerto.com/roblox/roblox-dev-sues-anime-vanguards-owners-after-claiming-he-was-cut-out-of-millions-3368438/)).

One more caution: revenue trackers are unreliable. One estimates Vanguards at ~$16.5M lifetime and $223K–311K per month ([profitable.app](https://profitable.app/roblox/games/anime-vanguards-extermination-event-pt-1)); another estimates ~$10K per month ([RoWatcher](https://rowatcher.com/games/5578556129)). Roblox publishes neither figure.

## Ten modes reuse one stage library, and each pays one currency

The anime TDs multiply content by remixing a small set of maps. Anime Vanguards shipped with 3 worlds and grew to **12 story worlds, each with 6 acts in Normal and Nightmare** ([fandom Story](https://animevanguards.fandom.com/wiki/Story); [old Story page](https://anime-vanguard.fandom.com/wiki/Story_Mode)). That is roughly one new world every one or two major updates. Each world's assets are then reused across many modes:

- **Infinite**: endless survival, unlocked after a world's six acts.
- **Legend Stages**: harder remixes that always run on Nightmare ([Sportskeeda](https://www.sportskeeda.com/roblox-news/how-legend-stages-anime-vanguards-89c98c23)).
- **Challenges**: modifier rotations on 30-minute, daily and weekly timers.
- **Paragon**: players stack difficulty "cards," each adding +10% enemy HP ([VGC](https://www.videogameschronicle.com/guide/anime-vanguards-patch-notes-changelogs/)).
- **Dungeons**: 30 waves or endless, with roguelite modifier cards and their own shop ([fandom Dungeons](https://animevanguards.fandom.com/wiki/Dungeons)).
- **Worldlines**: a 50-floor ladder that flows into an endless leaderboard climb.
- **Elemental Towers**: rewards loop back to Floor 1 after Floor 50 ([fandom Elemental Towers](https://animevanguards.fandom.com/wiki/Elemental_Towers)).
- **Rifts**: spawn in the hub roughly hourly for up to 6 players, and give the top damage dealer double rewards when 3+ players join ([fandom Rifts](https://animevanguards.fandom.com/wiki/Rifts)).
- **PvP (2026)**: weekly "Gauntlets" tournaments, plus a 3v3 capture-the-flag arena in Update 15.0 ([ugphone](https://www.ugphone.com/news/gameguides/anime-vanguards-15-new-features-en)).

The check-in rhythm comes from hard caps. The Trait Reroll Challenge pays one reroll per run on a **30-minute cooldown, capped at 20 runs a day**. The Daily Challenge pays 3 rerolls, the Weekly pays 20, and Boss Bounties are capped at 10 a day ([wiki.vanguards.gg Challenges](https://wiki.vanguards.gg/Challenges); [fandom FAQs](https://animevanguards.fandom.com/wiki/FAQs)).

The rest of the genre added signature modes on the same skeleton:

- **Anime Adventures**: Infinity Castle, **100 rooms of 15 waves each**, reset every season ([Gamer Journalist](https://gamerjournalist.com/how-to-complete-infinity-castle-in-anime-adventures-how-many-rooms/)).
- **Anime Last Stand**: Raids of **6 stages × 20 waves**, Portals, Legend Stages, Boss Rush, and Godly Trials gated to World 2 ([ALS Fandom Raids](https://alsroblox.fandom.com/wiki/Raids); [ALS Godly Trials](https://alsroblox.fandom.com/wiki/Godly_Trials)).
- **Anime Defenders**: Hall of Mirrors, where players survive 30 minutes on the hardest difficulty for a chance at Wishes.
- **Anime Rangers X**: an **AFK World** that rolls a 0.5% chance at a specific unit every 15 minutes ([Deltia's](https://deltiasgaming.com/?p=206188)).
- **ASTD and ASTDX**: Trials that reward 5- and 6-star units or orbs, plus PvP, Classic Infinite and Strategist Trials, all with traits disabled ([ASTD Fandom](https://allstartd.fandom.com/wiki/Trials); [Destructoid](https://www.destructoid.com/all-star-tower-defense-x-trait-tier-list/)).

Mapping each mode to its payout gives the genre's economic backbone. The pattern is mode → currency → shop → power:

- Challenges → trait rerolls
- Dungeons → familiars and tokens
- Towers → bulk rerolls
- Legend stages → evolution materials
- Rifts and events → banner currency

Tower Defense Simulator structures difficulty differently: a ladder of separate modes with growing wave counts.

| Mode | Waves |
|---|---|
| Easy | **20** (cut from 25 in January 2026) ([NamuWiki](https://en.namu.wiki/w/Tower%20Defense%20Simulator/Easy%20Mode)) |
| Intermediate | 30 |
| Molten | 35 |
| Fallen | 40, ending with the Fallen King ([TDS wiki Fallen](https://tds.fandom.com/wiki/Fallen_Mode)) |
| Hardcore | 45 (or 50 in the legacy version) |

Hardcore needs **Level 50**, caps lobbies at 3, pays Gems instead of Coins, and unlocks Voidcore ([TDS wiki Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode)). Starting cash is $500 in normal modes ([TDS wiki Waves](https://tds.fandom.com/wiki/Waves)). Shortening Easy suggests the developer is cutting entry-level session length.

Maps also carry placement rules. TDS has cliff-only towers like the Mortar, which is weak on maps with few cliffs ([TDS wiki Mortar](https://tds.fandom.com/wiki/Mortar)). Vanguards splits units into frontline ground units and ranged hill units ([knowthelore](https://knowthelore.com/games-tier-list/anime-vanguards-unit-tier-list/)). Tower Battles keeps its short, intersecting-path Venus map Survival-only ([Tower Battles wiki](https://roblox-tower-battles.fandom.com/wiki/Venus)), which implies that versus maps need vetting.

## Bosses that attack your board beat bosses that only have big HP

Anime TD enemies are mostly stat templates. Each Vanguards enemy has a Health Multiplier (1.375 for a basic grunt, 30 for one boss), a Speed, and an optional Overshield ([wiki.vanguards.gg Enemies](https://wiki.vanguards.gg/Enemies)). The interesting design lives in the bosses and modifiers:

- Some bosses **stun all units within 20 range for 4 seconds**; others stun one unit for 5 seconds ([Enemy Mechanics](https://wiki.vanguards.gg/Enemy_Mechanics)).
- The "Dispersal" modifier makes an enemy take only 30% of incoming damage and spread the other 70% to its neighbors ([fandom Modifiers](https://animevanguards.fandom.com/wiki/Modifiers)).
- Other modifiers grant stun immunity or dodge chance.
- Nightmare reportedly doubles enemy HP (uncertain) ([LDCloud](https://www.ldcloud.net/blog/roblox-anime-vanguards-tips-tricks)).

Elements exist, but guides call their weakness effects "minimal"; in practice they behave as unit-side buffs ([Gamezebo](https://www.gamezebo.com/walkthroughs/anime-vanguards-elements/)). Other games hint at deeper systems. ASTDX traits grant **Shield Bypass and True Damage** and reference "Elemental Rules." In Anime Rangers X, units have HP, so enemies fight back ([Beebom](https://beebom.com/all-star-tower-defense-x-traits-tier-list/); [Pocket Tactics](https://www.pockettactics.com/anime-rangers-x-traits)). Beyond that, the anime games' enemy rosters (armor, regen, flying, stealth) were barely documented in accessible sources.

Tower Defense Simulator has the strongest enemy design in the genre: **attributes act as loadout checks, not just stat checks.**

- **Hidden** enemies can only be targeted by towers with detection ([TDS wiki Hidden](https://tds.fandom.com/wiki/Hidden_(Attribute))).
- **Lead** enemies take damage only from lead-capable towers.
- **Flying** enemies need flying detection.
- **Elite Lead** keeps both Lead and stun immunity until a separate shield HP pool breaks ([TDS wiki Elite Lead](https://tds.fandom.com/wiki/Elite_Lead)).

With only 5 loadout slots, every hard mode forces players to cover detection, lead, anti-air, boss DPS and economy at once. All bosses are stun-immune, so stuns become 20% slows ([TDS Stun Immunity](https://tds.fandom.com/wiki/Stun_Immunity)). The legacy Fallen King summons minions, stomps to stun towers, and enters **Rage at 75,000 HP**, at which point it speeds up, gains a 15,000-HP shield and spawns three Guardians. A hidden wave continues the fight into Awakened phases ([TDS Legacy](https://tds-legacy.fandom.com/wiki/Fallen_King); [Awakened FK](https://tds.fandom.com/wiki/Awakened_Fallen_King)).

Bloons TD 6 adds a vocabulary worth borrowing.

| Mechanic | How it works |
|---|---|
| Damage-type immunities | Lead is immune to sharp damage; purple resists energy and fire; regrow heals when left undamaged ([Bloon Properties](https://bloons.fandom.com/wiki/Bloon_Properties)) |
| Fortified | A multiplier that **doubles MOAB-class durability** ([Bloonswiki](https://www.bloonswiki.com/Fortified_Bloon_(BTD6))) |
| Blimps with children | A MOAB has 200 HP and releases 4 Ceramics, testing single-target DPS and then splash ([Bloonswiki MOAB](https://www.bloonswiki.com/MOAB_(BTD6))) |
| Milestone introductions | MOAB arrives at round 40, ZOMG at 80, BAD at 100 |
| "Exam" rounds | Round 95 tests camo, lead, regrow and blimp DPS at once ([Bloons wiki](https://bloons.fandom.com/wiki/Fortified_Camo_Regrow_Bloon)) |
| Boss events | HP-threshold "skulls" that spawn minions or grant invulnerability, Vortex's 20-round time limit, and an Elite tier unlocked after beating Normal ([Boss Event](https://bloons.fandom.com/wiki/Boss_Bloon_Event_(BTD6))) |

Pacing guidance converges across these games. The genre's typical difficulty spike is one wave twice the size of the previous one, and boss stages "break loose" in the last three waves ([LoadLastSave](https://loadlastsave.substack.com/p/talking-about-tower-defense-games)). TDS removes timers on final boss waves so a boss can't be skipped into the previous wave, and it signals late-game wave bands with music changes ([TDS Hardcore](https://tds.fandom.com/wiki/Hardcore_Mode)). No game publishes an HP-per-wave formula, so the curve in the build plan below is a design proposal, not a copy.

## Units grow sideways through roles, actives, evolutions and dupes

Rarity naming has converged. ASTD's star system (3–6 stars, plus "Unbound") gave way to named tiers. Vanguards uses Rare, Epic, Legendary, Mythic, Exclusive (limited), Secret, and an apex **Vanguard** tier ([wiki.vanguards.gg Unit List](https://wiki.vanguards.gg/Unit_List)). Vanguards' own wiki says rarity "largely has no inherent impact" on gameplay. In practice, rarer units get more passives (Exclusive usually 2, Mythic and above usually 3), while Rare units get more placements. All units share **Damage, SPA (seconds per attack) and Range**, plus passive abilities ([wiki.vanguards.gg Vanguards](https://wiki.vanguards.gg/Vanguards)). Placement limits are set per unit and some kits change them mid-match ([Unit Mechanics](https://wiki.vanguards.gg/Unit_Mechanics)).

Roles are clearest in the economy and support towers.

| Farm | Rarity / limit | Yen per wave | Upgrade costs | Total cost |
|---|---|---|---|---|
| Sprintwagon ([wiki](https://wiki.vanguards.gg/Sprintwagon)) | limit 3 | 250 → 2,550 | 550 to place, then 1,050 / 1,800 / 2,550 / 3,050 | 9,000 |
| Takaroda ([wiki](https://wiki.vanguards.gg/Takaroda)) | limit 1 | 250 → 10,000 over six upgrades | — | 39,800 |
| TDS Farm ([guide](https://www.towerdefensesimulator.com/towers/farm/)) | — | $60 → $1,500 | — | $9,350 |

Takaroda only pulls ahead from its fourth upgrade, which is why guides reserve it for long modes ([Gamezebo](https://www.gamezebo.com/walkthroughs/anime-vanguards-sprintwagon/)). TDS supports buff every tower in range, including teammates' towers. The DJ Booth switches between range, discount and damage tracks. The Commander adds a 10–20% fire-rate aura plus an **active "Call to Arms"** that stacks a further 10–20% for 10 seconds ([TDS DJ Booth](https://tds.fandom.com/wiki/DJ_Booth); [Commander](https://tds.fandom.com/wiki/Commander)).

Active abilities and ultimates are the least-documented system in the genre, and that gap is real. The clearest evidence is indirect: Vanguards' official Auto Play (December 2025) "does not toggle any active abilities." So actives exist and stay manual, which keeps a skill ceiling on hard content even as placement gets automated ([Sportskeeda](https://www.sportskeeda.com/roblox-news/anime-vanguards-update-10-patch-notes)). Cooldowns, cutscenes and manual-versus-automatic activation were not found for ALS, AA, ASTDX or the others.

Upgrade paths are better sourced:

- **BTD6** offers 3 paths × 5 tiers with a crosspath rule (for example 5-2-0), so one tower supports several builds ([Bloons Crosspathing](https://bloons.fandom.com/wiki/Crosspathing/Engineer_Monkey)).
- **TDS's Enforcer** (August 2026) uses a lighter fork: two Lv5 branches. Unlocking it means raising the base Shotgunner to evolution Level 20 through play XP (or paying 499 Robux to skip), then paying 4,750 Gems plus 15,000 Coins ([Stealthy Gaming](https://stealthygaming.com/tower-defense-simulator-enforcer-tower-update/)).

Evolution is the genre's main progression sink, and every mode exists partly to feed it:

- **Anime Vanguards**: only Mythic, Exclusive and Secret units evolve. Evolution needs a unit-exclusive item, Essence Stones, and **~15,000 Gold (~30,000 for Secrets)**, sometimes plus a takedown count, with quest guidance ([TechWiser](https://techwiser.com/anime-vanguards-evolution-guide/); [ProGameGuides](https://progameguides.com/roblox/anime-vanguards-evolution-guide-roblox/)).
- **Anime Last Stand**: evolution items are scattered across Raid, Boss Rush and event shops. Godly evolutions need a quest Glyph combined with an empty Helix ([ALS Godly Trials](https://alsroblox.fandom.com/wiki/Godly_Trials)).
- **ASTDX**: duplicates are spent on Skill Nodes alongside Skill Orbs ([Deltia's](https://deltiasgaming.com/?p=281458)).
- **ASTD**: orbs raise 6-star base stats, for example range 28 to 33 ([Trello Finder](https://trellofinder.com/games/all-star-tower-defense)).

Vanguards keeps adding layers on top of evolution: Memoria cards that give flat Damage and Range plus a passive ([wiki.vanguards.gg Memoria](https://wiki.vanguards.gg/Memoria)), Familiars with stats rolled at obtain ([TechWiser](https://techwiser.com/anime-vanguards-familiars-guide/)), a separate Shiny roll at **1.5%** that rises to 3% with a 1,299-Robux pass ([Droid Gamers](https://www.droidgamers.com/guides/anime-vanguards-shiny-guide/)), and "Transcendent" evolutions.

It also shows the cost of over-layering. Update 15.0 **removed Ascension entirely**, and previously ascended units lost their bonuses ([wiki.vanguards.gg Ascensions](https://wiki.vanguards.gg/Ascensions)). The lesson for a new game: design every power axis with a cap on day one, rather than pruning later and breaking players' investment.

## Gacha converges on 50 gems, sub-1% top tiers and two-layer pity

The summon systems are near-identical across the genre, which makes the conventions safe to adopt and the differences easy to read.

| Game | Pull cost | Top-tier odds | Pity | Rotation |
|---|---|---|---|---|
| Anime Vanguards | 50 gems, 500 for 10×, 40 with VIP | Rare 75.496%, Epic 20%, Legendary 4%, Mythic 0.5%, Secret 0.004%, Vanguard 0.005% ([bloxodes](https://bloxodes.com/wiki/anime-vanguards/banners)) | Legendary 50, Mythic 400; one Vanguard per banner at 20,000–25,000 pulls (sources conflict) ([fandom Summon](https://animevanguards.fandom.com/wiki/Summon)) | Special banner hourly; event banners at 150 event currency per pull |
| Anime Adventures | 50 gems (40 VIP) | Mythic 0.25% Special / 0.5% Event; Secret ~1 in 400,000 ([AA Fandom](https://animeadventures.fandom.com/wiki/Summon)) | Meter: +2% Legendary and +0.25% Mythic per pull ([GLS](https://www.gameslearningsociety.org/how-much-gems-to-get-mythical-in-anime-adventure/)) | Hourly, 3 featured Mythics |
| Anime Last Stand | version-dependent | Mythic 0.5%, Legendary 2% | Legendary 60, Mythic 250; Secret 500 ([ALS Fandom](https://alsroblox.fandom.com/wiki/Summoning_Banners)) | Banner versions vary |
| ASTDX | 50 gems, 450 for 10× | star rarities; featured 5-star ~1% | "guarantees 5-star+", count unpublished ([Sportskeeda](https://www.sportskeeda.com/roblox-news/all-star-tower-defense-x-a-beginner-s-guide)) | — |
| Anime Reborn | 50 gems, 500 for 10× ([Destructoid](https://www.destructoid.com/anime-reborn-traits-tier-list/)) | — | — | — |
| Toilet Tower Defense | 100 coins (Basic), 1,200 (Mythic crate) | Godly 0.01–0.15%, Ultimate 0.0001%, Shiny 1% ([TTD wiki](https://toilet-tower-defense-game.fandom.com/wiki/Crates)) | none found | Crates; Robux-only exclusive crates |

Vanguards' design is a deliberate two-layer pity. Soft guarantees at 50 and 400 pulls keep free players progressing. The headline Vanguard guarantee sits at whale scale and can be used once per banner. Luck potions raise Legendary and Mythic odds but leave Secret, Vanguard, Shiny and pity untouched ([allthings.how](https://allthings.how/anime-vanguards-on-roblox-how-to-get-and-equip-units/)). Secret, Vanguard and Shiny results only unlock at account level 10, which slows alt-account farming. Auto-sell never touches shinies or units that rolled a trait from summoning ([fandom Summon](https://animevanguards.fandom.com/wiki/Summon)).

Vanguards also hands out gems lavishly. Single codes pay **20,000–50,000 gems**, which is up to 1,000 pulls ([roonby](https://roonby.com/2026/10/13/anime-vanguard-codes/amp/)). Gems are therefore inflated on purpose, and the real scarcity sits in rerolls, chips, event currency and Vanguard pity.

Toilet Tower Defense shows the other extreme. Ultra-rare tradeable units became speculative assets: Telanthric Titan was valued at 3.8 billion gems ([game.guide](https://www.game.guide/toilet-tower-defense-value-list)). The market crashed with every flood of new units and became a scam hotspot, which a parental guide described as mimicking "gambling loops" ([Screenwise](https://screenwiseapp.com/media/skibidi-toilet-tower-defense-game)). The economy eventually needed a separate-save "Legacy" lobby to reset ([TTD wiki](https://toilet-tower-defense-game.fandom.com/wiki/Legacy_Update)).

## Rerolls are the real endgame, and the real revenue

Once players own the units they want, the grind moves to the trait slot, and every game sells the reroll consumable:

| Game | Consumable | Price |
|---|---|---|
| ASTDX | Trait Burners | **299 Robux for 12, 3,200 for 180** ([Destructoid](https://www.destructoid.com/all-star-tower-defense-x-trait-tier-list/)) |
| Anime Last Stand | Technique Shards | — |
| Anime Defenders | Trait Crystals | — |
| Anime Reborn | Shards | — |

The trait tables follow one template. Commons sit around 8–17% for a +5–15% boost to a single stat. Mid tiers run 1–4%. There is an economy trait (Fortune, Midas Touch, Capitalist). At the top is a "god trait" at 0.03–0.2% with an enormous multiplier, usually offset by a **one-placement limit**.

| Game | Top trait | Rate | Effect | Pity |
|---|---|---|---|---|
| Anime Vanguards | Monarch | 0.1% | +300% Damage, −10% SPA, +5% Range, placement limit 1 | 1,500 rerolls ([seemeta](https://seemeta.com/en/anime-vanguards/traits); [fandom Traits](https://animevanguards.fandom.com/wiki/Traits)) |
| Anime Last Stand | Glitched | 0.03% | +750% DMG (+350% in another patch), one placement ([Deltia's](https://deltiasgaming.com/?p=168829)) | — |
| ASTDX | All Star | 0.2% | top trait; Corrupted (0.8%) adds Shield Bypass | 1,000 (Corrupted 450) ([ASTDX Fandom](https://astdx.fandom.com/wiki/Traits)) |
| Anime Reborn | Paladin / Miracle | 0.2% | Miracle limited to one unit per field | Mythic/Secret trait every 200 rolls ([Destructoid](https://www.destructoid.com/anime-reborn-traits-tier-list/)) |
| Anime Defenders | Almighty | 0.1% | plus a second "Divine Trait" layer bought with Raid Shards ([Try Hard Guides](https://tryhardguides.com/anime-defenders-divine-traits-guide/)) | — |
| Anime Rangers X | Seraph / Capitalist | unpublished | Seraph: +50% DMG/HP/Range and **+1 spawn cap**; Capitalist halves costs ([Pocket Tactics](https://www.pockettactics.com/anime-rangers-x-traits)) | — |

Vanguards' full ladder runs from Vigor/Swift/Range I–III at 5% each for the top tier, through Scholar (10%, +50% XP), Marksman (6.5%), Fortune (2.5%) and Blitz (1.85%, −20% SPA), up to the four pity traits:

| Trait | Rate | Effect | Pity |
|---|---|---|---|
| Solar | 0.5% | ~+15.8% DPS | 300 |
| Deadeye | 0.375% | 45% crit chance, +50% crit damage | 400 |
| Ethereal | 0.175% | ~+50% DPS | 858 |
| Monarch | 0.1% | +300% Damage, placement limit 1 | 1,500 |

Pity is **tracked per unit and survives evolution** ([allthings.how](https://allthings.how/anime-vanguards-how-to-roll-the-0-1-monarch-trait-on-jotaro/)). Every one of those pity thresholds is exactly **1.5× the expected number of rolls** (for example, 1 ÷ 0.1% = 1,000 rolls, and Monarch's pity is 1,500). That rule makes pity tuning trivially reproducible. Traits also reset on trade, which stops the market from laundering perfect rolls ([wiki.vanguards.gg Trading](https://wiki.vanguards.gg/Trading)). A second-layer variant appears in ALS, where "double traits" put two techniques on one unit at about 0.5% per roll ([Deltia's](https://deltiasgaming.com/how-to-get-double-traits-in-anime-last-stand-roblox/)).

Vanguards' second reroll layer, **stat grades**, is its most elegant anti-pay-to-win lever. Damage, SPA and Range each roll a grade:

| Grade | Damage bonus | SPA / Range bonus |
|---|---|---|
| D | 0–4.99% | — |
| S | 14–16.99% | 7–8.49% |
| Above S | Z, Z+, up to "Deity" | — |

([fandom Stats](https://animevanguards.fandom.com/wiki/Stats); [Destructoid](https://www.destructoid.com/increase-reroll-potential-fast-anime-vanguards/)). Stat Chips reroll all three stats and Super Stat Chips reroll one. The odds depend on a **potential meter that fills with the unit's takedowns**. At 100% potential, which takes 5,000 takedowns, results are A or better only: A 75%, S 20%. The meter resets after each roll ([wiki.vanguards.gg Stats](https://wiki.vanguards.gg/Stats)). Money can buy chips, but playtime makes each chip better. No comparable stat-grade system was confirmed in the other games.

## Economy, live ops and platform rules decide the business

Vanguards runs a multi-currency economy:

- **Yen**: in-match currency.
- **Gems**: summons.
- **Gold**: evolutions and storage.
- **Mode tokens and event currencies.**

Account level gates the progression: Secret and Shiny results at level 10, many codes and Towers at 30, trading at 50. Around it sit a 50-level Battle Pass with a featured unit on both the free and premium tracks ([allthings.how](https://allthings.how/anime-vanguards-how-to-max-the-meliodas-battle-pass-fast/)), plus daily, weekly and evolution-guide quests ([fandom Quests](https://animevanguards.fandom.com/wiki/Quests)).

Gamepass prices across the leaders:

| Gamepass | Price (Robux) |
|---|---|
| Vanguards VIP (cheaper summons, +XP) | **299** |
| Vanguards Shiny Hunter | 1,299 |
| Vanguards Display All Units | 599 |
| Vanguards Extra Storage (+50 slots) | 149 |
| Vanguards Premium Pass | 799 |
| ALS 3x Game Speed | 799 |
| ALS 3 More Team Slots | 599 |
| ALS Starter Pack | 499 |

Sources: [twinfinite](https://twinfinite.net/guides/how-to-get-anime-vanguards-gamepass-coupons/); [Rolimons ALS](https://www.rolimons.com/gamepass/866675844).

TDS proves a no-gacha alternative works:

- Towers unlock through levels and coins.
- Crates sell cosmetic skins.
- A 50,000-coin Golden Crate grants "Golden" skins with gameplay perks ([TDS wiki Golden Crate](https://tds.fandom.com/wiki/Golden_Crate)).

The live-ops recipe is consistent. Vanguards shipped about 15 numbered updates in roughly 25 months, plus ".5" and "Part 2" follow-ups ([Pro Game Guides](https://progameguides.com/roblox/anime-vanguards-codes/)). Each update brings a new event currency, banner, featured unit, code and mode, and renames the experience title ("Wrathful Assault", "2nd Anniversary") for discovery ([RoWatcher](https://rowatcher.com/games/5578556129/vanguards-2nd-anniversary)). Anniversaries add 7-day login rewards ([Gamezebo](https://www.gamezebo.com/walkthroughs/anime-vanguards-2nd-anniversary-codes/)). TDS does the same with "[EVENT]" and "[NEW BOSS]" title tags and multi-night events like Hexscape ([TDS wiki Hexscape](https://tds.fandom.com/wiki/Hexscape_Event)).

Roblox's discovery system rewards exactly what that cadence produces:

- **Play-through rate** from Recommended for You is the top signal.
- First-play **bounce under 60 seconds** counts against the game.
- Play days are measured across D1, D2–7 and D8–28 ([Roblox Discovery](https://create.roblox.com/docs/production/promotion/discovery)).
- Thumbnail personalization tests up to five thumbnails and raised qualified play-through by **8.5% on average** ([GamesBeat](https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/)).

The money mechanics in 2026:

- **DevEx pays $0.0038 per Robux** since September 5, 2025 ([DevForum RDC25](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)).
- **Creator Rewards** replaced Premium Payouts and holds earnings for 60 days ([DevForum](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)).
- **Managed Pricing** automatically enrolls items in regional pricing and price tests ([DevForum](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)). Prices must be read at runtime, never hard-coded.
- **Rewarded video ads** are open to experiences with 2,000+ monthly unique visitors and must reward a developer product ([DevForum](https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278)). One developer reported earning only 171 Robux in a month, so treat ads as a supplement.

Platform policy is binding:

- **Odds disclosure.** Any summon bought with Robux, or with a currency that can be bought with Robux, is a **Paid Random Item**. The game must list every outcome with numerical odds that **sum to exactly 100%**, show them before purchase, and update them live when boosted ([Roblox PRI policy](https://create.roblox.com/docs/production/monetization/paid-random-items)).
- **PolicyService.** `PolicyService:GetPolicyInfoForPlayerAsync` returns `ArePaidRandomItemsRestricted` and `IsPaidItemTradingAllowed`. When the first is true, the game must hide, replace or block paid summons ([PolicyService docs](https://create.roblox.com/docs/reference/engine/classes/PolicyService); [creator-docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md)).
- **Regulated markets.** Roblox's 2026 clarification names **Australia, Belgium, the Netherlands, the UK and Brazil** and requires testing with the Player Emulator ([DevForum](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)). Roblox publishes no full country list, so always query the API.
- **Maturity labels.** Unrated experiences cannot be played. Minimal and Mild labels reach the 5–15 Kids and Select audiences ([Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity)).
- **Chat age checks.** Since January 2026, age checks gate chat worldwide ([Roblox Newsroom](https://about.roblox.com/newsroom/2026/01/roblox-age-checks-required-to-chat)). That weakens chat-negotiated trading and favors a structured trade UI.

Exploits target client-trusted remotes: placement anywhere, duplication, reward spam. The fix is server validation of every request ([DevForum](https://devforum.roblox.com/t/tower-defense-game-preventing-exploiters-from-abusing-placements/3801331)). Titan Tower Defense had to roll player decks back about 8 days after a hacked item value in March 2026 ([NamuWiki](https://en.namu.wiki/w/Titan%20Tower%20Defense)).

## The haret-al-yasmin build plan: systems, numbers, toolchain and milestones

The strategy is to combine the strongest proven pieces and drop the ones that killed games:

- **Vanguards' meta depth**: summon, trait, stat-grade and evolution layers with per-unit pity.
- **TDS's strategic core**: attribute-checked enemies, fair co-op cash and support towers.
- **BTD6's boss kit**: HP thresholds, Elite tiers and time limits.
- **Original IP**, which no competitor in the anime space has.
- **Bounded pity, a fair-play mode and no premium-priced summon currency**, which answer the Anime Defenders and TTD failure modes.

Every number below is a starting value to tune with telemetry, not a sourced fact. Where a number is modeled on a competitor, the source is the evidence above.

### Original IP is the foundation, not a nice-to-have

Build haret-al-yasmin on an **original cast and world**. Every big anime TD has had its existence threatened by IP, and relaunches recover only about half their audience. Parody spellings did not make Vanguards safe from criticism either.

The name suggests a natural original setting. "Haret al-Yasmin" means roughly "the Jasmine Quarter": a night-blooming city district whose guardians defend its lanes against waves of an invading blight. The setting gives you four things a licensed anime never could: lore you own, merch and licensing optionality (the TenSura license route chosen by the Anime Adventures team shows the value of clean IP ([allthings.how](https://allthings.how/?p=224262))), freedom to rebalance any character, and zero takedown exposure.

Write an IP bible with these rules:

- Characters may be inspired by archetypes (the stoic swordsman, the lightning prodigy) but **never named characters**, logos, signature attack names, recognizable silhouettes or ripped models.
- Prefer CC0 sources such as Poly Haven for reference and kitbash assets.
- Avoid unattributed CC-BY content. About 69% of Poly Pizza models need attribution ([blender-mcp](https://github.com/ahujasid/blender-mcp)).
- License-check every AI-generated mesh.
- Before the first commit, sign written contracts with every contributor that include **IP assignment and a defined revenue share**. The Vanguards lawsuit is the cautionary tale.

### Mode list: launch with five, add one per update

| Mode | Unlock | Format | Primary reward | Phase |
|---|---|---|---|---|
| Story | start | 4 worlds × 6 acts, Normal (15/18/20/22/25/30 waves) and Nightmare | Gems, Gold, XP, unit drops | Launch |
| Infinite | clear Act 6 of a world | endless; HP ×1.06 per wave after wave 30 | Gems per wave milestone, leaderboard | Launch |
| Trials (Challenges) | Lv 5 | Story stage + modifier; 30-min (cap 20/day), daily, weekly | Trait Seeds (1 / 3 / 20), doubled on weekends | Launch |
| Raid | Lv 15 | 6 stages × 20 waves, bosses at 10 and 20 | Raid Sigils → evolution relics, Divine Seeds | Launch |
| Boss Bounty | Lv 10 | single boss, 3 phases, 5-min limit | 1 Trait Seed each, cap 10/day | Launch |
| Legend Stages | clear world Nightmare | remixed Nightmare-only stages | Evolution relics, Essence | Update 1 |
| Bazaar Dungeons | Lv 25 | 30 waves, pick 1 of 3 roguelite cards every 5 waves | Dungeon tokens → Charms (equipment) | Update 2 |
| Minaret Climb | Lv 30 | 50-floor ladder, rewards loop after 50; seasonal leaderboard | Bulk Seeds and Stat Cores | Update 3 |
| Night Bloom Rifts | Lv 10 | hub event every ~60 min, up to 6 players, MVP 2× rewards at 3+ players | Event currency | Update 3 |
| Boss Event | Lv 20 | 5 Normal tiers → Elite, 20-wave time limit per tier | Exclusive cosmetics, banner currency, leaderboard | Update 4 |
| Fair-Play Arena | Lv 30 | traits and stat grades disabled; score attack, then 2v2 versus | Ranked cosmetics only | Update 5 |
| Garden Idle (AFK) | Lv 10 | AFK zone, passive rolls every 15 min | Gold, low-odds AFK-exclusive unit | Update 6 |

The Infinite, Minaret and Raid structures copy the 50-floor loop, the hourly MVP Rift and the 6×20 Raid from Vanguards and ALS. The Fair-Play Arena borrows ASTDX's trait-free modes so leaderboards stay skill-based. Run the Boss Event's Normal → Elite progression and time limits on the BTD6 model.

### Units: eight roles, ground/hill placement, a Lv4 fork and one active each

| Rarity | Passives | Placement cap | Active | Evolves | Launch count |
|---|---|---|---|---|---|
| Rare | 0–1 | 5–6 | none | no | 8 |
| Epic | 1 | 4–5 | none | no | 8 |
| Legendary | 2 | 3–4 | 1 active | no | 8 |
| Mythic | 2–3 | 3 | 1 active + ultimate | yes | 5 |
| Secret (limited) | 3 | 1–2 | 1 active + ultimate | yes | 1 per banner |

Skip a separate "Vanguard" apex tier at launch. Add a Transcendent evolution path later instead of a new rarity, so the rarity ladder never gets reworked.

| Role | Placement | Job | Example tuning |
|---|---|---|---|
| Striker (single-target DPS) | ground | boss and elite DPS | highest base damage; "Strongest" targeting default |
| Sweeper (AoE) | ground | circle, cone or line splash vs swarms and splitters | ~40% of Striker per-hit damage across up to 6 targets |
| Marksman (anti-air) | hill | only role that hits Flyers at full damage | +range; other roles deal 50% to Flyers or cannot target them |
| Lantern (detector) | hill | reveals Veiled enemies within aura for all players | detection from Lv2; modest damage |
| Breaker | ground | shreds Shields and Armor | 3× damage to shield pools; strips Armor in 3 hits |
| Warden (CC) | ground | slow and stun; vs bosses, stuns become 20% slows | TDS boss stun rule |
| Herald (support) | hill | range/damage/SPA aura incl. teammates; active "Rally" +15% SPA for 10s | TDS DJ/Commander model |
| Merchant (farm) | ground | cash per wave | see farm table below |

Each unit gets **Lv0 plus 5 upgrades, and Lv4 forks into two branches** (for example single-target or splash). This is TDS's Enforcer fork, a casual-friendly version of BTD6 crosspaths that doubles build identity without doubling unit IDs.

**Actives and ultimates.** Legendary and higher units get one manual active on a 30–90 second cooldown. Mythic and Secret units add an **ultimate that charges from damage dealt and support uptime**, with a 1–2 second camera flourish that skips after the first viewing. Auto Play should place and upgrade but never fire actives, which keeps hard content skill-tested as Vanguards does.

**Duplicates** feed a "Bloom" track (Bloom 1–5: +2% Damage each and a cosmetic petal aura at Bloom 5), so pulls keep value after the first copy, as with ASTDX skill nodes.

**Evolution** applies to Mythics and Secrets. It costs a unit-specific Relic from a Legend or Raid stage, **15,000 Gold (30,000 for Secrets)**, 20 Essence, and a quest such as 1,000 takedowns with that unit. Evolution adds a passive, upgrades the ultimate and swaps the model. This mirrors Vanguards' cost structure.

| Farm | Cap | Place | U1 | U2 | U3 | U4 | U5 | Cash/wave by level | Total |
|---|---|---|---|---|---|---|---|---|---|
| Spice Caravan (Rare) | 3 | 500 | 900 | 1,600 | 2,600 | 3,600 | — | 150 / 350 / 700 / 1,200 / 1,900 | 9,200 |
| Silk Bazaar (Legendary) | 1 | 800 | 1,500 | 3,000 | 5,500 | 9,000 | 13,000 | 200 / 500 / 1,100 / 2,200 / 3,800 / 6,000 | 32,800 |

The Caravan matches the ~9,000 total of Vanguards' Sprintwagon and TDS's Farm. The Bazaar is tuned so it only wins in modes longer than about 25 waves, the same intent as Takaroda.

### Summons: familiar rates, friendlier bounded pity and a spark

| Rarity | Standard rate |
|---|---|
| Rare | 72.00% |
| Epic | 22.50% |
| Legendary | 4.75% |
| Mythic | 0.70% |
| Secret (limited banners only) | 0.05% |
| **Total** | **100.00%** |

Pricing and pity:

- **Cost**: 50 Gems per pull, or 500 Gems for 10× with the tenth slot guaranteed Epic or better.
- **Hard pity**: **Legendary at 40 pulls and Mythic at 300.** That is about 2× the expected pulls for Mythic, matching the ratio of Vanguards' 400-pull pity at 0.5%.
- **Featured Mythic**: 50% of Mythic results; losing the 50/50 makes the next Mythic the featured one.
- **Featured Secret**: limited banners award **1 Sigil per pull, and 1,200 Sigils buy the featured Secret outright**. Leftover Sigils convert to shop currency at banner end instead of vanishing.
- **Shiny**: an independent **1% roll**, cosmetic only. A Shiny Charm pass can raise it to 2%, with the odds UI updating live.
- **Pity counters**: shared between the standard and featured banners; Secret and Shiny results gated to account level 10.

Rotations: the standard banner is permanent; a featured banner rotates every 4 hours with 2 featured Mythics (gentler than Anime Adventures' hourly loop); and the limited banner runs for each update's lifetime.

Model economy for engaged free players: about 2,000 Gems a day (stages ~1,000, quests ~600, trials ~400). On that budget, a guaranteed Mythic takes about 7.5 days, and the 1,200-pull spark costs 60,000 Gems, roughly 30 days or one update cycle. That bounds the worst case at one chase unit per update for a dedicated free player, compared with Vanguards' whale-scale 20,000-pull guarantee.

Keep codes at 1,000–3,000 Gems plus 10–50 Trait Seeds. Matching Vanguards' 50,000-gem codes would collapse gem scarcity. Do not sell luck potions at launch; they add dynamic-odds burden for little revenue.

### Traits: 17 entries summing to 100%, a crown trait capped at one placement

| Trait | Rate | Effect | Pity (≈1.2× expected) |
|---|---|---|---|
| Might I / II / III | 16.5% / 8% / 2.5% | +5% / +10% / +15% Damage | — |
| Haste I / II / III | 16.5% / 8% / 2.5% | −4% / −8% / −12.5% SPA | — |
| Reach I / II / III | 16.5% / 8% / 2.5% | +5% / +10% / +15% Range | — |
| Scholar | 7% | +50% unit XP | — |
| Merchant | 4% | +20% farm income; −10% upgrade cost on non-farm units | — |
| Steadfast | 3% | immune to boss stuns; +10% damage vs bosses | — |
| Keen Eye | 2.6% | 35% crit chance, +50% crit damage | — |
| Tempest | 1.47% | −20% SPA | — |
| Radiant | 0.60% | +10% Damage, −5% SPA, +25% Range | 200 |
| Eclipse | 0.25% | +25% Damage, −15% SPA, +10% Range, ignores 25% of shields | 480 |
| **Crown of Jasmine** | **0.08%** | **+200% Damage, −10% SPA, +10% Range; placement limit 1** | **1,500** |

The totals add up to exactly 100.00%. Trait Seeds are 1 per reroll. Pity is tracked per unit and carries through evolution. An **auto-reroll "stop at or above" setting** prevents accidentally overwriting a good trait.

Crown of Jasmine follows the Monarch and Glitched pattern: an outsized multiplier made safe by the one-placement cap. Its +200% is deliberately below Monarch's +300% to leave headroom for later power creep.

Add a Divine Seed layer (a second trait slot from Raid Sigils) at Update 2 rather than launch, the way Anime Defenders extended its reroll sink. A free player earning about 40 Seeds a day from trials, bounties and dailies reaches Crown pity on one unit in about five to six weeks. Seeds sell as dev products in packs priced near ASTDX's burner ladder, at roughly 15–25 Robux per Seed.

### Stat grades: potential fills with takedowns

| Grade | Damage bonus | SPA and Range bonus | Base odds | Odds at 100% potential |
|---|---|---|---|---|
| D | 0–4.99% | 0–2.49% | 35% | 0% |
| C | 5–7.99% | 2.5–3.99% | 30% | 0% |
| B | 8–10.99% | 4–5.49% | 22% | 0% |
| A | 11–13.99% | 5.5–6.99% | 10% | 70% |
| S | 14–16.99% | 7–8.49% | 2.5% | 22% |
| SS | 17–19.99% | 8.5–9.99% | 0.45% | 7% |
| Jasmine (Z) | 20–22% | 10–11% | 0.05% | 1% |

The D–S grade ranges copy Vanguards. **Stat Cores** reroll all three stats and **Focus Cores** reroll one. Potential fills linearly to 100% over **3,000 takedowns by that unit**; Vanguards uses 5,000, and the lower count suits shorter planned modes. Potential resets after each roll, and odds interpolate linearly between the base and full-potential columns. This keeps rerolls purchasable but makes playtime the multiplier that matters. Traits and stats are disabled in the Fair-Play Arena.

### Enemies: ten archetypes, attribute checks every five to eight waves

| Archetype | HP × | Speed × | Rule | Counter |
|---|---|---|---|---|
| Wisp (grunt) | 1.0 | 1.0 | baseline | any |
| Courier (runner) | 0.5 | 1.8 | leaks if ignored | Sweeper, Warden |
| Brute | 4.0 | 0.6 | high HP | Striker |
| Veiled | 1.2 | 1.1 | untargetable without detection; splash still hits | Lantern aura |
| Ironbound | 2.5 | 0.8 | immune to non-Breaker damage until its armor breaks, then also loses stun immunity | Breaker (TDS Elite Lead pattern) |
| Warded | 1.5 + shield 1.0 | 1.0 | separate shield pool absorbs first | Breaker, Eclipse trait |
| Moth (flyer) | 0.8 | 1.3 | only hill Marksmen hit it at full damage | Marksman |
| Hive (splitter) | 3.0 | 0.7 | death releases 4 Couriers | Striker, then Sweeper (MOAB-children pattern) |
| Mender | 1.5 | 0.9 | regenerates after 3s unhit; heals neighbors | burst DPS |
| Hexer (disruptor) | 2.0 | 0.9 | stuns the nearest unit in 15 range for 3s every 10s | spacing, Steadfast trait |

HP per enemy is `baseHP × archetype × (1 + 0.12w + 0.004w²) × difficulty`, where `w` is the wave number. The wave factor is 2.6× at wave 10, 5.0× at wave 20, 8.2× at wave 30 and 14.5× at wave 45. Difficulty multipliers: Normal 1.0, Nightmare 2.0 (also applies **Fortified**, doubling shield pools), Legend 3.0, event Hard 10× (the Vanguards Wrath precedent). Infinite multiplies by 1.06 per wave after the final authored wave.

**The wave template for a 20-wave act:**

| Wave | Content |
|---|---|
| 1–4 | basics |
| 5 | first new attribute (Veiled) |
| 8 | spike wave at 2× size |
| 10 | mid-boss |
| 12 | second attribute (Moth) |
| 15 | third attribute (Ironbound) |
| 17 | mixed "exam" wave covering every attribute |
| 18 | breather |
| 20 | untimed, unskippable final boss |

Telegraph the bands with music changes and an enemy-preview strip for the next wave.

**The boss kit:**

- HP-threshold phases at 66% and 33%, each spawning minions or raising a shield.
- A board-stun pulse in a radius with a visible wind-up.
- Stun immunity, with incoming stuns converted to 20% slows.
- Elite variants for Boss Events with a 20-wave time limit.

### Economy and monetization: sell time, convenience and cosmetics

| Currency | Earned from | Spent on |
|---|---|---|
| Cash (in-match) | wave bonus `(250 + 40 × wave) ÷ players`, kills split evenly | placement and upgrades |
| Gems (earned and paid, tracked separately) | stages, quests, codes; paid via dev products | summons, storage |
| Gold | all matches | levels, evolution, Bloom |
| Trait Seeds / Divine Seeds | Trials, Bounties, Minaret, Raid shop | trait rerolls |
| Stat and Focus Cores | Minaret, Dungeons, pass | stat rerolls |
| Raid Sigils, Dungeon tokens, event currency | their modes | relics, Charms, event banners |

Co-op rules follow TDS:

- Starting cash is 600.
- Per-player unit caps shrink with party size (40 / 30 / 25 / 20).
- Vote skip needs all but one player, and AFK players count as abstaining.
- A 90-second reconnect window keeps a dropped player's units alive.

Monetization stays in four channels:

| Channel | Item | Price (Robux) |
|---|---|---|
| Gamepasses | VIP (+10% XP and Gold, 1 free daily summon, chat tag) | 299 |
| Gamepasses | 3× Speed (2× free) | 399 |
| Gamepasses | +100 Storage | 149 |
| Gamepasses | Extra Team Preset Slots | 299 |
| Gamepasses | Shiny Charm | 499 |
| Battle pass | Premium track (featured unit on both tracks) | ~499 per 4–6 week season |
| Battle pass | Monthly "Jasmine Club" subscription with daily Gems | — |
| Gem packs | 600 / 3,300 / 7,000 / 15,000 / 40,000 Gems | 99 / 499 / 999 / 1,999 / 4,999 |
| Rewarded video | 1 free summon ticket per day | — |

All gem prices are read at runtime and left enrolled in Managed Pricing. Never sell single pulls of a scarce summon currency at a premium price; that is the Anime Defenders mistake. Auto Play with shareable layout codes ships free.

Launch without trading. Add it at Update 5 under these rules:

- A level 50 gate.
- Server escrow.
- Traits, stats and Bloom reset on trade.
- Limited Secrets and event units stay untradeable, to avoid TTD-style speculative inflation.

### Compliance: odds tables generated from the same config as the RNG

Because Gems can be bought, every banner, the Trait Seed reroll and the Stat Core reroll count as Paid Random Items. The implementation:

- **One config for odds and RNG.** Each banner's odds table is generated from the same `Banners` config module the server RNG uses. It lists every unit's individual odds to four decimals summing to 100%, sits behind a labeled "View Odds" button rather than a bare (i) icon, and shows live pity counters. Any boost re-renders the table.
- **PolicyService gating.** On join, the server calls `GetPolicyInfoForPlayerAsync`. If `ArePaidRandomItemsRestricted` is true, that player's summon and reroll UI spends **only the earned-Gem and earned-Seed balances**, and their paid Gems go to guaranteed purchases only (unit selector packs, cosmetics, passes).
- **Trading gate.** If `IsPaidItemTradingAllowed` is false, any unit flagged `paidOrigin` cannot be traded.
- **Testing.** Test both paths in the Player Emulator for Australia, Belgium, the Netherlands, the UK and Brazil.
- **Maturity.** Complete the questionnaire targeting **Mild**: stylized combat and no blood, which keeps the 9–15 Select audience reachable.
- **Unit tests.** Assert that every odds table sums to 100%, and run a million-pull simulation that must match the published rates within tolerance.

### Toolchain: Fable 5.1 driving Studio MCP and Blender MCP from one repo

Roblox Studio and its MCP configs exist only for Windows and macOS ([Roblox Studio MCP docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)). So the agent loop runs on the developer's own machine, with this repository cloned locally; the Linux container hosting this repo cannot drive Studio.

Use the **built-in Studio MCP server**, not the legacy `studio-rust-mcp-server`, which was archived on April 3, 2026 ([GitHub](https://github.com/Roblox/studio-rust-mcp-server)). To enable it, open Studio's **Assistant**, choose **… > Manage MCP Servers** and toggle **Enable Studio as MCP server**. A green indicator shows connected clients. Its roughly 27 tools cover:

- Scripts: `script_read`, `multi_edit`, `script_grep`.
- Execution: `execute_luau` in Edit, Client or Server contexts.
- Playtesting: `start_stop_play`, `get_console_output`, `screen_capture`.
- Input simulation: `user_mouse_input`, `user_keyboard_input`, `character_navigation`.
- Assets: `search_asset`, `insert_asset`, `generate_mesh`.
- Multi-instance control through `studio_id`.

For Blender, use `ahujasid/blender-mcp`, now packaged as `mcp-for-blender`. It needs Blender 3.0+, Python 3.10+ and uv. Install the addon with `uvx mcp-for-blender install-addon`, enable "Interface: MCP for Blender", then press N and click **Start MCP Server**. It listens on an unauthenticated localhost socket, port 9876 ([blender-mcp](https://github.com/ahujasid/blender-mcp)).

Claude Fable 5.1 (`claude-fable-5-1`, released September 1, 2026) has these properties ([Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview)):

- 1M-token context and 128K output.
- Always-on adaptive thinking.
- **$10 / $50 per million input/output tokens, with cache reads at $0.25**.
- Forced tool use is unsupported, so any custom harness must use `auto` tool choice.

In Claude Code it requires **v2.1.257+** and is selected with `/model fable` ([Claude Code model config](https://code.claude.com/docs/en/model-config)). Commit a project `.mcp.json` (Windows shown; on macOS the Studio command is `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`) ([Claude Code MCP docs](https://code.claude.com/docs/en/mcp)):

```json
{
  "mcpServers": {
    "Roblox_Studio": { "command": "cmd.exe", "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"] },
    "blender": { "command": "uvx", "args": ["mcp-for-blender"] }
  }
}
```

```bash
# equivalent CLI setup, then launch with Fable 5.1
claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
claude mcp add blender -- uvx mcp-for-blender
export MAX_MCP_OUTPUT_TOKENS=50000   # screenshots and Blender renders exceed the 25K default cap
export DISABLE_TELEMETRY=true        # Blender MCP telemetry is on by default
claude --model fable
```

Code lives on disk under **Rojo** (with Wally packages and git). Rojo streams changes into Studio and deploys from the CLI ([rojo](https://github.com/rojo-rbx/rojo)). The working rule is **one source of truth per script**: Rojo owns all Luau, and the Studio MCP never `multi_edit`s Rojo-managed scripts, because a sync would overwrite those edits. The MCP is used for what files cannot do: inspecting the live DataModel, placing map geometry, inserting assets, playtesting, and reading output.

The optional `Chrrxs/robloxstudio-mcp` fork adds multi-client playtests and script and micro profilers ([Chrrxs](https://github.com/Chrrxs/robloxstudio-mcp)). That is useful for stress-testing enemy replication, but it is third-party and needs HTTP requests enabled.

Put a `CLAUDE.md` in the repo that encodes the conventions: `--!strict`, config-driven data, the server-authority rules, and the Rojo-owned-code rule. The docs advise starting most workloads on Opus 5.5 ($4/$20). A sensible split:

- **Fable 5.1** for architecture, the enemy simulation, economy math and hard debugging.
- **Opus or Sonnet 5.5** for bulk scripting and UI.

In unattended sessions, Fable's usage-credit consent prompt can block a turn for 5 minutes, so pre-approve before running long jobs.

The asset loop:

1. Blender MCP `execute_blender_code` models or decimates the mesh: units at 3–8K triangles and enemies at 1.5–4K, against Roblox's **20,000-triangle per-mesh cap**. It also unwraps a single UV set and bakes 512–1024² PBR maps.
2. `look` verifies the result visually.
3. Export to FBX with **Apply Scalings = FBX Unit Scale**, leaf bones off, at most 4 bone influences per vertex, and **one animation per FBX**. glTF needs no scaling fixes ([Roblox Blender guide](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/blender.md); [specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md)).
4. Upload via the Open Cloud Assets API (≤20 MB per file) ([Assets API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md)).
5. Place it with `insert_asset` and validate with `inspect_instance` and `screen_capture`.

Both MCP servers can read and modify open content, so commit and save before every agent session. Use `BLENDER_MCP_SAFE_MODE=1` when file and network access aren't needed.

### Technical architecture: data enemies, server authority, two places

```
haret-al-yasmin/
  default.project.json  wally.toml  CLAUDE.md  .mcp.json
  src/shared/config/   Units, Traits, StatGrades, Banners, Enemies, Waves, Modes (pure data, --!strict)
  src/shared/sim/      PathMath (cumulative-length tables), Targeting, DamageCalc, Rng (seeded, auditable)
  src/server/services/ Profile (ProfileStore), Summon, Reroll, Policy, Economy, Match, WaveDirector,
                       EnemySim, TowerService, Matchmaking (MemoryStore), Analytics, AuditLog
  src/client/          EnemyRenderer (pooled models), PlacementController, UI (Vide or Fusion)
  tests/               Jest-Lua specs: odds sum to 100%, pity math, wave HP curve, placement validation
  assets/blender/      .blend sources, export scripts, LICENSES.md
```

**Places.** A **Lobby place** holds the hub, summon station, trait shrine, trials board and Rift spawn point. It queues parties in a MemoryStore queue and calls `TeleportAsync` from the server with `ShouldReserveServer = true`. A **Match place** runs a mode. Teleport data carries only a match-ticket ID, because teleport data is client-visible. The match server reads the map, difficulty and party from MemoryStore and validates them against an allowlist ([Teleport docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md); [MemoryStore](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/memory-stores/index.md)).

**Enemies are plain server data**: `{id, typeId, pathId, spawnT, speed, hp, shield, flags}`. Progress along the path is computed analytically from distance-parameterized waypoints. The server sends reliable spawn, damage, death and speed-change events, plus optional UnreliableRemoteEvent corrections packed with `buffer` under the **1,000-byte payload limit** ([Remote events](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/events/remote.md)). Clients compute positions from `GetServerTimeNow()`, move pooled rigged meshes with AnimationController rather than Humanoids, and skip animation for distant enemies.

Community reports put Humanoid-based enemies at lag around 100 units and client-rendered data enemies at around 500–1,000 ([DevForum](https://devforum.roblox.com/t/how-to-optimize-tower-system/2830931/9)). Set the target at 400 enemies on mid-range mobile. Targeting runs at 10 Hz over path-distance buckets and can move into multiple Parallel Luau Actors as unit counts grow ([Parallel Luau](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/multithreading.md)). All damage is resolved on the server, and clients draw the VFX.

**Security and data.**

- **Server authority.** The client never sends damage, positions or currency. Every place, upgrade, sell, summon, reroll and claim request is type-checked, ownership-checked, cash-checked and rate-limited per player with a token bucket. Placement is validated by raycast against tagged Ground or Hill surfaces, off-path, with spacing and cap checks ([Security tactics](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/security-tactics.md)).
- **Player data.** ProfileStore session locking stores player data ([ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)). Every unit is a GUID-keyed record holding level, trait, per-trait pity, stats, potential, evolution, Bloom, shiny and `paidOrigin`. Gems are stored as separate paid and earned balances. Storage caps at 300 units, far below the 4 MB per-key limit ([DataStore limits](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/error-codes-and-limits.md)).
- **Recovery.** Summons, rerolls, trades and currency grants write to an audit log with idempotency keys. Versioned backups enable targeted rollbacks.
- **Rewards.** All rewards are computed on the server from waves cleared and time spent, so macros cannot inflate reward rates.

### Phased milestones: about 26 weeks to launch, then a 3–4 week cadence

| Phase | Weeks | Deliverables | Exit criteria |
|---|---|---|---|
| 0. Foundations | 1–2 | IP bible and contributor contracts; Rojo/Wally/git repo, `CLAUDE.md`, `.mcp.json`; config schemas; Blender export round-trip of one test unit | Fable 5.1 edits code, playtests and reads console via Studio MCP; one asset goes Blender → Open Cloud → Studio |
| 1. Core prototype | 3–8 | 1 map with ground/hill tags; server enemy sim; 6 archetypes; 8 units covering all roles; place/upgrade/sell; Lv4 fork; 1 active; 20 waves + boss; 1–4 player co-op cash rules | 400 enemies stable on mobile; blind playtesters choose to replay |
| 2. Meta systems | 9–14 | Lobby, ProfileStore, matchmaking and teleport; summons with odds UI, pity and spark; PolicyService paths; traits; stat grades; Bloom; evolution for 2 Mythics; quests; account levels | Player Emulator tests pass in the 5 regulated markets; million-pull sim matches tables |
| 3. Content alpha | 15–20 | 4 worlds × 6 acts (Normal and Nightmare), Infinite, Trials, Raid, Bounties; 30 units; Battle Pass S1; onboarding that reaches wave 1 and a free summon within 60 s; analytics funnel | Closed test of 100–300 players; no exploit found in a red-team pass |
| 4. Beta / soft launch | 21–24 | Maturity questionnaire; 5 thumbnails and icon; Discord with code channel; mobile perf pass; backups and rollback drill; small Ads Manager test | First-play bounce and D1/D7 trending up week over week; fix onboarding before scaling ads |
| 5. Launch | 25–26 | Public release with Update 1 (Legend Stages + World 5) about 80% built | Stable servers through launch weekend; codes at like/favorite milestones |
| 6. Live ops | month 7+ | Major update every 3–4 weeks in Part 1 / Part 2 beats: Dungeons + Divine Seeds; Minaret + Rifts; Boss Event (Elite); trading; Fair-Play Arena; Garden Idle | Update-day title tags; each update brings a banner, event currency, mode and codes |

The schedule assumes a small team of 2–4 people (scripting/economy, maps/VFX, character art, community). Claude Fable 5.1 carries much of the scripting, testing and asset-preparation load. The research found no public data on the team sizes or timelines of the top games, so the schedule is a planning estimate.

Measure the signals Roblox ranks on: qualified play-through rate, bounce under 60 s, D1, D7 and playtime. No public TD benchmarks exist, so set targets from your own soft-launch cohort rather than borrowed numbers.

The highest risks, in order:

| Risk | Mitigation |
|---|---|
| Pay-to-win perception | Bounded pity, a spark, a fair mode and no premium summon currency |
| Economy inflation after trading | Untradeable limiteds, resets on trade, sinks |
| Dupes | Session locks, GUIDs, audits |
| System churn | Cap every power axis now; never ship an Ascension you'll have to remove |
| Team disputes | Contracts before code |

## Conclusion

The genre's history argues that haret-al-yasmin should compete on three things the leaders cannot easily copy. The first is **ownership**: original IP removes the takedown risk that ended Anime Adventures and Anime Rangers X and that still hangs over every parody-named competitor. The second is **trust**: published, bounded pity, a spark that a dedicated free player can reach once per update, and a trait-free arena, after Anime Defenders and Toilet Tower Defense showed how quickly players punish perceived greed and speculative economies. The third is **strategic depth**: TDS-style attribute checks and support play layered under Vanguards-style collection. Anime TDs have mostly been stat races, and none of them has paired gacha depth with a loadout puzzle.

Compliance reinforces the third point. Roblox's paid-random-item rules and PolicyService force a clean, data-driven odds pipeline, and that same pipeline makes balance tuning and live-ops iteration faster. The 2026 tooling changes the economics of building all this. With Studio's built-in MCP and Blender MCP, Fable 5.1 can close the write-playtest-observe loop on its own, so a two-to-four-person team can plausibly match the update cadence that kept Vanguards near 80,000 concurrent players. The bottleneck shifts from engineering hours to design judgment and art direction.
