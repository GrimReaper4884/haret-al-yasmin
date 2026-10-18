# Story Plan: Season Story 1 "The Night Guard" (الحارس الليلي)

*Written 2026-10-18 by the planning session (Claude Fable 5.1) after reading the code, the balance tables,
the polish plan and the Part 1 research below. Executor: **Opus 5.5** in Claude Code on the owner's Windows
machine. Owner: approves names and looks, imports GLBs, uploads, publishes. Plan only: nothing in this
document is built yet.*

This is the whole work queue for the content update that turns the three existing episodes into a nine-episode
**Season Story 1** that follows the arc of the classic lane drama's first part (renamed, one letter off, the
way Anime Vanguards renames its roster), adds the enemies that arc needs (all through Meshy), makes the
defenders read as the lane's people at a glance (costume, build, prop, never a face), replaces the Cat with
**Al-Adashari (العدشري)** as the secret unit and gives him his own episode, adds unit upgrades and traits
with declared caps, and builds the maps (new arenas and the event map) from a modular 3D kit made in Blender.
Everything is a task with an **Accept** line (§12). Difficulty rises every episode; the curve is in §5.3 and is
asserted by the balance harness.

Companion docs: `CLAUDE.md` (rules), `docs/TOWER_DEFENSE.md` (what exists), `docs/POLISH_PLAN.md` (look pass;
some of its tasks are prerequisites here), `docs/CHARACTER_PIPELINE.md` (Meshy → Studio), `docs/DECISIONS.md`.

---

## 0. Kickoff prompt (paste this into Opus 5.5)

> Read `CLAUDE.md`, `docs/TOOLS.md`, `docs/DECISIONS.md`, `docs/TOWER_DEFENSE.md`, `docs/CHARACTER_PIPELINE.md`,
> `docs/POLISH_PLAN.md` §2 and §10, and all of `docs/STORY_PLAN.md`. Work through `docs/STORY_PLAN.md` §12
> workstream by workstream in the order of §12.0, starting with S1-N01. For every task: follow the CLAUDE.md
> verify loop (code + Lune spec, `tools/check.ps1` green, `script_grep` sync check, Studio playtest through the
> MCP with `screen_capture` evidence, `lune run tests/balance` for anything that touches Config/Units, Enemies,
> Waves, TD or Traits), commit one task per commit on branch `phase/story1` (cut it from `phase/polish`), tick
> the task in `docs/STORY_PLAN.md` §13 with the commit hash, and log every TUNE change and deviation in
> `docs/DECISIONS.md`. Every generated asset and every new name gets a `docs/COPYRIGHT_REGISTER.md` row. Numbers
> live in `src/shared/Config`, never inline. Stop and ask for anything on a **STOP** line (the name table in §3
> before any string changes, Meshy spend above a task's budget, GLB imports, image uploads, publishing, legal).
> Never put a TV series title, an actor's name or a real person in any prompt or file. When a workstream is
> ticked, post the before/after evidence and wait.

---

## 1. What the owner asked for (2026-10-18) and what this plan decides

| Ask | Plan |
|---|---|
| More episodes for Season Story 1, harder each time | Nine episodes (the three existing ones re-titled into the arc + six new), waves 20 → 60, a new mechanic and boss per episode, a difficulty ladder asserted by the harness (§5) |
| More enemies, Meshy models | 11 new regular attackers and 6 new bosses, each with a Meshy prompt in the house style (§6); concept first, owner judges, then mesh |
| Upgrades, traits and more for the units | Level-7 "signature" upgrade with a two-way choice for Epic+, traits v2 (12 traits, 2nd slot at 3 stars), shabriyeh beads (per-unit passives earned in episodes), every axis with a cap declared in DECISIONS (§7) |
| Units that read as the lane's real people, renamed by one letter | A costume/build/prop signature per defender (§4.2) and the renaming table (§3). Faces stay chibi cartoons: the C-201 rule against actor likenesses stands |
| Maps, an event map built in Blender from 3D modules | A modular lane-and-orchard kit built in Blender (§8), new arenas laid out in Blender and exported as config, and the Olive Press event map for the running Olive Harvest event (§8.4, §9) |
| Al-Adashari as the secret unit instead of the Cat, and an episode about him | `adashari` secret unit (§7.6), Episode 9 "The Confession" (§5), the Cat retired to a lobby prop with a profile migration (§7.7) |
| Research Part 1 first | §2 digest with sources; `docs/research/BAB_AL_HARA_REFERENCE.md` stays the long form |

**Decisions the owner must make before strings or assets change (STOP):**

1. The renaming table in §3 (one letter off), including the Arabic spellings.
2. Whether the lobby roleplay mystery in `docs/SEASON_1.md` ("Diamonds of the Lane", Episodes 2–5 unbuilt) is
   retired in favour of this story. Recommended: keep its Episode 1 errand as the lobby hook, do not build the
   rest, and mark the doc superseded (§10.4).
3. The secret unit's drop rule (§7.6: a chance per Episode 9 clear with a clear-count pity, and a guaranteed copy
   on the first Nightmare clear). Not a paid random item, so no policy gating; the odds are still shown.
4. Meshy budget: the full roster costs ≈ 1,400 credits; the balance is ≈ 1,150. §12.0 phases it so the first
   two phases fit; the owner tops up or we stop after Episode 6.

---

## 2. Research digest: Part 1 of the classic lane drama (2006)

Sources read 2026-10-18: AR Wikipedia Part 1 page and the full character list, TheTVDB Part 1 episode
summaries (ep. 9, 10, 17, 29, 31), Al Jazeera "the repentant villain" piece (2026-02-23, via its mirror),
Dramaar's full-story recap, the fan blog "the whole tale", Elcinema and TMDB cast pages, plus the project's
own `docs/research/BAB_AL_HARA_REFERENCE.md` (2026-10-16). **No costume descriptions exist in any text
source**; the looks in §4 are period-archetype reads and the researcher's recollection, not quotations.

### 2.1 The arc (33 episodes, Harat al-Dab'a, 1920s–30s)

1. **A thief given a chance.** A fierce man with a criminal past is lent money by the za'im to sell pickles
   from a donkey cart. He cannot leave his past.
2. **The gold and the watchman.** He steals the cloth merchant's gold; the night watchman catches him at the
   gate; he kills the watchman and buries him with the gold in his own yard. He loses a **shoe** while fleeing;
   the lane suspects him; the corrupt police sergeant beats him; nothing is proven.
3. **The false oath.** Before the za'im, the sheikh and the men, he swears on the holy book that he is
   innocent. He then moves his family to the rival lane, whose 'akeed houses him.
4. **Stirring the rival lane.** He turns the rival 'akeed against our lane (TVDB ep. 9–10) and sets up a fight
   between the two lanes so he can appear as a hero. In the clash our 'akeed cuts the rival's cheek; the thief's
   **hand** is cut. He returns to our lane honoured.
5. **Honest money.** The coffee-house owner gives him a knife-sharpening stone; our 'akeed hires him as the
   **night guard of his warehouse (البوايكية)**; he stops the rival thug **Abu Satour** from burning it (ep. 29)
   and is paid **one gold lira**, the first honest coin of his life, which brings him to tears.
6. **Divine justice.** A rival thug (Sakhr, "Abu al-Hokm", who loses a hand to him) stabs his oath hand; the
   barber-hakim finds old infected wounds; **gangrene**; the arm is amputated (ep. 29). His eldest son
   **Ma'rouf**, a porter, dies of a **snake bite** while the father digs for the gold.
7. **Confession.** Tormented by nightmares, he confesses on his deathbed to the za'im, the sheikh, the hakim,
   the 'akeed and the merchant; the watchman and the gold are dug up; half the gold goes to the lane fund and
   half to the watchman's family. He dies forgiven. His younger son sells the house and leaves.

**Parallel threads of Part 1:** the corrupt police sergeant and his corporal; the "blind" beggar housed in the
mosque who is a spy (killed in Part 2 by the 'akeed; in Part 1 he murders the hummus seller carrying money for
the rebels, found dead at the gate); the barber's eldest son's engagement to the gossip's daughter and the
divorce-and-secret-remarriage comedy; the henpecked neighbour and his loud wife; the coppersmith's deaf
daughter; the coffee-house owner raising his nephew; the Armenian cloth merchant who leaves for Aleppo; the
za'im's son reported dead abroad (the engagement party turns to mourning).

### 2.2 Who is who (Part 1 only; our ids in brackets)

| Show role | Ours today | Fate / note |
|---|---|---|
| The hakim, barber and wise elder (`umm_hara`) | Abu Issam, Legendary healer | alive; divorces and secretly remarries |
| The 'akeed (`zaim_akbar`) | Abu Shehab, Mythic | alive; hires the thief as night guard |
| The za'im (`zaim`) | Abu Saleh, Legendary | alive at the end of Part 1 |
| The barber's hot son (`qabaday`) / elder son (`hallaq`) | Mo'taz / Issam | Issam marries Lutfiya |
| Coffee-house owner (`qahwaji`) | Abu Hatem, farm | gives the sharpening stone |
| Henpecked neighbour (`mukhtar`) and his wife (`saqqa`) | Abu Badr / Fawzia | comedy |
| Baker (`farran`), coppersmith (`haddad`) | Abu Bashir / Abu Khater | the show's coppersmith; ours is "blacksmith" |
| Chickpea seller, gossip (`khayyat`) | Abu Ghalib | from the rival lane in the show; a spiteful gossip |
| Watchman (`natour`) | Abu Fares (Part 2 name); Part 1's watchman is murdered in ep. 1 | our story keeps the murdered watchman as a separate NPC |
| **The thief** (`chief_thief` boss) | Al-Idaashari | **becomes our secret unit after Episode 9** |
| Rival 'akeed (`rival_zaim` boss) | Abu al-Nar | feud, later ally |
| The spy (`spy`) | Al-Nims (a Part 4+ character) | kept as a generic sneak enemy |
| Not yet in the game | the police sergeant Abu Jawdat and corporal Nouri; thugs Abu Satour, Abu Dira'a, Sakhr Abu al-Hokm; the "blind" spy Sateef; the murdered watchman Abu Sam'o; the merchant Abu Ibrahim; the hummus seller Abu Samir; the hammam owner Abu Qasim; the midwife Umm Zaki; the cobbler Abu Mahmoud; the greengrocer Abu Marzouq; the second watchman Abu Majed; the garbage man Abu Ahmad and his donkey; the Armenian merchant | all candidates in §6 and §7 |

### 2.3 What we never do (unchanged, C-201 / D-007)

No series title anywhere, no actor names or photos in prompts, no likeness (chibi cartoon faces only), no
theme music or recordings, no quoted lines. Costume, build, prop, era and **story beats** are folk and
historical material and are what this plan uses.

---

## 3. Names: one letter off (STOP: owner approves the table)

