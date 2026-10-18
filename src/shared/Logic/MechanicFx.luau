--!strict
-- What the match HUD draws for the Season Story 1 mechanics (STORY_PLAN §10.3, S1-C02), decided here
-- so EnemyRenderController and MatchController only draw: the markers on an enemy's health bar, the
-- ground ring an enemy carries (drummer aura, porter shield) under a per-kind cap, where the dashes
-- of Lateef's telegraph fall along the road, which effects an Effects level keeps, and how many
-- flame pips the gate bar shows. Pure (Lune-tested in vfx.spec); callers pass the configs.

export type Ring = { kind: "aura" | "shield", radius: number }
export type Plan = { rings: boolean, telegraph: boolean, flashes: boolean }

local MechanicFx = {}

-- Health-bar markers, left to right: armour, stealth, and "?" while a disguise holds.
function MechanicFx.markers(def: any, revealed: boolean): { string }
	local out = {}
	if (def.armor or 0) > 0 then
		table.insert(out, "shield")
	end
	if def.stealth == true then
		table.insert(out, "eye")
	end
	if def.disguised == true and not revealed then
		table.insert(out, "mech_disguise")
	end
	return out
end

-- The ground ring an enemy carries (an aura wins over a shield; no attacker has both today).
function MechanicFx.ring(def: any): Ring?
	if def.aura and def.aura.radius then
		return { kind = "aura", radius = def.aura.radius }
	elseif def.shield and def.shield.radius then
		return { kind = "shield", radius = def.shield.radius }
	end
	return nil
end

-- Ring slots in use per kind: admit() takes one if `cap` allows, release() gives it back.
function MechanicFx.admit(counts: { [string]: number }, kind: string, cap: number): boolean
	local n = counts[kind] or 0
	if n >= cap then
		return false
	end
	counts[kind] = n + 1
	return true
end

function MechanicFx.release(counts: { [string]: number }, kind: string)
	counts[kind] = math.max(0, (counts[kind] or 0) - 1)
end

-- Effects level → what is drawn. Rings and the telegraph are play information ("reduced" keeps
-- them); the reveal and summon flashes are decoration ("full" only); "off" draws no world part.
function MechanicFx.plan(level: string): Plan
	if level == "off" then
		return { rings = false, telegraph = false, flashes = false }
	end
	return { rings = true, telegraph = true, flashes = level == "full" }
end

-- Path distances of the telegraph dashes from `from` to `to`, `spacing` apart, at most `maxDashes`
-- (spread evenly over the whole jump when it is longer), never past `to`.
function MechanicFx.dashes(from: number, to: number, spacing: number, maxDashes: number): { number }
	local out = {}
	local length = to - from
	if length <= 0 or spacing <= 0 or maxDashes <= 0 then
		return out
	end
	local n = math.min(maxDashes, math.max(1, math.floor(length / spacing)))
	local step = length / n
	for i = 1, n do
		table.insert(out, from + step * (i - 0.5))
	end
	return out
end

-- Health-bar size for an attacker (S1-C03): boss, small (snakes) or normal; `bars` is Vfx.STORY.bars.
function MechanicFx.bar(def: any, bars: any): { w: number, h: number, offset: number }
	if def.boss == true then
		return bars.boss
	elseif def.small == true then
		return bars.small
	end
	return bars.normal
end

-- Is an attacker enraged at this health fraction (its `enrage.belowHp` reached)? Bosses and
-- brutes charge once wounded; the client tints them from the 10 Hz health stream.
function MechanicFx.enraged(def: any, hpFrac: number): boolean
	local en = def.enrage
	return en ~= nil and hpFrac > 0 and hpFrac <= en.belowHp
end

-- Flame pips under the gate bar: one per burn stack, clamped to the stack cap.
function MechanicFx.burnPips(stacks: number?, maxStacks: number): number
	if type(stacks) ~= "number" or stacks ~= stacks then
		return 0
	end
	return math.clamp(math.floor(stacks), 0, maxStacks)
end

return MechanicFx
