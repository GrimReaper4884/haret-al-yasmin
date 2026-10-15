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
Nightmare (HP ×1 / 1.6 / 2.6, rewards ×1 / 1.6 / 2.4, gate HP 100 / 60 / 35). Episode N+1 unlocks after
clearing N on Normal; Hard after Normal, Nightmare after Hard, per episode.

## 3. Match rules (`Config/TD`, `Logic/TdSim`, `Logic/TdTowers`)

| Rule | Value |
|------|-------|
| Start cash | 500 per player; wave bonus 90 + 20 × wave; skip vote +60 to all |
| Prep | 15 s before wave 1, 9 s between waves; all players voting skip starts at once |
| Placement | anywhere inside the arena bounds, ≥ 3.2 studs from the road centreline, ≥ 2.6 from another defender, ≤ 20 per player, per-unit cap (`maxPlaced`) |
| Upgrades | 5 levels (Rare) / 6 (Epic+); sell refunds 60 % of everything spent |
| Targeting | first / last / strongest / closest (per defender) |
| Stealth | night thieves and spies are invisible to defenders without `hitsStealth` (watchman, barber, 'akeed, za'im, 'arada, cat) |
| Armor | fraction of damage ignored (bandit 15 %, rider 20 %, sapper 35 %, bosses 20–40 %) |
| Support | the Mukhtar and Umm Zaki multiply the damage of defenders inside their range (best buff wins) |
| Farm / repair | the coffee-house keeper pays cash per cleared wave; Umm Zaki repairs the gate per wave |
| Abilities | **shabriyeh** ('akeed ×6 / za'im ×10 / great za'im ×15 damage on one hit, every 12 / 9 / 7 s); **sweep** (strongman, 'arada: damage to everything in a radius) |
| Speed | 1× / 2× free; 3× with the Fast Mode pass (host controls) |
| Tick | 20 Hz fixed step; positions streamed at 10 Hz on an UnreliableRemoteEvent; client interpolates along the path |

The simulation is pure (`TdSim.step(state, dt)` returns events) and covered by `tests/td.spec.luau`.

## 4. Defenders (`Config/Units`)

| Id | Name (EN) | Rarity | Role | Signature |
|----|-----------|--------|------|-----------|
| walad | Lane Boy | Rare | ranged | starter unit, cheap, 8 max |
| natour | Abu Fares the Watchman | Rare | ranged | sees stealth, lantern slows |
| farran | Abu Bashir the Baker | Rare | splash | hot loaves |
| saqqa | Abu Jamil the Water Carrier | Rare | splash | soaks and slows |
| hallaq | Abu Nidal the Barber | Rare | melee | fast razor, sees stealth |
| khayyat | Abu Samir the Tailor | Rare | ranged | longest range |
| qahwaji | Abu Hamed the Coffee-house Keeper | Rare | farm | cash per wave |
| qabaday | The 'Akeed | Epic | melee | shabriyeh ×6 |
| haddad | Abu Khater the Blacksmith | Epic | splash | stuns |
| mukhtar | The Mukhtar | Epic | support | +15–65 % damage aura |
| zaim | The Za'im | Legendary | melee | shabriyeh ×10 |
| pahlawan | The Strongman | Legendary | splash | sweep, stun |
| umm_hara | Umm Zaki, Mother of the Lane | Legendary | healer | repairs the gate, small aura |
| arada | The 'Arada Troupe | Mythic | splash | wide sweep |
| zaim_akbar | The Great Za'im | Mythic | melee | shabriyeh ×15; season-1 pass level 50 |
| qitt | Cat of the Lane | Secret | melee | code `QITT`, never from a banner |

Copies → stars (+5 % damage each; 1/2/4/7/11 extra copies). Each owned unit has one **trait**
(`Config/Traits`: steady, swift, keen, sharp, golden, hawk, za'im's blood, legend), rerolled with trait stones.

## 5. Attackers (`Config/Enemies`, `Config/Waves`)

Gendarme, night thief (fast, stealth), orchard bandit (tank), rival-lane thug, mounted officer (fast tank),
sapper (slow, armored, 8 gate damage), spy (stealth). Bosses: the Sergeant (wave 10), the Thief King (20),
the Za'im of the rival lane (30), the Commandant (40; endless cycles them every 10 waves). Waves are
generated from per-episode pool scripts (`WaveLogic.story`) with linear HP growth; endless uses quadratic
growth and a speed creep capped at ×1.6.

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
- Balance numbers are first-pass; tune with analytics (`MatchWon_*`, `Summon_*`, `PassClaim_*`).