Anime Vanguards renames every unit by a letter or two (Noruto, Alocard, Song Jinwu, Sprintwagon) so the roster
is recognisable without using the licensed names. The owner chose the same rule. This **lowers** the legal and
reputational exposure that C-201 recorded (exact principal names were rated Medium/High); it does not remove
it: the register row C-210 records the change and the rationale. Display names live only in
`Config/Strings.luau` (`unit.*.name`, `enemy.*.name`, `npc.*`); ids and balance do not change.

Rules: exactly one letter changed, added or removed in **both** English and Arabic where possible; the result
should still sound like a lane name (the Arabic is what matters to our players); avoid names that are
religiously or politically loaded (so not Abu Bakr, Abu Talib, Bashar, Abu Azzam); keep the trade in the name
where the current string has it ("the Watchman", "the Baker").

| Id | Today (EN / AR) | Proposed (EN / AR) | Letter | Note |
|---|---|---|---|---|
| `umm_hara` | Abu Issam, the Barber-Hakim / أبو عصام | **Abu Hissam**, the Barber-Hakim / أبو حسام | ع→ح | Hussam is a common name; the father's kunya follows the son |
| `hallaq` | Issam, the Barber's Son / عصام | **Hissam** / حسام | ع→ح | matches his father |
| `qabaday` | Mo'taz / معتز | **Mo'ez** / معز | drop ت | Mu'izz is a real name |
| `zaim_akbar` | Al-'Akeed Abu Shehab / العكيد أبو شهاب | Al-'Akeed **Abu Shehan** / العكيد أبو شهان | ب→ن | "'akeed" is a generic title and stays |
| `zaim` | Za'im Abu Saleh / الزعيم أبو صالح | Za'im **Abu Faleh** / الزعيم أبو فالح | ص→ف | Faleh is a real name |
| `qahwaji` | Abu Hatem of the Coffee House / أبو حاتم | **Abu Hazem** of the Coffee House / أبو حازم | ت→ز | |
| `mukhtar` | Abu Badr / أبو بدر | **Abu Bader** / أبو بادر | add ا | reads as a name in both scripts |
| `saqqa` | Fawzia / فوزية | **Fawza** / فوزة | drop ي | Fawza is a real name; "Abu Bader's wife" in the desc |
| `khayyat` | Abu Ghalib the Chickpea Seller / أبو غالب | **Abu Ghadeb** the Chickpea Seller / أبو غاضب | ل→ض | "the angry one": fits the spiteful gossip |
| `farran` | Abu Bashir the Baker / أبو بشير | **Abu Baseer** the Baker / أبو بصير | ش→ص | "the clear-sighted" |
| `haddad` | Abu Khater the Blacksmith / أبو خاطر | **Abu Shater** the Blacksmith / أبو شاطر | خ→ش | "the clever one" |
| `natour` | Abu Fares the Watchman / أبو فارس الناطور | **Abu Hares** the Watchman / أبو حارس الناطور | ف→ح | "the guard": the pun is the point |
| `pahlawan`, `arada`, `walad` | The Strongman, The 'Arada Troupe, Lane Boy | unchanged | | generic |
| `spy` | Al-Nims / النمس | **Al-Nimr** / النمر | س→ر | "the tiger", for a weasel |
| `chief_thief` → new unit `adashari` | Al-Idaashari / الإدعشري | **Al-Adashari** / العدشري | drop إ | the owner's spelling; used for the boss and the secret unit |
| `rival_zaim` | Abu al-Nar / أبو النار | **Abu al-Nahr** / أبو النهر | add ه | "father of the river" |
| new | Abu Jawdat (police sergeant) / أبو جودت | **Abu Jawdan** / أبو جودان | ت→ن | |
| new | Nouri (corporal) / نوري | **Houri** / حوري | ن→ح | |
| new | Abu Satour (cleaver thug) / أبو ساطور | **Abu Shatour** / أبو شاطور | س→ش | |
| new | Abu Dira'a (drunk brute) / أبو دراع | **Abu Zira'** / أبو زراع | د→ز | |
| new | Sakhr "Abu al-Hokm" / صخر | **Fakhr** Abu al-Hokm / فخر | ص→ف | |
| new | Sateef the blind spy / صطيف | **Lateef** / لطيف | ص→ل | "the gentle one": irony |
| new NPC | Abu Sam'o (the murdered watchman) / أبو سمعو | **Abu Shem'o** / أبو شمعو | س→ش | "candle": the watchman's lantern |
| new NPC | Abu Ibrahim (cloth merchant) / أبو إبراهيم | **Abu Brahim** / أبو براهيم | drop إ | |
| new NPC | Ma'rouf (the thief's son) / معروف | **Ma'touf** / معطوف | ر→ط | story text only |
| new unit | Abu Qasim (hammam owner) / أبو قاسم | **Abu Basim** / أبو باسم | ق→ب | |
| new unit | Umm Zaki (midwife) / أم زكي | **Umm Baki** / أم باقي | ز→ب | |
| new unit | Abu Samir (hummus seller) / أبو سمير | **Abu Samih** / أبو سميح | ر→ح | |
| new unit | Abu Mahmoud (cobbler) / أبو محمود | **Abu Hamoud** / أبو حمود | drop م | |
| new unit | Abu Ahmad the garbage man / أبو أحمد الزبال | **Abu Ahmar** / أبو أحمر | د→ر | "the red one" |
| new unit | Suad Khanum (the matriarch) / سعاد | **Su'da Khanum** / سعدى خانم | ا→ى | Su'da is a real name |

Where the sheet above says "unchanged", the id's strings stay. Everything else is one commit (S1-N01) that
changes only `Strings.luau`, the comments in `Units.luau` / `CharacterLooks.luau`, the register and this doc;
tests that match display strings (`tests/strings.spec.luau` if any) update in the same commit.

---

## 4. Looks: units that read as the lane's people

### 4.1 The rule

We never model a face from an actor. What fans recognise from the match camera is **silhouette**: build,
headwear, how the tarboosh is wrapped, the moustache shape, the garment cut and colour, the prop in the hand,
the stance. ART_BIBLE §5 (chibi, dignity, hand-painted flats) and POLISH_PLAN §2's style lock stay. The
existing 16 Meshy defenders are kept; S1-L02 re-rolls only the ones whose signature is wrong (table below) and
S1-L03 gives every defender a **signature pose** in the idle (the posed card preview is what players stare at).

### 4.2 Signature sheet (period archetypes; what to check on each model)

| Id | Build | Head | Face hair | Garment | Prop / stance | Today's model |
|---|---|---|---|---|---|---|
| `umm_hara` Abu Hissam | slim, upright, mid-50s | red tarboosh, no wrap | thick dark moustache, no beard | grey-striped qumbaz, white barber apron over it, prayer beads | remedy jar; calm, one hand raised as if advising | AbuIssam: **keep** |
| `zaim_akbar` Abu Shehan | broad, tall | tarboosh wrapped in a dark **laffeh** (hatta), end over the shoulder | thick dark moustache, stubble | black sherwal, black sidriyeh vest over white shirt, very wide black belt | shabriyeh at the right hip; feet planted, chin up | AbuShehab: check the laffeh wrap and the belt width |
| `zaim` Abu Faleh | heavy, old | white tarboosh wrapped in white | full white beard | dark qumbaz, fur-collared **bisht**, cane, beads | cane in both hands, seated-looking stance | AbuSaleh: **keep** |
| `qabaday` Mo'ez | athletic, young | tarboosh wrapped tight, dark | **handlebar** moustache, no beard | sherwal, striped sidriyeh, sash | shabriyeh half-drawn; forward lean | Motaz: check the handlebar |
| `hallaq` Hissam | slim, young | small tarboosh | thin moustache | white barber apron, rolled sleeves | razor and towel | Issam: **keep** |
| `qahwaji` Abu Hazem | stout, pompous | red tarboosh high on the head | thick moustache, round cheeks | striped qumbaz, gold-trimmed vest, beads | tea tray on the fingertips, chest out | AbuHatem: **keep** |
| `mukhtar` Abu Bader | small, hunched | tarboosh too big | thin moustache, timid eyes | over-long qumbaz, slippers | hands clasped, flinching | AbuBadr: check the hunch |
| `saqqa` Fawza | big, loud | bright headscarf (indoor dress, no veil) | — | patterned house dress, sleeves rolled, apron | broom raised, one foot forward | Fawzia: **keep** |
| `khayyat` Abu Ghadeb | skinny, sly | battered tarboosh | thin moustache, narrow eyes | patched qumbaz, chickpea pot on a strap | ladle; leaning in to whisper | AbuGhalib: check the pot |
| `farran` Abu Baseer | heavy, strong | white cap | thick moustache | flour-dusted white shirt, apron | bread peel; wide stance | AbuBashir: **keep** |
| `haddad` Abu Shater | broad | none, bald or grey cap | full dark beard | leather apron, rolled sleeves, soot | hammer and tongs | AbuKhater: **keep** |
| `natour` Abu Hares | normal, older | hatta | grey short beard | dark cloak over qumbaz | lantern up, stick | AbuFares: **keep** |
| `adashari` (new) | wiry, gaunt | dark laffeh low over the brow | stubble, hollow cheeks | grey-brown striped qumbaz, wide black belt, **left sleeve pinned (one arm)** after Ep 9; bandage | lantern in the right hand, knife in the belt; guarded stance | new (§7.6) |

