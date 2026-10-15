# Copyright and Originality Register

*Status: living document · Last updated 2026-10-15*

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

## 4. Process

1. Add a row with status **Proposed** before you use anything.
2. Store drafts in `assets/unapproved/`.
3. A reviewer checks the license and the similarity, sets the row to **Approved**, and the asset moves to
   `assets/production/`.
4. CI and review rule (planned): no `rbxassetid://` in `src/` unless its id appears in an Approved row.
