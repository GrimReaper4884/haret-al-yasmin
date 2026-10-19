--!strict
-- Lobby life math (POLISH_PLAN PV-E02): what each Effects level allows, the washing-line sway,
-- where each bird of the flock is, how a cat turns, a fountain ripple's phase and when the oven
-- puffs. LobbyLifeController draws it. Pure.

local LobbyLife = {}

export type Tier = { static: boolean, motion: boolean, particles: boolean }

-- Effects "full": everything; "reduced": no particles (Fx rule) but the world still moves;
-- "off": nothing extra at all (the vines too).
function LobbyLife.tier(level: string): Tier
	if level == "full" then
		return { static = true, motion = true, particles = true }
	elseif level == "reduced" then
		return { static = true, motion = true, particles = false }
	end
	return { static = false, motion = false, particles = false }
end

function LobbyLife.near(dx: number, dy: number, dz: number, radius: number): boolean
	return dx * dx + dy * dy + dz * dz <= radius * radius
end

-- A cloth's swing angle in degrees: a slow sine with a gentle second harmonic, never past `amp`.
function LobbyLife.sway(t: number, seed: number, amp: number, hz: number): number
	local w = t * hz * 2 * math.pi + seed
	return amp * (math.sin(w) * 0.8 + math.sin(w * 2.3 + seed) * 0.2)
end

-- Yaw (radians, Roblox CFrame.Angles(0, yaw, 0)) that faces from (fx, fz) towards (tx, tz).
function LobbyLife.yawToward(fx: number, fz: number, tx: number, tz: number): number
	return math.atan2(-(tx - fx), -(tz - fz))
end

-- Shortest signed difference b - a, wrapped into (-pi, pi].
function LobbyLife.angleDiff(a: number, b: number): number
	local d = (b - a) % (2 * math.pi)
	if d > math.pi then
		d -= 2 * math.pi
	end
	return d
end

-- The turn (radians) to apply this step: towards `target` the short way, at most `maxStep`.
function LobbyLife.turnStep(current: number, target: number, maxStep: number): number
	local d = LobbyLife.angleDiff(current, target)
	return math.clamp(d, -maxStep, maxStep)
end

-- Bird `i` (1-based) of the flock at time `t`: position, the yaw along its heading and the roll
-- of its wing beat (radians).
function LobbyLife.bird(i: number, t: number, cfg: any): (number, number, number, number, number)
	local theta = t * cfg.speed - (i - 1) * cfg.spacing
	local r = cfg.radius + ((i % 3) - 1) * cfg.spread
	local x = cfg.center[1] + math.cos(theta) * r
	local z = cfg.center[2] + math.sin(theta) * r
	local y = cfg.height + math.sin(t * 1.3 + i * 1.7) * cfg.bob + ((i % 2) * 2 - 1) * 0.6
	-- Heading: the derivative of the circle (counter-clockwise for a positive speed)
	local hx, hz = -math.sin(theta), math.cos(theta)
	if cfg.speed < 0 then
		hx, hz = -hx, -hz
	end
	local yaw = math.atan2(-hx, -hz)
	local roll = math.rad(cfg.flap) * math.sin(t * cfg.flapHz * 2 * math.pi + i * 1.1)
	return x, y, z, yaw, roll
end

-- A ripple's progress 0..1 at time `t` (ripple `k` of `n` is offset so they don't pulse together).
function LobbyLife.ripple(t: number, k: number, n: number, period: number): number
	return ((t / period) + (k - 1) / n) % 1
end

-- True when the oven should flare and puff: the player is within `trigger` studs and the last
-- puff is at least `cooldown` seconds old.
function LobbyLife.ovenPuff(
	dist: number,
	now: number,
	lastAt: number,
	trigger: number,
	cooldown: number
): boolean
	return dist <= trigger and now - lastAt >= cooldown
end

-- The oven light's multiplier `since` seconds after a flare: `boost` settling linearly to 1.
function LobbyLife.flare(since: number, boost: number, duration: number): number
	if since < 0 or since >= duration then
		return 1
	end
	return boost + (1 - boost) * (since / duration)
end

-- A walking NPC's loop (LP-D02): `points` is a closed loop of { x, z }; at each point the walker
-- stands `pause` seconds, then walks to the next at `speed` studs/s. The cycle length in seconds.
function LobbyLife.routeCycle(points: { { number } }, speed: number, pause: number): number
	local total = 0
	local n = #points
	for i = 1, n do
		local a, b = points[i], points[i % n + 1]
		total += pause + math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2) / speed
	end
	return total
end

-- Where the walker is `t` seconds into the shared clock (every client and the server agree):
-- x, z, the yaw it faces (towards the next point while walking, along the leg it came in on while
-- standing) and whether it is walking.
function LobbyLife.route(points: { { number } }, speed: number, pause: number, t: number): (number, number, number, boolean)
	local n = #points
	local cycle = LobbyLife.routeCycle(points, speed, pause)
	if n == 0 then
		return 0, 0, 0, false
	end
	local first = points[1]
	if n == 1 or cycle <= 0 then
		return first[1], first[2], 0, false
	end
	local left = t % cycle
	for i = 1, n do
		local a, b = points[i], points[i % n + 1]
		if left < pause then
			local prev = points[(i - 2) % n + 1]
			return a[1], a[2], LobbyLife.yawToward(prev[1], prev[2], a[1], a[2]), false
		end
		left -= pause
		local legT = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2) / speed
		if left < legT then
			local k = left / legT
			return a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k, LobbyLife.yawToward(a[1], a[2], b[1], b[2]), true
		end
		left -= legT
	end
	return first[1], first[2], 0, false -- float rounding at the very end of the cycle
end

return LobbyLife