Enemies keep POLISH_PLAN §2's colder palette (indigo, basalt, olive, red accents). Bosses get a 1.4–1.8× scale
and one unmistakable prop (cleaver, cane, rifle, beggar's staff).

---

## 5. Season Story 1: nine episodes, harder each time

### 5.1 Structure

The story is told by the **Hakawati**: each episode has a 3-line intro and a 3-line outro (EN + AR) shown on
the Play panel card and the result screen (`Config/Story.luau`, `story.epN.intro/outro`), plus one line per
boss arrival. Episodes 1–3 keep their ids, arenas and tuned waves (their titles and blurbs change). Episode N+1
unlocks after N on Normal (existing rule); Hard after Normal, Nightmare after Hard. Every episode has one **new
mechanic** introduced by its enemies, one **new boss**, and one **map**. Rewards scale with `TD.STORY_REWARDS`
(§5.4). Numbers below are the design intent; the balance harness (§5.3) is the acceptance test.

### 5.2 The episodes

| # | Id | Title (EN / AR) | Beat | Arena | Waves | Mechanic introduced | Bosses (wave) |
|---|---|---|---|---|---|---|---|
| 1 | `ep1` | Night of the Thieves / ليلة الحرامية | the gold is stolen; the thief at the gate | orchard | 20 | stealth (exists) | Sergeant (10), **Al-Adashari, thief** (20) |
| 2 | `ep2` | The Rival Lane / الحارة التانية | the thief stirs Abu al-Nahr's lane | orchard | 30 | armor, speed (exists) | Sergeant (10), Al-Adashari (20), Abu al-Nahr (30) |
| 3 | `ep3` | The Siege / الحصار | the garrison answers the feud | siege | 40 | sappers (exists) | Sergeant, Al-Adashari, Abu al-Nahr, Commandant (40) |
| 4 | `ep4` | The Lost Shoe / الصرماية | pickpocket swarms; the gendarmes search houses | **saha** (new) | 40 | **swarm** (tiny fast enemies, 60/wave cap raised) + **drummer** (speed aura) | Corporal Houri (10), Sergeant (20), **Abu Jawdan** (40) |
| 5 | `ep5` | Fire at the Warehouse / حريق البوايكية | Abu Shatour's men come with torches | **warehouse yard** (new) | 45 | **burners** (gate burn stacks; water units douse) + **porters** (shield aura) | Sergeant (15), **Abu Shatour** (30), Abu Shatour + Abu al-Nahr (45) |
| 6 | `ep6` | The Blind Beggar / الشحاد الأعمى | the spy walks among neighbours | **saha at night, fog** | 50 | **disguised** (look like lane folk; revealed by lantern or a hit; splash-immune until revealed) | Al-Nimr (10), Abu Jawdan (25), **Lateef** (50, teleports forward once) |
| 7 | `ep7` | The Police Post / المخفر | the gendarmerie marches on the lane | **post road** (new) | 50 | **ranged saboteurs** (disable a defender 2.5 s), heavy armor | Corporal Houri (10), Sergeant (20), Abu Jawdan (35), **Commandant** (50, summons) |
| 8 | `ep8` | The Two Lanes / الحارتين | Abu al-Nahr's whole lane vs ours; the thief returns | **twin gates** (new, two spawns) | 55 | **two paths** that merge; **splitter** carts; **healer** (rival hakim) | Fakhr Abu al-Hokm (15), Abu Zira' (30), Abu al-Nahr (45), **Al-'Akeed Abu al-Nahr, enraged** (55) |
| 9 | `ep9` | The Confession / الاعتراف | one-armed, he guards the gate; the snakes in the grave; the end | **twin gates, dusk→night** | 60 | **ally tower**: Al-Adashari stands at the gate as a free, unsellable defender from wave 1; **snake swarms** (stealth, tiny) | Abu Shatour (15), Lateef (30), Abu Zira' + Fakhr (45), **Abu al-Nahr and the Commandant together** (60) |

Episode notes:

- **Ep 4 "The Lost Shoe".** Opens in the fountain square (the lobby's own saha rebuilt as an arena: the gate
  is at the lane end, enemies come from the rooftop stair and the side alley). Swarms are many weak
  `pickpocket`s with a **drummer** every third group; the Sergeant's house search is the wave-20 boss; Abu
  Jawdan arrives with two Corporals. Hakawati: the shoe found by the chest; the thief beaten but silent.
- **Ep 5 "Fire at the Warehouse".** The yard of the 'akeed's warehouse in the orchards: the objective is the
  warehouse door (same gate HP rules; the gate prop is a double door with sacks). `torchbearer`s that reach the
  door add a **burn stack** (1 gate HP per 2 s per stack, max 5, 20 s); Fawza, the water carrier and Abu Basim's
  steam clear stacks (`douse` on hit, §7). Hakawati: the night guard's lantern; Abu Shatour caught; one gold lira.
- **Ep 6 "The Blind Beggar".** The saha at night in fog (Atmosphere density up, lantern radius matters).
  `disguised` enemies walk as neighbours: untargetable and splash-immune until a lantern (Natour / Umm Baki)
  lights them or a single-target hit lands; a revealed one stays revealed. Lateef's **teleport** jumps him 20 %
  of the path once at half HP (telegraphed 2 s). Hakawati: the beggar in the mosque courtyard; the purse at the gate.
- **Ep 7 "The Police Post".** Barbed wire, sandbags, a tricolour-free colonial post (no real flag). `rifleman`
  saboteurs stop 2.5 s before entering a defender's range and **disable** the nearest defender for 2.5 s
  (cooldown 8 s per enemy, one defender at a time, bosses immune to nothing). The Commandant **summons** 4
  gendarmes every 12 s. Hakawati: the sergeant's cell; the corporal's stolen rifle.
- **Ep 8 "The Two Lanes".** Two spawn gates (`Arenas.spawns = { {x,z}, {x,z} }`, two polylines that merge at
  the mid-point); the Play panel shows both. `cart` splitters release 4 thugs when killed; the rival `hakim`
  heals enemies in 8 studs by 2 % per second. Al-Adashari (boss form) appears on wave 40, reaches the gate…
  and **turns**: a scripted moment where he becomes an ally tower for waves 41–55 (the first time players see
  his guard form). Hakawati: the cheek cut; the hand cut; "he came back a hero".
- **Ep 9 "The Confession".** Same twin-gate arena, dusk turning to night by wave 30 (client lighting). The
  ally Al-Adashari stands at the gate from wave 1 at level 3 (unsellable, no upgrades, shown with a gold
  "ally" ring); if the gate falls he "falls" first (he absorbs the first 20 gate damage of the match). Snake
  swarms (`snake`: tiny, stealth, 2 gate damage, 12/s) from wave 20. Final wave: Abu al-Nahr and the Commandant
  walk together with their escorts. Winning any difficulty rolls the **secret unit drop** (§7.6). Hakawati:
  the grave, the snake, the confession, the forgiveness.

### 5.3 The difficulty ladder (TUNE targets; asserted in `tests/td.spec.luau` "Balance" via `tests/balance`)

Today's curve: ep1 Normal = 4 upgraded Rare/Epic; ep2 Normal = 6–10 upgraded Rare/Epic; ep3 Normal = a
Legendary; Hard adds a tier; Nightmare needs Mythics (TOWER_DEFENSE §5). The new episodes continue the ladder
by one tier each and are what the new power axes (§7) are for. New harness loadouts: **leg10up+sig** (leg10up
with level-7 signatures), **myth12up+beads** (beads at 2 of 3 slots), **whale2** (whale + traits v2 + beads).

| Episode | Waves | `hpPerWave` | Normal is won by | Hard | Nightmare |
|---|---|---|---|---|---|
| ep1 | 20 | 0.07 | re4up | re10up / leg10up | myth12up |
| ep2 | 30 | 0.075 | re6up | leg10up | myth12up (coin flip) → whale |
| ep3 | 40 | 0.075 | leg10up | myth12up | whale |
| **ep4** | 40 | 0.085 | leg10up (needs a stealth-free swarm answer: splash) | leg10up+sig | myth12up+beads |
| **ep5** | 45 | 0.085 | leg10up+sig (needs a douser) | myth12up | myth12up+beads |
| **ep6** | 50 | 0.09 | leg10up+sig (needs 2 revealers) | myth12up+beads | whale2 |
| **ep7** | 50 | 0.095 | myth12up | myth12up+beads | whale2 |
| **ep8** | 55 | 0.10 | myth12up+beads | whale2 | whale2 at ≤ 10/35 gate (a coin flip by design) |
| **ep9** | 60 | 0.10 (+ ally) | myth12up+beads | whale2 | whale2 + the ally (the only cell where the ally decides it) |

Rules for tuning: every cell one tier harder than the one above it; **no episode is won by the tier below
its Normal target on Normal** (asserted); bosses stay gate-breakers (gate damage 40/60/80/100/120 for the new
tier); the opening waves of every difficulty are playable with 600 cash (Nightmare keeps `hp = 1.0`). Record the
whole `lune run tests/balance --md` table in `TOWER_DEFENSE.md` §5 and the TUNE line in DECISIONS.

### 5.4 Rewards and unlocks (`TD.STORY_REWARDS`, `Config/Modes`)

| Episode | lira / qirsh / xp (Normal, × difficulty.reward, × 2 first clear) | Extra |
|---|---|---|
| ep4 | 300 / 300 / 320 | first Normal clear: 1 trait stone |
| ep5 | 360 / 340 / 380 | first Hard clear: 1 bead (§7.4) |
| ep6 | 420 / 380 / 440 | first Normal clear: the **Umm Baki** unit (a story gift, Rare) |
| ep7 | 480 / 420 / 500 | first Hard clear: 2 beads |
| ep8 | 560 / 480 / 580 | first Nightmare clear: a "Two Lanes" cosmetic (laffeh, qirsh item) |
| ep9 | 650 / 540 / 680 | **secret unit roll** on every win (§7.6); first Nightmare clear guarantees him |

Endless stays as is. The Lane Diary is untouched; Season 2's pass is a later task.

---

## 6. Enemies: the new roster (Meshy, no block figures)

Baseline is Normal, wave 1, solo (compare TOWER_DEFENSE §5 table: gendarme 40 HP / 5.5 / 14 cash / 1 gate).
Every number is a starting point for the harness; names are the §3 spellings. New sim flags are in §10.1.
Meshy prompts get `style` + the entry + `enemy_texture_style` prepended automatically (D-018); heights are
chibi metres as in `characters.json`. ≈ 47 credits per character to a rigged mesh with the free walk, +9 for
hit/death clips (D-023 pattern).

### 6.1 Regular attackers

| Id | Name (EN / AR) | HP | Speed | Armor | Reward | Gate | Flags | From ep | Prompt (height) |
|---|---|---|---|---|---|---|---|---|---|
| `pickpocket` | Pickpocket / نشّال | 16 | 9.5 | – | 6 | 1 | `swarm` (counts ½ toward the 90/wave cap; groups of 12) | 4 | Street pickpocket boy of 1930s Damascus, wiry teenager with a smirk, flat cap, patched grey shirt, short baggy trousers, barefoot, clutching a stolen purse, mid-sprint (1.45) |
| `drummer` | Rival-lane Drummer / طبّال الحارة التانية | 110 | 5.0 | – | 28 | 1 | `aura = { speed = 1.25, radius = 7 }` | 4 | Rival-lane drummer, stocky man with a sneer, olive turban-wrapped tarboosh, dark striped qumbaz, a large frame drum slung on the chest, beating it with a curved stick (1.75) |
| `torchbearer` | Torchbearer / مشعلجي | 70 | 6.2 | – | 20 | 1 | `burn = 1` (adds a stack at the gate) | 5 | Night arsonist of 1930s Damascus, lean man with a scarf over the mouth, dark sherwal and vest, holding a burning rag torch high in the right hand and an oil jar in the left (1.75) |
| `porter` | Porter with a Crate / عتّال | 260 | 3.6 | 0.25 | 45 | 2 | `shield = { radius = 6, reduce = 0.3 }` (enemies in range take 30 % less; not stacking) | 5 | Burly 1930s porter (attal) of a Damascus market, thick neck and arms, rolled head scarf as a pad, sleeveless vest, wide belt, carrying a huge wooden crate on his back, bent forward (1.85) |
| `disguised` | A "Neighbour" / واحد من الحارة | 120 | 5.4 | – | 32 | 2 | `disguised` (untargetable and splash-immune until revealed by a lantern or a single-target hit) | 6 | Shifty man dressed as an ordinary 1930s Damascus neighbour, plain beige qumbaz and red tarboosh, hands hidden in the sleeves, eyes darting sideways, a dagger hilt showing at the belt (1.75) |
| `beggar` | False Beggar / شحاد كذّاب | 90 | 6.0 | – | 26 | 1 | `disguised`, `stealth` after reveal | 6 | 1930s street beggar with a dark blindfold pushed up on the forehead, patched grey cloak, bare feet, a wooden staff in one hand and a begging bowl in the other, sly posture (1.7) |
| `rifleman` | Tirailleur / بندقجي | 150 | 5.0 | 0.2 | 38 | 2 | `sabotage = { range = 10, duration = 2.5, cooldown = 8 }` (disables the nearest defender) | 7 | Colonial-era colonial infantry rifleman of the 1930s, lean soldier with a tall red felt cap with a tassel, khaki tunic with a leather belt, puttees, holding a long rifle across the chest, stern face (1.8) |
| `cart` | Donkey Cart / عربية حمار | 420 | 3.4 | 0.3 | 60 | 3 | `split = { enemy = "thug", count = 4 }` on death | 8 | Small wooden two-wheeled cart pulled by a grey donkey, piled with sacks and four hidden figures peeking out, 1930s Levantine style, stylized chibi proportions, no driver (2.0 long) |
| `hakim_rival` | Rival-lane Hakim / حكيم الحارة التانية | 200 | 4.6 | – | 50 | 1 | `healAura = { radius = 8, pct = 0.02 }` | 8 | Rival-lane healer of 1930s Damascus, thin old man with a grey goatee, green turban, long dark robe, a leather satchel of bottles over the shoulder, holding a glass vial up (1.7) |
| `snake` | Grave Snake / حية القبر | 20 | 12.0 | – | 4 | 2 | `stealth`, `swarm`, `small` (half-height health bar) | 9 | Stylized cartoon viper, sand-and-black diamond pattern, raised head, forked tongue, coiled S-shape ready to strike, no base (0.5) |
| `brute` | Rival-lane Brute / زكرت الحارة التانية | 380 | 4.2 | 0.2 | 65 | 3 | `enrage = { belowHp = 0.5, speed = 1.6 }` | 8 | Hulking rival-lane fighter, shaved head with a scar, dark laffeh around the neck, sleeveless striped vest, wide red belt, iron knuckles, fists raised, drunken swagger (1.95) |

### 6.2 Bosses

| Id | Name (EN / AR) | HP | Speed | Armor | Reward | Gate | Flags | Prompt (height) |
|---|---|---|---|---|---|---|---|---|
| `corporal` | Corporal Houri / العريف حوري | 900 | 4.4 | 0.2 | 240 | 40 | `boss` | Jumpy young colonial-gendarmerie corporal of the 1930s, thin moustache, kepi askew, dark blue uniform one size too big, holding a rifle he clearly cannot handle, wide anxious eyes, comic (1.8) |
| `abu_jawdan` | Sergeant Abu Jawdan / الرقيب أبو جودان | 2,400 | 3.8 | 0.3 | 520 | 80 | `boss`, `summon = { enemy = "corporal_minion", count = 2, every = 15 }` | Corrupt 1930s police sergeant over four lanes, portly man with a big curled moustache and heavy brows, red-banded kepi, dark blue jacket straining at brass buttons, baton tucked under the arm, smug half-smile (1.95) |
| `abu_shatour` | Abu Shatour / أبو شاطور | 3,000 | 4.6 | 0.2 | 600 | 80 | `boss`, `burn = 3` | Rival-lane thug boss of 1930s Damascus, broad man with a cleaver (a wide butcher's blade) in the right hand and a torch in the left, black laffeh wrapped tight, dark striped vest, chest hair, scar across the nose, snarling (2.0) |
| `lateef` | Lateef the "Blind" / لطيف "الأعمى" | 3,600 | 4.4 | – | 700 | 90 | `boss`, `disguised`, `teleport = { atHp = 0.5, fraction = 0.2, telegraph = 2 }` | 1930s false blind beggar revealed as a spy, gaunt man ripping a dark blindfold off with one hand, dagger in the other, patched grey cloak flying, bare feet, cruel grin (1.85) |
| `fakhr` | Fakhr Abu al-Hokm / فخر أبو الحكم | 4,200 | 4.8 | 0.25 | 800 | 90 | `boss`, `enrage` | One-handed rival-lane bruiser of 1930s Damascus, massive shoulders, a bandaged stump for the left hand, a spiked club in the right, dark hatta, open black vest, red sash, roaring (2.05) |
| `abu_zira` | Abu Zira' / أبو زراع | 5,000 | 5.2 | 0.2 | 950 | 100 | `boss`, `enrage = { belowHp = 0.6, speed = 1.7 }` | Drunken rival-lane fighter of 1930s Damascus, lanky man with a long drooping moustache, tarboosh fallen backwards, unbuttoned striped shirt, a broken bottle in one hand and a shabriyeh in the other, reeling stance (1.95) |
| `rival_zaim_enraged` | Al-'Akeed Abu al-Nahr, enraged / العكيد أبو النهر | 9,000 | 5.0 | 0.3 | 1,600 | 120 | `boss`, `shield = { radius = 8, reduce = 0.3 }`, `enrage` | Re-use the `AbuNar` model with a red `Highlight`, a torn sleeve and a 1.75 scale (no new mesh) |
| (existing) `chief_thief` → id kept, display "Al-Adashari, the thief" | | 1,200 | 4.6 | – | 320 | 60 | | model `Idaashari` kept |

`corporal_minion` is a copy of `gendarme` with the corporal's colours (no new mesh). Boss intros (PV-A04 /
PV-B06) get one Hakawati line each (`story.boss.<id>`).

### 6.3 Pipeline and budget

PV-A01/A02/A03 pattern exactly: add entries to `tools/meshy/characters.json → characters` with
`"texture_style": "enemy"`, `make <id> --until concept` for a batch, build a contact sheet
(`tools/meshy/contact_sheet.py`) to `docs/art/story_enemy_concepts_<date>.png`, **STOP** for the owner's
approval, then `make <id>` to the end, `islands.py` check (drop fused props; HandProps gets the torch, drum
stick, cleaver, staff, rifle), preview with Blender headless, batch the GLBs into one import request, `.rbxm`
into `assets/production/CharacterModels/`, `CharacterLooks[id].model`, clips through `tools/anim/clips.json`
(walk + hit + death; bosses + intro/stagger), `fetch.py`, `bake.py`. Register rows C-211… per character.

Budget: 11 regular + 6 bosses, of which one is a re-skin = 16 characters × ≈ 56 ≈ **900 credits**, plus the
secret unit and 5 new defenders (§7.5) ≈ 340 = **≈ 1,240** against ≈ 1,150 on the account after PV-A. §12.0
phases it: Episodes 4–6 first (≈ 560), then 7–9 (≈ 500), then the new defenders. **STOP** at each phase
boundary with the running total.

---

## 7. Units: upgrades, traits, beads, new defenders, the secret unit

D-008 says new power axes declare a cap before shipping. Here they are. The whole point is that Episodes 7–9
need them (§5.3) while Episodes 1–3 stay exactly as tuned today (every axis is additive on top of today's
numbers; `tests/td.spec.luau` keeps the ep1–ep3 tables within a few gate HP).

### 7.1 Level 7: the signature upgrade (Epic and above)

Every Epic/Legendary/Mythic/Secret unit gets a 7th level, bought only at level 6 and only once, that asks the
player to **choose one of two paths** (`Units[id].signature = { a = {...}, b = {...} }`, each a `Level` delta plus
an optional ability tweak; the choice is per placed tower, so the same unit can be built both ways in one match).
Cost ≈ 1.5 × the level-6 cost. Cap: a signature adds at most **+35 % damage or one new effect**, never both.

| Unit | Path A | Path B |
|---|---|---|
| Mo'ez (`qabaday`) | **Rage**: shabriyeh cooldown 12 → 8 s | **Guard**: hits stun 0.3 s |
| Abu Shater (`haddad`) | **Anvil**: stun 1.0 → 1.4 s | **Forge**: splash radius 7 → 9 |
| Abu Bader (`mukhtar`) | **Loud**: buff 1.65 → 1.8 | **Brave**: he also attacks (6 dmg, 1.2 s) |
| Za'im Abu Faleh (`zaim`) | **Judgment**: shabriyeh ×10 → ×14 | **Mercy**: shabriyeh also slows 50 % for 3 s |
| The Strongman (`pahlawan`) | **Iron**: sweep radius 9 → 12 | **Pin**: sweep stuns 1.5 s |
| Abu Hissam (`umm_hara`) | **Hakim**: heal 32 → 44 | **Elder**: buff 1.45 → 1.6 |
| The 'Arada (`arada`) | **Drums**: cooldown −20 % | **Swords**: hits reveal disguised and stealth for allies in range |
| Abu Shehan (`zaim_akbar`) | **'Akeed**: shabriyeh ×15 → ×20 | **Rally**: defenders within 10 studs gain +10 % cooldown speed |
| Al-Adashari (`adashari`) | **Repentance**: ability marks 2 enemies | **Guard of the Warehouse**: douses 2 burn stacks per hit |

Sim: `TdTowers.upgrade` accepts `path` at level 7 (validated: enum `a|b`, level == 6, cash); `UnitLogic.stats`
merges the delta. Spec: both paths of every signature unit, rejection of a second choice, cost.

### 7.2 Traits v2 (12 traits, two slots)

Today: 8 traits, one per owned unit, rerolled with stones. Additions (`Config/Traits`, weights sum shown in the
Rates panel as always):

| Id | Name (EN / AR) | Effect | Weight | Tier |
|---|---|---|---|---|
| `lantern` | Lantern / فانوس | the unit reveals stealth to itself (`hitsStealth`) | 6 | 2 |
| `miser` | Miser / بخيل | placement and upgrades cost −10 % | 5 | 3 |
| `twin` | Twins / توأم | `maxPlaced` +1 | 3 | 3 |
| `fireproof` | Fireproof / ما بيحرق | hits douse one burn stack | 6 | 2 |

Weights re-normalise; the existing 8 keep their relative odds (`steady` 30 … `legend` 0.5 → the new four take
20 of the total so `legend` stays at ≈ 0.4 %). **Second trait slot** opens at **3 stars** (7 extra copies), rolled
with a stone; two traits never stack the same stat (the better one wins). Cap: the product of every damage
multiplier from traits ≤ **1.5×** (legend alone is 1.5), range ≤ 1.25×, cooldown ≥ 0.85×; `UnitLogic.stats`
clamps and a spec proves the clamp.

### 7.3 Stars

Unchanged (+5 % per star, 5 stars). The 3-star threshold is now also the second trait slot.

### 7.4 Shabriyeh beads (خرزات الشبرية): per-unit passives from the story

A new, non-random progression item: **beads**, earned from first clears (§5.4), the Diary premium track from
Season 2, and Episode 7–9 Hard/Nightmare wins (1 per win, capped at 3 per day per `Config/Economy`). Each unit
has **3 bead slots** (`profile.units[id].beads = { slot1, slot2, slot3 }`), each slot taking one of three fixed
bead kinds per unit (`Units[id].beads = { "range", "cooldown", "cash" }`-style keys into `Config/Beads`); a bead
adds a flat small bonus (range +1 stud, cooldown −4 %, kill cash +8 %, heal +2, buff +0.03). Cap: three beads
never exceed **+12 %** on any one stat; beads are not tradeable and are lost with the unit if trading ever ships.
Server-only mutation through `DataService.mutate`; `UnitsController` shows them as three beads on the dagger
sheath of the card frame (icon PV-C05 style).

### 7.5 New defenders (5 + the secret unit; Meshy, §4.1 signatures)

| Id | Name (EN / AR) | Rarity | Role | Signature | Numbers (level 1 → max) | Model prompt (height) |
|---|---|---|---|---|---|---|
| `qabilah` | Umm Baki the Midwife / أم باقي الداية | Rare (story gift, also banner) | ranged | **reveals disguised and stealth** in range (second revealer after Abu Hares), no slow | 160 cash; 3 → 15 dmg; range 11 → 15; cd 1.2 → 1.0 | Elderly 1930s Damascus midwife, round and brisk, white headscarf, dark house dress, striped apron, a cloth bundle under one arm and a small oil lamp held out, knowing look (1.6) |
| `hammam` | Abu Basim of the Hammam / أبو باسم صاحب الحمّام | Epic | support | **steam aura**: enemies in range slowed 20 % and **douse** 1 burn stack per 3 s | 480 cash; range 11 → 16; slow 0.8 → 0.65 | Stout 1930s bathhouse owner, towel over the shoulder, white undershirt, red-striped waist wrap (izar), wooden clogs (qabqab), a copper water bowl steaming in both hands, cheerful squint (1.8) |
| `hummus` | Abu Samih the Hummus Seller / أبو سميح بيّاع الحمّص | Rare | farm | pays per **kill** in range (6 → 24 cash) instead of per wave | 320 cash; 4 → 14 dmg; range 9 → 11 | 1930s Damascus street seller of hummus and fava, thin cheerful man, white skullcap, grey qumbaz with a canvas money apron, a brass pot on a tripod and a ladle, offering a bowl (1.7) |
| `iskafi` | Abu Hamoud the Cobbler / أبو حمود الإسكافي | Rare | splash | **nails**: ground patch slows 40 % for 2 s (a trap-like splash) | 240 cash; 4 → 20 dmg; splash 3 → 4.5 | Old 1930s cobbler, small and bent, grey beard, round black cap, leather apron full of nails, a hammer in one hand and a slipper on a last in the other (1.6) |
| `matriarch` | Su'da Khanum / سعدى خانم | Mythic | splash | **The Cry** (ability `sweep` radius 11, ×4 damage, **stuns 1.2 s**, cooldown 11 s); hits stealth | 1,300 cash; 60 → 480 dmg; splash 6 → 9 | Formidable 1930s Damascus matriarch, tall and straight-backed, embroidered dark indoor dress, gold-edged headscarf, heavy necklace, one hand on the hip and the other pointing accusingly, fierce dignified face (1.8) |
| `adashari` | **Al-Adashari, the Night Guard / العدشري حارس الليل** | **Secret** | melee | §7.6 | §7.6 | §7.6 |

`Config/Banners`: Umm Baki and Abu Hamoud join the Rare pool, Abu Basim the Epic pool, Su'da Khanum the Mythic
featured rotation for the update month. The odds table and pity are unchanged (`TD.ODDS`); the Rates screen
regenerates itself from config.

### 7.6 The secret unit: Al-Adashari (replaces the Cat)

- **Identity.** The thief of Episodes 1–3, the ally of 8–9, now a defender: one-armed (left sleeve pinned, a
  bandage), lantern in the right hand, knife in the belt, dark laffeh low over the brow, grey-brown striped qumbaz,
  wide black belt, guarded stance. Meshy prompt (height 1.8): *"Gaunt wiry 1930s Damascus night guard with a
  haunted but kind expression, stubble and hollow cheeks, dark head cloth wrapped low, grey-brown striped qumbaz,
  wide black belt with a short dagger, left arm missing with the sleeve pinned up and a white bandage at the
  shoulder, holding a lit oil lantern forward in the right hand, standing guard"*. Texture style: the cast style
  (warm), not the enemy one: he is ours now. Clips: idle "Guard Idle"-type, attack a lantern swing + knife jab,
  ability a slow kneel-and-rise (the oath). Register row.
- **Role.** melee, `hitsStealth`, `revealsStealth` with a 6-stud lantern (smaller than Abu Hares's), `maxPlaced 1`,
  `noBanner`. Levels (cost; damage; range; cooldown): 900; 60; 8; 0.6 → 600; 90; 8.5; 0.58 → 1,000; 135; 9; 0.55 →
  1,600; 200; 9.5; 0.5 → 2,400; 300; 10; 0.46 → 3,600; 450; 11; 0.42. Between Legendary and Mythic single-target,
  which is where a secret belongs (the Cat's 960-damage joke curve goes).
- **Ability "The Oath" (اليمين)**, new kind `mark`: every 10 s marks the strongest enemy in range for 4 s; marked
  enemies take **+40 %** damage from every defender (not stacking). Cap: one mark per Adashari, +40 % max.
- **How players get him (STOP: owner confirms).** Not from any banner or code. Every **Episode 9 win** rolls a
  drop: 2 % Normal, 5 % Hard, 12 % Nightmare, with a **pity of 25 wins** (counter in `profile.td.secretPity`),
  and the **first Nightmare clear guarantees** him. Copies beyond the first are the only way to star him (so a
  3-star Adashari is a real achievement). The odds are printed on the Episode 9 card. All server-side in
  `MatchRewards` with a spec (odds sum, pity bound, idempotent grant in the same `mutate` as the match reward).
- **In the lobby.** His pickle cart stands by the gate from the update on (`PropPlacements.lobby`, a Meshy prop
  or Blender kit module); after the player clears Episode 9 he stands behind it as an NPC with three lines.

### 7.7 Retiring the Cat (migration)

`qitt` leaves `Config/Units`, `CharacterLooks`, `Banners` (it was `noBanner`), the `QITT` code (set `expiresAt`
to the deploy time first, then remove it a release later), `tools/meshy/characters.json` (entry kept, marked
retired), and `tests/meta.spec.luau` (the code test moves to a code that grants a Rare). **Profile migration**
(`ProfileSchema.MIGRATIONS[current]`, version +1, fixture test): every profile that owns `qitt` loses it and
gains **one copy of `adashari`** with the same trait (the owner's call: they were given a secret unit and keep
a secret unit) plus 100 lira; `qitt` is removed from loadouts. The `Cat.rbxm` model stays: it is already the
coffee-house cat (`World/Props.luau`) and PV-E02 makes it look at players. Strings `unit.qitt.*` go.

---

## 8. Maps: a modular kit from Blender, arenas laid out in Blender, built by code

### 8.1 Why Blender, and the rule it must respect

CLAUDE.md: nothing map-related is Studio-owned; the world is built at runtime from `server/World/*` and config.
So Blender is used for two things only: **(a)** to model the **kit** (reusable modules, exported as GLB, imported
to `.rbxm` under `assets/production/PropModels`, exactly like today's six props) and **(b)** to **lay out** each
arena with those modules and export the layout as **config** (`src/shared/Config/ArenaLayouts/<arena>.luau`,
generated, in `.styluaignore` like `Anim/Clips`). `World/Arena.luau` then places the kit from the layout the way
`PropDressing` places props today, and falls back to the primitive dressing when a module is missing. The
road polyline and the bounds also come out of Blender (a curve object per path) into `Config/Arenas`.

### 8.2 The kit (`assets/blender/hara_kit.blend`, built by `tools/blender/kit_build.py` and hand-finished)

Budgets per module: ≤ 2,000 tris (bosses of the kit, the gate and the warehouse, ≤ 6,000 and split into ≤ 20k
MeshParts by the importer), one 1024² hand-painted palette atlas shared by the whole kit (`kit_atlas.png`,
uploaded once through `tools/upload_asset.py` or the importer), vertex-colour fallback so a missing texture
still reads. Unit: 1 Blender unit = 1 stud; origin at the module's ground centre; +Y up, front −Z (the
`PropPlacements` convention). Export: `glTF 2.0`, `export_apply = True`, `export_yup = True`, one GLB per module,
names `kit_<module>.glb`.

| Group | Modules | Notes |
|---|---|---|
| Lane walls | `wall_2m`, `wall_4m`, `wall_corner`, `wall_arch` (ablaq voussoirs), `wall_window_grille`, `mashrabiya_bay` | tileable; black-and-white ablaq course |
| Gates | `gate_lane` (double leaves, wicket, knockers, bar hooks: the existing `gate.rbxm` is replaced only if the new one is better), `gate_rival` (cooler palette), `warehouse_door` (wide, sacks beside it) | the match "gate" prop at the path end |
| Street | `cobble_tile_4m`, `kerb_4m`, `gutter_4m`, `step_set`, `fountain_octagon` (exists), `well`, `bench_dikkeh`, `lantern_wall`, `lantern_wire_span` | the road is still a Config polyline; tiles are dressing |
| Orchard | `olive_tree_a/b/c`, `orchard_wall_low`, `terrace_step`, `irrigation_channel_4m`, `olive_press` (stone mill, beam, basin), `sack_pile`, `oil_jar_cluster`, `harvest_net`, `ladder` | the Olive Harvest event map (§8.4) |
| Quarter | `coffee_house_front` (exists), `barber_front` (exists), `bakery_front`, `warehouse_block` (the bawaykiyeh), `police_post` (sandbags, barbed wire, sentry box, no real flag), `rooftop_stair`, `skyline_dome`, `skyline_minaret` (far, no collision) | |
| Ground | `grass_patch`, `dust_patch`, `rubble` | |

Building it: `kit_build.py` generates the tileable modules procedurally with `bpy` (boxes, bevels, booleans for
arches, arrays for ablaq courses, a simple UV layout onto the atlas), so the kit is reproducible from the repo;
organic ones (olive trees, sacks, jars) are sculpted by hand in the live Blender through the MCP and saved in
the .blend. Preview every module with `render_thumbnail_to_path` before export; `tools/anim/islands.py list`
on each GLB to check tri counts. The `.blend` and the GLBs are committed (binary, small); the atlas is a PNG.

### 8.3 Arena authoring in Blender (`tools/blender/export_layout.py`)

A scene per arena (`arenas/<id>.blend`, linked to the kit): kit modules placed as linked duplicates, a `Path`
curve (the enemy road), a `Bounds` plane, an empty `PlayerSpawn`, empties `Spawn_1..n` and `Gate`. The export
script walks the scene and writes:

- `Config/Arenas[<id>]` fields: `path` (curve points, resampled to ≤ 12 points), `bounds`, `gateYaw`,
  `spawnYaw`, `playerSpawn`, and for twin-gate arenas `paths = { {…}, {…} }` merging at a shared point (§10.1).
- `Config/ArenaLayouts/<id>.luau`: `{ { module, x, z, yaw, scale }, … }`, sorted, deterministic.
- A top-down PNG (`render_viewport_to_path`) to `docs/art/arena_<id>_layout_<date>.png` for the record.

`World/Arena.luau` gains `Arena.dress(model, origin, layout)` that places each module's `.rbxm` (scaled by the
layout's `scale`, `yaw`, solid where the module says so), keeps the road/kerb/fence builders, and skips modules
whose model is missing (the primitive gardens then fill in, as today). Part budget per arena ≤ 1,200 parts and
≤ 150 unique meshes in a server (ART_BIBLE §9); measure with `[World] built`.

### 8.4 The event map: "The Olive Press" (المعصرة) for Olive Harvest Nights

The running event (`Events.olive_harvest`, 2026-10-16 → 11-30, mode `ev_olive`, 15 waves on `orchard`) gets its
own arena `olive_press`. Story tie: the harvest is stored in the 'akeed's warehouse; bandits and riders come
for it; the night guard's lantern hangs at the press. Layout (local studs, ground Y = 0; drawn in Blender,
exported as above):

```
   spawn (rival gate)                             olive terraces (west)
   (-70, 30) ──► road along the irrigation channel ──► (-30, 30)
                                                      │
                 olive press (mill, beam, basin)  ◄── (-30, -10)  bend
                 sack piles / oil jars on the kerb        │
                 (12, -10) ──► (12, 24) ──► (48, 24) ──► (48, -20) = warehouse door (the "gate")
   party spawn (30, -32) on the terrace behind the door; lantern wire spans at the three bends
   bounds x -80..80, z -40..36; the press sits inside the first loop so towers ring it
```

Modules used: `orchard_wall_low` ×14, `olive_tree_*` ×22, `terrace_step` ×8, `irrigation_channel_4m` ×12,
`olive_press` ×1, `sack_pile` ×6, `oil_jar_cluster` ×5, `harvest_net` ×3, `ladder` ×2, `lantern_wire_span` ×3,
`warehouse_door` ×1, `gate_rival` ×1 (spawn), `well` ×1. Night lighting as PV-E01's match night; the harvest
nets glow faintly gold under lanterns (client, Effects full). Event wave script stays; `Modes.ev_olive.arena =
"olive_press"`. The press becomes a **tower spot magnet** by design (two bends in range), which the harness
confirms gives a 15-wave event a comfortable Normal with re6up.

Future event maps reuse the kit: "Issam's Wedding Zaffeh" (the saha dressed with lanterns and banners, December),
"Ramadan Nights" (the lane at night, February 2027). Each is a layout file, not a new builder.

### 8.5 New story arenas (all from the kit; path and bounds authored in Blender)

| Arena id | Episodes | Shape | Signature modules |
|---|---|---|---|
| `saha` | 4, 6 | the lobby square rebuilt as an arena: spawn at a rooftop stair and a side alley merging before the fountain, gate = the lane mouth | `fountain_octagon`, `bench_dikkeh`, `coffee_house_front`, `mashrabiya_bay` ×6, `rooftop_stair`; ep6 adds fog |
| `warehouse` | 5 | orchard road ending at the warehouse yard; two tight bends under lantern wires | `warehouse_block`, `warehouse_door`, `sack_pile`, `oil_jar_cluster` |
| `post_road` | 7 | long straight with sandbag chicanes (the road narrows: `PATH_HALF_WIDTH` unchanged, dressing only) | `police_post`, sandbags, barbed wire, `lantern_wall` |
| `twin_gates` | 8, 9 | two spawn gates 40 studs apart; two polylines merge at the saha; one gate at the end | `gate_rival` ×2, `gate_lane`, `wall_*`, `skyline_*` |

Each arena: part count ≤ 1,200, overhead capture from the arena origin for the record, `PropPlacements.arenas`
entries for the lanterns, a `Config/Arenas` entry exported from Blender.

---

## 9. Events: the calendar after the olive harvest

| Event | Dates (UTC) | Mode / map | Currency | Shop highlights | Featured unit |
|---|---|---|---|---|---|
| Olive Harvest Nights (running) | 2026-10-16 → 11-30 | `ev_olive` on `olive_press` (§8.4) | olives | as today + **Al-Adashari's lantern** cosmetic (qirsh item) once Ep 9 ships | Abu Hares |
| Issam's Wedding Zaffeh / زفّة حسام | 2026-12-10 → 2027-01-05 | `ev_zaffeh` on `saha` dressed; 20 waves; the 'arada drums buff defenders in the last 5 waves (a positive aura: `allyAura`) | sweets | laffeh colours, a wedding banner for the home gate | The 'Arada |
| Ramadan Nights / ليالي رمضان | 2027-02-07 → 03-10 (owner confirms dates) | `ev_ramadan` on `lane_night` (kit layout); lanterns; dawn-to-dusk lighting cycle | lanterns | fanous cosmetics, a Diary XP boost | Abu Hazem |

All events: data only (`Config/Events`, `Config/Waves.events`, `Config/Modes`), no Robux, server-validated.

---

## 10. Systems work

### 10.1 Simulation (`Logic/TdSim`, `Logic/WaveLogic`, pure, specced)

| Feature | Where | Spec |
|---|---|---|
| `swarm` (counts ½ toward `MAX_PER_WAVE`; `MAX_PER_GROUP` 40 → 60 for swarm entries) | WaveLogic | cap holds; a 12-pickpocket group spawns whole |
| `aura = { speed, radius }` (drummer) and `healAura = { radius, pct }` (rival hakim) | TdSim.moveEnemies, a per-tick pass over enemies with auras (≤ 10 % of enemies have one; O(n·k)) | speed never exceeds `MAX_SPEED_MUL`; heal never exceeds max HP |
| `shield = { radius, reduce }` (porter, enraged 'akeed) | TdSim.hit: damage × (1 − reduce) if inside any shield; not stacking | one porter = 30 %, two porters = 30 % |
| `burn` stacks on the gate: `state.gateBurn = { stacks, until }`; 1 HP per 2 s per stack, max 5; `douse` on defenders removes a stack per hit (or per 3 s for Abu Basim) | TdSim.step | stacks cap; douse ordering; no burn after the wave ends |
| `disguised`: untargetable by all and splash-immune until revealed; reveal by a lantern (`revealsStealth` range) or by taking a single-target hit from a `hitsStealth` defender; stays revealed | TdSim.pickTarget / splashHits | a Lane Boy cannot target one; Abu Hares can; after reveal everyone can |
| `sabotage = { range, duration, cooldown }`: an enemy disables the nearest defender (`t.disabledUntil`); bosses' and ally towers immune | TdSim.towersAct | a disabled tower skips its cooldown; re-enables; the UI shows a grey ring |
| `split = { enemy, count }` on death | TdSim.hit → events `spawn` at the death position with the parent's path distance | children inherit `hpMul`; rewards once |
| `enrage = { belowHp, speed }` | TdSim.moveEnemies | speed capped |
| `teleport = { atHp, fraction, telegraph }` (boss) | TdSim.step emits `telegraph` then moves `dist += fraction × length` once | fires once; never past the gate |
| `summon = { enemy, count, every }` (boss) | TdSim.step | counts toward the wave; stops at the boss's death |
| Two paths: `Arenas[id].paths` (list) with a shared merge point; `enemy.pathIndex`; `EnemyPositions` carries the index; `Path` gets `merge` | Path, TdSim, replication | distance-to-road checks placement against every path; positions correct on both |
| Ally tower: `TdSim.addAlly(state, unitId, level, x, z)`: a tower with `owner = nil`, unsellable, un-upgradable, absorbs the first `allyShield` gate damage | TdSim, MatchService on episode start / scripted wave | cannot be sold or upgraded by any remote; `RemoteGuard` rejects |
| Ability kind `mark` (+40 % damage taken, 4 s, one per marker) | TdSim.hit / towersAct | not stacking; expires |
| Level 7 `signature` path; traits v2 clamp; beads | UnitLogic.stats, TdTowers.upgrade | caps (§7) proved by specs |

Performance gate: re-run the D-014 synthetic worst case (4 players, waves 60–62, 60 towers) with the new flags
on; `TdSim.step` stays ≤ 2 ms p95 (was 1.23 ms). If the aura pass pushes it over, auras tick at 5 Hz.

### 10.2 Server and remotes

- `UpgradeTower` gains an optional `path` (`"a" | "b"`), validated by `RemoteGuard.wrap` (enum, level == 6).
- New remote `SetBead(unitId, slot, beadKind)`: ownership, slot 1–3, kind ∈ `Units[id].beads`, cost (beads in
  `profile.beads`), rate-limited. No other new client→server remotes. Ally towers, marks, burns, disguises are
  server state replicated through `MatchEvents` (`towerDisabled`, `gateBurn`, `revealed`, `telegraph`, `ally`).
- `MatchRewards.compute` adds the secret drop (§7.6) and beads; the grant, the pity counter and the receipt of
  the match live in the same `DataService.mutate`.
- `ProfileSchema` migration (§7.7) + `profile.td.secretPity`, `profile.beads`, `units[id].beads`,
  `units[id].trait2`. `DATA_SCHEMA.md` updated.

### 10.3 Client

- **Play panel Story tab**: nine cards with PV-C06 banners, the Hakawati intro, the mechanics icons ("stealth",
  "burn", "disguised", "two paths": PV-C04 style icons), rewards, the secret-drop odds line on Episode 9,
  **Replay / Next** on the result screen (ANIME_VANGUARDS_STUDY §1).
- Match HUD: a burn meter on the gate bar, a grey ring and "disabled" label on a sabotaged defender, a question
  mark marker over disguised enemies (not targetable), the ally's gold ring and name, the second spawn marker,
  the telegraph line for Lateef, the level-7 path chooser (two cards, one tap, confirm).
- Lobby: the pickle cart and, after Episode 9, the Adashari NPC; the Hakawati's room gets the nine episode
  outros as "tales" (text only; AFK rules unchanged).
- Lighting: `saha` fog (ep6) and the ep9 dusk→night tween are client `Config/Lighting` presets keyed by arena.

### 10.4 Docs

`TOWER_DEFENSE.md` §4–§5 regenerated; `DATA_SCHEMA.md`; `DECISIONS.md` (naming D-0xx, caps D-0xx, Cat migration,
Blender-authored layouts, SEASON_1.md superseded if the owner agrees); `COPYRIGHT_REGISTER.md` (C-210 names;
C-211… assets; one row per arena layout and the kit); `WORLD_MAP.md` arenas table; `RELEASE_CHECKLIST.md`
gets the migration note (servers on the old schema kick new profiles as designed).

---

## 11. Rules for this pass

- Everything in `CLAUDE.md`: server-authoritative, validated remotes, odds from config, pure logic with Lune
  specs, numbers in Config, no MCP script writes, one task per commit, STOP list.
- **Episodes 1–3 do not get harder or easier.** Their balance rows are frozen in `tests/td.spec.luau`; any drift
  beyond a few gate HP is a bug.
- **Power caps are law** (§7): signature ≤ +35 % or one effect; traits damage ≤ 1.5×; beads ≤ +12 %; one mark.
  Each cap gets a DECISIONS row before the feature ships (D-008).
- **Style lock** (ART_BIBLE §5, POLISH_PLAN §2): chibi, dignity, no actor likeness, enemies cold-palette and
  hostile but never grotesque; the thief-turned-guard uses the warm cast palette.
- **Names only in Strings.** Ids never change; `Config/Strings` carries EN + AR; every new string gets both and
  the Arabic goes on `docs/review/ARABIC_STRINGS_REVIEW.md` for the native pass (BUILD_PLAN P3-10).
- **Cultural care** (DAMASCUS_LANE_LIFE §9): no mosque interior as an arena, no religious figure as a unit
  (the sheikh stays an NPC voice), no alcohol shown (Abu Zira' is "reeling", the bottle in his prompt becomes a
  jug), no smoking, snakes and fire are cartoon.
- **Phone first.** Every new HUD element is judged at 844×390; two paths and a burn meter must read at 30 px.
- **Budgets.** Meshy per §6.3 and §12.0 (STOP at each phase total); kit ≤ 2k tris per module; arenas ≤ 1,200
  parts; ≤ 150 unique meshes per server; `TdSim.step` ≤ 2 ms p95 in the D-014 case.
- **File ownership when sessions run in parallel.** N (names) = `Config/Strings`, register, docs; S (sim) =
  `Logic/TdSim`, `Logic/WaveLogic`, `Logic/Path`, `Logic/UnitLogic`, `Logic/TdTowers`, `Logic/MatchRewards`,
  `Config/TD`, `Config/Units`, `Config/Enemies`, `Config/Waves`, `Config/Traits`, `Config/Beads`,
  `Config/Modes`, `Config/Story`, `tests/*`; A (assets) = `tools/meshy/*`, `tools/anim/*`, `assets/*`,
  `Config/CharacterLooks`, `Config/Banners`; M (maps) = `tools/blender/*`, `assets/blender/*`,
  `Config/Arenas`, `Config/ArenaLayouts/*`, `Config/PropPlacements`, `server/World/*`, `Config/Lighting`;
  C (client) = `Controllers/*`, `UI/*`, `Config/Icons`, `Config/Vfx`. Two sessions never edit the same file;
  `ListAgents` and message first.

---

## 12. Workstreams and tasks

Each task: **Goal · Files · Accept · Deps · Budget**. IDs are `S1-<workstream><nn>`. The verify loop of CLAUDE.md
applies to every task; "harness" means `lune run tests/balance --md` with the table pasted into
`TOWER_DEFENSE.md` §5.

### 12.0 Order, phases, budget

| Phase | Tasks | Ships | Meshy |
|---|---|---|---|
| 1 Names and foundations | S1-N01 → S1-N02, S1-S01 → S1-S04, S1-M01 → S1-M03 | renamed roster, the kit, the Olive Press event map, the sim flags for ep4–6, traits v2 | kit 0 (Blender) |
| 2 Episodes 4–6 | S1-S05 → S1-S07, S1-A01 → S1-A03, S1-M04, S1-C01 → S1-C03 | three episodes, 7 enemies + 4 bosses, Umm Baki, Play panel story tab | ≈ 560 **STOP** at 600 |
| 3 Power and episodes 7–9 | S1-S08 → S1-S12, S1-A04 → S1-A06, S1-M05, S1-C04 → S1-C06 | level 7, beads, 4 enemies + 3 bosses, twin gates, the ally, the secret unit and Cat migration | ≈ 500 **STOP** at 1,150 total |
| 4 New defenders and events | S1-A07 → S1-A08, S1-S13, S1-M06 | 5 defenders, Su'da banner, the Zaffeh event | ≈ 340 **STOP**: needs a top-up |

Phase 1 can run as three parallel sessions (N, S, M). Phase 2's A tasks mostly wait on Meshy jobs and the
owner's import click: batch all GLBs of a phase into one request. Dependencies on POLISH_PLAN: PV-A02 (the six
block enemies) should land before S1-A01 so the importer request is one batch; PV-C04/C05/C06 icons and banners
are used by S1-C01 (fallback drawers if absent, as always).

### 12.1 Workstream N: names and story text

- **S1-N01 Rename the roster (one letter off).** Goal: apply §3 after the owner's approval. Files:
  `Config/Strings.luau` (EN + AR), comments in `Config/Units.luau` and `Config/CharacterLooks.luau`, `tools/meshy/
  characters.json` prompts (display names only; prompts never contained them), `docs/TOWER_DEFENSE.md` §4,
  `docs/COPYRIGHT_REGISTER.md` C-210 (the table, the rationale, the revert path), `docs/DECISIONS.md`.
  **Accept:** `tools/check.ps1` green; `lune run tests/run` green; `script_grep "Abu Hissam"` finds the synced
  string; a Studio capture of the Units screen in EN and AR showing the new names; no id or number changed
  (`git diff --stat` touches no `levels`). Deps: owner approval (STOP). Budget: 0.
- **S1-N02 Story text.** Goal: `Config/Story.luau` (pure: `episodes[id] = { intro = key, outro = key, boss = {
  [enemyId] = key } }`), 9 × (3 + 3) lines + 13 boss lines, EN + AR, in the Hakawati's voice; `tests/config.spec`
  asserts every key resolves in both languages; the Arabic listed in `docs/review/ARABIC_STRINGS_REVIEW.md`.
  **Accept:** spec green; the Play panel (S1-C01) shows the intro; register row for the episode texts.
  Deps: none. Budget: 0.

### 12.2 Workstream S: simulation, config, balance

- **S1-S01 Sim flags, batch 1.** `swarm`, `aura` (speed), `shield`, `burn` + `douse`, `disguised` + reveal rules
  (§10.1) in `TdSim`/`WaveLogic`; `Enemies` and `Units` type fields; specs for each (`tests/td.spec.luau` new
  describe blocks). **Accept:** specs green; ep1–ep3 harness rows unchanged; D-014 perf case re-run ≤ 2 ms p95
  (`execute_luau` in a Studio server, numbers in DECISIONS). Deps: none.
- **S1-S02 Traits v2.** Four traits, weights, the second slot at 3 stars, the clamp (§7.2); `UnitLogic.stats`,
  `rerollTrait(slot)`; `RerollTrait` remote gains `slot` (validated); Rates panel regenerates. **Accept:** odds
  sum spec; clamp spec; Studio capture of the Rates trait panel showing 12 traits; harness unchanged for ep1–3.
- **S1-S03 New enemies, batch 1 (config).** `pickpocket`, `drummer`, `torchbearer`, `porter`, `disguised`,
  `beggar`, bosses `corporal`, `abu_jawdan`, `abu_shatour`, `lateef` with §6 numbers, primitive `visual` +
  `CharacterLooks` fallbacks so matches run before the meshes exist. **Accept:** `tests/config.spec` (every
  nameKey resolves, every flag typed); a Studio match on a debug wave script spawns each one (primitive).
- **S1-S04 Episode 4–6 wave scripts and modes.** `Config/Waves.ep4..ep6`, `Config/Modes` (requires chain,
  portals replaced by the Play panel: `portal` kept for the debug teleport), `TD.STORY_REWARDS`, the Umm Baki
  story gift (`Config/Grants` or `MatchRewards.firstClearGifts`). **Accept:** harness table meets §5.3 for ep4–6
  on all difficulties (and ep1–3 unchanged); TUNE line in DECISIONS; `TOWER_DEFENSE.md` §5 regenerated.
  Deps: S1-S01, S1-S03, S1-M04 (the arenas; the harness uses the path).
- **S1-S05 Boss behaviours, batch 1.** `summon` (Abu Jawdan), `teleport` + `telegraph` (Lateef), `burn = 3`
  (Abu Shatour). **Accept:** specs; a Studio capture of Lateef's telegraph line and Abu Jawdan's corporals.
- **S1-S06 Sim flags, batch 2.** `sabotage` + `disabledUntil`, `split`, `enrage`, `healAura`, `mark` ability
  kind. **Accept:** specs; perf re-run.
- **S1-S07 Two paths and the ally.** `Arenas.paths`, `Path.merge`, `enemy.pathIndex` in replication, placement
  checks against every path, `TdSim.addAlly`, `allyShield`, scripted wave hook in `MatchService`
  (`Waves.ep8.script = { [40] = { kind = "ally_turn", unit = "adashari", level = 3 } }`, pure data). **Accept:**
  specs (merge geometry, placement rejection near either path, ally unsellable through the remote, shield
  absorbs exactly `allyShield`); a Studio capture with both spawns active and the ally ring.
- **S1-S08 New enemies, batch 2 (config).** `rifleman`, `cart`, `hakim_rival`, `snake`, `brute`, bosses `fakhr`,
  `abu_zira`, `rival_zaim_enraged`, `corporal_minion`. **Accept:** as S1-S03.
- **S1-S09 Episodes 7–9 wave scripts.** As S1-S04 for ep7–ep9, with the ep9 dusk flag and the final double
  boss. **Accept:** harness meets §5.3 rows for ep7–9 (the whale2 loadout exists in `tests/balance`); ep1–6
  unchanged. Deps: S1-S06, S1-S07, S1-S08, S1-M05.
- **S1-S10 Level 7 signatures.** `Units[id].signature`, `TdTowers.upgrade(path)`, `UnitLogic.stats` merge,
  the cap check in a spec, the `UpgradeTower` remote field. **Accept:** both paths per unit specced; DECISIONS
  cap row; harness `leg10up+sig` loadout rows.
- **S1-S11 Beads.** `Config/Beads`, `profile.beads`, `units[id].beads`, `SetBead` remote, `MatchRewards` bead
  drops with the daily cap, the cap clamp. **Accept:** specs (cap, daily cap, ownership, idempotent grant);
  DECISIONS cap row; harness `myth12up+beads`.
- **S1-S12 The secret unit and the Cat migration.** `Units.adashari` (§7.6), ability `mark`, the Episode 9
  drop in `MatchRewards` (odds, pity, Nightmare guarantee, same-mutation grant), `ProfileSchema` migration
  (§7.7) with a fixture spec, `Codes.QITT` expiry, `tests/meta.spec` update. **Accept:** odds/pity specs; the
  migration fixture (a v-current profile with `qitt` in the loadout → `adashari`, loadout clean, +100 lira);
  Studio: `HaretDebug:Invoke("grant", "adashari")` then a match with him placed and marking. STOP for the
  drop rule.
- **S1-S13 Season 2 pass and events data.** `Config/SeasonPass` s2 (beads on the premium track), `Events.zaffeh`,
  `Waves.events.zaffeh`, `allyAura` for the 'arada drums. **Accept:** specs; dates from the owner.

### 12.3 Workstream A: assets

- **S1-A01 Enemy concepts, batch 1 (≈ 60 credits).** 10 entries from §6 (batch 1 + bosses) in `characters.json`
  with `"texture_style": "enemy"`; concepts; one contact sheet `docs/art/story_enemy_concepts_<date>.png`;
  register rows Proposed. **Accept:** owner approves the sheet (STOP). Deps: S1-N01 (names in the sheet).
- **S1-A02 Enemy meshes, rigs, clips, batch 1 (≈ 500 credits).** `make` to the end; islands check; previews;
  **STOP** for the import of 10 GLBs; `.rbxm`; `CharacterLooks[id].model`; clips (walk, hit, death; bosses +
  intro, stagger) fetched and baked; HandProps for torch, drum stick, cleaver, staff. **Accept:** a Studio wave
  with every batch-1 enemy imported (no `Imported = nil` figure in `workspace.EnemyRender`); tri counts logged;
  register rows Approved by the owner.
- **S1-A03 Umm Baki (≈ 60 credits).** The story-gift Rare: concept, mesh, rig, idle + attack clips, lamp prop.
  **Accept:** card preview and placed figure captures.
- **S1-A04 Enemy concepts and meshes, batch 2 (≈ 440 credits).** As A01/A02 for §6 batch 2 + bosses
  (`rival_zaim_enraged` is a re-skin: `Highlight` + torn-sleeve decal, no mesh). **Accept:** as A02.
- **S1-A05 Al-Adashari, the Night Guard (≈ 70 credits).** §7.6 prompt (warm cast palette), one-armed rig check
  (Meshy's auto-rig expects two arms: model the pinned sleeve as geometry on the torso and leave the left arm
  bones unused; verify the idle has no left-arm motion, or edit the bake to zero those bones), lantern in
  HandProps, clips idle / attack / ability. **Accept:** owner approves the concept (STOP); Studio captures of
  the card, the placed figure and the ability; register row.
- **S1-A06 Signature re-rolls (≈ 120 credits, STOP before each).** Only the §4.2 "check" rows that fail the
  owner's eye on a side-by-side sheet: Abu Shehan's laffeh and belt, Mo'ez's handlebar, Abu Bader's hunch,
  Abu Ghadeb's chickpea pot. New version per character (`<id>_v2`), re-bake clips. **Accept:** the owner picks
  v1 or v2 per character on a contact sheet; `CharacterLooks` points at the winner.
- **S1-A07 New defenders (≈ 270 credits).** Abu Basim, Abu Samih, Abu Hamoud, Su'da Khanum: concept → mesh →
  rig → idle/attack/ability clips, HandProps (bowl, ladle, hammer, pointing hand). **Accept:** as A03.
- **S1-A08 Lobby props: the pickle cart and the Adashari NPC.** Either a Blender kit module (`pickle_cart`) or a
  Meshy prop (≈ 20 credits); `PropPlacements.lobby`; `Config/Npcs` entry gated on `profile.td.cleared.ep9`.
  **Accept:** lobby capture by the gate; the NPC appears only after the clear (toggle with `HaretDebug`).

### 12.4 Workstream M: maps

- **S1-M01 The kit, procedural half.** `tools/blender/kit_build.py` (headless: `blender -b --factory-startup -P`)
  builds the walls, gates, street, quarter and ground modules of §8.2 into `assets/blender/hara_kit.blend` with
  the atlas UVs; `tools/blender/export_kit.py` writes one GLB per module to `assets/unapproved/kit/`;
  `tools/anim/islands.py list` for tri counts; thumbnails to `docs/art/kit_sheet_<date>.png`. **Accept:** every
  module ≤ 2k tris (gate/warehouse ≤ 6k); the sheet; the script is re-runnable from a clean checkout.
- **S1-M02 The kit, organic half + atlas.** Olive trees, sacks, jars, nets, press, ladder modelled in the live
  Blender through the MCP (save first; `get_screenshot_of_area_as_image` before every export); the painted
  `kit_atlas.png` (1024², Higgsfield or hand-painted flats; ≤ 20 credits); vertex colours as fallback.
  **Accept:** sheet; atlas uploaded (STOP) or imported with the GLBs; register row C-2xx for the kit.
- **S1-M03 Import and the layout loader.** **STOP** for the importer (all kit GLBs in one request; Rig Type
  none); `.rbxm` to `assets/production/PropModels/kit_*`; `Config/ArenaLayouts/` folder + `Arena.dress`;
  `tools/blender/export_layout.py`; the Olive Press arena (§8.4) authored in `assets/blender/arenas/olive_press
  .blend`, exported, `Modes.ev_olive.arena = "olive_press"`. **Accept:** `[World] built` ≤ 1,200 parts for the
  arena; overhead capture; event match played to wave 15 with re6up by the harness and once in Studio; the
  layout file regenerates byte-identical from the .blend.
- **S1-M04 Arenas `saha` and `warehouse`.** Authored in Blender, exported, lanterns in `PropPlacements`, ep6 fog
  preset in `Config/Lighting`. **Accept:** captures; part counts; `Arenas` entries exported not hand-written.
- **S1-M05 Arenas `post_road` and `twin_gates`.** Including the two-path export and the merge point; the ep9
  dusk→night preset. **Accept:** both spawns visible in a capture; placement rejection near either path
  shown with the placement ghost.
- **S1-M06 Event layouts `saha_zaffeh` and `lane_night`.** Dressing-only layouts on existing arenas. **Accept:**
  captures; `Modes.ev_zaffeh.arena`.

### 12.5 Workstream C: client

- **S1-C01 Play panel Story tab.** Nine cards (PV-C06 banners when present), Hakawati intro, mechanic icons,
  rewards, lock states, difficulty pills, the secret odds line on Episode 9; Replay / Next on the result screen.
  **Accept:** phone-emulator capture (844×390) in EN and AR; no new remote beyond the existing queue ones.
- **S1-C02 Match HUD for batch-1 mechanics.** Burn meter on the gate bar, disguised "?" marker, reveal flash,
  drummer aura ring (subtle), porter shield ring, telegraph line, summon toast. All `Effects`-gated, under
  `Config/Vfx` caps with `tests/vfx.spec` rows. **Accept:** one composite capture per mechanic; `[Fx] live` ≤ 80.
- **S1-C03 Enemy render for new figures.** Snake and cart scale/health-bar rules (`small`), split spawn pop,
  enraged red tint, disabled-tower grey ring and label. **Accept:** captures.
- **S1-C04 Level-7 chooser and beads UI.** Two-card chooser on the tower panel at level 6; bead slots on the
  unit card (Units screen) with the `SetBead` flow; trait slot 2 at 3 stars in the Units → Traits panel.
  **Accept:** captures EN/AR; a wrong path or slot rejected server-side shows the existing error toast.
- **S1-C05 Twin gates and the ally.** Second spawn marker, both roads drawn, the ally's gold ring and
  nameplate, the "he turns" moment in ep8 (camera push à la PV-B06, Hakawati line, 1.5 s), ep9 dusk tween.
  **Accept:** captures of the turn and of night at wave 30.
- **S1-C06 Lobby story bits.** The pickle cart interaction (3 lines), the Hakawati's room tales list gains the
  episode outros (read-only), the Diary season name. **Accept:** captures.

---

## 13. Checklist (tick with the commit hash)

- [x] S1-N01 1eb2504 · [x] S1-N02 f86d874
- [x] S1-S01 4472de1 · [x] S1-S02 663db30 (+ 4eddbf7) · [x] S1-S03 2f1bc1e · [ ] S1-S04 · [x] S1-S05 74b5873 · [x] S1-S06 1352b05 · [ ] S1-S07 · [ ] S1-S08 · [ ] S1-S09 · [ ] S1-S10 · [ ] S1-S11 · [ ] S1-S12 · [ ] S1-S13
- [ ] S1-A01 · [ ] S1-A02 · [ ] S1-A03 · [ ] S1-A04 · [ ] S1-A05 · [ ] S1-A06 · [ ] S1-A07 · [ ] S1-A08
- [ ] S1-M01 · [ ] S1-M02 · [ ] S1-M03 · [ ] S1-M04 · [ ] S1-M05 · [ ] S1-M06
- [ ] S1-C01 · [ ] S1-C02 · [ ] S1-C03 · [ ] S1-C04 · [ ] S1-C05 · [ ] S1-C06

Definition of done for the whole update: a tester opens Play → Story and sees nine episodes with the Hakawati's
words; every attacker on every road is a painted character; Episode 4 is harder than 3 and 9 than 8 by the
harness table; a player who clears Episode 9 can earn Al-Adashari and place a one-armed night guard with a
lantern at the gate; the renamed roster reads as the lane's people and no string carries the old names; the
Olive Press event map is built from the Blender kit and the layout file; `tools/check.ps1` green; the register
complete; DECISIONS carries every cap and TUNE.

---

## 14. Open questions for the owner (answer once, in one message)

1. §3 names: approve, or edit any row (especially the Arabic).
2. §1 item 2: retire the roleplay mystery (`SEASON_1.md` Episodes 2–5)?
3. §7.6 secret drop rule: 2 / 5 / 12 % with pity 25 and a Nightmare guarantee, or a different shape?
4. Meshy top-up for Phase 4 (≈ 340 credits beyond the balance), or stop after Episode 9's assets?
5. Event dates for the Zaffeh and Ramadan events (§9).
6. Whether the Cat's current owners should receive Al-Adashari (the plan's default) or lira only.

## 15. Sources (research, 2026-10-18)

- AR Wikipedia, Part 1 page and the series character list (families, trades, fates in Part 1).
- TheTVDB, Part 1 episode summaries (ep. 9, 10, 17, 29, 31: the rival lane stirred, the engagement, the
  warehouse fire attempt and the amputation, Abu Dira'a leaves Abu al-Nar).
- Al Jazeera (2026-02-23), "the repentant villain": the pickle cart, the shoe, the false oath, the gangrene, the
  son's snake bite, the exile and return, the honest gold lira, the confession, the actor's refusal to return.
- Dramaar, "the full story of the series", Part 1 section; the fan blog "the whole tale" (2015), Part 1 section
  (the sharpening stone, the warehouse night-guard job, Abu al-Hokm's stabbing, the gold's division).
- Elcinema and TMDB cast lists for Part 1 (roles and actors, used only to map roles, never in prompts).
- Pocket Tactics / Destructoid / Deltia's Gaming for the Anime Vanguards renaming pattern (Noruto, Alocard,
  Song Jinwu, Sprintwagon; spellings vary by source).
- This repo: `docs/research/BAB_AL_HARA_REFERENCE.md`, `docs/research/ANIME_VANGUARDS_STUDY.md`,
  `docs/research/DAMASCUS_LANE_LIFE.md`, `docs/TOWER_DEFENSE.md` §5 balance tables, `docs/POLISH_PLAN.md`.
