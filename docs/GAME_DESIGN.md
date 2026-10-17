# Haret Al Yasmin: Game Design Document

Anime-style co-op tower defense for Roblox, built on original IP. Source research: [`reports/Roblox tower defense game blueprint.md`](../reports/Roblox%20tower%20defense%20game%20blueprint.md).

**How to read this document**

- Every number here is a starting value to tune with telemetry, not a sourced fact. Where the report gave a range or left a value open, this document picks one and tags it **TUNE**.
- The data tables live in `src/shared/Config/*.luau`. At runtime Config wins. Any change to a number changes Config **and** this document in the same commit, and `Validate.luau` must still pass.
- Probabilities are stored as integer ppm (parts per million; 1,000,000 = 100%) so that every disclosed table sums to exactly 100.0000%.

---

## 1. Pillars

1. **Ownership.** Original cast and world. Zero takedown exposure.
2. **Trust.** Bounded, published pity; a spark a dedicated free player can reach once per update; odds shown from the same data the RNG uses; a trait-free Fair-Play Arena.
3. **Strategic depth.** TDS-style attribute checks (Veiled, Flying, Ironbound, Warded) turn the 6-slot loadout into a puzzle, and support roles matter in co-op.
4. **Collection depth with caps.** Summons, traits, stat grades, Bloom and evolution, with every power axis capped on day one (§21).
5. **Cadence.** A major update every 3–4 weeks, each with a banner, an event currency, a mode and codes.

## 2. Setting, tone and IP rules

**Haret Al Yasmin, "the Jasmine Quarter"** is a night-blooming city district of lantern-lit souqs, tiled courtyards, rose-water canals, rooftops and minarets. Each night **the Wilt**, a creeping blight of thorns, ash-moths and hollow husks, pushes up the Quarter's lanes toward the **Garden Gate**. The Quarter's guardians hold the lanes until dawn.

- **Tone:** warm, heroic, stylized. Target maturity label **Mild**: stylized combat, no blood or gore. Defeated enemies dissolve into petals and ash.
- **Palette:** indigo night, jasmine white, brass gold, saffron, turquoise tile. The Wilt reads as grey-violet with sickly green highlights.
- **Motifs:** lanterns, brass, tilework, jasmine vines, fabric awnings, crescent moons. Avoid religious symbols and real-world flags or emblems.

**IP rules (binding):**

