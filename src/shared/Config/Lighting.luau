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
	},
	flicker = {
		min = 0.9, -- lantern brightness swings between min and max of its own value
		max = 1.1,
		hz = 15, -- updates per second
		radius = 120, -- studs from the camera; farther lanterns hold still
		maxLights = 40, -- ART_BIBLE §9 lights budget
	},
}
