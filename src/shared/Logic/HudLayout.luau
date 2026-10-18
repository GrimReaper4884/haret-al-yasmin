--!strict
-- Touch HUD layout maths (docs/MOBILE_HUD_PLAN.md B1–B3, B6): which layout profile a device gets,
-- the UIScale, Roblox's thumbstick / jump corners, and where the hotbar, the right rail and the lobby
-- bar go so they never sit under those corners. Pure: the client (UI/Device) passes Config/Hud as
-- `cfg` and reads the engine values; specs in tests/hud.spec.luau.
--
-- Units: `safeSize`, reserved rects and the free band are in **screen px** (the ScreenGui's safe-area
-- AbsoluteSize, after DPI). Layout results (hotbar, rail, lobby bar) are in **design px**: the offsets a
-- controller writes under the single UIScale, so screen = design × scale (`toScreen`).

export type Profile = "touch-phone" | "touch-tablet" | "desktop"
export type Size = { x: number, y: number }
export type Rect = { x0: number, y0: number, x1: number, y1: number }
export type Reserved = { left: Rect?, right: Rect? }
export type Measured = { jump: Rect?, thumbstick: Rect? }
export type Input = { preferredInput: string, displaySize: string, safeSize: Size }
export type Hotbar = { slotW: number, slotH: number, gap: number, width: number, x: number, y: number }
export type Point = { x: number, y: number }
export type Rail = { size: number, gap: number, buttons: { Point }, columns: number, menu: Point & { size: number } }
export type Bar = { size: number, gap: number, width: number, x: number, y: number }

local HudLayout = {}

function HudLayout.isTouch(profile: Profile): boolean
	return profile ~= "desktop"
end

-- touch-phone: last input was touch, a small physical display and a short safe area; touch-tablet: any
-- other touch screen (tablets, touch laptops); desktop: everything else (gamepad included, for now).
-- `preferredInput` / `displaySize` are the enum item names ("Touch", "Small", …).
function HudLayout.profile(cfg: any, input: Input): Profile
	if input.preferredInput ~= "Touch" then
		return "desktop"
	end
	if input.displaySize == "Small" and input.safeSize.y < cfg.PHONE_MAX_HEIGHT then
		return "touch-phone"
	end
	return "touch-tablet"
end

local function slotBase(cfg: any, profile: Profile): { number }
	return if HudLayout.isTouch(profile) then cfg.HOTBAR.slot.touch else cfg.HOTBAR.slot.desktop
end

-- The single UIScale: safe height / base × the player's preset, floored per profile (touch never
-- below 1.0) and capped at max, then capped again so a FIT_SLOTS-slot hotbar plus two margins fits
-- the width (the width cap wins over the floor on an absurdly narrow screen).
function HudLayout.scale(cfg: any, profile: Profile, safeSize: Size, preset: string?, slotCount: number?): number
	local S = cfg.SCALE
	local mult = S.presets[preset or "default"] or 1
	local floor = if HudLayout.isTouch(profile) then S.touchMin else S.desktopMin
	local s = math.clamp(safeSize.y / S.base * mult, floor, S.max)
	local n = math.max(slotCount or 0, cfg.HOTBAR.FIT_SLOTS)
	local base = slotBase(cfg, profile)
	local need = n * base[1] + (n - 1) * cfg.HOTBAR.gap + 2 * cfg.HOTBAR.margin
	return math.min(s, safeSize.x / need)
end

