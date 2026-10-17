--!strict
-- Client effects budget and the numbers behind the match VFX pass (BUILD_PLAN P2-17). Pure data:
-- no requires, no Roblox datatypes (loaded by Lune tests). Colours are hex strings.
-- Every effect is drawn from the shared pool in UI/Fx with these caps; nothing here changes play.

return {
	MAX_LIVE = 80, -- pooled effect parts on screen at once (hard cap)
	MAX_PER_FRAME = 14, -- pooled parts handed out in one frame; the rest of that frame's effects are skipped

	-- A small spark where a strike lands (every hit; "reduced" and "off" skip it).
	HIT = { size = 0.8, grow = 2.2, life = 0.18 },

	-- Deaths: a jasmine-petal poof for people, an ash poof for bosses. No blood anywhere.
	DEATH = {
		petals = 6, -- parts per poof ("reduced": 2)
		petalSize = 0.45,
		rise = 3.2, -- studs the cloud rises
		spread = 2.4, -- studs sideways
		life = 0.7,
		petalColors = { "#FFF6EA", "#F6D4DC", "#FFE9B8" }, -- jasmine white, blossom pink, lantern gold
		ashColors = { "#6B6560", "#4A4642", "#8C847C" },
		ashSize = 0.7,
	},

	-- The gate takes a hit: a red disc flashes at the gate and the screen edge blinks.
	GATE_HIT = { radius = 6, life = 0.45, color = "#D9453B", vignette = 0.45, vignetteLife = 0.5 },

	-- A boss is coming: pulsing rings at the spawn end of the path during the wave banner,
	-- then a shock ring where the boss steps in.
	BOSS = {
		pulses = 3,
		pulseEvery = 0.7,
		pulseRadius = 9,
		pulseLife = 0.9,
		color = "#B8322A",
		spawnRadius = 7,
		spawnLife = 0.6,
	},

	-- Ultimate strikes (EnemyRenderController.ultimateStrike): kept from P1-15.
	SHABRIYEH = { bladeLife = 0.35, bladeLength = 9 },
	SWEEP = { ringLife = 0.5, dustLife = 0.8, dustColor = "#C9B48F" },
}