- Characters may draw on archetypes (stoic swordsman, storm archer) but must **never** use named characters from any existing work, their logos, signature attack names, recognizable silhouettes or color schemes, or ripped models. No parody spellings.
- Names are original combinations of common given names and descriptive titles, for example "Tarek, Alley Duelist". Before shipping a new name, the agent searches it against well-known anime, game and film character names (asks the user if unsure).
- Asset sources: self-made first, then CC0 (Poly Haven), then CC-BY with an attribution row in `assets/LICENSES.md`. AI-generated meshes are logged with provider and prompt and checked against these rules.
- Contributor contracts with **IP assignment and a defined revenue share** must be signed before anyone else commits (user/legal task, not the agent's).

## 3. Core loop

```
Lobby (Courtyard) ──queue──▶ Match (Story / Trials / Raid / ...) ──rewards──▶ Lobby
   ▲  summon, reroll, level, evolve, quests                    │
   └────────────────────────────────────────────────────────────┘
In a match: Cash ▶ place/upgrade units ▶ kill waves ▶ Cash + wave bonus ▶ ... ▶ final boss
Out of match: Gems ▶ summons ▶ units ▶ Trait Seeds / Cores / Gold / Relics ▶ stronger units ▶ harder modes
```

Session target: one Story act takes 12–25 minutes (15–30 waves at an average of 30–60 s per wave, with vote skip).

## 4. Lobby: the Courtyard

A central tiled courtyard with a jasmine-tree fountain. Stations (each is a ProximityPrompt that opens a UI):

| Station | Function | Unlock |
|---|---|---|
| Summon Pavilion | Standard, Featured and Limited banners; "View Odds" button; pity counters | start (Limited at Lv10) |
| Seed Shrine | Trait rerolls (auto-reroll with "stop at or above") | start |
| Grade Loom | Stat Core and Focus Core rerolls; potential meter | Lv5 |
| Garden Gate pads | Story queue pads for 1–4 players (party by stepping on a pad together) | start |
| Trials Board | 30-min, daily and weekly Trials | Lv5 |
| Bounty Board | Boss Bounties | Lv10 |
| Raid Gate | Raid queue | Lv15 |
| Exchange | Exchange Tokens → selector boxes, cosmetics; Raid shop | start |
| Pass Board | Battle pass | start |
| Quest Keeper | Daily, weekly and evolution-guide quests | start |
| Rift Circle (Update 3) | Night Bloom Rift spawn point | Lv10 |

### First-session onboarding (wave 1 and a free summon within 60 s)

| Time | Step |
|---|---|
| T+0 s | Spawn facing the Summon Pavilion. One prompt: "Your first light." |
| ≤ T+15 s | Free **Tutorial summon** (guaranteed Epic: Nadia or Bassam, 50.0000% each; odds shown). The starter team is auto-equipped: Tarek, Rima, Old Hadi, Spice Caravan plus the pulled unit. |
| ≤ T+40 s | "Defend the Quarter" auto-queues a solo reserved server for World 1 Act 1. |
| ≤ T+60 s | First-wave countdown (10 s) ends and wave 1 starts. |

In-match hints: place Tarek (wave 1), place a Spice Caravan (wave 2), upgrade Old Hadi to U2 before wave 5 (the preview strip flags Veiled), place Rima before wave 11 (Moths). If analytics show the median join→wave-1 time above 60 s, the first match runs inside the lobby place instead; the Dev place role already supports this (BUILD_PLAN P2-01).

## 5. Match rules

| Rule | Value |
|---|---|
| Party size | Story, Trials, Raid, Bounty: 1–4. Rifts: up to 6 |
| Starting Cash | 600 per player (World 1) |
| Wave-end bonus | `(250 + 40 × wave) ÷ partySize` to each player |
| Kill bounty | Enemy bounty (§12) split evenly across the party, regardless of who dealt damage |
| Merchant income | Paid at wave end to the owner only |
| Placement caps | Per unit (§8) and per player by party size: 40 / 30 / 25 / 20 |
| Placement validity | Raycast hit on a surface tagged `Ground` (ground units) or `Hill` (hill units); distance to the path centerline ≥ path half-width + 1.0 stud clearance; ≥ 2 × 1.5-stud footprint from other units; cash and caps checked on the server |
| Sell | 60% of total Cash spent on that unit (**TUNE**) |
| Targeting modes | First (default) / Last / Strongest / Closest. Strikers default to Strongest |
| Gate HP | 100. Each leak subtracts the enemy's leak damage. 0 = defeat |
| Wave timer | `min(75, 30 + 1 × enemies)` seconds, then the next wave starts. Boss finales are untimed and unskippable |
| Vote skip | Opens 10 s into a wave. Passes with all-but-one yes; AFK players abstain. Solo skips instantly |
| AFK | No input for 120 s marks a player AFK (**TUNE**) |
| Reconnect | 90 s window. A dropped player's units keep fighting and their Cash keeps accruing. After 90 s their units stay on the board but can't be upgraded, and future shared Cash is split among the remaining players |
| Game speed | 1× and 2× free, 3× with the pass. Effective speed is the lowest speed selected by any non-AFK player |
| Defeat rewards | 50% of the Gold and XP for waves cleared; no Gems |
| Preview | An enemy-preview strip shows the next wave's archetypes and attribute icons |
| Music | Band changes at waves 10, 20 and 27 (World 1) telegraph difficulty |

## 6. Modes by phase

| Mode | Unlock | Format | Primary reward | Ships in |
|---|---|---|---|---|
| Story | start | 4 worlds × 6 acts; Normal (15/18/20/22/25/30 waves) and Nightmare (unlocks after that world's Normal Act 6) | Gems, Gold, XP, Essence (Nightmare), Relic drops | Prototype: W1 Act 3. Vertical slice: W1 all acts. Alpha: W1–W4 + Nightmare |
| Infinite | clear a world's Act 6 | endless; past wave 30, wave factor frozen and HP ×1.06 per wave | 30 Gems per 5 waves past 30 (max 600 per run, **TUNE**); weekly leaderboard | Alpha |
| Trials | Lv5 | Story act + modifiers; 30-min (1 modifier, 20/day cap), daily (2), weekly (3) | Trait Seeds 1 / 3 / 20 (+20 Gems per 30-min run); 30-min and daily doubled on weekends | Alpha |
| Raid | Lv15 | "The Sunken Cistern": 6 stages × 20 waves, mini-boss at 10, boss at 20 | Raid Sigils (10 + 5 × stage) → Raid shop | Alpha |
| Boss Bounty | Lv10 | single world boss, 3 phases, 5-min limit; boss rotates daily | 1 Trait Seed + 30 Gems each, cap 10/day | Alpha |
| Legend Stages | clear a world's Nightmare Act 6 | remixed stages at Legend difficulty (HP ×3, Fortified) | Relics, Essence | Update 1 |
| Bazaar Dungeons | Lv25 | 30 waves; pick 1 of 3 roguelite cards every 5 waves | Dungeon Tokens → Charms (equipment) | Update 2 |
| Minaret Climb | Lv30 | 50-floor ladder; rewards loop after floor 50; seasonal leaderboard | bulk Trait Seeds, Stat Cores | Update 3 |
| Night Bloom Rifts | Lv10 | hub event every ~60 min, up to 6 players, MVP 2× rewards when 3+ join | event currency | Update 3 |
| Boss Event | Lv20 | 5 Normal tiers → Elite; each tier must be won within 20 waves | exclusive cosmetics, banner currency, leaderboard | Update 4 |
| Fair-Play Arena | Lv30 | traits and stat grades disabled; score attack, later 2v2 versus | ranked cosmetics only | Update 5 |
| Garden Idle | Lv10 | AFK zone, passive roll every 15 min | Gold, low-odds AFK-exclusive unit | Update 6 |

**Trial modifiers** (8 at launch, **TUNE**): Thick Bark (+50% enemy HP), Swift Wilt (+30% enemy speed), Veil Night (30% of non-boss enemies gain Veiled), Iron Rain (20% of Wisps become Ironbound), Lean Purse (−30% wave bonus and bounty), Shared Roots (enemies take 30% of damage dealt to them and 70% is spread across enemies within 6 studs), Silent Heralds (Herald auras disabled), Stunproof (all enemies stun-immune).

**Raid stage scaling:** stage *n* uses Nightmare rules with HP × (1.5 + 0.25*n*) (**TUNE**). Raid shop prices: unit Relic 400 Sigils (1 per relic per week), Essence 25, Stat Core 60, Focus Core 150, Divine Seed 40 (from Update 2).

**Auto Play** (free, Alpha): the player picks an anchor point and Auto Play places and upgrades their loadout. Layouts export as shareable codes. Auto Play **never** fires actives or ultimates.

## 7. Units: rules

### 7.1 Rarity

| Rarity | Passives | Placement cap | Active | Ultimate | Evolves | Launch count |
|---|---|---|---|---|---|---|
| Rare | 0–1 | 5–6 | – | – | no | 8 |
| Epic | 1 | 4–5 | – | – | no | 8 |
| Legendary | 2 | 3–4 | 1 | – | no | 8 |
| Mythic | 2–3 | 3 | 1 | yes | yes | 5 |
| Secret (limited) | 3 | 1–2 | 1 | yes | yes | 1 per limited banner |

Farms override the placement cap (Spice Caravan 3, Silk Bazaar 1). There is no apex rarity above Secret; later power arrives as a Transcendent *evolution path*, so the rarity ladder never has to be reworked.

### 7.2 Roles

| Role | Placement | Job | Rule |
|---|---|---|---|
| Striker | Ground | single-target boss DPS | highest base damage; Strongest targeting by default |
| Sweeper | Ground or Hill | AoE (cone, circle, line) vs swarms and splitters | ~40% of a Striker's per-hit damage across up to 6 targets |
| Marksman | Hill | anti-air | the only role with **Full** damage vs Flying |
| Lantern | Hill | detection | from U2, the aura reveals Veiled enemies to **every player's** units |
| Breaker | Ground | shields and armor | 3× damage to shield pools; strips 1 Ironbound plate per hit |
| Warden | Ground | slow and stun | vs bosses and mini-bosses, stuns become 20% slows |
| Herald | Hill | support | aura (damage/range/SPA/discount) buffs every player's units; active Rally |
| Merchant | Ground | farm | Cash per wave to the owner; no attack |

**Flying:** Marksmen deal Full damage. Lanterns, Heralds and Sweepers deal Half (50%). Strikers, Breakers and Merchants cannot target Flying. Wardens deal Half.

**Veiled:** cannot be selected as a primary target unless inside a detection aura. Splash, Nova, Line, Cone and Zone damage still hits them.

**Ironbound:** takes no damage from non-Breaker sources (splash included) and is stun-immune until its 3 armor plates are stripped by Breaker hits; then it takes normal damage and can be stunned.

### 7.3 Stat formula

```
damage = levelDamage
       × (1 + unitLevel×0.005 + bloom×0.02 + gradeDamage + traitDamage)        -- permanent bucket, additive
       × (1 + bestHeraldAuraDamage + yasminFragrance + activeBuffs)             -- match buffs
       × (1 + bossDamagePct)          [vs MiniBoss/Boss tiers only]
       × (1 + flyingDamagePct) × 0.5  [vs Flying, Half rule only; Full rule skips the 0.5]
       × (1 + min(0.40, Σ damage-taken debuffs on the target))                  -- Bind, Storm Mark, Beacon
       × crit       [chance = min(0.75, Σ crit chance); multiplier = 1.5 + Σ critDamagePct]
Breaker vs shield pool: ×3.  Eclipse: 25% of the hit bypasses the shield.
SPA   = levelSpa × max(0.5, 1 + traitSpa − gradeSpa + auraSpa) × activeSpaMult, floor 0.2 s
range = levelRange × (1 + gradeRange + traitRange + auraRange)
```

Herald auras don't stack with each other (the strongest value per stat applies). Upgrade discounts from all sources (Merchant trait, Haggler, New Moon) combine additively, capped at −25%.

### 7.4 Upgrades and the Lv4 fork

Each unit has **Lv0 (placement) plus 5 upgrades**. U4 forks into **branch A or B** (chosen when U4 is bought), and U5 continues that branch. Merchants don't fork (Spice Caravan has 4 upgrades and Silk Bazaar 5, matching the farm tables). Full per-level data is in `UnitConfig.luau`.

### 7.5 Actives and ultimates

- Legendary and higher units have one **manual active** on a 30–90 s cooldown, enforced by the server.
- Mythic and Secret units add an **ultimate** with a 0–100 charge: +1.5 per damaging hit and +1.0 per second spent inside a Herald aura. When it fires, a 1.5 s camera flourish plays; it can be skipped after the player's first viewing.
- **Auto Play never fires actives or ultimates.**

### 7.6 Long-term growth (out of match)

| Axis | Rule | Cap |
|---|---|---|
| Unit level | XP from matches (10 per wave cleared, per placed unit); Gold converts 1:1 to unit XP ("Train"). XP to next level = 50 × L^1.5 (**TUNE**) | Lv50 = +24.5% damage |
| Bloom | duplicates: Bloom *n* costs 1 duplicate + 1,000 × *n* Gold; +2% damage each; petal aura cosmetic at Bloom 5 | Bloom 5 = +10% |
| Evolution | Mythic/Secret only: unit Relic + 15,000 Gold (30,000 Secret) + 20 Essence + quest "1,000 takedowns with this unit". Adds a passive, upgrades the ultimate, swaps the model | once |
| Trait | §10 | Crown of Jasmine, 1 placement |
| Stat grades | §11 | Jasmine grade (+22% / +11%) |

Duplicates beyond Bloom 5 convert to Exchange Tokens: Rare 1, Epic 3, Legendary 10, Mythic 40, Secret 100 (**TUNE**).

## 8. Starter roster (12 units)

All original. Costs are in-match Cash. "Total" is Lv0 through U5.

| # | Unit | Rarity | Role | Place | Cap | Attack | vs Flying | Total cost |
|---|---|---|---|---|---|---|---|---|
| 1 | Spice Caravan, Mule-Cart Traders | Rare | Merchant | Ground | 3 | none (income 150 → 1,900/wave) | – | 9,200 |
| 2 | Tarek, Alley Duelist | Rare | Striker | Ground | 6 | Single | None | 7,750 |
| 3 | Rima, Rooftop Slinger | Rare | Marksman | Hill | 5 | Single | Full | 8,200 |
| 4 | Old Hadi, the Lamplighter | Epic | Lantern | Hill | 4 | Single + detection aura from U2 | Half | 7,150 |
| 5 | Nadia, Ember Fan Dancer | Epic | Sweeper | Ground | 5 | Cone 90°, 6 targets | Half | 8,900 |
| 6 | Bassam, the Anvil | Epic | Breaker | Ground | 4 | Single | None | 9,550 |
| 7 | Silk Bazaar, Night-Market Pavilion | Legendary | Merchant | Ground | 1 | none (income 200 → 6,000/wave) | – | 32,800 |
| 8 | Layla, Nightwind Warden | Legendary | Warden | Ground | 3 | Circle r5, 5 targets, slows | Half | 11,250 |
| 9 | Qamar, Moon Herald | Legendary | Herald | Hill | 3 | Single (weak) + aura | Half | 11,950 |
| 10 | Saif al-Layl, the Night Blade | Mythic | Striker | Ground | 3 | Single | None | 16,000 |
| 11 | Dalia, Monsoon Archer | Mythic | Marksman | Hill | 3 | Line 3 wide, 4 targets | Full | 16,950 |
| 12 | Yasmin, the Night-Blooming | Secret (Limited S1) | Sweeper | Hill | 2 | Circle r7, 8 targets | Half | 20,000 |

Starter units granted to every account: Tarek, Rima, Old Hadi, Spice Caravan (plus the Tutorial summon). The prototype (Phase 1) uses units 1–6 and 8–9, which cover all 8 roles.

### Level tables

Format: `cost: damage / SPA / range`. A dash means "inherits from the previous level".

**Spice Caravan** (income per wave): Lv0 500: 150 · U1 900: 350 · U2 1,600: 700 · U3 2,600: 1,200 · U4 3,600: 1,900. Matches the ~9,000 total of the genre's standard farm.

**Silk Bazaar** (income per wave): Lv0 800: 200 · U1 1,500: 500 · U2 3,000: 1,100 · U3 5,500: 2,200 · U4 9,000: 3,800 · U5 13,000: 6,000. Only beats Caravans in modes longer than ~25 waves.
- Passives: *Caravanserai* (your Spice Caravans earn +10%), *Haggler* (your other units' upgrades −5%).
- Active *Market Day* (90 s): instantly pays 50% of this Bazaar's current per-wave income.

**Tarek**: Lv0 250: 40/1.0/14 · U1 300: 60 · U2 600: 95/0.9 · U3 1,100: 160/0.85/15.
- A *Lone Blade*: U4 2,000: 300/0.8 · U5 3,500: 520/0.75/16.
- B *Crescent Sweep* (cone 70°, 4 targets): U4 2,000: 180/0.8 · U5 3,500: 300/0.75/16.
- Passive *Duelist's Focus*: +15% vs mini-bosses and bosses.

**Rima**: Lv0 300: 30/1.4/24 · U1 350: 45 · U2 650: 70/1.3/26 · U3 1,200: 120/1.2/28.
- A *Hawk's Eye*: 2,100: 230/1.1/32 · 3,600: 400/1.0/34.
- B *Scatter Shot* (circle r4→r5, 5 targets): 2,100: 120/1.1 · 3,600: 210/1.0.
- Passive *Spotter*: +20% vs Flying.

**Old Hadi**: Lv0 400: 20/1.5/16 · U1 350: 30 · U2 600: 45, detection aura r16 · U3 1,000: 70, aura r18.
- A *Beacon*: 1,800: aura r22, revealed enemies take +10% · 3,000: aura r26, +15%.
- B *Flare* (circle r5→r6, 6 targets): 1,800: 90 · 3,000: 150.
- Passive *Lamplight* (detection is shared with every player).

**Nadia**: Lv0 450: 18/1.3/11 · U1 400: 28 · U2 750: 42/1.2 · U3 1,300: 70/–/12.
- A *Whirl* (nova r12, 8→10 targets): 2,200: 110 · 3,800: 180.
- B *Flame Ribbon* (line 4 × 18→20, 6 targets): 2,200: 130 · 3,800: 220.
- Passive *Cinders*: burn 10% of hit damage per second for 3 s.

**Bassam**: Lv0 500: 35/1.6/9 · U1 450: 55 · U2 800: 85/1.5 · U3 1,400: 140/–/10.
- A *Splitting Maul* (circle r3, 3 targets): 2,400: 220 · 4,000: 360.
- B *Rivet Driver* (2 plates per hit): 2,400: 240/1.1 · 4,000: 400/1.0.
- Passive *Shatter*: 3× vs shields, strips 1 plate per hit.

**Layla**: Lv0 700: 25/1.4/12, slow 30% for 2 s · U1 550: 38 · U2 1,000: 55, slow 35% · U3 1,700: 85/–/13, every 3rd attack stuns 1.5 s.
- A *Gale Prison* (r6): 2,800: 110, stun 2.5 s · 4,500: 160, every 2nd attack stuns.
- B *Ebb Tide* (no stun; permanent aura slow 25%→35% in range): 2,800: 120 · 4,500: 180.
- Passives: *Bind* (stunned or rooted enemies take +10%), *Calm Air* (immune to Hexer stuns).
- Active *Nightwind Snare* (60 s): stuns all non-boss enemies in range for 3 s; bosses slowed 20% for 5 s.

**Qamar**: attack 15/2.0/16. Aura by level:
- Lv0 650: r14, +8% damage · U1 600: +10% · U2 1,100: r16, +10% damage, +5% range · U3 1,800: +12% / +8%.
- A *Full Moon*: 3,000: r18, +20% / +10% · 4,800: +25% / +12% / −5% SPA.
- B *New Moon*: 3,000: r16, +12% / +8% / −10% upgrade cost · 4,800: r18, +15% / +8% / −15%.
- Passives: *Guiding Light* (aura buffs all players), *Steady Hands* (units in the aura recover from stuns 30% faster).
- Active *Rally* (45 s): units in the aura get SPA ×0.85 for 10 s.

**Saif al-Layl**: Lv0 900: 120/1.1/16 · U1 800: 190 · U2 1,400: 320/1.0 · U3 2,400: 560/0.95/17.
- A *Edge of Night*: 4,000: 1,000/0.9 · 6,500: 1,700/0.85/18.
- B *Petal Storm* (cone 90°, 5 targets): 4,000: 520/0.9 · 6,500: 900/0.85/18.
- Passives: *Moonlit Edge* (+20% vs bosses), *Momentum* (+4% per consecutive hit on the same target, max +20%), *Night's Patience* (10% crit).
- Active *Crescent Draw* (40 s): 4 × 24 dash line, 6× damage. Ultimate *Thousand-Petal Cut*: 12 strikes × 3× over 2 s.
- Evolution → **Saif, Dawnbreaker** (Relic: Dawnsteel Hilt): adds *Dawn* (the first hit on each enemy +50%); ultimate becomes 16 strikes × 3.5×.

**Dalia**: Lv0 1,000: 90/1.5/28 · U1 850: 140 · U2 1,500: 230/1.4 · U3 2,600: 400/1.3/30.
- A *Heavenpiercer* (line 40 long, 6 targets): 4,200: 700 · 6,800: 1,150/1.2.
- B *Tempest Volley* (3 single targets): 4,200: 300 · 6,800: 500/1.2.
- Passives: *Skybreaker* (+30% vs Flying), *Rain-Soaked* (10% slow for 1 s), *Storm Mark* (every 5th arrow: target takes +15% for 4 s).
- Active *Cloudburst* (50 s): r10, 8× over 2 s, hits Flying and Veiled. Ultimate *Monsoon Bloom*: 4 s, 2× every 0.2 s to all enemies in range (max 12).
- Evolution → **Dalia, Eye of the Monsoon** (Relic: Stormglass Quiver): adds *Eye of the Storm* (detects Veiled in her own range); ultimate lasts 6 s.

**Yasmin**: Lv0 1,200: 80/1.4/22 · U1 1,000: 125 · U2 1,800: 200/1.3 · U3 3,000: 340/1.25/24.
- A *Moonflower* (circle r8, 10 targets): 5,000: 600 · 8,000: 1,000.
- B *Thorn Lattice* (persistent zone r6, ticks every 0.5 s, 12 targets): 5,000: 150 · 8,000: 260.
- Passives: *Thorned Garden* (0.5 s root; bosses get a 20% slow), *Fragrance* (your units within 12 studs +8%, stacks with Heralds), *Uproot* (2× vs Mender and Hive).
- Active *Jasmine Gale* (60 s): 6 × 40 gust, 10×, pushes non-boss enemies back 6 studs. Ultimate *Night of a Thousand Blossoms*: 5 s field r16, 1.5× every 0.25 s (max 16), reveals Veiled.
- Evolution → **Yasmin, Eternal Bloom** (Relic: Seed of the First Garden, 30,000 Gold): adds *Perennial* (ultimate charges 25% faster); ultimate 7 s, r20.

**Relic sources at launch:** Dawnsteel Hilt drops at 10% from W1 Nightmare Act 6; Stormglass Quiver at 10% from W2 Nightmare Act 6; Seed of the First Garden from the Limited S1 event shop. All three are also in the Raid shop (400 Sigils, 1/week). **TUNE.** Legend Stages become a further source in Update 1.

## 9. Summons

### 9.1 Rates (`SummonConfig.RarityPpm`)

| Rarity | Standard / Featured | Limited | 10th pull of a 10× (Standard) | 10th pull (Limited) |
|---|---|---|---|---|
| Rare | 72.0500% | 72.0000% | 0% | 0% |
| Epic | 22.5000% | 22.5000% | 94.5500% | 94.5000% |
| Legendary | 4.7500% | 4.7500% | 4.7500% | 4.7500% |
| Mythic | 0.7000% | 0.7000% | 0.7000% | 0.7000% |
| Secret | 0% | 0.0500% | 0% | 0.0500% |
| **Total** | **100.0000%** | **100.0000%** | **100.0000%** | **100.0000%** |

The report's 0.05% Secret rate applies only to Limited banners, so on Standard/Featured it is folded into Rare (72.05%).

### 9.2 Costs, pity, featured, spark, shiny

- **Cost:** 50 Gems per pull, or 500 Gems for 10×. The 10th pull always rolls from the Slot-10 table above: Rare's weight moves to Epic, and Legendary/Mythic keep their base odds (no hidden boost).
- **Hard pity:** Legendary on the 40th pull without Legendary+, Mythic on the 300th pull without Mythic+. Mythic wins if both trigger. A result resets every counter at or below its rarity.
- **Pity groups:** Standard and Featured share counters ("Main"). Each Limited banner has its own counters (**TUNE**).
- **Featured banner:** rotates every 4 hours with 2 featured Mythics, chosen deterministically from the window index so all servers agree. 50% of Mythic results are featured (split evenly between the two). Losing the 50/50 guarantees the next Mythic is featured. If every Mythic in the pool is featured, the featured share is effectively 100%.
- **Limited banner** (one per update, account Lv10+): the featured Secret receives 100% of Secret results. One featured Mythic follows the 50/50 rule. Each pull grants **1 Moon Sigil**; **1,200 Moon Sigils buy the featured Secret outright**. At banner end, leftover Sigils convert 1:1 to Exchange Tokens.
- **Shiny:** an independent 1% roll on every summon, cosmetic only. The Shiny Charm pass makes it 2%, and the odds UI updates live. Below account Lv10 the shiny chance is 0% and the odds UI says so.
- **Gem spending order:** earned Gems first, then paid Gems. Any pull that uses paid Gems flags the unit `paidOrigin`.
- **No luck potions at launch.** They add dynamic-odds burden for little revenue.

### 9.3 Odds disclosure (generated, never typed)

The "View Odds" panel is labeled with words (not a bare (i) icon) and is shown before purchase. It lists **every unit individually** at 4 decimals summing to exactly 100.0000%, plus the Slot-10 table, the shiny chance, live pity counters, the 50/50 guarantee state and the Sigil balance. Per-unit ppm = rarity ppm split across that rarity's pool (featured split per §9.2), rounded with **largest-remainder at 1 ppm**.

Example, Standard banner with the 12-unit roster:

| Rarity | Pool | ppm each | Displayed |
|---|---|---|---|
| Rare | Spice Caravan, Tarek, Rima | 240,167 / 240,167 / 240,166 | 24.0167% / 24.0167% / 24.0166% |
| Epic | Old Hadi, Nadia, Bassam | 75,000 each | 7.5000% |
| Legendary | Silk Bazaar, Layla, Qamar | 15,834 / 15,833 / 15,833 | 1.5834% / 1.5833% / 1.5833% |
| Mythic | Saif, Dalia | 3,500 each | 0.3500% |

### 9.4 Free-player math (engaged player, ~2,000 Gems/day)

- 40 pulls/day.
- Guaranteed Mythic (300 pulls = 15,000 Gems): about 7.5 days.
- Limited spark (1,200 pulls = 60,000 Gems): about 30 days, so one chase Secret per update cycle.
- Codes stay at 1,000–3,000 Gems plus 10–50 Trait Seeds.

## 10. Traits (`TraitConfig.luau`)

17 traits, 1 Trait Seed per reroll; the table sums to exactly 100.0000%.

| Trait | Rate | Effect | Pity (≈1.2× expected) |
|---|---|---|---|
| Might I / II / III | 16.5% / 8% / 2.5% | +5% / +10% / +15% Damage | – |
| Haste I / II / III | 16.5% / 8% / 2.5% | −4% / −8% / −12.5% SPA | – |
| Reach I / II / III | 16.5% / 8% / 2.5% | +5% / +10% / +15% Range | – |
| Scholar | 7% | +50% unit XP | – |
| Merchant | 4% | +20% income on Merchant units; −10% upgrade cost on non-Merchant units | – |
| Steadfast | 3% | immune to boss stuns; +10% damage vs bosses | – |
| Keen Eye | 2.6% | 35% crit chance, +50% crit damage | – |
| Tempest | 1.47% | −20% SPA | – |
| Radiant | 0.60% | +10% Damage, −5% SPA, +25% Range | 200 |
| Eclipse | 0.25% | +25% Damage, −15% SPA, +10% Range, 25% of damage bypasses shields | 480 |
| **Crown of Jasmine** | **0.08%** | **+200% Damage, −10% SPA, +10% Range; placement limit 1** | **1,500** |

- Pity is **per unit** and survives evolution. If several counters trigger on one reroll, the rarest wins and the others keep counting.
- Auto-reroll with "stop at or above" (a chosen trait or rank) prevents overwriting a good trait.
- Units are summoned with no trait (**TUNE**). Traits reset on trade (Update 5) and are disabled in the Fair-Play Arena.
- About 40 Seeds/day for an engaged free player means Crown pity on one unit takes ~38 days.
- **Divine Seeds** (second trait slot, from the Raid shop) ship in Update 2.

## 11. Stat grades and potential (`StatGradeConfig.luau`)

Damage, SPA and Range each roll a grade. The bonus is uniform within the grade's range.

| Grade | Damage bonus | SPA and Range bonus | Base odds | Odds at 100% potential |
|---|---|---|---|---|
| D | 0–4.99% | 0–2.49% | 35% | 0% |
| C | 5–7.99% | 2.5–3.99% | 30% | 0% |
| B | 8–10.99% | 4–5.49% | 22% | 0% |
| A | 11–13.99% | 5.5–6.99% | 10% | 70% |
| S | 14–16.99% | 7–8.49% | 2.5% | 22% |
| SS | 17–19.99% | 8.5–9.99% | 0.45% | 7% |
| Jasmine | 20–22% | 10–11% | 0.05% | 1% |

- **Potential** fills linearly to 100% over **3,000 takedowns by that unit** since its last roll, and resets after any roll. Odds interpolate linearly between the two columns: `odds = base × (1 − p) + full × p`.
- **Stat Cores** reroll all three stats; **Focus Cores** reroll one chosen stat. Newly summoned units roll at 0% potential.
- Money can buy cores, but playtime makes each core better.
- The odds UI shows the selected unit's interpolated table, rounded with largest-remainder, summing to 100.0000%.

## 12. Enemies (`EnemyConfig.luau`)

Base HP 100, base speed 6 studs/s, Gate HP 100.

| Archetype | HP × | Speed × | Bounty | Leak | Rule | Counter |
|---|---|---|---|---|---|---|
| Wisp (grunt) | 1.0 | 1.0 | 6 | 3 | baseline | any |
| Courier (runner) | 0.5 | 1.8 | 4 | 2 | leaks if ignored | Sweeper, Warden |
| Brute | 4.0 | 0.6 | 20 | 10 | high HP | Striker |
| Veiled | 1.2 | 1.1 | 8 | 4 | untargetable without detection; splash still hits | Lantern aura |
| Ironbound | 2.5 | 0.8 | 18 | 8 | immune to non-Breaker damage and stun-immune until 3 plates break | Breaker |
| Warded | 1.5 (+ shield 1.0) | 1.0 | 14 | 6 | shield pool absorbs damage first | Breaker, Eclipse |
| Moth (flyer) | 0.8 | 1.3 | 8 | 3 | Flying | Marksman |
| Hive (splitter) | 3.0 | 0.7 | 24 | 10 | releases 4 Couriers on death | Striker then Sweeper |
| Mender | 1.5 | 0.9 | 14 | 5 | after 3 s unhit: regen 5% max HP/s; heals enemies within 6 studs 2% of their max HP/s (bosses too) | burst DPS |
| Hexer (disruptor) | 2.0 | 0.9 | 18 | 6 | stuns the nearest unit within 15 studs for 3 s every 10 s | spacing, Steadfast, Calm Air |

Bounty and leak values are **TUNE**. Mini-bosses and bosses are stun-immune: incoming stuns become a 20% slow for the stun's duration.

## 13. Waves (`WaveConfig.luau`)

### 13.1 HP formula

```
hp = 100 × archetypeHP × waveFactor(w) × difficulty × world [× finaleHpScale for the act's final boss]
waveFactor(w) = 1 + 0.12w + 0.004w²      → 2.6× (w10), 5.0× (w20), 8.2× (w30), 14.5× (w45)
```

| Difficulty | HP × | Shield pools |
|---|---|---|
| Normal | 1.0 | ×1 |
| Nightmare | 2.0 | Fortified ×2 |
| Legend | 3.0 | Fortified ×2 |
| Event Hard | 10.0 | Fortified ×2 |

- **World multipliers** (**TUNE**): W1 1.0, W2 1.6, W3 2.5, W4 4.0, W5 6.0.
- **Infinite:** past the final authored wave *L*, waveFactor is frozen at *L* and HP × 1.06^(w−L).
- **Sample HP, W1 Normal:** Wisp 112 (w1), 260 (w10), 500 (w20), 820 (w30); Brute 4×; Thornback 5,200 (w10).

### 13.2 Cash curve (solo, World 1)

Starting 600 plus cumulative wave bonus `250N + 20N(N+1)`:

| By wave | Cumulative wave bonus |
|---|---|
| 5 | 1,850 |
| 10 | 4,700 |
| 15 | 8,550 |
| 20 | 13,400 |
| 30 | 26,100 |

Bounties add roughly 150–700 per wave; Merchants add up to 1,900 (Caravan) or 6,000 (Bazaar) per wave each.

### 13.3 World 1 "Lantern Market": 30-wave master template

Act 6 plays all 30 waves. Acts 1–5 play the first N waves (15 / 18 / 20 / 22 / 25), and the act's **last wave is replaced by the finale** (the Wilt Matron, untimed, unskippable) at the act's `finaleHpScale`.

| W | Tag | Content (count) | Total |
|---|---|---|---|
| 1 | Basics | Wisp 8 | 8 |
| 2 | Basics | Wisp 12 | 12 |
| 3 | Basics | Wisp 10, Courier 4 | 14 |
| 4 | Basics | Wisp 14, Courier 6 | 20 |
| 5 | **New: Veiled** | Wisp 10, Veiled 6 | 16 |
| 6 | Basics | Wisp 12, Brute 2 | 14 |
| 7 | Basics | Courier 8, Veiled 8 | 16 |
| 8 | **Spike (2× w7)** | Wisp 14, Courier 8, Veiled 8, Brute 2 | 32 |
| 9 | Breather | Wisp 12 | 12 |
| 10 | **Mini-boss** | Thornback 1 (sheds 4 Couriers at 50%), Wisp 10 | 11 |
| 11 | **New: Moth** | Wisp 12, Moth 6 | 18 |
| 12 | Basics | Courier 10, Moth 8, Veiled 4 | 22 |
| 13 | **New: Warded** | Wisp 10, Warded 6 | 16 |
| 14 | Basics | Wisp 10, Brute 4, Mender 4 | 18 |
| 15 | **Mid-boss** | Lantern-Eater 1 (flying; snuffs the nearest Lantern aura for 4 s every 12 s), Moth 6 | 7 |
| 16 | Breather | Wisp 14, Courier 6 | 20 |
| 17 | **New: Ironbound** | Wisp 14, Ironbound 4 | 18 |
| 18 | Basics | Courier 10, Hive 3 (+12 Couriers) | 13 |
| 19 | Basics | Wisp 12, Brute 4, Hexer 2 | 18 |
| 20 | **Spike (2× w19)** | Wisp 16, Brute 6, Veiled 6, Moth 6, Hexer 2 | 36 |
| 21 | Basics | Moth 12, Veiled 10 | 22 |
| 22 | Basics | Ironbound 6, Warded 6, Mender 4 | 16 |
| 23 | Breather | Wisp 16, Courier 8 | 24 |
| 24 | Basics | Brute 6, Hive 6, Hexer 3 | 15 |
| 25 | **Mini-boss ×2** | Thornback 2, Mender 4, Warded 4 | 10 |
| 26 | Basics | Courier 10, Veiled 10, **Veiled Moth** 6 | 26 |
| 27 | **Exam** | Wisp 10, Veiled 6, Moth 6, Ironbound 4, Warded 4, Brute 4, Mender 3, Hive 2, Hexer 2 | 41 |
| 28 | Breather | Wisp 16 | 16 |
| 29 | Rush | Courier 20, Brute 8, Warded 4 | 32 |
| 30 | **Final boss** (untimed, unskippable) | Wilt Matron 1, Wisp 8 | 9 |

Music bands: Dusk 1–9, Lanterns 10–19, Wilt 20–26, Last Bloom 27–30.

| Act | Waves | Finale HP scale | Matron HP (Normal) | Matron HP (Nightmare) |
|---|---|---|---|---|
| 1 | 15 | 0.50 | 27,750 | 55,500 |
| 2 | 18 | 0.65 | 43,446 | 86,892 |
| 3 | 20 | 0.80 | 60,000 | 120,000 |
| 4 | 22 | 0.90 | 75,276 | 150,552 |
| 5 | 25 | 0.95 | 92,625 | 185,250 |
| 6 | 30 | 1.00 | 123,000 | 246,000 |

Worlds 2–4 each get their own 30-wave template and boss in Alpha (BUILD_PLAN P3-02), following the same pacing rules: a new attribute every 5–8 waves, a 2× spike, a mid-boss at 50–60% of the run, an exam wave 2–3 waves before the final, a breather before the boss, and an untimed final boss.

## 14. Bosses

**Common rules:** stun-immune (stuns become 20% slows). A HP bar shows phase markers. Every board-stun has a visible telegraph ring for its wind-up. Final bosses are untimed and unskippable.

### The Wilt Matron (World 1 final boss)

HP × 150, speed × 0.5, leak 100 (a leaked final boss ends the match).

| Phase | Trigger | Behaviour |
|---|---|---|
| 1 | 100% | Walks. **Wilting Pulse** every 15 s: 2 s wind-up ring, then stuns every player unit within 18 studs for 3 s |
| 2 | 66% HP | Roots for 3 s. Summons 6 Wisps + 2 Brutes. Gains a shield of 15% max HP (Breakers deal 3×). Pulse every 12 s |
| 3 | 33% HP | Speed ×1.3. Summons 4 Veiled + 2 Menders (Menders heal her). Pulse every 10 s, radius 20, 1.5 s wind-up |

Counterplay: spread units outside the 18-stud ring, bring a Breaker for the shield and a Lantern for the phase-3 Veiled, kill the Menders fast, and use Steadfast-trait units or Calm Air.

### Other bosses

- **Thornback** (mini-boss): HP × 20, speed × 0.6. At 50% HP it sheds 4 Couriers.
- **Lantern-Eater** (flying mid-boss): HP × 30, speed × 0.9. Every 12 s it snuffs the nearest Lantern aura within 30 studs for 4 s, so one Lantern alone isn't enough.
- **Boss Bounty:** the day's world boss at wave-25 Nightmare HP with all 3 phases and a 5-minute limit.
- **Elite variants (Boss Event, Update 4):** +100% HP, pulse 1.5× more often, each tier must be won within 20 waves.

## 15. Economy

### 15.1 Currencies

| Currency | Earned from | Spent on | Paid/earned split |
|---|---|---|---|
| Cash (in match) | 600 start, wave bonus, bounties, Merchants | placement, upgrades | – |
| Gems | stages, quests, Trials, Bounties, codes, battle pass; paid via gem packs | summons, storage expansions (+25 slots for 2,000 Gems, twice), Exchange selectors | **yes** |
| Gold | every match | unit training, Bloom, evolution | no |
| Trait Seeds | Trials, Bounties, quests, codes, battle pass, Minaret (U3); paid via seed packs | trait rerolls | **yes** |
| Divine Seeds (U2) | Raid shop | second trait slot | yes |
| Stat Cores / Focus Cores | battle pass, Raid shop, Minaret (U3), Dungeons (U2) | stat rerolls | **yes** |
| Essence | Nightmare clears (2), Raid stages (2), Legend Stages (U1) | evolution | no |
| Relics | drops (§8), Raid shop, event shop | evolution | no |
| Moon Sigils | Limited banner pulls | featured Secret (1,200) | – |
| Exchange Tokens | leftover Sigils, excess duplicates | Exchange: Epic Selector 60, Legendary Selector 300, Mythic Selector (standard pool) 1,500, cosmetics | – |
| Raid Sigils | Raid | Raid shop | – |
| Dungeon Tokens (U2), event currency (per update) | their modes | Charms; event banner (150 per pull), event shop | – |

**Paid-balance rule:** anything granted by a Robux purchase (gem and seed packs, VIP and Club daily grants, premium battle pass items) goes to the **paid** balance. Earned balances come only from gameplay, codes and the free battle pass track.

### 15.2 Match rewards (Normal; Nightmare ×1.5 Gems and Gold, first clear ×2)

| Reward | Formula | Act 1 (15 waves) | Act 6 (30 waves) |
|---|---|---|---|
| First-clear Gems (once) | 100 + 50 × act | 150 | 400 |
| Repeat-clear Gems | 30 + 2 × waves | 60 | 90 |
| Gold | 150 + 15 × waves | 375 | 600 |
| Account XP | 20 × waves | 300 | 600 |
| Unit XP (each placed unit) | 10 × waves | 150 | 300 |
| Pass XP | 10 × waves | 150 | 300 |

All rewards are computed on the server from waves cleared, never reported by the client.

### 15.3 Daily budget for an engaged free player (**TUNE**, verify with telemetry)

| Resource | Sources | Per day |
|---|---|---|
| Gems | ~10 stage runs (~1,000), quests (~600: dailies 4 × 100, weeklies 1,400/week), 30-min Trials (20 × 20 = 400) | ~2,000 |
| Trait Seeds | 30-min Trials 20, Bounties 10, daily Trial 3, weekly Trial ~3, daily quests 4 | ~40 |
| Gold | ~10 runs × ~450 | ~4,500 |

## 16. Progression and quests

### Account level

XP to next level = 150 + 50 × L (**TUNE**); cap 100. Lv10 takes about 12 Act-1 runs, Lv50 about 230.

| Lv | Unlocks |
|---|---|
| 5 | Trials, Grade Loom |
| 10 | Boss Bounty, Limited banners, Secret and Shiny results, Rifts (U3), Garden Idle (U6) |
| 15 | Raid |
| 20 | Boss Event (U4) |
| 25 | Bazaar Dungeons (U2) |
| 30 | Minaret Climb (U3), Fair-Play Arena (U5) |
| 50 | Trading (U5) |

### Quests

- **4 dailies**, each worth 100 Gems + 250 Pass XP + 1 Trait Seed: clear 3 stages; place 30 units; defeat 500 enemies; use 5 actives. Reset 00:00 UTC.
- **5 weeklies**, each worth 280 Gems + 2,000 Pass XP: clear 20 stages; clear a Nightmare act; complete 5 Trials; defeat 10 bosses; earn 50,000 in-match Cash. Reset Monday 00:00 UTC.
- No quest ever requires summoning or spending.
- **Evolution guides:** a 4-step quest chain per Mythic/Secret (reach Lv30 → 1,000 takedowns → obtain the Relic → evolve).

### Storage and loadouts

- Storage: 150 units base, +25 twice for 2,000 Gems each, +100 with the pass. Hard cap 300.
- Team: 6 loadout slots; 2 team presets (+3 with the pass).
- Auto-sell by rarity never touches shinies, evolved units or units with a rank-5+ trait.

## 17. Battle pass

| Item | Value |
|---|---|
| Season length | 6 weeks (**TUNE**; spans one major update and its Part 2) |
| Levels | 50 × 1,000 Pass XP. Dailies give ~1,000 Pass XP/day, matches the rest (~1,200/day finishes the pass) |
| Free track | Gold 1,000 on most levels; 200 Gems every 5th level (2,000 total); 5 Trait Seeds on 10 levels (50); Stat Core at levels 10/20/30/40; **featured Legendary at Lv50** |
| Premium track | **Featured Legendary at Lv1**; +300 Gems every 5 levels (3,000); +10 Seeds every 5 levels (100); Focus Cores at Lv25 and Lv50; **Shiny featured unit at Lv50**; petal aura cosmetic and title. Price tier ≈ 499 Robux (read at runtime) |
| S1 featured unit | a new Legendary designed in P3-08 |

## 18. Monetization

Monetization sells time, convenience and cosmetics through four channels: game passes, battle pass/subscription, gem and seed packs, and rewarded video. **No Robux price ever appears in code.**

- Config stores only product **keys → IDs**. The client reads live prices with `MarketplaceService:GetProductInfo` (passes: `Enum.InfoType.GamePass`; products: `Enum.InfoType.Product`).
- Items stay enrolled in Managed Pricing. The target tiers below are what the user sets in the Creator Dashboard.

| Key | Item | Target tier (Robux) |
|---|---|---|
| PASS_VIP | VIP: +10% account XP and Gold, 1 free daily summon on Standard/Featured, chat tag | 299 |
| PASS_SPEED3 | 3× game speed (2× is free) | 399 |
| PASS_STORAGE | +100 storage | 149 |
| PASS_PRESETS | +3 team preset slots | 299 |
| PASS_SHINY | Shiny Charm: shiny chance 1% → 2% | 499 |
| BP_PREMIUM | Premium battle pass (per season) | ~499 |
| SUB_CLUB | "Jasmine Club" monthly subscription: 300 Gems + 2 Trait Seeds per day | set by user (subscriptions are priced in the dashboard; tier not decided) |
| GEM_600 / GEM_3300 / GEM_7000 / GEM_15000 / GEM_40000 | Gem packs | 99 / 499 / 999 / 1,999 / 4,999 |
| SEED_12 / SEED_50 / SEED_180 | Trait Seed packs (~16–25 Robux per Seed) | 299 / 999 / 2,999 |
| AD_TICKET | Rewarded video: 1 free summon ticket per day (needs 2,000+ monthly unique visitors) | – |

**Never sold:**
- single pulls of a scarce summon currency at a premium price (the Anime Defenders mistake)
- luck potions (at launch)
- units for Robux outside the battle pass's own featured unit
- power that bypasses pity

Auto Play ships free.

**Trading (Update 5):**
- Lv50 gate; server escrow with an atomic commit to both profiles.
- Traits, stat grades and Bloom reset on trade.
- Limited Secrets and event units are untradeable.
- `paidOrigin` units are untradeable for players whose `IsPaidItemTradingAllowed` is false.
- Structured trade UI only (chat is age-checked worldwide since January 2026).

## 19. Live-ops calendar

L = public launch (end of week 26). Every update ships a banner, an event currency, a mode or world, 2–4 codes (1,000–3,000 Gems + 10–50 Seeds) and a title tag such as `[UPD 1] Haret Al Yasmin`.

| Week | Beat | Content |
|---|---|---|
| L−4 | Soft launch | Closed and soft test; onboarding fixes |
| L | **Launch** | W1–W4, Story N/NM, Infinite, Trials, Raid, Bounties; Limited S1 "Night of First Bloom" (Yasmin); battle pass S1; codes: launch + like/favorite milestones |
| L+3 | **Update 1, Part 1** | Legend Stages (W1–W4) + World 5 "Saffron Docks"; new Mythic on the Featured pool; event "Saffron Tide" (Saffron Threads) |
| L+5 | Update 1, Part 2 | W5 Nightmare + Legend; balance pass |
| L+6 | Battle pass S2 | – |
| L+7 | **Update 2, Part 1** | Bazaar Dungeons, Divine Seeds (second trait slot), Charms; Limited S2 (new Secret) |
| L+9 | Update 2, Part 2 | new dungeon cards and Charm sets |
| L+11 | **Update 3, Part 1** | Minaret Climb (season-1 leaderboard), Night Bloom Rifts (Night Petals currency, hourly) |
| L+12 | Battle pass S3 | – |
| L+13 | Update 3, Part 2 | Rift featured unit rotation |
| L+15 | **Update 4** | Boss Event (5 Normal tiers → Elite, 20-wave tier limit) |
| L+19 | **Update 5** | Trading (rules in §18) + Fair-Play Arena |
| L+23 | **Update 6** | Garden Idle (AFK) |
| then | every 4 weeks | a new world every second update; a new Limited each update; seasonal overlays when the launch date is known ("Wilt Moon" autumn, "Frost Jasmine" winter, anniversary with 7-day login rewards) |

## 20. Compliance

1. **Paid random items.** Gems and Seeds can be bought, so every banner, the trait reroll and the stat reroll are Paid Random Items. Every outcome is listed with numerical odds to 4 decimals summing to **exactly 100%**, shown **before purchase** behind a labeled "View Odds" button, and updated live when anything changes them (Shiny Charm, featured guarantee, potential).
2. **One config for odds and RNG.** The disclosure is generated from `SummonConfig` / `TraitConfig` / `StatGradeConfig`, the same modules the server RNG reads. Tests assert every table sums to 1,000,000 ppm, and a 1,000,000-pull simulation must match the published per-rarity rates within 4σ (pity disabled), with no streak longer than the pity thresholds (pity enabled).
3. **PolicyService.** On join, the server calls `PolicyService:GetPolicyInfoForPlayerAsync` (pcall with 3 retries; on failure treat the player as restricted for that session).
   - If `ArePaidRandomItemsRestricted` is true, summons and rerolls spend **only earned** balances. Paid balances can buy only guaranteed items (Exchange selectors, cosmetics, storage). The Shiny Charm is not offered and has no effect. The VIP daily summon is replaced by 5 Exchange Tokens.
   - **Decision for the user:** these restricted-path substitutions are a conservative default; confirm them before launch.
4. **Trading gate.** If `IsPaidItemTradingAllowed` is false, `paidOrigin` units can't be traded.
5. **Testing.** Both policy paths are tested in Studio's Player Emulator for **Australia, Belgium, the Netherlands, the UK and Brazil**. Roblox publishes no full country list, so the game always reads the API and never hard-codes countries.
6. **Prices.** Read at runtime; never hard-coded; Managed Pricing left on.
7. **Maturity.** Complete the questionnaire targeting **Mild** (unrated experiences can't be played).
8. **Chat.** No feature depends on chat; trading uses a structured UI.
9. **Rewarded video.** The reward must be a developer product; requires 2,000+ monthly unique visitors.
10. **IP.** §2 rules; `assets/LICENSES.md` complete before launch; contributor contracts signed.
11. **Data safety.**
    - ProfileStore session locking; GUID unit records.
    - Audit log with idempotency keys for summons, rerolls, trades and grants.
    - Versioned backups and a rehearsed rollback.

## 21. Power-axis caps (day one)

| Axis | Cap |
|---|---|
| Unit level | 50 (+24.5% damage) |
| Bloom | 5 (+10% damage) |
| Stat grades | Jasmine: +22% damage, +11% SPA/range |
| Trait | 1 slot (2 from Update 2); Crown +200% at 1 placement |
| Herald auras | don't stack with each other |
| Upgrade discounts | −25% total |
| Crit chance | 75% |
| Enemy damage-taken debuffs | +40% total |
| SPA floor | 0.2 s |
| Placements per player | 40 / 30 / 25 / 20 |
| Storage | 300 |

New systems must declare their cap here before shipping. Never ship a layer you would have to remove later (the Ascension lesson).

## 22. Metrics

Track Roblox's ranking signals:
- qualified play-through rate
- first-play bounce under 60 s
- D1 / D7 / D28 retention
- playtime per user

Also track: the onboarding funnel (join → summon prompt → summon done → teleport → wave 1 → wave 5 → act clear), economy sources and sinks per currency, and conversion.

No public TD benchmarks exist, so targets come from the soft-launch cohort. The one hard target: **median join → wave 1 ≤ 60 s**.
