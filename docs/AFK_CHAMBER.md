# AFK Chamber: the Hakawati's Room (مجلس الحكواتي)

*Status: built, unit-tested, play-tested in Studio (PC) · 2026-10-17*

Our AFK chamber is an upstairs room in Abu Hatem's coffee house. Abu Tawfiq the hakawati (storyteller)
tells the old coffee-house epics there all night. Players who sit with him earn a slow, steady trickle of
lira, qirsh and Diary XP. The genre's AFK room becomes the lane's own institution: in Damascus the
hakawati in the coffee house was the place people went to sit for hours.

Code: `Config/Afk`, `Logic/AfkLogic`, `Server/Services/AfkService`, `Server/World/AfkRoom`,
`Client/Controllers/AfkController`. Tests: `tests/afk.spec.luau`.

## 1. How Anime Vanguards does it (research, 2026-10-17)

Sources: wiki.vanguards.gg (Time_Chamber, Gems, Store, patch notes 3.0 / 12.5 / 13.5 / 14.0), Pocket
Tactics codes page (updated 2026-10-10), ItemLevel, Nerdschalk; Reddit and Fandom were unreachable.
**[C]** confirmed by a source, **[?]** sources disagree.

| Topic | Anime Vanguards "AFK Chamber" / "Time Chamber" |
|-------|--------------------------------------------------|
| Entry | A floating rocket next to Summons (press E), also in the Areas teleport menu [C]. Players idle in the lobby are sent there automatically [C] |
| Where | A separate place: "teleports you from the main game to an AFK screen". No units, no matches inside [C] |
| Pay | **20 gems every 4 minutes = 300 gems/h** [C]. In 2024 it was 10 per 2 min, the same hourly rate. Plus event currency on the same tick (300 per 4 min, ×2 in 2x events) [C] |
| Scale | About 15 % of an active hour (Infinite pays 1,700–2,100 gems/h) [C]. Players call it "free passive income", but weak if you watch it |
| Multipliers | VIP (299 R$) ×2; Roblox Premium ×1.5 [C]. Stacking unclear (the wiki shows both additive and multiplicative numbers) [?] |
| Cap | None reported; linear accrual [C] |
| Drops / streaks | None (gems and event currency only) [C] |
| UI | A countdown to the next tick, the running total, a "Currency Gained" popup per tick. They shipped bugs in exactly these popups (13.5, 14.0) [C] |
| Idle kick | "Auto-reconnects every 19 minutes to prevent being kicked for AFK" [C]. Disconnects still happen [?] |
| Others | Anime Defenders: AFK lobby gated at level 10, −50 % below it (anti-alt). Anime Last Stand: +2 emeralds/min (+3 VIP). Toilet TD: 1 coin/min. Anime Rangers X: 25 gems / 5 min, **capped** at 500 per session |

## 2. What we copied as a pattern, and what we changed

**Patterns kept:**
- A small fixed tick (5 min).
- About 12 % of an active hour's lira, close to their 15 %.
- VIP ×2 and Premium ×1.5.
- Idle lobby players walked up automatically.
- A server hop just before the 20-minute kick.
- A countdown, a running total and a toast per payout.

**Changed, and why:**

| Their way | Ours | Why |
|-----------|------|-----|
| A rocket / sci-fi AFK screen | An upstairs room in the coffee house with a storyteller; benches, stools, a painted 'ajami ceiling, lanterns | Our setting. The hakawati is real Damascene coffee-house culture (folk epics are public domain) |
| A separate place | A room built off-map in the same place (`ORIGIN` −3000, 0, 0), like our arenas | We have one place (no teleport place yet). Walking in and out takes a second, and the room is visible and social |
| Uncapped | **Daily lira cap** (240 at ×1, scaled by the bonus), then a small qirsh overflow | Their gem economy is inflated (codes give 50,000 gems). Ours is tight: an active free player earns 250–400 lira a day. Uncapped 80 lira/h overnight would outpace playing |
| Flat tick only | **Cups and tales:** a cup every 5 min, a tale (bonus) every 6 cups, 5 % trait-stone chance per tale, tale progress kept across visits | A reason to stay the full half hour, and flavour: the storyteller's lines change with the tale |
| Reconnect timer | Client watches `Player.Idled` and asks the server to hop after 15 idle minutes; the server teleports to the same place with `TeleportData { afk = true }`, and the player is seated again on arrival | The kick only comes after real idleness, so only idle players hop |
| Time lost on disconnect (2024 guides) | Sitting time toward the next cup is saved in the profile (`afk.carry`) | Nothing is ever lost: leaving at 4:59 keeps the 4:59 |

## 3. Rules (`Config/Afk`)

