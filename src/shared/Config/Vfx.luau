--!strict
-- Client effects budget and the numbers behind the match VFX pass (BUILD_PLAN P2-17). Pure data:
-- no requires, no Roblox datatypes (loaded by Lune tests). Colours are hex strings.
-- Every effect is drawn from the shared pool in UI/Fx with these caps; nothing here changes play.

return {
	MAX_LIVE = 80, -- pooled effect parts on screen at once (hard cap)
	MAX_PER_FRAME = 14, -- pooled parts handed out in one frame; the rest of that frame's effects are skipped

	-- Particle sprites (PV-B01, assets/marketing/vfx/*.png, 256² with alpha). id 0 = not uploaded:
	-- UI/Fx.emitter returns nil and callers keep their part-based effect. MAX_EMITTERS caps the
	-- pooled ParticleEmitters (POLISH_PLAN §2: <= 24 in a match).
	TEXTURES = {
		spark = { id = 74879464229953, size = 1.4, life = 0.25, speed = 6, light = 1 },
		dust = { id = 77870170170422, size = 2.2, life = 0.6, speed = 3, light = 0 },
		petal = { id = 134057751781553, size = 0.6, life = 0.9, speed = 4, light = 0 },
		smoke = { id = 100319124340565, size = 2.4, life = 1.2, speed = 2, light = 0 },
		steam = { id = 81355377598187, size = 1.6, life = 1.4, speed = 1.5, light = 0 },
		crumb = { id = 116915557453058, size = 0.5, life = 0.5, speed = 5, light = 0 },
		shard = { id = 136345368143259, size = 0.45, life = 0.4, speed = 7, light = 0.5 },
		star = { id = 138138713844695, size = 0.8, life = 0.6, speed = 2, light = 1 },
	},
	MAX_EMITTERS = 16,

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

	-- Placing, upgrading and selling a defender (PV-B05). Landing: a dust ring and `petals` jasmine
	-- petals; upgrade: `stars` gold sparks bursting up and a 1 -> `punch` -> 1 scale punch on the
	-- figure, plus a brief gold glow from level `glowLevel`; sell: `coins` cash coins into the pill.
	-- The range ring gets an ablaq edge of `dashes` alternating basalt/cream dashes.
	TOWER = {
		dustRadius = 3.5, dustLife = 0.45, dustColor = "#D8C4A0",
		petals = 4, petalLife = 0.8, petalColor = "#FFF6EA",
		stars = 6, starLife = 0.55, starColor = "#F2C14E",
		punch = 1.12, punchLife = 0.3,
		glowLevel = 3, glowLife = 0.4, glowColor = "#F2C14E",
		coins = 6, coinGap = 0.05,
		dashes = 24, dashDark = "#3D3A38", dashLight = "#F1E9DA",
	},

	-- Enemies read at a glance (PV-A04): a dark-red stroke around every health bar, marker icons
	-- (armour, stealth) beside it, a red ground disc under bosses ("reduced" keeps it), and a boss
	-- bar at the top of the screen with a portrait.
	ENEMY_READ = { barStroke = "#5A0E0E", barStrokeWidth = 1.5, marker = 12, discColor = "#B8322A", discRadius = 3.2, discTransparency = 0.55, bossBarWidth = 320, portrait = 64 },

	-- Wave and boss presentation (PV-B06, Logic/MatchMoments decides, MatchFxController draws).
	MOMENTS = {
		bossPush = 1.2, pushDistance = 22, pushHeight = 9, -- camera push toward the spawn gate (s, studs)
		clearHold = 1.6, -- wave-cleared banner from the top
		finalTint = "#FFE2C2", finalDensity = 0.1, lanternBoost = 1.2, finalLife = 2, -- warm last wave
		ribbonLife = 1.8, ribbonSegments = 6, ribbonColors = { "#C8322B", "#F2C14E" }, -- 'arada ribbons
		petalSeconds = 3, petalEvery = 0.15, petalsPer = 3, petalFall = 2.6, petalHeight = 26, petalSpread = 28,
		defeatLife = 1.5,
	},

	-- Season Story 1 mechanics in a match (S1-C02, Logic/MechanicFx). A drummer's speed aura and a
	-- porter's shield are faint ground rings that follow the figure (one pooled part each, moved in the
	-- per-frame BulkMoveTo; at most `max` of a kind at once, the rest go without). A disguised attacker
	-- carries a "?" marker on its health bar until it is revealed, then a gold ring flashes on it.
	-- Lateef's jump is telegraphed by up to `maxDashes` dashes along the road to where he lands and a
	-- ring there. A boss's summon pulses a ring at the boss (and always shows a toast). Effects "off"
	-- draws none of the world parts; "reduced" keeps the rings and the telegraph (they are play
	-- information) and drops the flashes. Burn stacks on the gate show as flame pips under the gate
	-- bar (HUD, every Effects level), `burnPip` px each.
	STORY = {
		aura = { color = "#E8A33A", transparency = 0.8, max = 6, height = 0.1 },
		shield = { color = "#8FB3D9", transparency = 0.78, max = 6, height = 0.1 },
		reveal = { color = "#F2C14E", radius = 3.5, life = 0.5 },
		telegraph = { color = "#B04CC4", spacing = 3, dash = 1.6, width = 0.45, maxDashes = 14, landRadius = 3 },
		summon = { color = "#4A5C8C", radius = 5, life = 0.6 },
		burnPip = 16,
	},

	-- Ultimate strikes (EnemyRenderController.ultimateStrike): kept from P1-15.
	SHABRIYEH = { bladeLife = 0.35, bladeLength = 9 },
	SWEEP = { ringLife = 0.5, dustLife = 0.8, dustColor = "#C9B48F" },
}
