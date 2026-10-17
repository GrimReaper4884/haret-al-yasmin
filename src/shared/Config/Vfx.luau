--!strict
-- Client effects budget and the numbers behind the match VFX pass (BUILD_PLAN P2-17). Pure data:
-- no requires, no Roblox datatypes (loaded by Lune tests). Colours are hex strings.
-- Every effect is drawn from the shared pool in UI/Fx with these caps; nothing here changes play.

return {
	MAX_LIVE = 80, -- pooled effect parts on screen at once (hard cap)
	MAX_PER_FRAME = 14, -- pooled parts handed out in one frame; the rest of that frame's effects are skipped

	-- A small spark where a strike lands (every hit; "reduced" and "off" skip it).
	HIT = { size = 0.8, grow = 2.2, life = 0.18 },

	-- Hit feedback on the figure (PV-B02, Logic/HitFx). Numbers: a pooled BillboardGui per number,
	-- rising `rise` studs over `life` s; ability hits are `critScale` larger in gold. Flash: a pooled
	-- white Highlight on bosses and the selected tower's target only (Roblox caps Highlights at 31);
	-- everyone else is nudged back `knock` studs and returns over `life` s.
	DAMAGE_NUMBERS = { pool = 32, textSize = 18, critScale = 1.4, stroke = 2, rise = 2, life = 0.5, color = "#FFFFFF", critColor = "#F2C14E", maxDistance = 160 },
	HIT_FLASH = { color = "#FFFFFF", fill = 0.55, life = 0.08, max = 4 },
	HIT_PUNCH = { knock = 0.35, life = 0.1 },

	-- Deaths and gate hits (PV-B03). A boss death adds a dust ring and a short camera shake (Effects
	-- "full" and not Reduced Motion). Your own kills fling a cash coin from the body to the cash
	-- pill (at most `max` in flight, the rest skipped). A gate hit shudders the gate leaves by
	-- `angle` degrees and kicks up `dust` puffs at the foot of the doors.
	BOSS_DEATH = { ringRadius = 10, ringLife = 0.7, dustColor = "#B9A57E", shake = 0.2, amplitude = 0.6 },
	COIN_FLIGHT = { max = 6, life = 0.55, size = 32, lift = 90 },
	GATE_SHUDDER = { life = 0.25, angle = 3, dust = 4, dustSize = 1.6, dustRise = 2.5, dustLife = 0.6, dustColor = "#C9B48F" },

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

	-- Per-role impact when a hit lands (PV-B04), drawn with pooled parts; thrown props keep their
	-- own landing (ThrowFx) and skip the "puff". kind: arc (a white blade sweep + spark), puff (a
	-- burst at the target), ring (a ground ring + dust, and `hitStop` s frozen on the striker's
	-- clip), pulse (a soft ring around the support defender, radius = its range), sparkle (motes
	-- rising at the target), none. Abilities add `abilitySlow`: the striker's clip runs at
	-- `factor` for `seconds` (a slow-in) before the strike.
	ROLES = {
		melee = { kind = "arc", color = "#FFFFFF", life = 0.14, length = 3.2 },
		ranged = { kind = "puff", color = "#C9B48F", life = 0.3, size = 1.8 },
		splash = { kind = "ring", color = "#E8D2A6", life = 0.4, radius = 4, dust = 3, hitStop = 0.05 },
		support = { kind = "pulse", color = "#F2C14E", life = 0.6 },
		healer = { kind = "sparkle", color = "#CFF7D6", life = 0.6, motes = 4, rise = 3 },
		farm = { kind = "none" },
	},
	ROLE_KINDS = { "arc", "puff", "ring", "pulse", "sparkle", "none" },
	abilitySlow = { factor = 0.4, seconds = 0.3 },

	-- Ultimate strikes (EnemyRenderController.ultimateStrike): kept from P1-15.
	SHABRIYEH = { bladeLife = 0.35, bladeLength = 9 },
	SWEEP = { ringLife = 0.5, dustLife = 0.8, dustColor = "#C9B48F" },
}
