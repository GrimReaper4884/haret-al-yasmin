--!strict
-- What a landed hit draws (POLISH_PLAN PV-B02), decided from the Effects level so the controller
-- only draws; plus the slot maths of the damage-number pool. Pure (Lune-tested in vfx.spec).
--
-- "full": number, spark, and either a white flash (bosses and the selected tower's target: Roblox
-- caps Highlights, so only figures the player is watching get one) or a knockback nudge;
-- "reduced": the number only; "off": nothing.

export type Plan = { number: boolean, spark: boolean, flash: boolean, punch: boolean }

local HitFx = {}

function HitFx.plan(level: string, boss: boolean, watched: boolean): Plan
	if level == "off" then
		return { number = false, spark = false, flash = false, punch = false }
	end
	if level ~= "full" then
		return { number = true, spark = false, flash = false, punch = false }
	end
	local flash = boss or watched
	return { number = true, spark = true, flash = flash, punch = not flash }
end

-- A fixed pool of slots, each busy until a time. Acquire takes a free slot, or recycles the one
-- that frees soonest (the oldest number) so a burst never allocates and never drops the newest.
export type Pool = { untilAt: { number } }

function HitFx.newPool(size: number): Pool
	local u = table.create(size, 0)
	return { untilAt = u }
end

function HitFx.acquire(pool: Pool, now: number, life: number): number
	local best, bestAt = 1, math.huge
	for i, at in pool.untilAt do
		if at <= now then
			best = i
			break
		end
		if at < bestAt then
			best, bestAt = i, at
		end
	end
	pool.untilAt[best] = now + life
	return best
end

function HitFx.busy(pool: Pool, now: number): number
	local n = 0
	for _, at in pool.untilAt do
		if at > now then
			n += 1
		end
	end
	return n
end

-- Height of a rising number at progress k (0..1): quick rise that eases out.
function HitFx.rise(k: number, height: number): number
	local c = math.clamp(k, 0, 1)
	return height * (1 - (1 - c) * (1 - c))
end

-- Knockback (studs) of a punched figure at `elapsed` seconds: full at once, back to 0 by `life`.
function HitFx.knock(elapsed: number, life: number, amount: number): number
	if elapsed < 0 or elapsed >= life then
		return 0
	end
	return amount * (1 - elapsed / life)
end

-- A point on the coin's flight from (x0, y0) to (x1, y1) at progress k (0..1): a quadratic curve
-- whose middle sits `lift / 2` px above the higher end (screen space, y grows downward).
function HitFx.arc(k: number, x0: number, y0: number, x1: number, y1: number, lift: number): (number, number)
	local c = math.clamp(k, 0, 1)
	local cx, cy = (x0 + x1) / 2, 2 * math.min(y0, y1) - (y0 + y1) / 2 - lift
	local a, b, d = (1 - c) * (1 - c), 2 * (1 - c) * c, c * c
	return a * x0 + b * cx + d * x1, a * y0 + b * cy + d * y1
end

-- A camera shake offset (studs) at `elapsed` of `life`: a decaying jitter, zero after `life`.
function HitFx.shake(elapsed: number, life: number, amplitude: number, seed: number): (number, number)
	if elapsed < 0 or elapsed >= life then
		return 0, 0
	end
	local fall = amplitude * (1 - elapsed / life)
	return math.sin(elapsed * 90 + seed) * fall, math.cos(elapsed * 70 + seed * 1.7) * fall
end

return HitFx
