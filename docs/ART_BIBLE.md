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
- Clothing reads as early-20th-century Levantine: long robes (*qumbaz*), sashes, waistcoats, headscarves,
  tarboosh. Avoid exaggerated or comic ethnic features: dignity first.

## 6. UI style

- Rounded panels (`UICorner` 12 px) in `plaster` at 0.06 transparency with a 2 px `woodDark` stroke.
- Text: `GothamMedium`/`BuilderSans` for Latin; Roblox falls back automatically to a font that supports
  Arabic.
- Accents in `copper` (currency) and `tile` (quests).
- Minimum touch target of 48×48 px; all layouts in Scale units with `UISizeConstraint` and
  `UIAspectRatioConstraint`; respect `ScreenGui.ScreenInsets = CoreUISafeInsets`.
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