| Knob | Value |
|------|-------|
| Cup | every 300 s: 5 lira, 10 qirsh, 15 Diary XP |
| Tale | every 6 cups (30 min): +10 lira, 20 qirsh, 40 XP; 5 % chance of a trait stone |
| Base hour | 80 lira, 160 qirsh, 260 XP (≈ 12 % of an active hour's lira) |
| Daily cap | 240 lira × bonus per UTC day (3 h at ×1). After it: 3 qirsh × bonus per cup, no XP, no lira |
| Bonus | VIP +1, Roblox Premium +0.5 (additive: ×1, ×1.5, ×2, ×2.5); scales the pay **and** the cap |
| Session | ends after 12 h; time is flushed into the profile every 30 s, at every payout, on leaving, and before the final save |
| Anti-idle hop | after 15 idle minutes inside; at most once per 10 min per player; not in Studio |
| Auto-enter | after 5 idle minutes in the lobby (not in a party, a dialogue or a match), setting **Idle → hakawati**, on by default |

Tales, in order (`afk.tale.*`, three storyteller lines each in `afk.line.*`): Antar and Abla, Al-Zahir
Baybars, the Banu Hilal, Al-Zir Salem, Sayf ibn Dhi Yazan, and the lane's own "The Night the Gate Held".

## 4. Flow

1. **Getting in:** by one of three routes:
   - the **AFK** button (the 9th cell of the lobby grid, a tea-glass icon);
   - the stair mat by the back door of the coffee house (`AfkGate` tag);
   - asking Abu Hatem "Is the hakawati upstairs?".

   The first two open the intro panel, which shows:
   - the pay with the player's own bonus applied;
   - today's lira against the cap;
   - **Go upstairs**.
2. **Server side:** `AfkService.enter` checks the profile is loaded and the player is not in a match. It
   takes them out of any party, streams the room in (`RequestStreamAroundAsync`) and seats them on the
   first free seat (front stools first, 34 seats). If every seat is taken, they stand on the carpet.
3. **Inside:**
   - The lobby HUD is hidden. A top card shows the tale and part, a countdown bar to the next cup,
     today's lira (or "Today's lira are in"), this visit's time and the bonus.
   - **Back to the lane** sits at the bottom.
   - Abu Tawfiq's lines appear above his chair every 14 s.
   - Each cup and tale toasts its reward.
4. **Staying in:** jumping off the seat is fine (the room is closed). Dying or resetting respawns the
   player on their seat. Leaving the room's bounds any other way ends the visit (anti-exploit). Matches
   cannot be queued while inside (`MatchmakingService.blocked`).
5. **Leaving:** by the button, the door prompt (E) in the south wall, the 12-hour limit, or leaving the
   game. Leaving shows a summary toast ("You sat 42:10 with the hakawati: +40 lira · …") and walks the
   player out by the coffee-house back door.

## 5. Data

`profile.afk = { day, lira, carry, cups, tales, seconds }`:

- `day` / `lira`: the UTC day and the lira paid that day (the cap).
- `carry`: seconds toward the next cup.
- `cups` / `tales`: lifetime counts, which also set which tale is being told and its part.
- `seconds`: lifetime seconds sat.

Filled by `ProfileSchema.sanitize` through `AfkLogic.sanitize`, so no migration is needed. The snapshot
carries `afk = { carry, cups, tales, paidToday, cap, mult, inside }`.

Remotes:
- `AfkState` (S→C): `{ inside, reason, carry, mult, session }`, or `{ inside = false, reason, summary }`.
- `AfkPayout` (S→C): `{ kind, granted, capped, tale }`.
- `AfkEnter(reason)`, `AfkLeave`, `AfkHop` (C→S, rate-limited by RemoteGuard).

Analytics:
- Economy source `afk_cup` / `afk_tale`.
- Custom events `AfkEnter_<reason>`, `AfkMinutes`, `AfkHop`.

## 6. Testing

- `lune run tests/run`: 12 AFK specs cover cups, carry, tales, stones, the hourly rate, the cap and the
  new day, bonuses, input clamping, sanitising, the profile round trip, the setting and the strings.
- **Studio keys** (DebugKeysController): **N** enters or leaves the room; **Y** adds 30 minutes of
  sitting (one full tale).
- **Command bar:** `HaretDebug:Invoke("afk", "enter" | "leave" | seconds)`.
- The hop can't run in Studio (TeleportService); it shows a "(Studio)" toast instead. Test it on the
  published test place.

## 7. Open items

- **Studio play-test (PC, 2026-10-17): passed.** Checked: the AFK button and intro panel; seating on
  the front stool; the bottom card (tale and part, countdown, today's lira, visit clock, bonus); the
  camera aimed at the dais and the dimmed indoor light; Y (+30 min) paying 40 lira and the tale toast;
  the storyteller's lines; Back to the lane with the summary toast; the stair mat; Abu Hatem's "Take me
  up"; carry kept between visits; re-seating after a reset. Fixed during the test: the intro text
  overflowing, the card covering the toasts and the dais (moved to the bottom, Leave inside it), the
  camera keeping its lobby angle, glare indoors, and the sign hiding the speech bubble.
- **Still to check on a phone:** the bottom card at 390 px high next to the thumbstick, and the
  Arabic layout.
- **Live server test of the anti-idle hop:** whether `Player.Idled`'s time is total idle time or time
  since the 2-minute mark, the session-lock handover on arrival (DataService waits up to 5 × 6 s), and
  the teleport loading screen.
- **Native-speaker review of the new Arabic strings** (`afk.*`, `dlg.hakawati.*`,
  `dlg.qahwaji.hakawati*`).
- **Balance:** watch the `AfkMinutes` analytics and the share of lira from `afk_*` sources. If the room
  is more than ~20 % of daily lira for active players, lower the cap before the rate.
- **Alt accounts:** a level gate like Anime Defenders' is not built (we have no player level yet). The
  daily cap limits what an alt can farm.
- **Event currency** on the cup tick (Vanguards does this) is not built yet; add it to
  `Config/Events` when the next event wants it.
