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
	flicker = {
		min = 0.9, -- lantern brightness swings between min and max of its own value
		max = 1.1,
		hz = 15, -- updates per second
		radius = 120, -- studs from the camera; farther lanterns hold still
		maxLights = 40, -- ART_BIBLE §9 lights budget
	},
}
