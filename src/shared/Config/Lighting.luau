--!strict
-- Lighting numbers (POLISH_PLAN PV-E01). Server: World/Atmosphere applies the day look; client:
-- MatchFxController blends to night for matches, AmbienceController flickers lanterns. Pure data.

return {
	day = {
		density = 0.32, -- Atmosphere "LaneHaze"
		hazeColor = "#DEC8AA", -- warm limestone dust
		hazeDecay = "#967864",
		bloom = 0.35,
		bloomSize = 24,
		sunRays = 0.08,
		stars = 3000, -- Sky.StarCount (no custom starfield texture approved)
	},
	night = {
		density = 0.45,
		hazeColor = "#2E3550", -- deep blue night air (a warm haze at night reads as grey fog)
		hazeDecay = "#1A1C2A",
		tint = "#E6EDFF", -- a slightly cool grade over the warm one
		contrast = 0.05,
		blend = 2.5, -- seconds
		clockTime = 19.4, -- the match night (MatchFxController)
		brightness = 1.4,
	},
	-- Episode 9 opens at dusk and night falls over the waves (STORY_PLAN §8.5, S1-M05): the start look;
	-- each wave start moves it toward `night`, reaching it at `nightByWave` (S1-C05,
	-- MatchMoments.nightFraction, MatchFxController). `modes` are the modes that open at dusk.
	dusk = {
		modes = { ep9 = true },
		brightness = 2,
		density = 0.38,
		hazeColor = "#C98A5A", -- low sun through dust
		hazeDecay = "#5A3A40",
		tint = "#FFE2C8",
		contrast = 0.03,
		clockTime = 18.2,
		nightByWave = 30,
	},
	-- The lobby's day (LP-D09): one look per lane-clock phase (Config/LobbyLife.CLOCK). LaneClockController
	-- eases Lighting toward the current one in the lobby; matches keep their own light. `ambient` /
	-- `outdoor` are RGB 0..255, `lanterns` multiplies every lobby lantern's brightness (their day value
	-- is tuned for sunlight; in the dark the same lanterns read far brighter, so night dims them).
	lane = {
		dawn = {
			clockTime = 6.4,
			brightness = 1.7,
			ambient = { 96, 84, 86 },
			outdoor = { 140, 122, 120 },
			density = 0.36,
			hazeColor = "#E7C1A8",
			hazeDecay = "#8A6A78",
			tint = "#FFE9DC",
			contrast = 0.02,
			lanterns = 1,
		},
		day = {
			clockTime = 15.6, -- the look World/Atmosphere sets at start
			brightness = 2.4,
			ambient = { 92, 80, 70 },
			outdoor = { 150, 135, 118 },
			density = 0.32,
			hazeColor = "#DEC8AA",
			hazeDecay = "#967864",
			tint = "#FFFFFF",
			contrast = 0,
			lanterns = 1,
		},
		evening = {
			clockTime = 18.3,
			brightness = 1.9,
			ambient = { 104, 78, 66 },
			outdoor = { 150, 110, 92 },
			density = 0.38,
			hazeColor = "#C98A5A",
			hazeDecay = "#5A3A40",
			tint = "#FFE2C8",
			contrast = 0.03,
			lanterns = 0.85,
		},
		night = {
			clockTime = 21.2,
			brightness = 0.7,
			ambient = { 50, 52, 76 }, -- kept readable: players must still find the shops
			outdoor = { 60, 66, 100 },
			density = 0.42,
			hazeColor = "#2E3550",
			hazeDecay = "#1A1C2A",
			tint = "#E6EDFF",
			contrast = 0.05,
			lanterns = 0.6, -- pools, not a wash: the lane's lanterns hang every few studs (D-113)
		},
	},
	flicker = {
		min = 0.9, -- lantern brightness swings between min and max of its own value
		max = 1.1,
		hz = 15, -- updates per second
		radius = 120, -- studs from the camera; farther lanterns hold still
		maxLights = 40, -- ART_BIBLE §9 lights budget
	},
}
