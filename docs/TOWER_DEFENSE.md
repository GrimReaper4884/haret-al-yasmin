# Tower Defense: "Defend the Gate"

*Status: v1 implemented 2026-10-16 · Code: `Config/TD, Units, Enemies, Waves, Arenas, Modes, Banners,
Traits, SeasonPass, Codes, Daily, Audio`, `Logic/TdSim, TdTowers, WaveLogic, Path, UnitLogic, SummonLogic,
PassLogic, CodesLogic, DailyLogic, MatchRewards, Grants`, server `ArenaService, MatchService,
MatchmakingService, MetaService, CrowdService`, client `Match*, Placement, EnemyRender, Summon, Units, Pass,
Codes, Daily, Queue, LobbyMenu, Audio` · Research: `docs/research/ROBLOX_TOWER_DEFENSE_GENRE.md`,
`BAB_AL_HARA_REFERENCE.md`, `ROBLOX_IP_AND_POLICY.md`.*

## 1. Pitch

The lane (the existing roleplay hub) is now the **lobby** of a tower-defense game. Players collect the
neighbourhood's defenders ("the men of the lane": the watchman, the baker, the barber, the water carrier, the
'akeed, the za'im…), step on a portal in the fountain square with up to three friends, and defend the lane
gate against waves of night thieves, gendarmes, bandits and rival-lane thugs. The night begins with the
watchman barring the gate, and the biggest moments are the shabriyeh strikes.