-- Bottom corners to keep clear (screen px), only on touch profiles while Roblox's touch controls show.
-- A measured jump button replaces the right fallback (padded, extended to the screen's edges); a
-- classic thumbstick frame replaces the left one. The Dynamic Thumbstick has no fixed frame: pass nil.
function HudLayout.reserved(cfg: any, profile: Profile, touchControls: boolean, safeSize: Size, measured: Measured?): Reserved
	if not HudLayout.isTouch(profile) or not touchControls then
		return {}
	end
	local R = cfg.RESERVED
	local w, h = safeSize.x, safeSize.y
	local left: Rect = { x0 = 0, y0 = h - R.left[2], x1 = R.left[1], y1 = h }
	local right: Rect = { x0 = w - R.right[1], y0 = h - R.right[2], x1 = w, y1 = h }
	local m: Measured = measured or {}
	if m.jump then
		right = { x0 = math.max(0, m.jump.x0 - R.pad), y0 = math.max(0, m.jump.y0 - R.pad), x1 = w, y1 = h }
	end
	if m.thumbstick then
		left = { x0 = 0, y0 = math.max(0, m.thumbstick.y0 - R.pad), x1 = math.min(w, m.thumbstick.x1 + R.pad), y1 = h }
	end
	return { left = left, right = right }
end

-- The horizontal band along the bottom edge that is clear of both corners (screen px).
function HudLayout.freeBand(safeSize: Size, reserved: Reserved): { x0: number, x1: number }
	return {
		x0 = if reserved.left then reserved.left.x1 else 0,
		x1 = if reserved.right then reserved.right.x0 else safeSize.x,
	}
end

function HudLayout.overlaps(a: Rect, b: Rect): boolean
	return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
end

-- True when `rect` (screen px) touches neither reserved corner.
function HudLayout.fits(rect: Rect, reserved: Reserved): boolean
	if reserved.left and HudLayout.overlaps(rect, reserved.left) then
		return false
	end
	if reserved.right and HudLayout.overlaps(rect, reserved.right) then
		return false
	end
	return true
end

-- A design-px rect in screen px.
function HudLayout.toScreen(rect: Rect, scale: number): Rect
	return { x0 = rect.x0 * scale, y0 = rect.y0 * scale, x1 = rect.x1 * scale, y1 = rect.y1 * scale }
end

-- The span (design px) a bottom-edge row may use: between the corners when they are reserved, else
-- inside the side margins.
local function bottomSpan(cfg: any, scale: number, safeSize: Size, reserved: Reserved): (number, number)
	local band = HudLayout.freeBand(safeSize, reserved)
	local w = safeSize.x / scale
	local lo = if reserved.left then band.x0 / scale else cfg.HOTBAR.margin
	local hi = if reserved.right then band.x1 / scale else w - cfg.HOTBAR.margin
	return lo, hi
end

-- `count` equal cells of at most `base` px, narrowed to fit `fitCount` of them between lo and hi but
-- never below TOUCH_MIN, centred in the span and kept on screen. Returns size, width, x.
local function row(cfg: any, base: number, gap: number, count: number, fitCount: number, lo: number, hi: number, w: number): (number, number, number)
	local fit = math.floor((hi - lo - gap * (fitCount - 1)) / fitCount)
	local size = math.max(cfg.TOUCH_MIN, math.min(base, fit))
	local width = count * size + math.max(0, count - 1) * gap
	local x = (lo + hi) / 2 - width / 2
	local margin = cfg.HOTBAR.margin
	if width > w - 2 * margin then
		x = (w - width) / 2
	else
		x = math.clamp(x, margin, w - margin - width)
	end
	return size, width, x
end

-- The defender hotbar (design px): slot size, total width and the bar's top-left corner.
function HudLayout.hotbar(cfg: any, profile: Profile, scale: number, safeSize: Size, slotCount: number, reserved: Reserved?): Hotbar
	local H = cfg.HOTBAR
	local base = slotBase(cfg, profile)
	local w, h = safeSize.x / scale, safeSize.y / scale
	local lo, hi = bottomSpan(cfg, scale, safeSize, reserved or {})
	local slotW, width, x = row(cfg, base[1], H.gap, slotCount, math.max(slotCount, H.FIT_SLOTS), lo, hi, w)
	return { slotW = slotW, slotH = base[2], gap = H.gap, width = width, x = x, y = h - H.bottom - base[2] }
end

-- The match rail (design px): the menu button at the top of the rail's edge and up to `count` buttons
-- vertically centred in the space between it and the jump zone (or the hotbar band), outermost
-- column first; a column that cannot hold them all spills into the next one inwards.
function HudLayout.rail(cfg: any, profile: Profile, scale: number, safeSize: Size, side: string, count: number, reserved: Reserved?): Rail
	local R = cfg.RAIL
	local res: Reserved = reserved or {}
	local w, h = safeSize.x / scale, safeSize.y / scale
	local size, gap, margin = R.button, R.gap, R.margin
	local right = side ~= "left"
	local menu = { x = if right then w - margin - R.menu else margin, y = cfg.TOP_CLEAR, size = R.menu }
	local top = cfg.TOP_CLEAR + R.menu + gap
	local zone = if right then res.right else res.left
	local hotbarTop = h - cfg.HOTBAR.bottom - slotBase(cfg, profile)[2]
	local bottom = hotbarTop - gap
	if zone then
		bottom = math.min(bottom, zone.y0 / scale - gap)
	end
	local perCol = math.max(1, math.floor((bottom - top + gap) / (size + gap)))
	local buttons: { Point } = {}
	local columns = 0
	local i = 0
	while i < count do
		local k = math.min(perCol, count - i)
		local colH = k * size + (k - 1) * gap
		local y0 = math.max(top, math.min((h - colH) / 2, bottom - colH))
		local x = if right then w - margin - size - columns * (size + gap) else margin + columns * (size + gap)
		for j = 0, k - 1 do
			table.insert(buttons, { x = x, y = y0 + j * (size + gap) })
		end
		i += k
		columns += 1
	end
	return { size = size, gap = gap, buttons = buttons, columns = columns, menu = menu }
end

-- The lobby's bottom bar on phones (design px): `count` buttons centred between the corners.
function HudLayout.lobbyBar(cfg: any, _profile: Profile, scale: number, safeSize: Size, count: number, reserved: Reserved?): Bar
	local B = cfg.LOBBY_BAR
	local w, h = safeSize.x / scale, safeSize.y / scale
	local lo, hi = bottomSpan(cfg, scale, safeSize, reserved or {})
	local size, width, x = row(cfg, B.button, B.gap, count, count, lo, hi, w)
	return { size = size, gap = B.gap, width = width, x = x, y = h - B.bottom - size }
end

-- A touch that moved at most TAP_SLOP_PX and lasted at most TAP_MAX_S is a tap.
function HudLayout.isTap(cfg: any, dx: number, dy: number, dt: number): boolean
	return dx * dx + dy * dy <= cfg.PLACE.TAP_SLOP_PX * cfg.PLACE.TAP_SLOP_PX and dt <= cfg.PLACE.TAP_MAX_S
end

-- Clamps a watchtower look-at point to the arena bounds ({ x0, z0, x1, z1 }) grown by `margin`.
function HudLayout.clampPan(x: number, z: number, bounds: { number }, margin: number): (number, number)
	local x0, x1 = math.min(bounds[1], bounds[3]) - margin, math.max(bounds[1], bounds[3]) + margin
	local z0, z1 = math.min(bounds[2], bounds[4]) - margin, math.max(bounds[2], bounds[4]) + margin
	return math.clamp(x, x0, x1), math.clamp(z, z0, z1)
end

return HudLayout
