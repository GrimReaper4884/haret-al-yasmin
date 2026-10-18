--!strict
-- What the tower panel and the Units screen offer for a defender's growth (STORY_PLAN §10.3, S1-C04),
-- decided here so the controllers only draw: the next step of a placed defender (another level, the
-- level-7 signature choice, or done), a signature's price, what a defender has cost so far (the sell
-- price is a share of it, as TdTowers keeps `invested`), and a unit's three bead slots. Pure:
-- callers pass the configs and UnitLogic's helpers.

export type Step = "level" | "choose" | "max"
export type BeadSlot = { slot: number, kind: string? }
export type BeadChoice = { kind: string, current: boolean }

local UpgradeView = {}

-- "level" while a level is left; "choose" at the last level of a unit with a signature and no path
-- yet; "max" otherwise (a signature bought, or none to buy).
function UpgradeView.step(def: any, level: number, path: string?): Step
	local last = #def.levels
	if level < last then
		return "level"
	elseif level == last and def.signature and path == nil then
		return "choose"
	end
	return "max"
end

-- A signature path's price after the trait (costFor = UnitLogic.costFor), or nil.
function UpgradeView.signatureCost(
	def: any,
	path: string,
	trait: any?,
	costFor: (number, any?) -> number
): number?
	local sig = def.signature and def.signature[path]
	if not sig then
		return nil
	end
	return costFor(sig.cost, trait)
end

-- Cash put into a placed defender: every level up to `level` and its signature, each after the trait.
function UpgradeView.invested(
	def: any,
	level: number,
	path: string?,
	trait: any?,
	costFor: (number, any?) -> number
): number
	local total = 0
	for i = 1, math.min(level, #def.levels) do
		total += costFor(def.levels[i].cost, trait)
	end
	if path then
		total += UpgradeView.signatureCost(def, path, trait, costFor) or 0
	end
	return total
end

-- The unit's slots in order; an empty slot ("" in the profile, or missing) has no kind.
function UpgradeView.beadSlots(owned: any, slots: number, kinds: { [string]: any }): { BeadSlot }
	local out: { BeadSlot } = {}
	local held = owned and owned.beads or {}
	for i = 1, slots do
		local k = held[i]
		table.insert(out, { slot = i, kind = if type(k) == "string" and kinds[k] then k else nil })
	end
	return out
end

-- The kinds a slot may take (UnitLogic.beadKinds), marking the one it already holds.
function UpgradeView.beadChoices(allowed: { string }, current: string?): { BeadChoice }
	local out: { BeadChoice } = {}
	for _, kind in allowed do
		table.insert(out, { kind = kind, current = kind == current })
	end
	return out
end

return UpgradeView
