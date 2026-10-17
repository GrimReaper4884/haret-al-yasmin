# Season 1 — "Diamonds of the Lane" (ألماس الحارة)

*Status: design draft v1 · 2026-10-15 · Original story; see COPYRIGHT_REGISTER.md. Historical texture
comes from `docs/research/DAMASCUS_LANE_LIFE.md`.*

## 1. Logline

On the eve of his daughter's wedding, the spice merchant **Hajj Rashid** finds the diamond necklace
meant for the bride gone from a locked chest. The lane gate was shut all night, so the thief must be
a neighbour. Over five episodes the player gathers clues, hears rumours, steps outside the gate, chases
a shadow across the rooftops, and finally faces the whole lane in the fountain square. There the truth
turns out to be about debt and shame, not greed, and the lane chooses together how to put it right.

**Themes:** trust and rumour, honour vs. mercy, the lane as one family.
**Tone:** warm and suspenseful. No violence beyond a shove on the rooftops, and kid-safe throughout.

## 2. Originality guardrails

- Every character, name, line and plot beat below is written for this game.
- Allowed **genre** elements, shared by many works and by history: the lane gate locked at night, a strongman
  (qabaday) as the lane's protector, coffeehouse talk, rooftop social life, a wedding with a dowry.
- We do **not** use names, relationships, story arcs or catch-phrases from any TV series. Reviewers check
  each episode against COPYRIGHT_REGISTER §1 before release.

## 3. Cast

| ID | Name (EN / AR) | Role in the season | Secret |
|----|----------------|--------------------|--------|
| `hajj_rashid` | Hajj Rashid / الحاج رشيد | Spice merchant, father of the bride; the victim | Promised the necklace to his late wife; his pride makes him quick to blame others |
| `layla` | Layla / ليلى | The bride; clever, quietly investigates on her own | Suspects her cousin early but won't say it |
| `nasim` | Nasim / نسيم | Hajj Rashid's nephew and shop assistant; **the culprit** | Owes money to an outside moneylender after a failed tobacco deal; pawned the necklace meaning to buy it back before the wedding |
| `mansour` | Mansour the qabaday / منصور القبضاي | The lane's strongman and protector | Wants a quick culprit to keep the lane's name clean |
| `umm_salma` | Umm Salma / أم سلمى | Water seller; hears every rumour at the fountain | Spreads one false rumour in good faith |
| `yusuf` | Yusuf / يوسف | Errand boy; red-herring suspect (seen near the chest) | Was hiding a stray kitten in the storeroom |
| `abu_nadim` | Abu Nadim / أبو نديم | Baker; fires the oven before dawn, so he's a witness | Saw a lantern moving on the rooftops |
| `khalil_tailor` | Khalil / خليل | Tailor; the indigo thread leads to his shop (red herring) | Made Nasim's indigo sash |
| `sitt_wardeh` | Sitt Wardeh / الست وردة | Elder; knows family histories, gives motive | Knows Nasim's father lost everything to the same lender |
| `zaki_effendi` | Zaki Effendi / زكي أفندي | Moneylender and pawnbroker outside the gate | Bends the law but isn't a villain; he can be bargained with |

## 4. The mystery: the clue chain (the "truth table")

| Clue | Found in | Points to (at first) | Real meaning |
|------|----------|----------------------|--------------|
| C1 Slipper print by the chest | Ep1, Rashid's shop | "Someone from the house, not a stranger" | Nasim lives above the shop |
| C2 Torn indigo thread on the gate nail | Ep1, Jasmine Gate | Khalil the tailor (indigo cloth) | Nasim's sash, made by Khalil: someone **left** the lane at night |
| C3 Copper token stamped with a crescent | Ep1, fountain bench | Unknown | A pawn ticket from Zaki Effendi's shop outside the gate |
| C4 Yusuf seen near the chest | Ep2, rumour from Umm Salma | Yusuf | He was hiding a kitten; clears him |
| C5 Lantern on the rooftops before dawn | Ep2, Abu Nadim's testimony | A rooftop route | The path from the shop roof to the gate |
| C6 Pawn ledger entry "N., one necklace" | Ep3, Zaki Effendi | Nasim | Confirms the pawn and the debt |
| C7 Nasim caught moving the money | Ep4, rooftop chase | Nasim | He tried to buy the necklace back secretly |

## 5. Episodes

### Episode 1: Wedding Eve (ليلة العرس) ✅ in development
- **Unlock:** "Warm ka'ak for Sitt Wardeh" completed (the player is known in the lane).
- **Flow:** Hajj Rashid (new shop on the fountain square) explains the theft and asks for help → the player
  inspects three clue spots (C1–C3) anywhere in the lane, in any order → reports back.
- **Reward:** 60 qirsh. The Episode 2 teaser line: "Mansour the qabaday will want a name by sunset."
- **New systems:** investigation quests (multi-objective progress), world clue spots, clue journal in the
  HUD, prerequisite quests, dialogue condition `ready`.

### Episode 2: Whispers (همسات)
- Talk to the suspects (Yusuf, Khalil, Umm Salma, Abu Nadim). Each conversation adds a statement to the
  **casebook**. Mansour pushes the player to accuse someone.
- **Choice:** accuse now (wrong → Yusuf's family loses face; affects reputation and later dialogue) or ask
  for more time. Introduces **reputation** per household (0–100, persisted).
- **New systems:** casebook UI, reputation, branching dialogue with consequences, NPC schedules (light).

### Episode 3: Outside the Gate (برّا البوابة)
- New zone: a **khan** (caravanserai) just outside the gate. Zaki Effendi will only talk business.
- **Bargaining mini-game:** trade favours or qirsh for a look at the ledger (C6).
- **New systems:** new streamed zone, bargaining UI, a currency sink.

### Episode 4: Rooftops at Night (سطوح الليل)
- Night falls (lighting change and lanterns). A rooftop traversal course from the shop roof to the gate;
  catch the figure with the pawn money (C7).
- **New systems:** day/night state, rooftop zone, a timed traversal challenge (mobile-friendly jump pads),
  a server-validated checkpoint path.

### Episode 5: The Fountain Square (ساحة البحرة)
- Public gathering. The player presents the evidence. Nasim confesses his debt.
- **Lane choice (server-wide vote):** shame him publicly, or everyone chips in to repay Zaki Effendi.
  Choosing mercy starts a **shared community goal** (players donate qirsh or complete errands) to redeem the
  necklace. That leads to the **wedding procession (zaffeh)** as a live event: emotes, music (licensed or
  original), and a cosmetic reward for everyone who took part.
- **New systems:** server-wide vote, community goals (MemoryStore), live event scheduling.

## 6. Persistence additions

| Field | Episode | Notes |
|-------|---------|-------|
| `quests[id].progress: { [objectiveId]: true }` | Ep1 | Clues found; optional, validated on load |
| `reputation: { [household]: number }` | Ep2 | 0–100, default 50 |
| `casebook: { [statementId]: true }` | Ep2 | Statements heard |
| `season1: { choice: string? }` | Ep5 | The player's vote |

## 7. Production checklist per episode

1. Design pass (this doc) and an originality review (register row).
2. Config: quests, dialogue, strings (EN + AR), clue spots.
3. Code: only new systems; content stays configuration.
4. Tests: config integrity (every reference resolves) and logic for new state.
5. Studio play test: happy path, abuse, persistence round trip, phone emulator.
6. Native-speaker review of the Arabic before public release.
