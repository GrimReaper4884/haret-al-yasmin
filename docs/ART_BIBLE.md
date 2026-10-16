# Art Bible

*Status: living document · Last updated 2026-10-15*

## 1. Visual pillars

1. **Warm stone and deep shade:** honey limestone walls, cool shadowed alleys and bright courtyards.
2. **Ablaq banding:** alternating courses of pale limestone and dark basalt on important façades. This is a
   regional architectural tradition and not owned by anyone.
3. **Life spilling outdoors:** awnings, crates of produce, copper pots, hanging lanterns, jasmine and vines.
4. **Readable from a phone:** big, simple shapes; strong silhouettes; never rely on fine detail.

## 2. Palette (sRGB)

| Token | Hex | Use |
|-------|-----|-----|
| `stoneLight` | `#E6D5B8` | Main walls |
| `stoneWarm` | `#D9BF94` | Accent walls, courtyard paving |
| `basalt` | `#3D3A38` | Ablaq bands, thresholds, fountain rim |
| `plaster` | `#F1E9DA` | Upper storeys, interiors |
| `wood` | `#6B4423` | Doors, mashrabiya, beams |
| `woodDark` | `#4A2E18` | Window frames, counters |
| `vine` | `#5E7D3A` | Vines, citrus trees |
| `jasmine` | `#FBF8F1` | Jasmine blossoms, highlights |
| `tile` | `#2E8B87` | Fountain tiles, door accents |
| `copper` | `#B87333` | Pots, lanterns, the coin icon |
| `fabricRed` | `#A4302A` | Awnings, tarboosh |
| `fabricIndigo` | `#2F3E6B` | Awnings, clothing |

UI uses the same palette (see §6). The palette tokens live in code in `src/shared/Config/Palette.luau` and
are shared by the world builder and the UI.

## 3. Materials

Use built-in Roblox materials only, so there are no texture uploads and no extra memory cost on mobile:
`Limestone`, `Basalt`, `Cobblestone` (alley floor), `Plaster`, `WoodPlanks`, `Wood`, `Fabric`, `Slate`,
`CeramicTiles` (fountain). Custom MaterialVariants are allowed later only through the asset approval process.

## 4. Architecture rules

- Ground floor 12 studs high, upper floor 10 studs, flat roofs with a low parapet.
- Doorways are 6×9 studs; important doors get a basalt arch band.
- Upper storeys jut out 2 studs over the alley on wooden corbels (the *mashrabiya* bay).
- Alley width: 14–18 studs, so two players can pass an NPC without collision issues.

## 5. Characters

- NPCs use Roblox R15 humanoids built from `HumanoidDescription` with body colors and simple
  primitive-built garments (tarboosh, headscarf, apron, sash). No marketplace clothing for now.
- Defenders and attackers are stylized jointed figures (big head, chunky hands, readable from the
  overhead match camera), or imported Meshy characters once approved. See
  `docs/CHARACTER_PIPELINE.md`; per-id looks live in `src/shared/Config/CharacterLooks.luau`.
- Clothing reads as early-20th-century Levantine: long robes (*qumbaz*), sashes, waistcoats, headscarves,
  tarboosh. Avoid exaggerated or comic ethnic features: dignity first.

## 6. UI style

- Genre conventions in the lane's palette (research: `docs/research/ROBLOX_TD_UI_PATTERNS.md`).
  Helpers in `src/client/UI/Theme.luau` and `Juice.luau`.
- Rounded panels (`UICorner` 12 px) in `plaster` with a 3 px `woodDark` stroke and a faint
  top-light gradient.
- Buttons: lighter-top gradient, 2.5 px dark border, white `FredokaOne` text with a dark outline,
  press squash (0.92) and springy release. Green = confirm/upgrade, red = sell/close, gold = premium.
- Numbers and titles: `FredokaOne` with a dark outline (`Theme.display`); body text `BuilderSans`.
  Roblox falls back automatically to a font that supports Arabic.
- Rarity colours: rare blue `#3A8FD6`, epic purple `#9B4FD1`, legendary gold `#E8B23A`,
  mythic red `#E0433A`, secret black. Legendary and above get a sweeping shine.
- Accents in `copper` (currency) and `tile` (quests).
- Minimum touch target of 48×48 px. Layouts are authored in offsets for a phone in landscape (~844×390),
  and a single `UIScale` on the root ScreenGui adapts them (clamped to 0.8–1.5). Panels use Scale widths
  with `UISizeConstraint` maxima. Respect `ScreenGui.ScreenInsets = CoreUISafeInsets`.
- HUD placement: Roblox owns the top-left (menu, chat window) and top-right (player list). Coins and the
  language toggle sit top-centre, toasts below them, the errand tracker on the right edge at 45% height,
  dialogue bottom-centre, the shop centred.
- Icons are drawn from UI primitives (`src/client/UI/Icons.luau`); avoid emoji (they render inconsistently).
- Arabic mode: text right-aligned, the dialogue speaker label on the right, and button rows reversed.

## 7. Lighting

Late afternoon (`ClockTime` 15.2), warm sun and soft ambient. ShadowMap or Future lighting is chosen per
platform at publish time; the slice must look correct under Voxel lighting as a fallback.

## 8. Audio (post-slice)

Only original or properly licensed audio: oud and qanun loops commissioned or from the Roblox-licensed
library, ambient market murmur, birds, the fountain. No commercial songs, and no TV themes or
"sound-alikes".

## 9. Performance budget (mobile)

| Item | Budget (slice) | Budget (full map, streamed) |
|------|---------------|------------------------------|
| Parts in workspace | ≤ 900 | ≤ 15,000 total, ≤ 3,000 per streaming region |
| Unique meshes | 0 | ≤ 150 |
| Lights (Point/Spot) | ≤ 8 | ≤ 40, with shadows only on hero lights |
| Draw calls target | < 400 | < 800 |
| Texture memory | ~0 MB | ≤ 150 MB |