Everything is **inspired by** the classic Damascus hara dramas and built from the shared folk tropes (the gate
and its bar, the 'akeed and the za'im, the shabriyeh, the 'arada troupe, the coffee house, the French post).
No TV character names, likenesses, lines, logos or music are used (see `COPYRIGHT_REGISTER.md` and the IP
report). Unit display names are plain strings in `Config/Strings.luau`.

## 2. Player journey

```
Lobby (the lane)                         Match (arena, far from the lobby)
┌──────────────────────────┐             ┌──────────────────────────────────┐
│ Daily reward · Codes      │  portal     │ Gate closes (cutscene) · prep 15s │
│ Summon (lira) · Units     │ ────────▶   │ waves: place / upgrade / sell     │
│ Loadout (6 slots, +1 pass)│  party 1–4  │ boss every 10 · skip votes        │
│ Diary (season pass)       │ ◀────────   │ win / lose → rewards → home       │
└──────────────────────────┘  rewards     └──────────────────────────────────┘
```

Modes (`Config/Modes`): Episode 1 "Night of the Thieves" (20 waves), Episode 2 "The Rival Lane" (30),
Episode 3 "The Siege" (40), Endless Night (infinite, rewards every 10 waves). Difficulties Normal / Hard /
Nightmare (HP growth ×1 / 1.7 / 4.5 per wave, boss HP ×1 / 1 / 1.8, rewards ×1 / 1.6 / 2.4, gate HP
100 / 60 / 35; full table in §5). Episode N+1 unlocks after
clearing N on Normal; Hard after Normal, Nightmare after Hard, per episode.

## 3. Match rules (`Config/TD`, `Logic/TdSim`, `Logic/TdTowers`)

| Rule | Value |
|------|-------|
| Start cash | 600 per player; wave bonus 110 + 20 × wave; skip vote +60 to all (× `PARTY_CASH`, §5) |
| Prep | 15 s before wave 1, 9 s between waves; all players voting skip starts at once |
| Placement | anywhere inside the arena bounds, ≥ 3.2 studs from the road centreline, ≥ 2.6 from another defender, ≤ 20 per player, per-unit cap (`maxPlaced`) |
| Upgrades | 5 levels (Rare) / 6 (Epic+); sell refunds 60 % of everything spent |
| Targeting | first / last / strongest / closest (per defender) |
| Stealth | night thieves and spies are invisible to defenders without `hitsStealth` (watchman, barber, 'akeed, za'im, 'arada, cat), unless the defender stands inside a watchman's lantern (`revealsStealth`: any other defender within his range sees them too; D-031). A sabotaged watchman's lantern is dark until he is back (D-038) |
| Story mechanics (Season Story 1, D-040) | built in the sim, used from Episode 4 on: **swarm** (groups up to 60, half weight in the 90-per-wave cap), **speed aura** (others nearby walk up to ×aura, best one, never past ×1.6 of base), **shield** (enemies near the bearer, itself too, take less damage; not stacking), **burn** (stacks on the gate: 1 HP per stack every 2 s for 20 s, max 5, out at wave end; `douse` defenders such as Fawza take a stack off per attack), **disguised** (only a lantern bearer or a defender in a lantern's light can hit one; lanterns and those single hits reveal it; splash never) |
| Armor | fraction of damage ignored (bandit 15 %, rider 20 %, sapper 35 %, bosses 20–40 %) |
| Parties | up to 4; regular enemy HP ×1 / 1.65 / 2.3 / 3.0 and boss HP ×1 / 1.35 / 1.65 / 2.1 for 1–4 players (§5) |
| Stuns | chain, but after 6 s of a chain an enemy ignores stuns for 3 s (it walks at least a third of the time) |
| Support | Abu Bader and Abu Hissam multiply the damage of defenders inside their range. **Buffs stack (LP-A02, D-092):** the multiplier is 1 + Σ(buff − 1) over every other support covering the defender, counting one player's copies of the same unit once (the strongest), capped at `TD.BUFF_CAP` = 1.8 (+80 %, never below one support's own buff). A sabotaged support gives nothing until it is back. Hastes (the 'akeed's Rally) multiply the cooldown, floored at `TD.HASTE_FLOOR` = 0.7. The sim caches each defender's total and recomputes it on place / upgrade / sell / ally / sabotage / wave end. The badge and the panel show the total and the count ("▲ +25% ·2"); selecting a support outlines the defenders it reaches |
| Farm / repair | the coffee-house keeper pays cash per cleared wave; Abu Issam repairs the gate per wave |
| Abilities | **shabriyeh** ('akeed ×6 / za'im ×10 / great za'im ×15 damage on one hit, every 12 / 9 / 7 s); **sweep** (strongman, 'arada: damage to everything in a radius) |
| Speed | 1× / 2× free; 3× with the Fast Mode pass (host controls) |
| Tick | 20 Hz fixed step; positions streamed at 10 Hz on an UnreliableRemoteEvent; client interpolates along the path |

The simulation is pure (`TdSim.step(state, dt)` returns events) and covered by `tests/td.spec.luau`.

## 4. Defenders (`Config/Units`; names one letter off since 2026-10-18, STORY_PLAN §3, C-241)

| Id | Name (EN) | Rarity | Role | Signature |
|----|-----------|--------|------|-----------|
| walad | Lane Boy | Rare | ranged | starter unit, cheap, 8 max |
| natour | Abu Hares the Watchman | Rare | ranged | sees stealth, lantern slows and reveals stealth to defenders in his range |
| farran | Abu Baseer the Baker | Rare | splash | hot loaves |
| saqqa | Fawza | Rare | splash | broom sweep, slows |
| hallaq | Hissam, the Barber's Son | Rare | melee | fast razor, sees stealth |
| khayyat | Abu Ghadeb the Chickpea Seller | Rare | ranged | longest range |
| qahwaji | Abu Hazem of the Coffee House | Rare | farm | cash per wave |
| qabaday | Mo'ez | Epic | melee | shabriyeh ×6 |
| haddad | Abu Shater the Blacksmith | Epic | splash | stuns |
| mukhtar | Abu Bader | Epic | support | +15–65 % damage aura |
| zaim | Za'im Abu Faleh | Legendary | melee | shabriyeh ×10 |
| pahlawan | The Strongman | Legendary | splash | sweep, stun |
| umm_hara | Abu Hissam, the Barber-Hakim | Legendary | healer | repairs the gate, small aura |
| arada | The 'Arada Troupe | Mythic | splash | wide sweep |
| zaim_akbar | Al-'Akeed Abu Shehan | Mythic | melee | shabriyeh ×15; season-1 pass level 50 |
| adashari | Al-Adashari, the Night Guard | Secret | melee | the only secret unit: Episode 9 wins (1 / 2.5 / 6 %, pity 40, first Nightmare clear guarantees him), never from a banner. The Cat (`qitt`) retired in S1-S12b (D-052) |

Copies → stars (+5 % damage each; 1/2/4/7/11 extra copies). Each owned unit has one **trait**, and a second
slot from 3 stars (traits v2, D-041; `Config/Traits`: steady, swift, keen, sharp, golden, hawk, za'im's blood,
legend, lantern, fireproof, miser, twins), each rerolled with a trait stone. Two traits never stack a stat (the
better one wins) and traits are capped at damage ×1.5, range ×1.25, cooldown ×0.85.

## 5. Attackers and balance (`Config/Enemies`, `Config/Waves`, `Config/TD`)

Gendarme, night thief (fast, stealth), orchard bandit (tank), rival-lane thug, mounted officer (fast tank),
sapper (slow, armored, 8 gate damage), spy (stealth). Bosses: the Sergeant (wave 10), the Thief King (20,
stealth), the Za'im of the rival lane (30), the Commandant (40; endless cycles them every 10 waves). Waves are
generated from per-episode pool scripts (`WaveLogic.story`) with linear HP growth; endless uses quadratic
growth that also compounds after wave 50, and a speed creep capped at ×1.6.

### Balance pass (2026-10-16)

Tuned with an auto-battler that plays every mode × difficulty × loadout on the real simulation:
`lune run tests/balance` (summary), `lune run tests/balance ep1 normal re6up` (one run, wave by wave),
`--md` for a Markdown table. The bot places its plan at the spots covering the most road, saves for the next
defender, then buys the upgrade with the most damage per cash (settling for an affordable one after a wave
that leaked); it never sells or retargets. The targets are asserted in `tests/td.spec.luau` ("Balance").
Wave-by-wave results: `TEST_REPORT_SLICE.md`, last section.

**Design targets.** Episode 1 Normal is won by 4–6 upgraded Rare/Epic defenders; without upgrades the wave-10
Sergeant breaks the defence and the run falls before the wave-20 Thief King. Hard needs a bigger upgraded
Rare/Epic team or a Legendary. Nightmare needs Mythics. Endless walls every team between waves 60 and 100.
Bosses are gate-breakers (40 / 60 / 80 / 100 gate damage): on Hard and Nightmare one leaked boss ends the run.

**Difficulties** (`TD.DIFFICULTIES`; HP of wave *w* in an episode = base × hp × (1 + hpPerWave × growth × (w − 1)),
bosses × boss on top; endless: base × hp × (1 + endless × (0.05 w + 0.006 w²)) × 1.035^(w − 50) after wave 50)

| | hp | growth | endless | boss | speed | kill cash / lira | gate |
|---|---|---|---|---|---|---|---|
| Normal | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | ×1 | 100 |
| Hard | 1.25 | 1.7 | 1.25 | 1.0 | 1.05 | ×1.6 | 60 |
| Nightmare | 1.0 | 4.5 | 1.6 | 1.8 | 1.1 | ×2.4 | 35 |

Nightmare starts at Normal HP so the opening is playable with 600 cash, then grows 4.5× as fast; its 2.4×
kill cash is what pays for the Mythics it demands.

**Attackers** (Normal, wave 1)

| Enemy | HP | Speed | Armor | Reward | Gate dmg | Notes |
|---|---|---|---|---|---|---|
| gendarme | 40 | 5.5 | – | 14 | 1 | every opener |
| thief | 28 | 8.5 | – | 12 | 1 | stealth; from wave 5 (ep1/ep2/endless) |
| thug | 90 | 5.6 | – | 22 | 1 | was 6.0 |
| bandit | 160 | 4.0 | 15 % | 30 | 2 | |
| rider | 180 | 6.8 | 20 % | 40 | 3 | was 220 HP / 7.5 |
| sapper | 320 | 3.2 | 35 % | 55 | 8 | |
| spy | 140 | 7.0 | – | 35 | 2 | stealth |
| **sergeant** | 700 | 3.8 | 20 % | 200 | **40** | was 900 HP / 4.2 / 10 dmg |
| **chief_thief** | 1200 | 4.6 | – | 320 | **60** | stealth; was 1400 / 5.5 / 15 |
| **rival_zaim** | 2600 | 4.8 | 25 % | 500 | **80** | was 25 dmg |
| **colonel** | 6000 | 3.6 | 40 % | 1200 | **100** | was 40 dmg |

**Waves** (`Config/Waves`): ep1 hpPerWave 0.07, opens with gendarmes (thieves from wave 5, thugs 7, bandits
12); ep2 0.075 (was 0.08), opens with gendarmes (thugs 3, thieves 5, bandits 9, spies 14, riders 18); ep3 0.075
(was 0.09), 4 gendarmes on wave 1 (was 6; thugs 4, riders 8, bandits 11, spies 13, sappers 18, thieves 22);
endless hpPerWave 0.05, hpPerWaveSq 0.006 (was 0.10 / 0.004), lateFrom 50, lateGrowth 0.035, gendarme opener
(thieves 5, thugs 7, bandits 11). **Units**: the Watchman's levels 1–2 hit 4 / 6 (was 3 / 5) at 1.15 / 1.1 s
(was 1.2 / 1.15 s) so the only cheap stealth detector can hold the first thieves. **Economy**: start cash 600
(was 500), wave bonus 110 + 20 × wave (was 90 + 20 ×).

**Outcome** (`lune run tests/balance --md`; WIN gate left / max, "lost wN" = the gate fell on wave N, endless
"died wN"). Loadouts (≤ 6 unit types, 7 with the Extra Slot pass): **re6** Lane Boy, Barber, Watchman, 'Akeed,
Blacksmith, Mukhtar, no upgrades · **re4up** the first four + upgrades · **re6up** re6 + upgrades · **re10up**
10 Rare/Epic towers (3 Barbers, 2 'Akeeds, 2 Watchmen…) + upgrades · **leg6** Lane Boy, Barber, Watchman, Za'im,
'Akeed, Mukhtar, no upgrades · **leg10up** 10 towers with 2 Za'ims + 2 Strongmen + upgrades · **myth12up** 12
towers: Barbers, Za'ims, Great Za'im, 'Arada, Strongmen, Mukhtars + upgrades · **whale** 16 towers of the same
plus 4 'Akeeds, 5 stars, za'im's-blood trait.

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | myth12up | whale |
|------|-------|------|------|------|------|------|------|------|------|
| ep1 | normal | lost w14 | WIN 100/100 | WIN 100/100 | WIN 100/100 | lost w19 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep1 | hard | lost w10 | lost w18 | lost w20 | WIN 15/60 | lost w11 | WIN 57/60 | WIN 54/60 | WIN 60/60 |
| ep1 | nightmare | lost w9 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 32/35 | WIN 35/35 |
| ep2 | normal | lost w11 | lost w19 | WIN 74/100 | WIN 83/100 | lost w15 | WIN 90/100 | WIN 80/100 | WIN 96/100 |
| ep2 | hard | lost w9 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 40/60 | WIN 33/60 | WIN 50/60 |
| ep2 | nightmare | lost w7 | lost w7 | lost w7 | lost w8 | lost w8 | lost w10 | WIN 3/35 | WIN 22/35 |
| ep3 | normal | lost w11 | lost w15 | lost w13 | lost w20 | lost w14 | WIN 94/100 | WIN 83/100 | WIN 96/100 |
| ep3 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w20 | WIN 26/60 | WIN 56/60 |
| ep3 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w10 | lost w10 | WIN 29/35 |
| infinite | normal | died w12 | died w16 | died w14 | died w17 | died w13 | died w21 | died w70 | died w80 |
| infinite | hard | died w10 | died w10 | died w10 | died w11 | died w10 | died w19 | died w30 | died w70 |
| infinite | nightmare | died w9 | died w10 | died w10 | died w10 | died w10 | died w30 | died w40 | died w40 |

Reading it: each episode raises the bar by one tier (ep1 Normal: 4 upgraded Rare/Epic; ep2 Normal: 6–10;
ep3 Normal: a Legendary), Hard adds one tier, Nightmare needs Mythics (ep3 Nightmare also stars/traits).
Endless deaths land on boss waves (60 = stealth Thief King, 100 = Commandant), so the "wave reached" is
quantized by tens; a fully maxed Mythic team stalls at 79–80 on Normal with six-figure cash it can no longer
spend (whale endless was w93 / w82 on Normal / Hard before stun chains were capped, see below). Known
limits: the bot never sells, and its placement is greedy, so margins of a few gate HP (ep2 Nightmare myth12up
3/35) should be treated as coin flips.

### Season Story 1 ladder (2026-10-18, S1-S04, D-057)

Episodes 4–6 continue the solo ladder (STORY_PLAN §5.3) with the Season 1 loadouts: **leg10up+sig** leg10up
buying level-7 signatures (path a) · **myth12up+beads** myth12up with beads in 2 of 3 slots (cooldown, range)
· **whale2** the whale with two traits (za'im's blood + hawk), beads and signatures, 7 slots. The bot brings
what an episode asks for and pays a loadout slot for it (`AutoBattle.adapt`): two Watchmen against disguised
attackers (Episode 6), Fawza against burning ones (Episode 5), in place of the plan's least-used unit type.
Episodes 1–3 and Infinite are unchanged (frozen in `tests/td.spec.luau`).

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | leg10up+sig | myth12up | myth12up+beads | whale | whale2 |
|------|-------|------|------|------|------|------|------|------|------|------|------|------|
| ep4 | normal | lost w11 | lost w18 | lost w20 | lost w20 | lost w14 | WIN 96/100 | WIN 96/100 | WIN 99/100 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep4 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 31/60 | WIN 31/60 | WIN 35/60 | WIN 40/60 | WIN 60/60 | WIN 60/60 |
| ep4 | nightmare | lost w8 | lost w9 | lost w8 | lost w8 | lost w6 | lost w10 | lost w10 | lost w8 | lost w20 | WIN 30/35 | WIN 35/35 |
| ep5 | normal | lost w12 | lost w17 | lost w30 | lost w30 | lost w13 | WIN 98/100 | WIN 98/100 | WIN 78/100 | WIN 87/100 | WIN 98/100 | WIN 99/100 |
| ep5 | hard | lost w9 | lost w9 | lost w12 | lost w12 | lost w10 | WIN 24/60 | WIN 24/60 | lost w9 | WIN 6/60 | WIN 58/60 | WIN 60/60 |
| ep5 | nightmare | lost w7 | lost w6 | lost w7 | lost w7 | lost w7 | lost w6 | lost w6 | lost w7 | lost w8 | WIN 29/35 | WIN 34/35 |
| ep6 | normal | lost w11 | lost w13 | lost w25 | lost w50 | lost w13 | lost w50 | WIN 80/100 | WIN 78/100 | WIN 83/100 | WIN 96/100 | WIN 100/100 |
| ep6 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 9/60 | WIN 19/60 | WIN 51/60 | WIN 58/60 |
| ep6 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w7 | lost w8 | lost w50 | WIN 35/35 |

Reading it: Episode 4 (the saha, two roads) is the Legendary wall at Abu Jawdan's first visit on wave 20;
Episode 5's torchbearers and Abu Shatour burn the door, but in the harness the burn costs less than the
loadout slot Fawza takes, so the bot wins Episode 5 without her (D-058); Episode 6 needs two
lanterns and, on Normal, the level-7 signatures to get Lateef down before his jump. Nightmare stays
whale territory (whale2 only in Episode 6): the frozen Nightmare multipliers (boss ×1.8, growth ×4.5) put a
boss ~6× further from Normal than the step between two loadouts, so no single boss HP could make
myth12up+beads the Nightmare answer without also handing Normal to Rare/Epic teams. Lateef's window is narrow
(4,750–4,925 HP keeps all three Episode 6 targets): retune him with the harness, never by feel.

### Episodes 7–9 (2026-10-18, S1-S09, D-066)

Same loadouts and bot. Episode 7 is the police-post road (one road); Episodes 8 and 9 the twin gates, where
spawns alternate between both roads (`Modes.twinRoads`) and the one-armed guard stands as an ally (Episode 8
from wave 41, after he comes as the thief on wave 40; Episode 9 from wave 1, taking the first 20 gate damage).
Every cell meets the STORY_PLAN §5.3 target and no lower tier wins it (asserted in `tests/td.spec.luau`).

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | leg10up+sig | myth12up | myth12up+beads | whale | whale2 |
|------|-------|------|------|------|------|------|------|------|------|------|------|------|
| ep7 | normal | lost w10 | lost w12 | lost w31 | lost w35 | lost w12 | lost w50 | lost w50 | WIN 80/100 | WIN 83/100 | WIN 100/100 | WIN 100/100 |
| ep7 | hard | lost w8 | lost w10 | lost w9 | lost w10 | lost w10 | lost w10 | lost w10 | lost w8 | WIN 10/60 | WIN 56/60 | WIN 58/60 |
| ep7 | nightmare | lost w7 | lost w8 | lost w7 | lost w7 | lost w7 | lost w7 | lost w7 | lost w7 | lost w7 | lost w50 | WIN 35/35 |
| ep8 | normal | lost w12 | lost w15 | lost w15 | lost w15 | lost w13 | lost w55 | lost w55 | lost w55 | WIN 84/100 | WIN 100/100 | WIN 100/100 |
| ep8 | hard | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w55 | lost w55 | WIN 56/60 |
| ep8 | nightmare | lost w5 | lost w5 | lost w5 | lost w5 | lost w5 | lost w5 | lost w5 | lost w6 | lost w7 | lost w55 | WIN 31/35 |
| ep9 | normal | lost w13 | lost w14 | lost w15 | lost w15 | lost w14 | lost w30 | lost w30 | lost w30 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep9 | hard | lost w10 | lost w10 | lost w12 | lost w12 | lost w11 | lost w13 | lost w13 | lost w13 | lost w15 | lost w15 | WIN 60/60 |
| ep9 | nightmare | lost w9 | lost w8 | lost w9 | lost w9 | lost w9 | lost w10 | lost w10 | lost w10 | lost w11 | lost w15 | WIN 35/35 |

Reading it: in this harness a maxed bot kills every regular enemy late, so the ladder is set by bosses
(`Waves.bossHp`, a factor per boss wave, optionally one per difficulty): Episode 7's commandant is the
finale's damage check (×2.5 Normal, ×1.8 Hard, ×1.6 Nightmare); Episode 8 softens Fakhr at wave 15 (×0.5)
and tunes the enraged 'akeed so that only beads beat him on Normal (×1.25, a narrow window) and whale2 just
holds on Nightmare (×0.44 wins 31/35, ×0.45 loses: the plan's coin flip); Episode 9 pins its bosses to the
long road (`bossRoad = 2`), sends Fakhr and the commandant down the other one as escorts at 0.3 HP
(`Waves` pool `path`, `hp`), and makes Lateef at wave 30 the Normal wall (×1). The ally does not decide
Episode 9 Nightmare in the harness (whale2 wins without him too).

### Party scaling (2026-10-16)

Every player in a party gets the full start cash and wave bonus and builds their own defence (≤ 20 towers
each), so without scaling 4 players were ~4× stronger against the same waves. `TD.PARTY_*` (indexed by
players in the match; `WaveLogic.partyScale`, applied in `MatchService.create`):

| Players | regular enemy HP (`PARTY_HP`) | boss HP (`PARTY_BOSS_HP`) | cash each (`PARTY_CASH`) |
|---|---|---|---|
| 1 | ×1 | ×1 | ×1 |
| 2 | ×1.65 | ×1.35 | ×1 |
| 3 | ×2.3 | ×1.65 | ×1 |
| 4 | ×3.0 | ×2.1 | ×1 |

Why these shapes: a party's cash grows by N × (start + wave bonus), but kill cash is shared (it goes to the
tower that lands the kill), the road fills up (later towers get worse spots) and more towers means fewer
upgrade levels each, so the swarm multiplier stays below N. Bosses get a milder curve because a single boss
walks past *every* player's defence; with the swarm curve on bosses too, upgraded parties lost to the
wave-10/20 bosses they beat solo. Cash stays ×1 so every player can place a defender on wave 1 (the knob is
there if live data says parties snowball).

Tuned with `lune run tests/balance --party N` (N auto-battlers, each playing the column's loadout with its own
cash, deciding in rotating order). Party ladders (compare with the solo table above; asserted in
`tests/td.spec.luau` "Parties of 2–4…" and "A party of 4…"):

Party of 2:

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | myth12up | whale |
|------|-------|------|------|------|------|------|------|------|------|
| ep1 | normal | lost w15 | WIN 100/100 | WIN 100/100 | WIN 100/100 | lost w20 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep1 | hard | lost w10 | lost w20 | lost w14 | WIN 13/60 | lost w15 | WIN 54/60 | WIN 59/60 | WIN 60/60 |
| ep1 | nightmare | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 34/35 | WIN 35/35 |
| ep2 | normal | lost w12 | lost w24 | WIN 76/100 | WIN 82/100 | lost w17 | WIN 87/100 | WIN 89/100 | WIN 100/100 |
| ep2 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w11 | WIN 42/60 | WIN 29/60 | WIN 53/60 |
| ep2 | nightmare | lost w7 | lost w7 | lost w7 | lost w8 | lost w8 | lost w8 | lost w8 | WIN 22/35 |
| ep3 | normal | lost w11 | lost w16 | lost w16 | lost w19 | lost w15 | WIN 88/100 | WIN 85/100 | WIN 99/100 |
| ep3 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w20 | WIN 22/60 | WIN 51/60 |
| ep3 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w9 | lost w10 | lost w9 | WIN 20/35 |
| infinite | normal | died w12 | died w16 | died w14 | died w17 | died w15 | died w22 | died w40 | died w80 |
| infinite | hard | died w10 | died w10 | died w10 | died w10 | died w10 | died w19 | died w40 | died w70 |
| infinite | nightmare | died w10 | died w10 | died w10 | died w10 | died w10 | died w10 | died w30 | died w40 |

Party of 3:

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | myth12up | whale |
|------|-------|------|------|------|------|------|------|------|------|
| ep1 | normal | lost w17 | WIN 100/100 | WIN 100/100 | WIN 100/100 | lost w20 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep1 | hard | lost w10 | WIN 53/60 | lost w13 | WIN 13/60 | lost w16 | WIN 60/60 | WIN 58/60 | WIN 60/60 |
| ep1 | nightmare | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | WIN 31/35 | WIN 35/35 |
| ep2 | normal | lost w13 | lost w28 | WIN 2/100 | WIN 80/100 | lost w18 | WIN 86/100 | WIN 86/100 | WIN 100/100 |
| ep2 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w12 | WIN 38/60 | WIN 31/60 | WIN 54/60 |
| ep2 | nightmare | lost w7 | lost w8 | lost w7 | lost w8 | lost w8 | lost w8 | lost w8 | WIN 21/35 |
| ep3 | normal | lost w13 | lost w17 | lost w18 | lost w18 | lost w15 | WIN 10/100 | WIN 77/100 | WIN 100/100 |
| ep3 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w11 | lost w30 | WIN 30/60 | WIN 52/60 |
| ep3 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w9 | lost w9 | lost w9 | lost w40 |
| infinite | normal | died w13 | died w18 | died w17 | died w17 | died w16 | died w23 | died w40 | died w80 |
| infinite | hard | died w10 | died w11 | died w10 | died w10 | died w13 | died w20 | died w40 | died w40 |
| infinite | nightmare | died w10 | died w10 | died w10 | died w10 | died w10 | died w10 | died w30 | died w40 |

Party of 4:

| Mode | Diff. | re6 | re4up | re6up | re10up | leg6 | leg10up | myth12up | whale |
|------|-------|------|------|------|------|------|------|------|------|
| ep1 | normal | lost w17 | WIN 100/100 | WIN 100/100 | WIN 100/100 | lost w20 | WIN 100/100 | WIN 100/100 | WIN 100/100 |
| ep1 | hard | lost w10 | WIN 57/60 | lost w16 | WIN 11/60 | lost w16 | WIN 59/60 | WIN 59/60 | WIN 60/60 |
| ep1 | nightmare | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w10 | lost w20 | WIN 35/35 |
| ep2 | normal | lost w14 | lost w28 | WIN 5/100 | WIN 86/100 | lost w19 | WIN 86/100 | WIN 81/100 | WIN 100/100 |
| ep2 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w13 | WIN 36/60 | WIN 27/60 | WIN 54/60 |
| ep2 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | WIN 24/35 |
| ep3 | normal | lost w12 | lost w16 | lost w16 | lost w17 | lost w16 | WIN 88/100 | WIN 82/100 | WIN 100/100 |
| ep3 | hard | lost w10 | lost w10 | lost w10 | lost w10 | lost w12 | lost w20 | lost w10 | WIN 54/60 |
| ep3 | nightmare | lost w8 | lost w8 | lost w8 | lost w8 | lost w8 | lost w9 | lost w9 | WIN 14/35 |
| infinite | normal | died w13 | died w19 | died w16 | died w18 | died w16 | died w29 | died w40 | died w80 |
| infinite | hard | died w10 | died w13 | died w10 | died w10 | died w13 | died w20 | died w30 | died w70 |
| infinite | nightmare | died w10 | died w10 | died w10 | died w10 | died w10 | died w10 | died w20 | died w30 |

Reading it: **Episode 1 Normal keeps the solo ladder for 2–4 Rare/Epic players** (no upgrades loses, 4–10
upgraded Rare/Epic win at full gate), and every story cell matches solo except a few within a wave or a few
gate HP of flipping: ep1 Hard re4up (solo lost on w19, party of 3 wins 57/60), ep2 Nightmare myth12up (solo
3/35, a coin flip, lost by every party) and ep3 Hard myth12up for 4 players (solo 26/60, lost on the w10 boss).
**Endless** is not matched yet: whales go as deep as solo or deeper (w80–102), but parties of 3–4 mid-tier
teams (leg10up, myth12up) die one to four boss waves earlier than solo (w30–40 instead of w60–79). Endless
results jump by whole boss waves between nearby multipliers, so it keeps the story curve for now; tuning it
needs a better party bot (each bot fills its whole plan before upgrading, which overcrowds the road) and
live data.

**Stun chains** (`TD.STUN_CHAIN_MAX`, `TD.STUN_IMMUNITY`, in `TdSim`): parties of whales stacked
enough Blacksmith/Strongman stuns to hold an endless wave at the spawn forever (wave 80 never ended — a match
that never finishes). Stuns still chain, but an enemy held for a minute without 3 s of freedom shrugs stuns off
for 3 s. Solo story results are unchanged; solo endless whales now fall to the wave-80 Commandant on Normal and
Hard (were w93 / w82), still inside the 60–100 wall.

*2026-10-17 (Discord report "infinite stun"):* a minute was still a lock to players: a pattern of Blacksmiths
held a wave in place. The cap is now **6 s** of chain, then **3 s** immune, so an enemy walks at least a third of
the time. Shorter caps (2.5–5 s) let the wave-40 Commandant reach the gate against myth12up (w40, below the
60–100 endless target); 6–7 s is a stable plateau. Story results move by a few gate HP; endless Mythic/whale
runs end one or two boss waves earlier (solo Normal myth12up w79 → w70), and a party of 4 myth12up now loses
ep1 Nightmare at w20, which matches "Nightmare needs the whale" above. Tables above are regenerated.

## 6. Economy and monetization (details in `MONETIZATION.md`)

- **Lira** (new currency) buys summons: 50 per pull, 500 per ten (VIP −20 %). Earned from matches
  (80 / 140 / 240 base per episode, ×difficulty, ×2 on first clear; endless 100 / 230 / 390 / 420 / 450 per
  10-wave tier), dailies, codes and the Diary.
- **Odds** (`TD.ODDS`): Rare 75.5 % · Epic 20 % · Legendary 4 % · Mythic 0.5 %. Pity: a Legendary within 50
  pulls, a Mythic within 400 (counters shown live on the Rates screen). Featured units take 50 % of their
  rarity. Banners rotate hourly (`Config/Banners`).
- **Paid random items policy**: the Rates button shows every outcome's percentage before purchase; players
  whose region restricts paid random items (`PolicyService`) cannot buy lira (earned lira still works).
- **Qirsh** stays the cosmetics currency.
- Robux: lira packs, trait stones, the Newcomer's bundle (once), the premium Diary track (per season, a
  developer product), level skips; passes VIP / Fast Mode / Extra Slot / Lane Patron. All IDs are 0 until
  the owner creates them.

## 7. Season pass "Lane Diary" (`Config/SeasonPass`, `Logic/PassLogic`)

50 levels, 100 + 10 × (level − 1) XP each (≈ 17k XP for the season). XP from matches, dailies and codes.
Free track: lira / qirsh every level, 120 lira every 10. Premium: doubles lira, trait stones, the embroidered
shawl (15), the gold tarboosh (30) and the Great Za'im (50). Season 1 ends 2026-11-30 (UTC); a new season
resets `profile.pass` (the premium flag is per season).

## 8. Codes, dailies, crowd

- `Config/Codes`: upper-case, once per player, expiring (YASMIN, HARA, SHABRIYEH, QITT, DIARY).
- `Config/Daily`: 7-day looping streak, UTC days; a missed day resets to day 1.
- `CrowdService`: 8 ambient neighbours stroll between gate, shops and square with pathfinding; they pass
  through players.

## 9. Lobby additions (`World/Zones/Extras`, `World/Props2`)

Four portals in the square (pad + banded arch + Arabic board + localized billboard), the coffee house (open
front, benches, tea trays, backgammon, samovar; no argileh by platform policy), the barber shop (chair,
mirror, bottles), painted shop signs (bakery, tailor, spice, barber, coffee), the gate nameplates "حارة
الياسمين" on both faces, the night watchman's stool and lantern, the notice board with the launch codes.
The lane gate is rebuilt in `Props2.gate`: studded leaves on hinges, wicket, knockers, bar hooks and the
night bar leaning by the jamb. The same prop stands closed and barred at the end of every arena; the
match opening animates the leaves shutting and the bar dropping (client, local).

**AFK chamber (2026-10-17):** the Hakawati's room upstairs in the coffee house pays a cup of tea every 5 minutes and a tale bonus every 30 to players who sit with the storyteller, with a daily lira cap and a server hop before the idle kick. Rules, research and flow: `docs/AFK_CHAMBER.md`.

## 10. Studio test harness (never active outside Studio)

- `DebugOverlayController`: last server/client warnings in the top-left of the screen.
- `DebugKeysController`: `1` Units · `2` Summon · `3` Diary · `4` Codes · `5` Daily · `6` Store · `7`/`8`
  summon ×1/×10 · `9` teleport to the Episode 1 portal · `0` to the square · `L` auto-fill the loadout · `X`
  close screens. In a match: `P` place the next loadout unit at your feet · `U` upgrade · `J` sell · `K` vote
  skip · `T` 2× · `C` +5000 match cash.
- `ServerStorage.HaretDebug` commands: `lira`, `cash`, `tp`, plus the persistence ones.
- Mock store: 5,000 lira and 5 trait stones are seeded so everything can be exercised.

## 11. Known gaps / next

- Unit art is primitive rigs (no uploads). Real models, animations and VFX come later.
- Audio: every cue id is 0 (silent) until original cues are produced (`AUDIO_BIBLE.md`).
- Trading, raids, unit evolutions, leaderboards (OrderedDataStore) and a teleport-to-match-place setup for
  big servers are not built yet.
- Balance is harness-tuned (§5) for solo play and same-loadout parties of 2–4; Endless party depth and
  mixed parties (one whale carrying three new players) are untuned, and the numbers still need live
  analytics (`MatchWon_*`, `Summon_*`, `PassClaim_*`).

## 12. Match effects (`Config/Vfx`, `Logic/VfxBudget`, `UI/Fx`; BUILD_PLAN P2-17)

Everything a match draws besides the figures comes from one pooled part budget: `Vfx.MAX_LIVE` (80) parts out
at once and `Vfx.MAX_PER_FRAME` (14) handed out per frame (`Logic/VfxBudget`, unit-tested). An effect that
misses the budget is skipped, never queued, and multi-part effects shrink to what fits (`Fx.allow`). The
Effects setting still gates them: "full" draws all, "reduced" drops sparks, telegraph pulses and most petals,
"off" keeps only the plain strike beams. The Studio overlay shows `[Fx] live · this frame · skipped`.

| Moment | Effect (client-side, from `MatchEvents`) | Numbers |
|---|---|---|
| Hit | neon streak (P1) + a small white-tinted spark at the target | `Vfx.HIT` |
| Death | model fades (P1) + jasmine petals (white, blossom pink, lantern gold); bosses give an ash poof. No blood | `Vfx.DEATH` |
| Shabriyeh / sweep | crossing blade flashes / running ground ring with dust (P1-15) | `Vfx.SHABRIYEH`, `Vfx.SWEEP` |
| Boss wave | red rings pulse at the spawn end during the boss banner; a shock ring where the boss steps in | `Vfx.BOSS` |
| Gate hit | red disc at the gate end of the path + a red screen-edge blink (one per step) | `Vfx.GATE_HIT` |
