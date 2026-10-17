--!strict
-- The Hakawati's room (AFK chamber) payouts: sitting time becomes cups of tea and finished tales
-- (Config/Afk, docs/AFK_CHAMBER.md). Days are UTC calendar days. Pure: the server passes the clock,
-- the multiplier and the rng.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Grants = sibling("Grants")

local AfkLogic = {}

local DAY = 86400

export type Payout = {
	kind: "cup" | "tale",
	granted: { [string]: any },
	capped: boolean, -- the day's lira were already in (only the overflow was paid)
	tale: string?, -- the tale just finished (kind "tale")
}

function AfkLogic.day(now: number): number
	return math.floor(now / DAY)
end

-- The pay multiplier: 1 + VIP_BONUS (VIP) + PREMIUM_BONUS (Roblox Premium).
function AfkLogic.multiplier(cfg: any, vip: boolean, premium: boolean): number
	return 1 + (if vip then cfg.VIP_BONUS else 0) + (if premium then cfg.PREMIUM_BONUS else 0)
end

-- Today's lira cap at this multiplier.
function AfkLogic.cap(cfg: any, mult: number): number
	return math.floor(cfg.DAILY_CAP_LIRA * mult)
end

-- Lira the room has paid today (0 when the stored day is another day). Read-only.
function AfkLogic.paidToday(profile: any, now: number): number
	local a = profile.afk
	return if a.day == AfkLogic.day(now) then a.lira else 0
end

-- The tale being told and how many of its cups have been poured (0..CUPS_PER_TALE-1). Read-only.
function AfkLogic.tale(profile: any, cfg: any): (string, number)
	local a = profile.afk
	return cfg.TALES[(a.tales % #cfg.TALES) + 1], a.cups % cfg.CUPS_PER_TALE
end

local function scaled(reward: any, mult: number): { [string]: number }
	local out = {}
	for k, v in reward do
		if type(v) == "number" then
			out[k] = math.floor(v * mult + 0.5)
		end
	end
	return out
end

local function pay(
	profile: any,
	cfg: any,
	kind: "cup" | "tale",
	mult: number,
	rng: () -> number,
	ctx: any
): Payout
	local a = profile.afk
	local room = AfkLogic.cap(cfg, mult) - a.lira
	local reward: { [string]: number }
	local capped = room <= 0
	if capped then
		reward = if kind == "cup" then scaled(cfg.OVERFLOW, mult) else {}
	else
		reward = scaled(if kind == "cup" then cfg.CUP else cfg.TALE, mult)
		reward.lira = math.min(reward.lira or 0, room)
		if kind == "tale" and rng() < cfg.TALE_STONE_CHANCE then
			reward.traitStones = 1
		end
	end
	local granted = Grants.apply(profile, reward, ctx)
	a.lira += granted.lira or 0
	return { kind = kind, granted = granted, capped = capped }
end

-- Adds `seconds` of sitting and pays every cup (and tale) they complete. Returns ok, err, payouts.
-- `seconds` is clamped to one flush window's worth so a stalled server can't pay a burst.
function AfkLogic.accrue(
	profile: any,
	seconds: number,
	now: number,
	cfg: any,
	mult: number,
	rng: () -> number,
	ctx: any
): (boolean, string?, { Payout }?)
	if type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 then
		return false, "bad_seconds", nil
	end
	seconds = math.min(seconds, cfg.FLUSH_SECONDS * 4)
	local a = profile.afk
	local today = AfkLogic.day(now)
	if a.day ~= today then
		a.day = today
		a.lira = 0
	end
	a.carry += seconds
	a.seconds += seconds
	local payouts: { Payout } = {}
	while a.carry >= cfg.CUP_SECONDS do
		a.carry -= cfg.CUP_SECONDS
		a.cups += 1
		table.insert(payouts, pay(profile, cfg, "cup", mult, rng, ctx))
		if a.cups % cfg.CUPS_PER_TALE == 0 then
			local finished = cfg.TALES[(a.tales % #cfg.TALES) + 1]
			a.tales += 1
			local p = pay(profile, cfg, "tale", mult, rng, ctx)
			p.tale = finished
			table.insert(payouts, p)
		end
	end
	return true, nil, payouts
end

-- Repairs profile.afk (used by ProfileSchema.sanitize).
function AfkLogic.sanitize(v: any): { [string]: number }
	local a = if type(v) == "table" then v else {}
	local function num(x: any, max: number, int: boolean): number
		if type(x) ~= "number" or x ~= x or x < 0 or x == math.huge then
			return 0
		end
		x = math.min(x, max)
		return if int then math.floor(x) else x
	end
	return {
		day = num(a.day, 1e7, true),
		lira = num(a.lira, 1e6, true),
		carry = num(a.carry, DAY, false),
		cups = num(a.cups, 1e9, true),
		tales = num(a.tales, 1e9, true),
		seconds = num(a.seconds, 1e10, false),
	}
end

return AfkLogic
