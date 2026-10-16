# Roblox TD / collection-game UI patterns (research, 2026-10-16)

*Engine facts are from create.roblox.com and the DevForum. Layout points marked [convention] are
genre practice (TDS, Anime Vanguards, Anime Defenders, ASTDX, PS99) — verify against gameplay video
before copying exact positions.*

## Phone budget (844×390 logical px, landscape)

- `ScreenInsets = CoreUISafeInsets` for interactive UI; `None` only for full-screen flashes.
- The top bar is ~58 px on new clients: read `GuiService.TopbarInset`, don't hardcode.
- In a match there is no character to move: `GuiService.TouchControlsEnabled = false` frees the
  bottom corners; restore it in the lobby.
- Touch targets ≥ 44 px, main actions 52–64 px. Labels ≥ 14 px, numbers ≥ 18 px.
- The "Preferred Text Size" accessibility setting (Sept 2025) rescales fixed-size text: pair
  `TextScaled` with a `UITextSizeConstraint`, or test with the setting maxed.
- Vertical budget: top HUD ~44 px, hotbar band ~85 px, ~250 px of playfield.

## In-match HUD [convention]

- **Top centre:** wave pill ("WAVE 7/20" + countdown) with the base-HP bar under it. HP fill tween
  0.5 s Exponential Out, colour green → amber → red, plus a lagging "ghost" bar that drains 0.3 s later.
- **Bottom centre:** unit hotbar, 6 slots of 60–64 px, 6 px gaps; each slot = portrait on a
  rarity-tinted frame, cost at the bottom, placed/limit counter in a corner. Can't afford → greyed
  with the cost in red.
- **Cash:** big gold number next to the hotbar (cost and wallet in one glance), count-up on change
  and a floating "+45".
- **Right column:** speed 1×/2×/3×, skip (vote toast in multiplayer), leave.
- **Tower panel** (tap a tower): card on the side; portrait, name, level pips; stat rows "120 → 165"
  with the gain in green; big green Upgrade with cost; Targeting cycle; red Sell with refund; ability
  button if any; shows the range circle while open.
- **Wave banner:** centre "WAVE 8" slides in, holds ~1.2 s, slides out; boss waves get a red
  "BOSS" bar + a wide boss HP bar under the wave pill.
- **Damage numbers:** pooled BillboardGuis, pop 1.3 → 1, rise and fade 0.6 s; throttle at 3×.

## Lobby [convention]

- Left rail of 56–64 px square icon buttons with labels and red notification badges (PS99 style).
- Currency pills ~130×36: icon overlapping the left edge, number, green "+".
- Inventory: grid of 3:4 cards with rarity gradient + dark stroke; one live 3D preview in the detail
  panel only.
- Summon reveal: dim → orb charge-up with escalating colour → full-screen flash in the rarity colour
  + shake → card pops in (Back Out 0.35 s), rotating shine for Legendary+, longer cutscene for Mythic.
- Codes: failure shakes the box ±8 px and turns the text red.

## Juice

| Interaction | Recipe |
|-------------|--------|
| Press | UIScale 0.92 in 0.06 s (Quad Out), release to 1.0 in 0.18 s (Back Out) |
| Popup open / close | UIScale 0.8 → 1 Back Out 0.25 s / → 0.85 Quad In 0.15 s |
| Count-up | ~0.5 s |
| Shine | preset a narrow white UIGradient band, animate only `Offset` −1 → 1 (cheap) |
| Base hit | ColorCorrection red tint flash + short camera shake (respect Reduced Motion) |

## Style that reads as "pro"

- Chunky display font for numbers and titles (FredokaOne / LuckiestGuy), Builder Sans for body
  text. Gotham/Arial are slated for removal.
- Thick dark outlines: text UIStroke 2–3 px, panels 3–4 px. A TextLabel can carry two UIStrokes
  (Contextual glyph outline + Border box).
- 2-stop vertical gradients on buttons (lighter top), green confirm, red sell/close, gold premium.
- A darker "lip" under buttons for depth, shrinking on press.
- Icons as uploaded images, never emoji.
- UI Styling (StyleSheet/StyleRule) is publishable since Jan 2026 for global tokens.

## Performance

- Each ViewportFrame allocates its own texture; dozens hurt. Use 1–3 live viewports (detail panel,
  summon reveal); image portraits for grids/hotbar long-term.
- CanvasGroup allocates an off-screen texture and can render blank on low settings: only for
  short fades, never for the HUD.
- Closed menus: `ScreenGui.Enabled = false` / `Visible = false`; update HUD text on change, not per frame.

## Sources

create.roblox.com/docs: ui/on-screen-containers, tutorials/use-case-tutorials/ui/create-hud-meters,
ui/cross-platform-design, ui/size-modifiers, ui/list-flex-layouts, ui/appearance-modifiers,
ui/styling, reference/engine/datatypes/Font. DevForum: 4047230 (TopbarInset), 3914959 (Preferred
Text Size), 2700490 (TextScaled), 404831 (UIGradient), 376225 / 2718794 (ViewportFrame cost),
1797885 (CanvasGroup), 3901480 (StyleSheet publish). tds.fandom.com/wiki/V1.7.0;
allthings.how (Anime Vanguards settings); creation.dev/blog/roblox-ui-design-best-practices.
