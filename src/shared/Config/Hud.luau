--!strict
-- Touch HUD numbers (docs/MOBILE_HUD_PLAN.md B1–B7). Every size is in logical px at UIScale 1 unless
-- it says "screen px"; Logic/HudLayout turns these into positions for a profile, a scale and a
-- safe-area size, and UI/Device feeds it on the client. Pure data.

return {
	-- Minimum hit target on both axes at the final scale (Apple 44 pt / Android 48 dp; Roblox GUI px are
	-- already DPI-scaled), the primary-action size, and the smallest text and number sizes at scale 1.
	TOUCH_MIN = 48,
	PRIMARY = 56,
	TEXT_MIN = 14,
	NUMBER_MIN = 18,

	-- UIScale = clamp(safe height / base × preset, floor, max), then capped so a FIT_SLOTS-slot hotbar
	-- plus its margins still fits the width. Phones never go below 1.0: the smallest phone gets the
	-- largest relative UI. The floor applies after the preset, so "small" only shrinks big screens.
	SCALE = {
		base = 390,
		touchMin = 1.0,
		desktopMin = 0.9,
		max = 1.5,
		presets = { small = 0.85, default = 1, large = 1.15, huge = 1.3 },
		-- Bridge used while the screens moved to the touch layout (MH-02 … MH-14): a minimum design
		-- canvas (w, h) kept for the pre-MH layouts. nil since MH-14: every screen fits a 640×282 safe
		-- area at 1.0 (DECISIONS D-073, D-082).
		legacyCanvas = nil :: { number }?,
	},

	-- Roblox's thumbstick (bottom-left) and jump button (bottom-right) zones in screen px, used while those
	-- controls are shown on a touch profile. A measured jump button (PlayerGui.TouchGui) replaces the
	-- right fallback, padded by `pad`; the Dynamic Thumbstick has no fixed frame, so the left one stays.
	RESERVED = { left = { 160, 160 }, right = { 140, 140 }, pad = 8 },
	-- Nothing interactive within this many px of the safe area's top edge.
	TOP_CLEAR = 8,

	-- Defender hotbar: slot size per input, gap and side margin; the width fit is computed for
	-- FIT_SLOTS slots (TD.LOADOUT_SLOTS 6 + the Extra Slot pass) so a pass holder's bar clears the
	-- corners too. On a narrow phone the slots narrow to fit the free band, never below TOUCH_MIN.
	HOTBAR = {
		slot = { touch = { 72, 88 }, desktop = { 68, 84 } },
		gap = 6,
		margin = 16,
		bottom = 6, -- px from the safe area's bottom edge
		FIT_SLOTS = 7,
		lift = 8, -- the picked slot rises this much
		costIconMin = 60, -- narrower slots show the price without the cash icon (it stays ≥ 16 px text)
	},

	-- Toasts: top of the stack in the lobby and in a match (under the wave / gate block and its burn
	-- pips), and the bottom band they never enter (hotbar, cash pill, Place / Cancel); `step` is one
	-- toast plus its gap, `max` the most shown at once where they fit.
	TOAST = { lobbyTop = 80, matchTop = 100, keepBottom = 160, step = 46, max = 3 },

	-- Right rail (Skip, Speed, View) in the thumb arc, above the jump zone; the match menu `≡` sits at
	-- the top of the same edge. When a column cannot hold every button the rest go into the next one in.
	RAIL = { button = 56, gap = 8, maxButtons = 4, margin = 12, menu = 48 },
	-- The Defenders panel (LP-B02): a left column on desktop, a centred sheet on touch, both ending
	-- above the cash pill. Rows: a name line over a line of buttons (row heights per input).
	DEFENDERS = {
		width = 400, -- desktop column
		heightFrac = 0.8, -- touch sheet: at most this share of the safe height (it may cover the wave pill)
		header = 54, -- title, count and the close button; the controls line sits under it
		row = { desktop = 86, touch = 100 },
		button = { desktop = 40, touch = 48 },
		line = { desktop = 34, touch = 40 }, -- name and level over the stat line
		portrait = { desktop = 56, touch = 64 },
		gap = 6,
		sellConfirmS = 3, -- the red "Sure?" state of Sell lasts this long
		batchGapS = 0.15, -- "Auto: all" and Sell all send one request per defender this far apart (LP-B03)
		pulseS = 1.2, -- a row whose ultimate is ready glows gold on this period
	},
	-- The speed sheet beside the rail's Speed button (LP-A03): one chip per TD.SPEEDS entry.
	SPEED_SHEET = { chip = 52, gap = 6, pad = 10, title = 18, caption = 16, lock = 16 },

	-- Touch placement (B3): tap slop and time, the long press that cancels, the ghost's offset above
	-- the finger, and the pick radius for selecting a placed defender.
	PLACE = {
		TAP_SLOP_PX = 12,
		TAP_MAX_S = 0.35,
		LONG_PRESS_S = 0.5,
		LONG_PRESS_SLOP_PX = 6, -- a long press must hold still; a slow drag is not a cancel
		FINGER_OFFSET_PX = 70,
		PICK_PX = { touch = 44, mouse = 34 },
		-- Place (rail side) and Cancel (the other side) sit in Roblox's bottom corners, which are empty
		-- while aiming (the thumbstick and jump hide): PRIMARY tall, at most maxW wide.
		PAIR = { maxW = 120, gap = 8, margin = 12 },
		-- The "why not" line under the ghost: px below the ghost's screen point.
		REASON_DY = 34,
	},

	-- Watchtower view on touch (B5): studs per dragged px (× zoom), the pinch zoom range as a factor of
	-- the default height, and how far past the arena bounds the look-at point may go.
	CAMERA = { PAN_STUDS_PER_PX = 0.12, ZOOM = { min = 0.6, max = 1.4 }, BOUNDS_MARGIN = 12, FOCUS_S = 0.4 },

	-- A touch screen whose safe area is shorter than this is a phone (taller is a tablet).
	PHONE_MAX_HEIGHT = 500,

	-- Lobby bottom bar on phones (B6): button size and gap; it narrows like the hotbar.
	LOBBY_BAR = { button = 64, gap = 8, bottom = 6 },
	-- The lobby rail on tablets and desktop (Theme v2, LP-C02): a wood panel with the gold Play
	-- (`play` × `tile`, as tall as both rows) at its left, Units / Summon / Diary in the top row and
	-- the smaller tiles under them; Play breathes (scale +`breathe` every `breatheS`).
	LOBBY_RAIL = { tile = 64, small = 56, play = 1.6, gap = 6, pad = 6, breathe = 0.03, breatheS = 2.4 },

	-- Sheet modals on phones (B7): margin to the safe area's edges.
	SHEET_MARGIN = 8,
	-- Codes on touch (B7): seconds the above-the-keyboard layout stays after typing ends (so the tap
	-- that ended it, usually Redeem, lands before the panel moves back), and the window in which a
	-- second Redeem (the button's own Activated after the focus-loss tap) is ignored.
	KEYBOARD = { restoreS = 0.4, redeemDebounceS = 0.5 },
	-- Telemetry (B8, MH-17): the HUD profiles a client may report (analytics value = position - 1:
	-- 0 desktop, 1 touch-phone, 2 touch-tablet), the PlaceTower refusals that count as a misplaced
	-- spot, the per-match cap on each count, and the PlaceCancelled rate limit (2 per second).
	TELEMETRY = {
		profiles = { "desktop", "touch-phone", "touch-tablet" },
		invalidReasons = { "bad_position", "out_of_bounds", "on_path", "too_close" },
		maxPerMatch = 1000,
		cancelLimit = { capacity = 2, perSecond = 2 },
	},
	-- Haptics (B8): at most one gate-hit buzz per this many seconds.
	HAPTICS = { notifyGapS = 0.3 },
	-- The defender bottom sheet (B4) is never wider than this (desktop with panelSide = bottom).
	SHEET_MAX_W = 640,
}
