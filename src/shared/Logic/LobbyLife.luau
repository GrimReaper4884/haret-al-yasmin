--!strict
-- Lobby life math (POLISH_PLAN PV-E02): what each Effects level allows, the washing-line sway,
-- where each bird of the flock is, how a cat turns, a fountain ripple's phase and when the oven
-- puffs. LobbyLifeController draws it. Pure.

local LobbyLife = {}

export type Tier = { static: boolean, motion: boolean, particles: boolean }

-- Lane life "full": everything; "lite" (or the Effects tier's "reduced"): no particles but the world
-- still moves; "off": nothing extra at all (the vines too).
function LobbyLife.tier(level: string): Tier
	if level == "full" then
		return { static = true, motion = true, particles = true }
	elseif level == "reduced" or level == "lite" then
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

-- A rooftop neighbour's call (LP-D07): every `every` seconds of the shared clock (shifted by
-- `offset`) she calls down for `show` seconds. Returns which of `count` lines she is calling now
-- (they take turns, one per period) and whether this is the period's first `waveFor` seconds;
-- nil when she is quiet.
function LobbyLife.callAt(t: number, every: number, show: number, count: number, offset: number, waveFor: number): (number?, boolean)
	if count <= 0 or every <= 0 then
		return nil, false
	end
	local s = t - offset
	local into = s % every
	if into >= show then
		return nil, false
	end
	local period = math.floor(s / every)
	return period % count + 1, into < waveFor
end

export type Clock = { cycle: number, fade: number, phases: { { id: string, from: number, to: number } } }

-- The lane clock (LP-D09): which phase of the `cycle`-second day the shared time `t` falls in, how
-- many seconds into that phase, and the minute of the cycle. Phases are { id, from, to } in minutes.
function LobbyLife.clock(t: number, c: Clock): (string, number, number)
	local s = t % c.cycle
	local minute = s / 60
	for _, p in c.phases do
		if minute >= p.from and minute < p.to then
			return p.id, s - p.from * 60, minute
		end
	end
	local first = c.phases[1]
	return first.id, s - first.from * 60, minute
end

-- The light to draw at `t`: the previous phase's preset fading into this phase's over the first
-- `fade` seconds of each phase. Returns (from id, to id, k) with k in 0..1 (1 = fully this phase).
function LobbyLife.lightBlend(t: number, c: Clock): (string, string, number)
	local id, into = LobbyLife.clock(t, c)
	local prev = c.phases[#c.phases].id
	for i, p in c.phases do
		if p.id == id then
			prev = c.phases[(i - 2) % #c.phases + 1].id
			break
		end
	end
	if c.fade <= 0 or into >= c.fade then
		return id, id, 1
	end
	local k = into / c.fade
	return prev, id, k * k * (3 - 2 * k) -- smoothstep
end

-- A recurring beat (LP-D10): `b` = { phases, every, offset, length } in seconds. Returns how many
-- seconds into the beat `t` is, or nil when it is not playing. A beat plays only when both its start
-- and `t` fall in one of its phases, so a window never spills into the next part of the day.
function LobbyLife.beatAt(t: number, c: Clock, b: { phases: { string }, every: number, offset: number, length: number }): number?
	local into = (t - b.offset) % b.every
	if into >= b.length then
		return nil
	end
	local now = LobbyLife.clock(t, c)
	local start = LobbyLife.clock(t - into, c)
	if table.find(b.phases, now) and table.find(b.phases, start) then
		return into
	end
	return nil
end

-- Seconds into `phase` when `t` lies between `from` and `to` seconds of it, else nil (the evening tale's
-- lines, the night watch's calls).
function LobbyLife.inPhase(t: number, c: Clock, phase: string, from: number, to: number): number?
	local id, into = LobbyLife.clock(t, c)
	if id == phase and into >= from and into < to then
		return into - from
	end
	return nil
end

-- The lane gate's leaves (degrees open; 100 = against the walls): they swing to `nightAngle` over the
-- first `swing` s of the night and back open over the first `swing` s of dawn.
function LobbyLife.gateAngle(t: number, c: Clock, g: { swing: number, nightAngle: number }): number
	local id, into = LobbyLife.clock(t, c)
	local k = math.clamp(into / g.swing, 0, 1)
	if id == "night" then
		return 100 + (g.nightAngle - 100) * k
	elseif id == "dawn" then
		return g.nightAngle + (100 - g.nightAngle) * k
	end
	return 100
end

return LobbyLife
