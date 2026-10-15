# Copyright and Originality Register

*Status: living document · Last updated 2026-10-16*

Every asset, name, text, sound and design reference used in the game gets a row. Nothing moves to
`assets/production/` or ships in a release without a row marked **Approved** by a human reviewer.
**Claude-authored entries are self-assessments, not legal clearance.**

## 1. Hard exclusions

We do not use any of the following:

- Characters, character names used as principal roles, plots, catch-phrases, dialogue, theme music or
  logos from Levantine TV series, including but not limited to *Bab al-Hara*, *Ayyam Shamiyeh*,
  *Al-Khawali*, *Al-Za'im*, *Tawq al-Banat* and *Laylat al-Qabd*.
- Actors' likenesses, voices or sound-alikes.
- Distinctive set designs copied from those productions (e.g. a recognisable signature gate or coffee-house
  layout).
- The series title "Bab al-Hara" as a zone name, game name or keyword.
- Marketplace models, audio or images not created by us or not licensed for our use.

## 2. Allowed sources

- Public-domain historical knowledge: architecture (ablaq, mashrabiya, courtyard houses), clothing (qumbaz,
  tarboosh), food (ka'ak, ka'ak bi-simsim), trades, social customs.
- Roblox built-in materials, primitives, fonts and default avatar parts.
- Assets created in-house or by contracted artists, with written assignment of rights.
- Roblox Creator Store assets **only** after review, with the license and creator recorded below.

## 3. Register

| ID | Item | Type | Source / author | License | Similarity check | Status |
|----|------|------|-----------------|---------|------------------|--------|
| C-001 | Game title "Haret Al-Yasmin" | Name | Original (generic Arabic: "Jasmine Lane") | n/a | Generic descriptive phrase; trademark search **pending** | Needs human review |
| C-002 | NPC "Abu Nadim" (baker) | Character | Original writing | Owned | Common kunya; not a principal character name in the shows listed in §1 to our knowledge; **needs native-speaker and legal check** | Needs human review |
| C-003 | NPC "Sitt Wardeh" | Character | Original writing | Owned | As above | Needs human review |
| C-004 | NPC "Khalil the tailor" | Character | Original writing | Owned | As above | Needs human review |
| C-005 | Quest "Warm Ka'ak for Sitt Wardeh" | Story / dialogue | Original writing (`Config/Dialogue.luau`, `Config/Strings.luau`) | Owned | Everyday errand; no lines adapted from TV | Self-assessed OK |
| C-006 | Slice map geometry | 3D | Built procedurally from primitives in `WorldService.luau` | Owned | Generic regional architecture; no reference to TV sets | Self-assessed OK |
| C-007 | Red Tarboosh cosmetic | 3D | Primitives in `Config/Items.luau` | Owned | Traditional generic garment | Self-assessed OK |
| C-008 | UI icons (coin, quest) | 2D | Unicode glyphs and primitives | n/a | — | Self-assessed OK |
| C-009 | Fonts | Font | Roblox built-in | Roblox ToS | — | Approved (platform) |
| C-010 | Materials | Texture | Roblox built-in | Roblox ToS | — | Approved (platform) |
| C-011 | Toolbox "My Models" items named after *Bab al-Hara* characters (tower_abu_issam, tower_motaz, …) | 3D | Pre-existing in the account, not part of this project | Unknown | Names derive from a TV series | **Excluded — do not use** |
| C-012 | Tower-defense pivot: the lane gate, the night bar, the 'akeed/za'im ranks, the shabriyeh, the 'arada troupe, the coffee house, the French gendarmerie | Setting tropes | Pre-existing Damascus folk culture and 1930s history (see `docs/research/BAB_AL_HARA_REFERENCE.md`, `ROBLOX_IP_AND_POLICY.md`) | n/a | Tropes, not expression; no set, logo, footage or dialogue copied | Self-assessed OK |
| C-013 | Defender roster names: Abu Fares, Abu Bashir, Abu Jamil, Abu Nidal, Abu Samir, Abu Hamed, Abu Khater, Umm Zaki, The 'Akeed, The Za'im, The Strongman, The Mukhtar, The 'Arada Troupe, The Great Za'im, Cat of the Lane (`Config/Strings` `unit.*`) | Character names | Original writing | Owned | Generic kunyas and role titles chosen to avoid the principal cast of the series listed in §1 (Abu Fares and Abu Khater are also minor/background names in that series: **swap if the native-speaker review objects**; one-line edits in Strings) | Needs human review |
| C-014 | Enemy roster (gendarme, night thief, bandit, thug, rider, sapper, spy; the Sergeant, the Thief King, the rival za'im, the Commandant) | Characters | Original writing | Owned | Historical archetypes | Self-assessed OK |
| C-015 | Unit and enemy rigs (`Util/RigBuilder`) | 3D | Primitives | Owned | Blocky original figures; no likeness | Self-assessed OK |
| C-016 | Gate prop (`Props2.gate`), arena, coffee house, barber, signs | 3D | Primitives | Owned | Generic regional architecture | Self-assessed OK |
| C-017 | Arabic sign texts (حارة الياسمين, فرن أبو نديم, خياطة خليل, عطارة الحاج رشيد, حلاق الحارة, قهوة الحارة) | Text | Original | Owned | Generic shop names | Self-assessed OK |
| C-018 | Audio cues (`Config/Audio`) | Sound | **None yet** (all ids 0). Brief in `docs/AUDIO_BIBLE.md`: original cues or Creator Store licensed tracks only; never the TV score | — | The TV theme and score are copyrighted and fingerprinted by Roblox; excluded | Proposed |
| C-019 | Mode and episode titles ("Night of the Thieves", "The Rival Lane", "The Siege", "Endless Night") | Text | Original | Owned | Generic | Self-assessed OK |
| C-020 | Experience title and keywords | Name | "Haret Al-Yasmin" (unchanged). Description may say "inspired by classic Damascus hara dramas, not affiliated with any broadcaster"; the series title is **never** used in the title, icon or tags | n/a | Trademark search for the series title still unverified (see IP report §4) | Needs human review |

## 4. Process

1. Add a row with status **Proposed** before you use anything.
2. Store drafts in `assets/unapproved/`.
3. A reviewer checks the license and the similarity, sets the row to **Approved**, and the asset moves to
   `assets/production/`.
4. CI and review rule (planned): no `rbxassetid://` in `src/` unless its id appears in an Approved row.
